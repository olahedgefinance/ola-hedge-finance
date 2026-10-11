import 'dart:io';
import 'dart:convert';
import '../../tool/compliance/font_evidence.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../tool/compliance/generate_sbom.dart';

void main() {
  final root = Directory.current.parent;
  final records = (jsonDecode(
      File('${root.path}/$fontEvidencePath/manifest.json')
          .readAsStringSync())['records'] as List);
  Map<String, dynamic> row(String id) =>
      jsonDecode(jsonEncode(records.singleWhere((r) => r['id'] == id)));
  List<int> repo(String p) => File('${root.path}/$p').readAsBytesSync();
  List<int> evidence(String p) =>
      File('${root.path}/$fontEvidencePath/$p').readAsBytesSync();
  String check(Map<String, dynamic> r, {List<int> Function(String)? read}) =>
      validateFontRecord(r, repo, read ?? evidence);
  test('all seven application font records validate conservatively', () {
    expect(verifyFontEvidence(root).length, 7);
  });
  test('matching version metadata without exact proof cannot clear a font', () {
    final r = row('font:Inter');
    r['licenseDeclared'] = 'OFL-1.1';
    expect(() => check(r), throwsStateError);
  });
  test('proprietary font cannot inherit a family licence', () {
    final r = row('font:Avenir');
    r['proof'] = row('font:DMSans')['proof'];
    r['licenseDeclared'] = 'OFL-1.1';
    r['classification'] = 'Verified with conditions';
    expect(() => check(r), throwsStateError);
  });
  test('source version substitution fails even for the same family', () {
    final r = row('font:DMSans');
    r['proof']['commit'] = '0000000000000000000000000000000000000000';
    expect(() => check(r), throwsStateError);
  });
  test('one matched weight does not clear an unmatched sibling', () {
    final r = row('font:DMSans');
    (r['proof']['matches'] as List).removeLast();
    expect(() => check(r), throwsStateError);
  });
  test('licence and original copyright bytes are mandatory', () {
    expect(
        () => check(row('font:DMSans'),
            read: (p) =>
                p == 'DMSans/LICENSE.txt' ? utf8.encode('OFL') : evidence(p)),
        throwsStateError);
  });
  test('changed bundled binary fails closed', () {
    final r = row('font:DMSans');
    r['files'][0]['sha256'] = '0' * 64;
    expect(() => check(r), throwsStateError);
  });
  test('unsafe source evidence path is rejected', () {
    final r = row('font:DMSans');
    r['proof']['commitPath'] = '../outside';
    expect(() => check(r), throwsStateError);
  });
  test('technical evidence never becomes legal or release approval', () {
    for (final field in ['legalClearance', 'releaseClearance']) {
      final r = row('font:DMSans');
      r[field] = true;
      expect(() => check(r), throwsStateError);
    }
  });

  test('exact DM Sans source evidence improves only its declared licence',
      () async {
    final bundle = await createComplianceArtifactBundle(
        repositoryRoot: Directory.current.parent);
    final dm = bundle.components.singleWhere((c) => c.id == 'font:DMSans');
    expect(dm.licenseDeclared, 'OFL-1.1');
    expect(dm.reviewStatus, 'verified-with-conditions');
    for (final id in [
      'font:Avenir',
      'font:Inter',
      'font:Inconsolata',
      'font:RobotoCondensed',
      'font:Metropolis',
      'font:Icons'
    ]) {
      expect(bundle.components.singleWhere((c) => c.id == id).licenseDeclared,
          'NOASSERTION');
    }
    expect(bundle.auditGaps.any((g) => g['id'] == 'font-rights'), isTrue);
  });
}
