import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'sbom_lib.dart' show encodeCanonicalJson;

const grpcEvidencePath =
    'compliance/evidence/reconstruction-2026-10-09/grpc-java-2026-10-13';
const grpcGraphPath =
    'compliance/evidence/reconstruction-2026-10-09/android-graph-2026-10-11/resolved-graph.json';
const _requiredConditions = [
  "Technical evidence only; not legal/release clearance or reproducible binary rebuild.",
  "Preserve upstream LICENSE, NOTICE.txt and applicable source copyright/modification notices. Repository-wide NOTICE references outside this cohort are context, not evidence of inclusion.",
  "Graph runtime distribution is not proof of release-APK inclusion; dependencies retain separate classifications. Production Android and iOS/native verification remain incomplete."
];
const _generated = '''/**
 * Automatically generated file. DO NOT MODIFY
 */
package io.grpc.android;

public final class BuildConfig {
  public static final boolean DEBUG = false;
  public static final String LIBRARY_PACKAGE_NAME = "io.grpc.android";
  public static final String BUILD_TYPE = "release";
}
''';
void _require(bool ok, String why) {
  if (!ok) throw StateError('gRPC evidence: $why');
}

String _hash(List<int> b) => sha256.convert(b).toString();
String _text(List<int> b) => utf8.decode(b);
String _tag(String s, String key) =>
    RegExp('<$key>([^<]*)</$key>').firstMatch(s)?.group(1) ?? '';
Map<String, List<int>> _unzip(List<int> bytes) {
  final decoder = ZipDecoder(), result = <String, List<int>>{};
  final archive = decoder.decodeBytes(bytes, verify: true);
  final names = decoder.directory.fileHeaders.map((f) => f.filename).toList();
  _require(names.length == names.toSet().length, 'duplicate ZIP entry');
  for (final n in names) {
    _require(
        !n.startsWith('/') &&
            !n.contains('\\') &&
            !n.contains(':') &&
            !n.split('/').contains('..'),
        'unsafe ZIP path');
  }
  final files = archive.files.toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  for (final f in files) {
    if (!f.name.endsWith('/')) result[f.name] = f.content as List<int>;
  }
  return result;
}

