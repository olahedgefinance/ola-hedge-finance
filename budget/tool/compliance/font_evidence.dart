import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'sbom_lib.dart';

const fontEvidencePath =
    'compliance/evidence/reconstruction-2026-10-09/fonts-2026-10-11';

void _require(bool ok, String reason) {
  if (!ok) throw StateError('Font evidence: $reason');
}

void _safe(String path) {
  _require(
      path.isNotEmpty &&
          !path.startsWith('/') &&
          !path.contains(':') &&
          !path.contains('\\') &&
          !path.split('/').any((p) => p == '..' || p.isEmpty),
      'unsafe path');
}

String _blob(List<int> bytes) => sha1.convert(
    [...utf8.encode('blob ${bytes.length}\u0000'), ...bytes]).toString();

/// Exact-byte provenance is a technical declaration, never legal clearance.
String validateFontRecord(
    Map<String, dynamic> row,
    List<int> Function(String) readRepo,
    List<int> Function(String) readEvidence) {
  List<int> repo(String p) {
    _safe(p);
    return readRepo(p);
  }

  List<int> evidence(String p) {
    _safe(p);
    return readEvidence(p);
  }

  _require(row['legalClearance'] == false && row['releaseClearance'] == false,
      'unsupported clearance');
  final files = (row['files'] as List).cast<Map>();
  _require(files.isNotEmpty, 'empty family');
  final paths = <String>{};
  for (final f in files) {
    final path = f['path'] as String;
    _require(paths.add(path) && path.startsWith('budget/assets/'),
        'duplicate or non-asset font');
    final bytes = repo(path);
    _require(
        bytes.length == f['bytes'] &&
            sha256.convert(bytes).toString() == f['sha256'],
        'bundled font hash mismatch');
    _require(
        f['distribution'] == 'runtime-distributed', 'incorrect distribution');
  }
  final proof = row['proof'];
  if (proof == null) {
    _require(
        row['licenseDeclared'] == 'NOASSERTION' &&
            ['Needs Verification / Do Not Ship', 'Counsel Review Required']
                .contains(row['classification']),
        'missing exact source proof');
    return 'NOASSERTION';
  }
  _require(
      row['classification'] == 'Verified with conditions' &&
          row['licenseDeclared'] == 'OFL-1.1' &&
          (proof['conditions'] as List).isNotEmpty,
      'unsupported declaration or missing conditions');
  // This is a reviewed source mapping, not a licence classifier for arbitrary fonts.
  _require(
      proof['repository'] == 'https://github.com/googlefonts/dm-fonts' &&
          row['id'] == 'font:DMSans',
      'unreviewed source mapping');
  final commit = proof['commit'] as String;
  _require(RegExp(r'^[a-f0-9]{40}$').hasMatch(commit), 'unpinned source');
  final commitData =
      jsonDecode(utf8.decode(evidence(proof['commitPath']))) as Map;
  _require(commitData['sha'] == commit, 'source commit mismatch');
  final tree = jsonDecode(utf8.decode(evidence(proof['treePath']))) as Map;
  _require(
      tree['truncated'] == false &&
          [commit, commitData['commit']['tree']['sha']].contains(tree['sha']),
      'tree identity mismatch');
  final entries = {for (final e in tree['tree'] as List) e['path']: e};
  void upstream(Map item, List<int> bytes) {
    final entry = entries[item['upstreamPath']];
    _require(
        entry != null &&
            entry['type'] == 'blob' &&
            entry['sha'] == item['upstreamBlob'] &&
            _blob(bytes) == item['upstreamBlob'],
        'upstream blob mismatch');
  }

  final covered = <String>{};
  for (final item in proof['matches'] as List) {
    final path = item['path'] as String;
    _require(paths.contains(path) && covered.add(path),
        'incomplete or duplicate source mapping');
    final bytes = repo(path);
    _require(
        sha256.convert(bytes).toString() ==
            sha256.convert(evidence(item['retainedPath'])).toString(),
        'source is not exact bundled binary');
    _require(
        item['url'] ==
            'https://raw.githubusercontent.com/googlefonts/dm-fonts/$commit/${item['upstreamPath']}',
        'source URL mismatch');
    upstream(item as Map, bytes);
  }
  _require(covered.length == paths.length, 'unmapped style');
  final supplied = <String>{};
  for (final item in proof['licenceSources'] as List) {
    _require(supplied.add(item['path'] as String), 'duplicate licence payload');
    upstream(item as Map, evidence(item['path']));
  }
  _require(
      supplied.length == 3 &&
          supplied.containsAll(
              ['DMSans/LICENSE.txt', 'DMSans/OFL.txt', 'DMSans/AUTHORS.txt']),
      'missing supplied notice');
  final text = utf8.decode(evidence('DMSans/LICENSE.txt'));
  _require(
      text.contains('SIL OPEN FONT LICENSE Version 1.1') &&
          text.contains('Copyright 2014-2017 Indian Type Foundry') &&
          text.contains('Copyright 2019 Google LLC'),
      'missing exact licence/copyright');
  return 'OFL-1.1';
}

