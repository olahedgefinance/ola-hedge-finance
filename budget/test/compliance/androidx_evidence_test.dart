import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../tool/compliance/androidx_evidence.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../tool/compliance/generate_sbom.dart';

void main() {
  final root = Directory.current.parent;
  final manifest = jsonDecode(
      File('${root.path}/$androidXEvidencePath/manifest.json')
          .readAsStringSync()) as Map;
  final rows = (manifest['records'] as List).cast<Map<String, dynamic>>();
  final records = {for (final r in rows) r['coordinate'] as String: r};
  Map<String, dynamic> row(String name) =>
      jsonDecode(jsonEncode(rows.singleWhere((r) => r['id'] == 'maven:$name')));
  List<int> read(String p) =>
      File('${root.path}/$androidXEvidencePath/$p').readAsBytesSync();
  String check(Map<String, dynamic> r,
          {Set<String>? hashes, List<int> Function(String)? reader}) =>
      validateAndroidXRecord(
          r,
          {'id': r['id'], 'version': r['coordinate'].split(':').last},
          hashes ??
              (r['files'] as List)
                  .where((f) => f['role'] == 'binary')
                  .map((f) => f['sha256'] as String)
                  .toSet(),
          reader ?? read,
          records: records);
  test('reviewed cohort is exact and conditional, not a namespace rule', () {
    expect(rows.length, 59);
    expect(rows.where((r) => check(r) == 'Apache-2.0').length, 50);
    expect(rows.where((r) => check(r) == 'NOASSERTION').length, 9);
  });
  test('content-address-valid false scope audit cannot clear embedded code',
      () {
    final r = row('androidx.datastore:datastore-preferences-core');
    final audit = jsonDecode(utf8.decode(read(r['audit']['path']))) as Map;
    for (final scan in (audit['archives'] as Map).values.cast<Map>()) {
      scan['risks'] = [];
    }
    final bytes = utf8.encode(jsonEncode(audit));
    final hash = sha256.convert(bytes).toString();
    final path = 'blobs/$hash.bin';
    r['audit'] = {'path': path, 'sha256': hash, 'bytes': bytes.length};
    r['classification'] = 'Verified with conditions';
    r['licenseDeclared'] = 'Apache-2.0';
    expect(() => check(r, reader: (p) => p == path ? bytes : read(p)),
        throwsStateError);
  });
  test('selected version cannot be silently substituted', () {
    final r = row('androidx.activity:activity');
    r['version'] = '1.7.3';
    expect(() => check(r), throwsStateError);
  });
  test('source URL is bound to the exact publisher release', () {
    final r = row('androidx.activity:activity');
    (r['files'] as List).firstWhere((f) => f['role'] == 'source')['url'] =
        'https://example.org/activity-1.7.2-sources.jar';
    expect(() => check(r), throwsStateError);
  });
  test('resolved binary must match the authoritative acquisition', () {
    expect(() => check(row('androidx.activity:activity'), hashes: {'0' * 64}),
        throwsStateError);
  });
  test('missing source and POM fail closed', () {
    for (final role in ['source', 'pom']) {
      final r = row('androidx.activity:activity');
      (r['files'] as List).removeWhere((f) => f['role'] == role);
      expect(() => check(r), throwsStateError);
    }
  });
  test('retained source or notice audit tampering fails', () {
    final r = row('androidx.activity:activity');
    for (final path in [
      r['audit']['path'],
      (r['files'] as List).firstWhere((f) => f['role'] == 'source')['path']
    ]) {
      expect(
          () => check(r,
              reader: (p) => p == path ? utf8.encode('changed') : read(p)),
          throwsStateError);
    }
  });
  test('embedded protobuf or raster scope cannot inherit Apache POM clearance',
      () {
    for (final name in [
      'androidx.datastore:datastore-preferences-core',
      'androidx.work:work-runtime',
      'androidx.appcompat:appcompat'
    ]) {
      final r = row(name);
      r['classification'] = 'Verified with conditions';
      r['licenseDeclared'] = 'Apache-2.0';
      expect(() => check(r), throwsStateError);
    }
  });
  test('legal/release clearance assertions and missing conditions fail', () {
    for (final field in ['legalClearance', 'releaseClearance', 'conditions']) {
      final r = row('androidx.activity:activity');
      r[field] = field == 'conditions' ? [] : true;
      expect(() => check(r), throwsStateError);
    }
  });
  test('payload paths cannot escape evidence directory', () {
    final r = row('androidx.activity:activity');
    r['audit']['path'] = '../manifest.json';
    expect(() => check(r), throwsStateError);
  });
  test('Kotlin and other namespaces cannot enter AndroidX review', () {
    final r = row('androidx.activity:activity');
    r['coordinate'] = 'org.jetbrains.kotlin:kotlin-stdlib:1.9.0';
    r['id'] = 'maven:org.jetbrains.kotlin:kotlin-stdlib';
    r['version'] = '1.9.0';
    expect(() => check(r), throwsStateError);
  });
  test('multiplatform parent link is required and version bound', () {
    final r = row('androidx.annotation:annotation-jvm');
    expect(check(r), 'Apache-2.0');
    expect(
        () => validateAndroidXRecord(
            r,
            {'id': r['id'], 'version': r['version']},
            (r['files'] as List)
                .where((f) => f['role'] == 'binary')
                .map((f) => f['sha256'] as String)
                .toSet(),
            read),
        throwsStateError);
  });
  test('metadata and empty compatibility artifacts retain scoped conditions',
      () {
    final metadata = row('androidx.annotation:annotation');
    expect(check(metadata, hashes: {}), 'Apache-2.0');
    expect(metadata['distributed'], false);
    final empty = row('androidx.lifecycle:lifecycle-common-java8');
    expect(check(empty), 'Apache-2.0');
    expect(
        (empty['conditions'] as List)
            .any((c) => c.contains('Empty compatibility')),
        true);
  });
  test('exact AndroidX activity source evidence improves only its declaration',
      () async {
    final bundle = await createComplianceArtifactBundle(
        repositoryRoot: Directory.current.parent);
    final activity = bundle.components
        .singleWhere((c) => c.id == 'maven:androidx.activity:activity');
    expect(activity.licenseDeclared, 'Apache-2.0');
    expect(activity.reviewStatus, 'verified-with-conditions');
    expect(
        bundle.components
            .singleWhere(
                (c) => c.id == 'maven:com.google.firebase:firebase-common')
            .licenseDeclared,
        'NOASSERTION');
    expect(
        bundle.auditGaps.any((g) => g['id'] == 'android-transitive-resolution'),
        isTrue);
  });
}