/// Recompute archive scope, including nested AAR classes and source associations.
Map<String, dynamic> inspectGrpcArchives(List<int> source, List<int> binary,
    Map<String, List<int>> upstream, String module) {
  final sources = _unzip(source), payload = _unzip(binary);
  final entries = <Map<String, dynamic>>[],
      mappings = <Map<String, dynamic>>[],
      risks = <String>[];
  bool same(List<int>? a, List<int> b) => a != null && _hash(a) == _hash(b);
  for (final e in sources.entries) {
    final n = e.key, b = e.value;
    if (n.endsWith('.java')) {
      final possible = ['$module/src/main/java/$n'];
      if (module == 'api' &&
          _text(upstream['api/build.gradle']!)
              .contains('sourceSets.context.allSource'))
        possible.add('api/src/context/java/$n');
      if (module == 'okhttp')
        possible.add('okhttp/third_party/okhttp/main/java/$n');
      final matches = possible.where((p) => same(upstream[p], b)).toList();
      final generated = module == 'android' &&
          n == 'io/grpc/android/BuildConfig.java' &&
          _text(b) == _generated &&
          _text(upstream['android/build.gradle']!)
              .contains("namespace 'io.grpc.android'") &&
          _text(upstream['android/build.gradle']!)
              .contains("singleVariant('release')");
      mappings.add({
        'path': n,
        'sha256': _hash(b),
        'upstreamPaths': matches,
        'generatedMetadata': generated
      });
      if (matches.isEmpty && !generated)
        risks.add('Source not mapped to exact upstream: $n');
      final text = _text(b);
      final header = text.substring(0, text.length < 6000 ? text.length : 6000);
      if (!generated && !header.contains('Apache License, Version 2.0'))
        risks.add('Unverified source licence header: $n');
      if (RegExp('copied from', caseSensitive: false).hasMatch(text))
        risks.add(
            'Copied third-party source lacks separately scoped evidence: $n');
      if (header.contains('Apache Software Foundation'))
        risks.add(
            'ASF source refers to separately scoped NOTICE not established: $n');
    } else if (n.startsWith('META-INF/services/') &&
        same(upstream['$module/src/main/resources/$n'], b)) {
      // Exact upstream service metadata, not an additional implementation.
    } else if (n != 'META-INF/MANIFEST.MF') {
      risks.add('Unreviewed source resource: $n');
    }
  }
  void scan(Map<String, List<int>> files, [String parent = '']) {
    for (final e in files.entries) {
      final n = e.key, b = e.value, path = '$parent$n';
      entries.add({'path': path, 'bytes': b.length, 'sha256': _hash(b)});
      if (n == 'classes.jar' && module == 'android' && parent.isEmpty) {
        scan(_unzip(b), '$path!');
        continue;
      }
      if (n.endsWith('.class')) {
        final outer =
            n.split(r'$').first.replaceFirst(RegExp(r'\.class$'), '') + '.java';
        if (!sources.containsKey(outer))
          risks.add('Binary class lacks published source file: $path');
      } else if (n == 'META-INF/MANIFEST.MF') {
      } else if (n.startsWith('META-INF/services/')) {
        for (final line in _text(b).split('\n')) {
          final value = line.split('#').first.trim();
          if (value.isNotEmpty &&
              !sources.containsKey(
                  value.split(r'$').first.replaceAll('.', '/') + '.java'))
            risks.add('Service provider lacks source: $path');
        }
      } else if (module == 'android' &&
          parent.isEmpty &&
          n == 'R.txt' &&
          b.isEmpty) {
      } else if (module == 'android' &&
          parent.isEmpty &&
          [
            'AndroidManifest.xml',
            'META-INF/com/android/build/gradle/aar-metadata.properties'
          ].contains(n)) {
      } else if (module == 'android' &&
          parent.isEmpty &&
          n == 'proguard.txt' &&
          same(upstream['android/proguard-rules.txt'], b)) {
      } else {
        risks.add('Unreviewed binary resource: $path');
      }
    }
  }

  scan(payload);
  risks.sort();
  return {
    'sourceEntries': [
      for (final e in sources.entries)
        {'path': e.key, 'bytes': e.value.length, 'sha256': _hash(e.value)}
    ],
    'binaryEntries': entries,
    'sourceMappings': mappings,
    'risks': risks
  };
}