Map<String, Map<String, dynamic>> verifyFontEvidence(Directory root) {
  List<int> repo(String p) {
    _safe(p);
    return File('${root.path}/$p').readAsBytesSync();
  }

  List<int> evidence(String p) => repo('$fontEvidencePath/$p');
  final manifest = jsonDecode(utf8.decode(evidence('manifest.json'))) as Map;
  _require(manifest['schemaVersion'] == 1, 'unsupported schema');
  for (final f in manifest['retainedFiles'] as List) {
    final bytes = evidence(f['path']);
    _require(
        bytes.length == f['bytes'] &&
            sha256.convert(bytes).toString() == f['sha256'],
        'retained payload mismatch');
  }
  final result = <String, Map<String, dynamic>>{};
  final inventoryPaths = <String>{};
  for (final r in (manifest['records'] as List).cast<Map<String, dynamic>>()) {
    _require(!result.containsKey(r['id']), 'duplicate family');
    validateFontRecord(r, repo, evidence);
    result[r['id'] as String] = r;
    for (final f in r['files'] as List) {
      _require(inventoryPaths.add(f['path'] as String), 'font assigned twice');
    }
  }
  final actual = Directory('${root.path}/budget/assets')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => RegExp(r'\.(ttf|otf|woff2?|ttc)$', caseSensitive: false)
          .hasMatch(f.path))
      .map((f) => f.path.substring(root.path.length + 1).replaceAll('\\', '/'))
      .toSet();
  _require(
      actual.length == inventoryPaths.length &&
          actual.containsAll(inventoryPaths),
      'font inventory drift');
  final pubspec = utf8.decode(repo('budget/pubspec.yaml'));
  final declared = RegExp(r'^\s*- asset: (assets/[^\r\n]+\.(?:ttf|otf))\s*$',
          multiLine: true)
      .allMatches(pubspec)
      .map((m) => 'budget/${m.group(1)}')
      .toSet();
  _require(
      declared.length == inventoryPaths.length &&
          declared.containsAll(inventoryPaths),
      'font manifest drift');
  final dependencyFonts = (manifest['dependencyFonts'] as List).cast<Map>();
  final release = jsonDecode(
          utf8.decode(evidence('dependencies/material-symbols-release.json')))
      as Map;
  final locked = parsePubLock(utf8.decode(repo('budget/pubspec.lock')))
      .singleWhere((p) => p.name == 'material_symbols_icons');
  _require(
      locked.source == 'hosted' &&
          locked.relationship == ComponentRelationship.directRuntime &&
          locked.version == release['version'] &&
          locked.checksumSha256 == release['archive_sha256'],
      'dependency font lock mismatch');
  final manual = jsonDecode(
          utf8.decode(repo('compliance/components/non_pub_components.json')))
      as Map;
  final tool = (manual['components'] as List)
      .singleWhere((c) => c['id'] == 'tool:flutter-sdk');
  _require(tool['version'] == manifest['flutterSource']['version'],
      'SDK font version mismatch');
  final pin =
      utf8.decode(evidence(manifest['flutterSource']['pinPath'])).trim();
  final sdkFonts = dependencyFonts
      .where((f) => f['componentId'] == 'tool:flutter-sdk')
      .toList();
  final symbols = dependencyFonts
      .where((f) => f['componentId'] == 'pub:material_symbols_icons')
      .toList();
  _require(
      sdkFonts.length == 1 &&
          symbols.length == 6 &&
          dependencyFonts.length == 7 &&
          dependencyFonts
                  .map((f) => '${f['componentId']}/${f['path']}')
                  .toSet()
                  .length ==
              7,
      'dependency font coverage');
  _require(
      sdkFonts.single['archiveUrl'] == 'https://storage.googleapis.com/$pin' &&
          sdkFonts.single['licenseDeclared'] == 'CC-BY-4.0',
      'SDK font pin/licence mismatch');
  for (final f in symbols) {
    _require(
        f['archiveSha256'] == locked.checksumSha256 &&
            f['archiveUrl'] == release['archive_url'] &&
            f['licenseDeclared'] == 'Apache-2.0',
        'package font archive/licence mismatch');
  }
  final expectedRuntime =
      inventoryPaths.map((p) => p.substring('budget/'.length)).toSet();
  for (final f in dependencyFonts
      .where((f) => f['distribution'] == 'runtime-distributed')) {
    expectedRuntime.add(
        '${f['componentId'] == 'tool:flutter-sdk' ? 'fonts/' : 'packages/material_symbols_icons/'}${f['path']}');
  }
  final observed =
      jsonDecode(utf8.decode(evidence('font-manifest.observed.json'))) as List;
  final observedRuntime = {
    for (final family in observed)
      for (final f in family['fonts']) f['asset']
  };
  _require(
      observedRuntime.length == expectedRuntime.length &&
          observedRuntime.containsAll(expectedRuntime),
      'runtime dependency font coverage');
  _require(pubspec.contains('uses-material-design: true'),
      'MaterialIcons selection changed');
  return result;
}
