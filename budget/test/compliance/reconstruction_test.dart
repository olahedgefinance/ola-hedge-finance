import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../tool/compliance/release_compliance.dart';
import '../../tool/compliance/generate_sbom.dart';

void main() {
  final root = Directory.current.parent;
  test(
      'canonical origin without dot-git is accepted without hiding identity blockers',
      () async {
    final errors = await runRepositoryComplianceAudit(repositoryRoot: root);
    expect(errors.where((e) => e.contains('origin remote')), isEmpty);
  });
  test(
      'strict gate reports unresolved inventory even with incomplete release metadata',
      () async {
    final errors = await runReleaseComplianceChecks(
        repositoryRoot: root,
        releaseManifestFile: File(
            '${root.path}/compliance/release/release-manifest.template.json'));
    expect(
        errors,
        contains(
            contains('Unresolved release gap: android-transitive-resolution')));
    expect(errors,
        contains(contains('Uncleared distributed component: font:Avenir')));
  });
  test('generator rejects tampered retained notice bytes', () async {
    final manifest = jsonDecode(File(
            '${root.path}/compliance/evidence/reconstruction-2026-10-09/pub/manifest.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final record = (manifest['records'] as List)
        .firstWhere((r) => r['id'] == 'pub:crypto');
    final path = record['files'][0]['path'];
    final source = File('${root.path}/$path');
    // Only this new evidence file is touched, restored byte-for-byte even on failure.
    final bytes = source.readAsBytesSync();
    try {
      source.writeAsStringSync('tampered notice');
      await expectLater(createComplianceArtifactBundle(repositoryRoot: root),
          throwsStateError);
    } finally {
      source.writeAsBytesSync(bytes);
    }
  });
}
