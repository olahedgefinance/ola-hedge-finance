import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'sbom_lib.dart';

const androidEvidencePath =
    'compliance/evidence/reconstruction-2026-10-09/android-graph-2026-10-11';
void _require(bool ok, String reason) {
  if (!ok) throw StateError('Android evidence: $reason');
}

String _id(String coordinate) =>
    'maven:${coordinate.split(':').take(2).join(':')}';

/// A selected graph proves resolution, never licence or release clearance.
void validateAndroidGraph(Map<String, dynamic> graph) {
  _require(
      graph['schemaVersion'] == 1 &&
          graph['gradleVersion'] == '7.5' &&
          (graph['javaVersion'] as String).startsWith('17.'),
      'unapproved diagnostic toolchain');
  final configs = (graph['configurations'] as List).cast<Map>();
  const expected = {
    'productionReleaseRuntimeClasspath',
    'productionReleaseCompileClasspath',
    'coreLibraryDesugaring'
  };
  _require(
      configs.length == expected.length &&
          configs.map((c) => c['name']).toSet().containsAll(expected),
      'wrong configuration coverage');
  final versions = <String, String>{};
  final artifactIds = <String, String>{};
  for (final config in configs) {
    final nodes = (config['components'] as List).cast<Map>();
    final ids = nodes.map((n) => n['id'] as String).toSet();
    _require(
        ids.length == nodes.length &&
            ids.contains(config['root']) &&
            config['root'] == 'project :app',
        'duplicate node or wrong root');
    for (final node in nodes) {
      final id = node['id'] as String;
      if (!id.startsWith('project :')) {
        final parts = id.split(':');
        _require(
            parts.length == 3 &&
                !RegExp(r'[+\[\](),]').hasMatch(parts.last) &&
                !parts.last.contains('SNAPSHOT') &&
                !parts.last.startsWith('latest.'),
            'unfixed selected version');
        _require(node['module'] == id, 'module identity mismatch');
        final key = _id(id);
        _require(!versions.containsKey(key) || versions[key] == parts.last,
            'configuration version mismatch');
        versions[key] = parts.last;
      }
      for (final dep in (node['dependencies'] as List).cast<Map>()) {
        _require(
            dep['constraint'] is bool &&
                ids.contains(dep['selected']) &&
                dep['requested'] is String,
            'unresolved or malformed dependency');
      }
    }
    for (final a in (config['artifacts'] as List).cast<Map>()) {
      _require(
          ids.contains(a['module']) &&
              !(a['module'] as String).startsWith('project :') &&
              RegExp(r'^[a-f0-9]{64}$').hasMatch(a['sha256'] as String) &&
              a['bytes'] > 0,
          'invalid module artifact');
      final key = '${a['module']}|${a['artifact']}';
      final identity = '${a['sha256']}|${a['bytes']}';
      _require(!artifactIds.containsKey(key) || artifactIds[key] == identity,
          'conflicting artifact identity');
      artifactIds[key] = identity;
    }
  }
}

class AndroidEvidence {
  AndroidEvidence(this.components, this.pubDependencies, this.appDependencies);
  final List<Map<String, dynamic>> components;
  final Map<String, List<String>> pubDependencies;
  final List<String> appDependencies;
}

