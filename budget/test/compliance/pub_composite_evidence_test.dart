import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../tool/compliance/generate_sbom.dart';
import '../../tool/compliance/pub_composite_evidence.dart';

void main() {
  final root = Directory.current.parent;
  final folder = Directory('${root.path}/$pubCompositeEvidencePath');
  final records =
      (jsonDecode(File('${folder.path}/manifest.json').readAsStringSync())[
              'records'] as List)
          .cast<Map<String, dynamic>>();
  final locked =
      parsePubLock(File('${root.path}/budget/pubspec.lock').readAsStringSync());
  Map<String, dynamic> row(String name) =>
      jsonDecode(jsonEncode(records.singleWhere((r) => r['name'] == name)));
  List<int> read(String path) => File('${folder.path}/$path').readAsBytesSync();
  String check(Map<String, dynamic> record) => validatePubCompositeRecord(
      record, locked.singleWhere((e) => e.name == record['name']), read);

  test('exact vector_math archive preserves simultaneous BSD and Zlib grants',
      () async {
    final bundle = await createComplianceArtifactBundle(repositoryRoot: root);
    expect(
        bundle.components
            .singleWhere((c) => c.id == 'pub:vector_math')
            .licenseDeclared,
        'BSD-3-Clause AND Zlib');
  });
  test('image_picker_android preserves Apache source and BSD wrapper grants',
      () async {
    final bundle = await createComplianceArtifactBundle(repositoryRoot: root);
    expect(
        bundle.components
            .singleWhere((c) => c.id == 'pub:image_picker_android')
            .licenseDeclared,
        'Apache-2.0 AND BSD-3-Clause');
    final spdx = jsonDecode(bundle.files['compliance/sbom/current.spdx.json']!);
    expect(
        (spdx['packages'] as List)
            .every((p) => p['licenseConcluded'] == 'NOASSERTION'),
        isTrue);
  });
  test('all ten reviews retain five ambiguous declarations', () {
    expect(records.length, 10);
    final unresolved = records
        .where((r) => check(r) == 'NOASSERTION')
        .map((r) => r['name'])
        .toSet();
    expect(unresolved, {
      'flutter_charset_detector',
      'image_picker',
      'image_picker_ios',
      'universal_html',
      'url_launcher_web'
    });
  });
  test(
      'three complete wrapper archives retain external engine notices without OR',
      () {
    for (final name in [
      'flutter_charset_detector_android',
      'flutter_charset_detector_ios',
      'flutter_charset_detector_platform_interface'
    ]) {
      final r = row(name);
      expect(check(r), 'MPL-2.0');
      expect(classifyLicenseText(utf8.decode(read('$name/source/LICENSE'))),
          'NOASSERTION');
    }
  });
  test('AND cannot be replaced with OR or a single permissive grant', () {
    for (final expression in ['BSD-3-Clause OR Zlib', 'BSD-3-Clause', 'MIT']) {
      final r = row('vector_math')..['declaration'] = expression;
      expect(() => check(r), throwsStateError);
    }
    final r = row('vector_math')..['operator'] = 'OR';
    expect(() => check(r), throwsStateError);
  });
  test('wrong release version archive or invented Git mapping is rejected', () {
    for (final field in [
      'version',
      'archiveSha256',
      'archiveUrl',
      'gitCommit',
      'sourceRepository'
    ]) {
      final r = row('vector_math')..[field] = 'wrong';
      expect(() => check(r), throwsStateError, reason: field);
    }
  });
  test('missing source witnesses and changed normalisation cannot pass', () {
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (r) => r['terms'][0]['scopeFiles'] = [],
      (r) => r['terms'][0]['scopeFiles'] = ['absent.dart'],
      (r) => r['terms'][0]['spdx'] = 'MIT',
      (r) => r['terms'][0]['endLine'] = 10,
      (r) => r['sourceScope'].removeLast(),
      (r) => r['terms'].removeLast(),
    ]) {
      final r = row('vector_math');
      mutate(r);
      expect(() => check(r), throwsStateError);
    }
  });
  test('wrapper declarations require complete retained archive coverage', () {
    final r = row('flutter_charset_detector_android');
    (r['retainedFiles'] as List)
        .removeWhere((f) => f['archivePath'] == 'CHANGELOG.md');
    expect(() => check(r), throwsStateError);
  });
  test('complete notices cannot be removed or tampered with', () {
    final r = row('vector_math');
    (r['retainedFiles'] as List)
        .removeWhere((f) => f['archivePath'] == 'AUTHORS');
    expect(() => check(r), throwsStateError);
    final clean = row('vector_math');
    expect(
        () => validatePubCompositeRecord(
            clean,
            locked.singleWhere((e) => e.name == 'vector_math'),
            (path) =>
                path.endsWith('/LICENSE') ? [...read(path), 32] : read(path)),
        throwsStateError);
  });
  test('unsafe or cross-package payload paths are rejected', () {
    for (final path in [
      '../escape.json',
      '/absolute',
      'C:/drive',
      'vector_math\\release.json',
      'image_picker/release.json'
    ]) {
      final r = row('vector_math')..['releaseMetadataPath'] = path;
      expect(() => check(r), throwsStateError);
    }
  });
  test('ambiguous records cannot promote themselves or claim clearance', () {
    final r = row('url_launcher_web')..['declaration'] = 'BSD-3-Clause';
    expect(() => check(r), throwsStateError);
    for (final key in ['releaseClearance', 'legalClearance']) {
      final r = row('vector_math')..[key] = true;
      expect(() => check(r), throwsStateError);
    }
  });
  test('duplicate archive paths and payload source substitutions fail', () {
    final r = row('vector_math');
    expect(
        () => validatePubCompositeRecord(
                r, locked.singleWhere((e) => e.name == 'vector_math'), (path) {
              if (!path.endsWith('archive-inventory.json')) return read(path);
              final files = jsonDecode(utf8.decode(read(path))) as List;
              files.add(files.first);
              return utf8.encode(jsonEncode(files));
            }),
        throwsStateError);
  });
  test('scoped Pub review cannot promote an unresolved CocoaPods declaration',
      () async {
    final bundle = await createComplianceArtifactBundle(repositoryRoot: root);
    expect(
        bundle.components
            .singleWhere((c) => c.id == 'pub:flutter_charset_detector_ios')
            .licenseDeclared,
        'MPL-2.0');
    expect(
        bundle.components
            .singleWhere(
                (c) => c.id == 'cocoapods:flutter_charset_detector_ios')
            .licenseDeclared,
        'NOASSERTION');
  });
}