/// Namespace/POM declarations alone never grant a licence classification.
List<Map<String, dynamic>> verifyGrpcManifest(
    Map m, Map graph, String graphHash, List<int> Function(String) reader) {
  _require(
      m['schemaVersion'] == 1 &&
          m['legalClearance'] == false &&
          m['releaseClearance'] == false,
      'manifest clearance/schema');
  _require(m['graphPath'] == grpcGraphPath && m['graphSha256'] == graphHash,
      'stale graph');
  List<int> read(Map f) {
    final p = f['path'] as String;
    _require(
        RegExp(r'^blobs/[a-f0-9]{64}\.bin$').hasMatch(p) &&
            p == 'blobs/${f['sha256']}.bin',
        'unsafe blob');
    final b = reader(p);
    _require(b.length == f['bytes'] && _hash(b) == f['sha256'], 'payload hash');
    return b;
  }

  final u = m['upstream'] as Map,
      commit = u['commit'] as String,
      version = u['version'] as String;
  _require(
      RegExp(r'^[a-f0-9]{40}$').hasMatch(commit) &&
          RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version),
      'invalid revision');
  _require(
      u['repository'] == 'https://github.com/grpc/grpc-java' &&
          u['tag'] == 'v$version',
      'upstream identity');
  _require(
      u['response']['url'] ==
              'https://api.github.com/repos/grpc/grpc-java/commits/v$version' &&
          jsonDecode(_text(read(u['response'])))['sha'] == commit,
      'tag commit binding');
  _require(
      u['archive']['url'] ==
          'https://codeload.github.com/grpc/grpc-java/zip/$commit',
      'source archive URL');
  final raw = _unzip(read(u['archive'])), prefix = 'grpc-java-$commit/';
  _require(
      raw.keys.every((n) => n.startsWith(prefix)), 'upstream archive root');
  final upstream = {
    for (final e in raw.entries) e.key.substring(prefix.length): e.value
  };
  _require(
      _text(upstream['build.gradle']!)
          .contains('version = "$version" // CURRENT_GRPC_VERSION'),
      'upstream release version');
  final licence = _text(upstream['LICENSE']!),
      notice = _text(upstream['NOTICE.txt']!);
  _require(
      licence.contains('Apache License') &&
          licence.contains('END OF TERMS AND CONDITIONS'),
      'complete Apache text');
  _require(
      notice.contains('Copyright 2014 The gRPC Authors') &&
          notice.contains('okhttp/third_party/okhttp/LICENSE'),
      'missing scoped NOTICE');
  _require(
      _text(upstream['okhttp/third_party/okhttp/LICENSE']!)
          .contains('END OF TERMS AND CONDITIONS'),
      'missing vendored OkHttp licence');
  final hashes = <String, Set<String>>{},
      coordinates = <String>{},
      edges = <String, Set<String>>{};
  for (final cfg in graph['configurations']) {
    for (final c in cfg['components']) {
      coordinates.add(c['id']);
      for (final d in c['dependencies']) {
        if (d['constraint'] != true)
          edges.putIfAbsent(c['id'], () => {}).add(d['selected']);
      }
    }
    for (final a in cfg['artifacts']) {
      hashes.putIfAbsent(a['module'], () => {}).add(a['sha256']);
    }
  }
  final cohort = coordinates.where((c) => c.startsWith('io.grpc:')).toList()
    ..sort();
  final rows = (m['records'] as List).cast<Map<String, dynamic>>();
  final keys = rows.map((r) => r['coordinate'] as String).toList()..sort();
  _require(
      jsonEncode(keys) == jsonEncode(cohort) &&
          jsonEncode(cohort) == jsonEncode(m['cohortCoordinates']),
      'cohort mismatch');
  for (final r in rows) {
    final coord = r['coordinate'] as String,
        parts = coord.split(':'),
        a = parts[1],
        v = parts[2],
        module = a.replaceFirst('grpc-', ''),
        stem = '$a-$v';
    _require(
        parts[0] == 'io.grpc' &&
            v == version &&
            r['id'] == 'maven:io.grpc:$a' &&
            r['version'] == v &&
            r['module'] == module,
        'wrong module/release');
    _require(
        r['legalClearance'] == false &&
            r['releaseClearance'] == false &&
            jsonEncode((r['conditions'] as List).take(3).toList()) ==
                jsonEncode(_requiredConditions) &&
            (r['conditions'] as List)
                .every((c) => c is String && c.trim().isNotEmpty),
        'clearance/conditions');
    _require(r['relationship'] == 'transitive' && r['distributed'] == true,
        'scope differs');
    final plugins = <String>[];
    for (final p in edges.keys
        .where((k) => k.startsWith('project :') && k != 'project :app')) {
      final todo = [p], seen = <String>{};
      while (todo.isNotEmpty) {
        final n = todo.removeLast();
        if (seen.add(n)) todo.addAll(edges[n] ?? {});
      }
      if (seen.contains(coord)) plugins.add(p);
    }
    plugins.sort();
    _require(jsonEncode(plugins) == jsonEncode(r['flutterPluginAncestors']),
        'plugin mapping differs');
    final files = {for (final f in r['files']) f['role'] as String: f as Map};
    _require(
        files.length == (r['files'] as List).length &&
            files.length == 3 &&
            files.keys.toSet().containsAll(['pom', 'source', 'binary']),
        'missing/duplicate publisher evidence');
    final expected = {
          'pom': '$stem.pom',
          'source': '$stem-sources.jar',
          'binary': '$stem.${module == 'android' ? 'aar' : 'jar'}'
        },
        data = <String, List<int>>{};
    for (final e in files.entries) {
      _require(
          e.value['filename'] == expected[e.key] &&
              e.value['url'] ==
                  'https://repo.maven.apache.org/maven2/io/grpc/$a/$v/${expected[e.key]}',
          'publisher release mismatch');
      data[e.key] = read(e.value);
    }
    _require(
        hashes[coord]?.length == 1 &&
            hashes[coord]!.contains(files['binary']!['sha256']),
        'graph binary mismatch');
    final pom = _text(data['pom']!),
        licenses = RegExp(r'<licenses>([\s\S]*?)</licenses>')
                .firstMatch(_text(data['pom']!))
                ?.group(1) ??
            '';
    _require(
        ['groupId', 'artifactId', 'version']
                .map((k) => _tag(pom, k))
                .join(':') ==
            coord,
        'POM identity');
    _require(
        RegExp(r'<license>').allMatches(licenses).length == 1 &&
            _tag(licenses, 'name') == 'Apache 2.0' &&
            _tag(licenses, 'url') ==
                'https://opensource.org/licenses/Apache-2.0',
        'POM licence');
    _require(
        _tag(RegExp(r'<scm>([\s\S]*?)</scm>').firstMatch(pom)?.group(1) ?? '',
                'url') ==
            u['repository'],
        'POM source repository');
    _require(!pom.contains('published-with-gradle-metadata'),
        'unhandled Gradle metadata');
    final packaging = _tag(pom, 'packaging');
    _require(
        (packaging.isEmpty ? 'jar' : packaging) ==
            (module == 'android' ? 'aar' : 'jar'),
        'packaging mismatch');
    _require(
        upstream.containsKey('$module/build.gradle'), 'module build missing');
    final audit =
        inspectGrpcArchives(data['source']!, data['binary']!, upstream, module);
    _require(
        encodeCanonicalJson(audit) ==
            encodeCanonicalJson(
                jsonDecode(_text(read(r['audit']))) as Map<String, dynamic>),
        'recomputed archive audit mismatch');
    _require(jsonEncode(r['risksSummary']) == jsonEncode(audit['risks']),
        'risk summary differs from recomputed audit');
    final blocked = (audit['risks'] as List).isNotEmpty;
    _require(
        r['licenseDeclared'] == (blocked ? 'NOASSERTION' : 'Apache-2.0') &&
            r['classification'] ==
                (blocked ? 'Needs Verification' : 'Verified with conditions'),
        'unsupported classification');
  }
  return rows;
}

