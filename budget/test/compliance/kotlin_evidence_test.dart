import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../tool/compliance/kotlin_evidence.dart';
import '../../tool/compliance/generate_sbom.dart';

void main() {
  final root = Directory.current.parent;
  final manifest = jsonDecode(
      File('${root.path}/$kotlinEvidencePath/manifest.json')
          .readAsStringSync()) as Map;
  final rows = (manifest['records'] as List).cast<Map<String, dynamic>>();
  final records = {for (final r in rows) r['coordinate'] as String: r};
  Map<String, dynamic> row(String name) =>
      jsonDecode(jsonEncode(rows.singleWhere((r) => r['id'] == 'maven:$name')));
  List<int> read(String p) =>
      File('${root.path}/$kotlinEvidencePath/$p').readAsBytesSync();
  String check(Map<String, dynamic> r,
          {Map? m, Set<String>? hashes, List<int> Function(String)? reader}) =>
      validateKotlinRecord(
          r,
          {'id': r['id'], 'version': r['version']},
          hashes ??
              (r['files'] as List)
                  .where((f) => f['role'] == 'binary')
                  .map((f) => f['sha256'] as String)
                  .toSet(),
          reader ?? read,
          records: records,
          manifest: m ?? manifest);
  test('exact stdlib evidence preserves simultaneous Boost terms', () async {
    final bundle = await createComplianceArtifactBundle(repositoryRoot: root);
    expect(
        bundle.components
            .singleWhere(
                (c) => c.id == 'maven:org.jetbrains.kotlin:kotlin-stdlib')
            .licenseDeclared,
        'Apache-2.0 AND BSL-1.0');
    expect(
        bundle.components
            .singleWhere((c) => c.id == 'maven:com.google.firebase:firebase-common')
            .licenseDeclared,
        'NOASSERTION');
  });
  test('review distinguishes metadata, stdlib and unverified debug payload',
      () {
    expect(rows.length, 9);
    expect(rows.where((r) => check(r) != 'NOASSERTION').length, 8);
    expect(check(row('org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm')),
        'NOASSERTION');
    expect(check(row('org.jetbrains.kotlin:kotlin-bom'), hashes: {}),
        'Apache-2.0');
    expect(
        check(row('org.jetbrains.kotlinx:kotlinx-coroutines-core'), hashes: {}),
        'Apache-2.0');
  });
  test('Boost terms cannot be silently collapsed to Apache or OR', () {
    for (final declaration in ['Apache-2.0', 'Apache-2.0 OR BSL-1.0']) {
      final r = row('org.jetbrains.kotlin:kotlin-stdlib');
      r['licenseDeclared'] = declaration;
      expect(() => check(r), throwsStateError);
    }
  });
  test('rehashed clean audit cannot clear bundled debug binary', () {
    final r = row('org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm');
    final audit = jsonDecode(utf8.decode(read(r['audit']['path']))) as Map;
    for (final scan in (audit['archives'] as Map).values) {
      scan['risks'] = [];
    }
    final bytes = utf8.encode(jsonEncode(audit)),
        hash = sha256.convert(utf8.encode(jsonEncode(audit))).toString();
    final path = 'blobs/$hash.bin';
    r['audit'] = {'path': path, 'sha256': hash, 'bytes': bytes.length};
    r['licenseDeclared'] = 'Apache-2.0';
    r['classification'] = 'Verified with conditions';
    expect(() => check(r, reader: (p) => p == path ? bytes : read(p)),
        throwsStateError);
  });
  test('missing exact source or POM cannot fall back to family licence', () {
    for (final role in ['source', 'pom']) {
      final r = row('org.jetbrains.kotlinx:kotlinx-coroutines-android');
      (r['files'] as List).removeWhere((f) => f['role'] == role);
      expect(() => check(r), throwsStateError);
    }
  });
  test('published Gradle module metadata cannot be omitted', () {
    final r = row('org.jetbrains.kotlinx:kotlinx-coroutines-android');
    (r['files'] as List).removeWhere((f) => f['role'] == 'module');
    expect(() => check(r), throwsStateError);
  });
  test('wrong release or source publisher is rejected', () {
    final r = row('org.jetbrains.kotlin:kotlin-stdlib');
    r['version'] = '1.8.22';
    expect(() => check(r), throwsStateError);
    final s = row('org.jetbrains.kotlin:kotlin-stdlib');
    (s['files'] as List).firstWhere((f) => f['role'] == 'source')['url'] =
        'https://example.org/source.jar';
    expect(() => check(s), throwsStateError);
  });
  test('graph binary hashes must agree with acquired release', () {
    expect(
        () => check(row('org.jetbrains.kotlin:kotlin-stdlib'),
            hashes: {'0' * 64}),
        throwsStateError);
  });
  test('BOM metadata cannot stand in for a runtime binary', () {
    expect(
        () => check(row('org.jetbrains.kotlin:kotlin-bom'), hashes: {'0' * 64}),
        throwsStateError);
    final r = row('org.jetbrains.kotlin:kotlin-stdlib');
    (r['files'] as List).firstWhere((f) => f['role'] == 'binary')['role'] =
        'reference-binary';
    expect(() => check(r, hashes: {}), throwsStateError);
  });
  test('headerless source requires exact upstream byte mapping', () {
    final r = row('org.jetbrains.kotlin:kotlin-stdlib-common');
    r['sourceMappings'][0]['sha256'] = '0' * 64;
    expect(() => check(r), throwsStateError);
  });
  test('coroutine NOTICE must be retained from the same release', () {
    final m = jsonDecode(jsonEncode(manifest)) as Map;
    final u = (m['upstreams'] as List).firstWhere((u) => u['tag'] == '1.7.3');
    final f = (u['files'] as List)
        .firstWhere((f) => f['sourcePath'] == 'license/NOTICE.txt');
    f['url'] = (f['url'] as String).replaceAll(u['commit'], 'main');
    expect(
        () => check(row('org.jetbrains.kotlinx:kotlinx-coroutines-android'),
            m: m),
        throwsStateError);
  });
  test('exact upstream tag identity cannot be switched across Kotlin releases',
      () {
    final r = row('org.jetbrains.kotlin:kotlin-bom');
    r['upstreamKey'] = 'v1.9.0';
    expect(() => check(r), throwsStateError);
  });
  test('legal and release clearance claims fail closed', () {
    for (final field in ['legalClearance', 'releaseClearance', 'conditions']) {
      final r = row('org.jetbrains.kotlinx:kotlinx-coroutines-play-services');
      r[field] = field == 'conditions' ? [] : true;
      expect(() => check(r), throwsStateError);
    }
  });
  test('unrelated JetBrains utilities cannot inherit Kotlin evidence', () {
    final r = row('org.jetbrains.kotlin:kotlin-stdlib');
    r['id'] = 'maven:org.jetbrains:annotations';
    r['coordinate'] = 'org.jetbrains:annotations:1.9.0';
    expect(() => check(r), throwsStateError);
  });
  test('multiplatform JVM publication requires reciprocal parent metadata', () {
    final r = row('org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm');
    expect(
        () => validateKotlinRecord(
            r,
            {'id': r['id'], 'version': r['version']},
            (r['files'] as List)
                .where((f) => f['role'] == 'binary')
                .map((f) => f['sha256'] as String)
                .toSet(),
            read,
            manifest: manifest),
        throwsStateError);
  });
}