AndroidEvidence loadAndroidEvidence(Directory root,
    List<PubLockEntry> pubEntries, List<Map<String, dynamic>> existing) {
  List<int> read(String path) {
    _require(
        path.isNotEmpty &&
            !path.contains('\\') &&
            !path.contains(':') &&
            !path.startsWith('/') &&
            !path.split('/').any((p) => p == '..' || p.isEmpty),
        'unsafe evidence path');
    return File('${root.path}/$path').readAsBytesSync();
  }

  dynamic json(String path) => jsonDecode(utf8.decode(read(path)));
  final manifest = json('$androidEvidencePath/manifest.json') as Map;
  _require(
      manifest['legalClearance'] == false &&
          manifest['releaseClearance'] == false,
      'unsupported clearance');
  final bytes = read('$androidEvidencePath/resolved-graph.json');
  _require(sha256.convert(bytes).toString() == manifest['graphSha256'],
      'graph hash mismatch');
  for (final input in manifest['inputs'] as List) {
    final normalized =
        utf8.encode(utf8.decode(read(input['path'])).replaceAll('\r\n', '\n'));
    _require(sha256.convert(normalized).toString() == input['sha256Lf'],
        'stale project input ${input['path']}');
  }
  final graph = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  validateAndroidGraph(graph);
  final pluginRows = json('$androidEvidencePath/plugin-inputs.json') as List;
  final plugins = <String, String>{};
  for (final p in pluginRows) {
    final locked = pubEntries.singleWhere((e) => e.name == p['name']);
    _require(locked.source != 'git' || p['acquisitionUrl'] == locked.sourceUrl,
        'Git source retrieval URL differs from lock');
    _require(
        p['sourceVerified'] == true &&
            (locked.source != 'git' ||
                locked.resolvedRevision == p['gitRevision']),
        'unauthenticated plugin source');
    _require(
        locked.version == p['version'] &&
            locked.source == p['source'] &&
            (locked.source != 'hosted' ||
                locked.checksumSha256 == p['archiveSha256']),
        'stale Flutter plugin identity');
    _require(
        sha256.convert(read('$androidEvidencePath/${p['path']}')).toString() ==
            p['sha256'],
        'plugin input hash mismatch');
    _require(!plugins.containsKey('project :${p['name']}'),
        'duplicate Flutter plugin');
    plugins['project :${p['name']}'] = 'pub:${p['name']}';
  }
  final modules = <String, Map>{};
  final edges = <String, Set<String>>{};
  final runtime = <String>{};
  final artifactHashes = <String, Set<String>>{};
  for (final c in graph['configurations'] as List) {
    for (final n in c['components'] as List) {
      final id = n['id'] as String;
      if (id.startsWith('project :')) {
        _require(id == 'project :app' || plugins.containsKey(id),
            'unmapped Flutter project $id');
      } else {
        modules[id] = n;
        if (c['name'] != 'productionReleaseCompileClasspath') runtime.add(id);
      }
      final set = edges.putIfAbsent(id, () => <String>{});
      for (final dep in n['dependencies'] as List) {
        // Constraints constrain selection; they are not runtime DEPENDS_ON edges.
        if (dep['constraint'] == false) set.add(dep['selected'] as String);
      }
    }
    for (final a in c['artifacts'] as List) {
      artifactHashes
          .putIfAbsent(a['module'] as String, () => <String>{})
          .add(a['sha256'] as String);
    }
  }
  final targetRows =
      json('$androidEvidencePath/target-provenance.json') as List;
  final targetArtifacts = <String, Map>{};
  for (final target in targetRows) {
    final coordinate = target['module'] as String;
    _require(
        modules.containsKey(coordinate) &&
            target['licenseDeclared'] == 'NOASSERTION' &&
            target['legalClearance'] == false,
        'unsupported target licence clearance');
    final binary = (target['files'] as List).cast<Map>().singleWhere((f) =>
        f['status'] == 200 &&
        ((f['url'] as String).endsWith('.aar') ||
            ((f['url'] as String).endsWith('.jar') &&
                !(f['url'] as String).endsWith('-sources.jar'))));
    _require(
        (artifactHashes[coordinate] ?? <String>{}).contains(binary['sha256']),
        'target binary does not match selected graph');
    targetArtifacts[_id(coordinate)] = binary;
  }
  _require(targetArtifacts.length == 5, 'incomplete target evidence');
  final applied = (manifest['appliedPlugins'] as List).cast<Map>();
  _require(
      applied.length == plugins.length + 1 &&
          applied.every((p) => p['appliedVersion'] == '7.3.1') &&
          applied
              .map((p) => 'project ${p['project']}')
              .toSet()
              .containsAll({...plugins.keys, 'project :app'}),
      'effective AGP coverage differs');
  final before = {for (final c in existing) c['id']: c};
  String mapId(String id) => id == 'project :app'
      ? 'application:ola-hedge-finance'
      : plugins[id] ?? _id(id);
  List<String> dependencies(String id) =>
      (edges[id] ?? <String>{}).map(mapId).toSet().toList()..sort();
  final appDeps = dependencies('project :app');
  final rows = <Map<String, dynamic>>[];
  for (final coordinate in modules.keys.toList()..sort()) {
    final id = _id(coordinate), version = coordinate.split(':').last;
    final old = before[id];
    final sameEvidence = old != null && old['version'] == version;
    final hashes = artifactHashes[coordinate] ?? <String>{};
    final declaration = sameEvidence ? old['licenseDeclared'] : 'NOASSERTION';
    rows.add({
      'id': id,
      'name': coordinate.split(':').take(2).join(':'),
      'version': version,
      'ecosystem': 'maven',
      'relationship': appDeps.contains(id) ? 'direct-runtime' : 'transitive',
      'source': 'gradle-resolved-graph',
      'downloadLocation': targetArtifacts[id]?['url'] ??
          (sameEvidence ? old['downloadLocation'] : 'NOASSERTION'),
      'licenseDeclared': declaration,
      'licenseEvidence':
          '$androidEvidencePath/resolved-graph.json#$coordinate; exact selected version/artifact identities only. ${sameEvidence ? old['licenseEvidence'] : 'Licence and source obligations remain unreviewed.'}',
      'distributed': runtime.contains(coordinate) &&
          hashes.isNotEmpty &&
          !coordinate.contains(':desugar_jdk_libs_configuration:'),
      'modified': false,
      'reviewStatus': declaration == 'NOASSERTION'
          ? 'review-required'
          : 'verified-with-conditions',
      'dependencies': dependencies(coordinate),
      if (hashes.length == 1) 'checksumSha256': hashes.single,
      'notes':
          'Configuration graph is not proof of inclusion in a release binary. Complete graph/constraint and artifact records retained; no legal or release clearance.',
    });
  }
  return AndroidEvidence(rows,
      {for (final p in plugins.entries) p.value: dependencies(p.key)}, appDeps);
}
