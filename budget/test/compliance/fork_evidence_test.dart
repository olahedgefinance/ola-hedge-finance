import 'dart:io';
import 'dart:convert';
import '../../tool/compliance/fork_evidence.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../tool/compliance/generate_sbom.dart';

void main() {
  final root = Directory.current.parent;
  final manifest = jsonDecode(
      File('${root.path}/$forkEvidencePath/manifest.json').readAsStringSync());
  final entries =
      parsePubLock(File('${root.path}/budget/pubspec.lock').readAsStringSync());
  Map<String, dynamic> row(String name) => Map<String, dynamic>.from(
      (manifest['records'] as List).singleWhere((r) => r['name'] == name));
  void verify(Map<String, dynamic> r) =>
      validateForkIdentity(r, entries.singleWhere((e) => e.name == r['name']));
  test('stale fork revision and source URL are rejected', () {
    expect(() => verify(row('file_picker')..['forkCommit'] = '0' * 40),
        throwsStateError);
    expect(
        () => verify(
            row('file_picker')..['forkRepository'] = 'https://example.invalid'),
        throwsStateError);
  });
  test('archive comparisons cannot invent Git ancestry or version', () {
    expect(() => verify(row('sliding_sheet')..['upstreamCommit'] = '0' * 40),
        throwsStateError);
    expect(() => verify(row('sliding_sheet')..['upstreamVersion'] = '0.0.0'),
        throwsStateError);
  });
  test('technical evidence cannot claim release clearance', () {
    expect(
        () => verify(row('reorderable_grid_view')..['releaseClearance'] = true),
        throwsStateError);
  });
  test('retained provenance cannot be substituted', () {
    for (final name in ['file_picker', 'sliding_sheet']) {
      final r = row(name);
      final file = r['source'] == 'git' ? 'ancestry.json' : 'pub-version.json';
      final proof = jsonDecode(
          File('${root.path}/$forkEvidencePath/$name/$file')
              .readAsStringSync()) as Map<String, dynamic>;
      validateForkProvenance(r, proof);
      r[r['source'] == 'git' ? 'upstreamCommit' : 'archiveSha256'] = '0' * 64;
      expect(() => validateForkProvenance(r, proof), throwsStateError);
    }
  });
  test('complete fork evidence closes only the technical fork gap', () async {
    final bundle = await createComplianceArtifactBundle(
        repositoryRoot: Directory.current.parent);
    expect(
        bundle.auditGaps.where((g) => g['id'] == 'fork-delta-review'), isEmpty);
    expect(bundle.auditGaps.length, 7);
    for (final name in [
      'file_picker',
      'reorderable_grid_view',
      'sliding_sheet',
      'implicitly_animated_reorderable_list'
    ]) {
      final component =
          bundle.components.singleWhere((c) => c.id == 'pub:$name');
      expect(component.modified, isTrue);
      expect(component.reviewStatus, 'verified-with-conditions');
      expect(component.notes, contains('forks/manifest.json'));
    }
  });
}