void applyGrpcLicences(Directory root, List<Map<String, dynamic>> components,
    Map<String, dynamic> graph) {
  List<int> read(String p) =>
      File('${root.path}/$grpcEvidencePath/$p').readAsBytesSync();
  final rows = verifyGrpcManifest(
      jsonDecode(_text(read('manifest.json'))) as Map,
      graph,
      _hash(File('${root.path}/$grpcGraphPath').readAsBytesSync()),
      read);
  for (final r in rows) {
    final c = components.singleWhere((c) => c['id'] == r['id']);
    _require(c['version'] == r['version'], 'component version mismatch');
    c['licenseDeclared'] = r['licenseDeclared'];
    c['reviewStatus'] = r['licenseDeclared'] == 'NOASSERTION'
        ? 'review-required'
        : 'verified-with-conditions';
    c['licenseEvidence'] =
        '$grpcEvidencePath/manifest.json#${r['coordinate']}; exact publisher POM/source/binary, pinned upstream source and scoped licence/NOTICE archive audit.';
    c['downloadLocation'] =
        (r['files'] as List).singleWhere((f) => f['role'] == 'binary')['url'];
    c['notes'] =
        '${r['classification']}. ${(r['conditions'] as List).join(' ')} ${(r['risksSummary'] as List).join(' ')}';
  }
}
