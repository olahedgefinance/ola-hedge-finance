import 'dart:io';
import 'dart:convert';
import '../../tool/compliance/android_evidence.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../tool/compliance/generate_sbom.dart';

void main() {
  Map<String, dynamic> graph() => jsonDecode(File(
          '${Directory.current.parent.path}/$androidEvidencePath/resolved-graph.json')
      .readAsStringSync());
  test('identical multi-variant artifact observations are accepted', () {
    expect(() => validateAndroidGraph(graph()), returnsNormally);
  });
  test('conflicting artifact observations fail conservatively', () {
    final g = graph();
    final a = g['configurations'][0]['artifacts'] as List;
    final duplicate = jsonDecode(jsonEncode(a.first));
    duplicate['sha256'] = '0' * 64;
    a.add(duplicate);
    expect(() => validateAndroidGraph(g), throwsStateError);
  });
  test('missing selected node fails graph verification', () {
    final g = graph();
    (g['configurations'][0]['components'] as List).removeAt(0);
    expect(() => validateAndroidGraph(g), throwsStateError);
  });
  test('wrong configuration cannot stand in for production resolution', () {
    final g = graph();
    g['configurations'][0]['name'] = 'developmentDebugRuntimeClasspath';
    expect(() => validateAndroidGraph(g), throwsStateError);
  });
  test('dynamic selected version cannot be recorded as exact provenance', () {
    final g = graph();
    final n = g['configurations'][0]['components'][0];
    n['id'] = 'example:library:1.+';
    n['module'] = n['id'];
    expect(() => validateAndroidGraph(g), throwsStateError);
  });

  Future<ComplianceArtifactBundle> bundle() =>
      createComplianceArtifactBundle(repositoryRoot: Directory.current.parent);
  test(
      'Android graph selects actual Firebase versions instead of root BOM assumptions',
      () async {
    final b = await bundle();
    expect(
        b.components
            .singleWhere(
                (c) => c.id == 'maven:com.google.firebase:firebase-auth')
            .version,
        '23.0.0');
    expect(
        b.components
            .singleWhere(
                (c) => c.id == 'maven:com.google.firebase:firebase-firestore')
            .version,
        '25.0.0');
    expect(
        b.components
            .singleWhere(
                (c) => c.id == 'maven:com.google.firebase:firebase-bom')
            .version,
        '33.1.0');
  });
  test(
      'observed native transitives enter inventory without guessed licence clearance',
      () async {
    final b = await bundle();
    final c = b.components.singleWhere(
        (c) => c.id == 'maven:com.google.android.gms:play-services-basement');
    expect(c.licenseDeclared, 'NOASSERTION');
    expect(c.dependencies, isNotEmpty);
    expect(c.reviewStatus, 'review-required');
  });
  test(
      'Flutter plugin edges and separate desugaring configuration are retained',
      () async {
    final b = await bundle();
    expect(
        b.components
            .singleWhere((c) => c.id == 'pub:in_app_review')
            .dependencies,
        contains('maven:com.google.android.play:review'));
    expect(
        b.components
            .singleWhere((c) => c.id == 'pub:firebase_auth')
            .dependencies,
        contains('maven:com.google.firebase:firebase-auth'));
    expect(
        b.components
            .singleWhere(
                (c) => c.id == 'maven:com.android.tools:desugar_jdk_libs')
            .dependencies,
        contains('maven:com.android.tools:desugar_jdk_libs_configuration'));
  });
  test(
      'version resolution does not clear ambiguous target licences or Android release gap',
      () async {
    final b = await bundle();
    for (final id in [
      'com.android.tools:desugar_jdk_libs',
      'com.google.android.play:review',
      'com.google.android.play:review-ktx',
      'com.google.firebase:firebase-auth',
      'com.google.firebase:firebase-firestore'
    ]) {
      expect(
          b.components.singleWhere((c) => c.id == 'maven:$id').licenseDeclared,
          'NOASSERTION');
    }
    expect(b.auditGaps.any((g) => g['id'] == 'android-transitive-resolution'),
        isTrue);
  });
}
