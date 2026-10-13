import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import '../../tool/compliance/grpc_evidence.dart';
import '../../tool/compliance/generate_sbom.dart';

void main() {
  final root = Directory.current.parent;
  final original = jsonDecode(
      File('${root.path}/$grpcEvidencePath/manifest.json')
          .readAsStringSync()) as Map;
  final graph =
      jsonDecode(File('${root.path}/$grpcGraphPath').readAsStringSync()) as Map;
  Map copy() => jsonDecode(jsonEncode(original)) as Map;
  List<int> read(String p) =>
      File('${root.path}/$grpcEvidencePath/$p').readAsBytesSync();
  List<Map<String, dynamic>> check(Map m) =>
      verifyGrpcManifest(m, graph, original['graphSha256'], read);
  Map row(Map m, String name) =>
      (m['records'] as List).singleWhere((r) => r['module'] == name) as Map;
  test('exact gRPC evidence changes only its reviewed declarations', () async {
    final b = await createComplianceArtifactBundle(repositoryRoot: root);
    expect(
        b.components
            .singleWhere((c) => c.id == 'maven:io.grpc:grpc-api')
            .licenseDeclared,
        'Apache-2.0');
    expect(
        b.components
            .singleWhere((c) => c.id == 'maven:io.grpc:grpc-okhttp')
            .licenseDeclared,
        'NOASSERTION');
    expect(
        b.components
            .singleWhere((c) =>
                c.id ==
                'maven:org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm')
            .licenseDeclared,
        'NOASSERTION');
  });
  test('seven exact modules retain three unresolved embedded scopes', () {
    final r = check(copy());
    expect(r.length, 7);
    expect(r.where((r) => r['licenseDeclared'] != 'NOASSERTION').length, 4);
  });
  test('top-level Apache cannot clear OkHttp missing notices', () {
    final m = copy();
    row(m, 'okhttp')['licenseDeclared'] = 'Apache-2.0';
    row(m, 'okhttp')['classification'] = 'Verified with conditions';
    expect(() => check(m), throwsStateError);
  });
  test('wrong release or tag cannot reuse retained source', () {
    for (final key in ['version', 'tag', 'commit']) {
      final m = copy();
      m['upstream'][key] = 'wrong';
      expect(() => check(m), throwsStateError);
    }
  });
  test('missing publisher sources cannot fall back to POM', () {
    final m = copy();
    (row(m, 'api')['files'] as List).removeWhere((f) => f['role'] == 'source');
    expect(() => check(m), throwsStateError);
  });
  test('exact source URL must match selected coordinate', () {
    final m = copy();
    row(m, 'api')['files'][1]['url'] = 'https://example.org/source.jar';
    expect(() => check(m), throwsStateError);
  });
  test('graph binding cannot become stale', () {
    final m = copy();
    m['graphSha256'] = '0' * 64;
    expect(() => check(m), throwsStateError);
  });
  test('module version and packaging cannot be substituted', () {
    final m = copy();
    row(m, 'android')['version'] = '1.58.0';
    expect(() => check(m), throwsStateError);
  });
  test('plugin ancestors are reproduced rather than trusted', () {
    final m = copy();
    row(m, 'api')['flutterPluginAncestors'] = [];
    expect(() => check(m), throwsStateError);
  });
  test('incomplete or duplicate cohort is rejected', () {
    final m = copy();
    (m['records'] as List).removeLast();
    expect(() => check(m), throwsStateError);
  });
  test('legal or release clearance flags are rejected', () {
    for (final key in ['legalClearance', 'releaseClearance']) {
      final m = copy();
      m[key] = true;
      expect(() => check(m), throwsStateError);
    }
  });
  test('payload hash mismatch cannot be ignored', () {
    final m = copy();
    row(m, 'api')['files'][0]['bytes'] = 1;
    expect(() => check(m), throwsStateError);
  });
  test('audit blob cannot be silently omitted', () {
    final m = copy();
    row(m, 'core')['audit']['path'] = '../outside';
    expect(() => check(m), throwsStateError);
  });
  test('copied Guava source is not cleared by top-level Apache', () {
    final r = check(copy());
    for (final name in ['core', 'protobuf-lite']) {
      expect(r.singleWhere((r) => r['module'] == name)['licenseDeclared'],
          'NOASSERTION');
    }
  });
  test('risk summaries cannot hide audited unresolved paths', () {
    final m = copy();
    row(m, 'okhttp')['risksSummary'] = [];
    expect(() => check(m), throwsStateError);
  });
  test('mandatory caveats cannot be replaced with empty strings', () {
    final m = copy();
    row(m, 'okhttp')['conditions'] = ['', '', ''];
    expect(() => check(m), throwsStateError);
  });
}
