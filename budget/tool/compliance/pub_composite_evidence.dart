import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'sbom_lib.dart';

const pubCompositeEvidencePath =
    'compliance/evidence/reconstruction-2026-10-09/pub-composite-2026-10-11';

void _require(bool ok, String message) {
  if (!ok) throw StateError('Pub composite evidence: $message');
}

void _safe(String path) {
  _require(
      path.isNotEmpty &&
          !path.startsWith('/') &&
          !path.contains(':') &&
          !path.contains('\\') &&
          !path.split('/').any((p) => p == '..' || p.isEmpty),
      'unsafe evidence path');
}

/// Validates reviewed exact-archive evidence, not arbitrary licence expressions.
/// Full mixed notices still return NOASSERTION in the general text classifier.
String validatePubCompositeRecord(Map<String, dynamic> row, PubLockEntry locked,
    List<int> Function(String) readPayload) {
  List<int> payload(String path) {
    _safe(path);
    _require(path.startsWith('${locked.name}/'), 'cross-package payload');
    return readPayload(path);
  }

  dynamic json(String path) => jsonDecode(utf8.decode(payload(path)));
  _require(
      row['name'] == locked.name &&
          row['version'] == locked.version &&
          row['source'] == 'hosted' &&
          locked.source == 'hosted' &&
          row['archiveSha256'] == locked.checksumSha256,
      'locked identity mismatch');
  _require(
      row['originalDeclaration'] == 'NOASSERTION' &&
          row['releaseClearance'] == false &&
          row['legalClearance'] == false &&
          row['distributed'] == true,
      'unsupported scope or clearance');
  _require(row['gitCommit'] == null && row['gitTag'] == null,
      'unproven Git release equivalence');
  final release = json(row['releaseMetadataPath'] as String) as Map;
  final spec = release['pubspec'] as Map;
  _require(
      spec['name'] == locked.name &&
          spec['version'] == locked.version &&
          release['version'] == locked.version &&
          release['archive_sha256'] == locked.checksumSha256 &&
          release['archive_url'] == row['archiveUrl'] &&
          Uri.decodeFull(row['archiveUrl'] as String) ==
              'https://pub.dev/api/archives/${locked.name}-${locked.version}.tar.gz',
      'published release mismatch');
  _require(
      row['sourceRepository'] == (spec['repository'] ?? spec['homepage']) &&
          row['pubspecLicense'] == spec['license'] &&
          encodeCanonicalJson(row['pubspecLicenses']) ==
              encodeCanonicalJson(spec['licenses']),
      'pubspec metadata mismatch');
  final inventory =
      (json(row['archiveInventoryPath'] as String) as List).cast<Map>();
  final files = <String, Map>{};
  for (final file in inventory) {
    final path = file['path'] as String;
    _safe(path);
    _require(
        !files.containsKey(path) &&
            RegExp(r'^[a-f0-9]{64}$')
                .hasMatch(file['sha256'] as String? ?? '') &&
            file['bytes'] is int &&
            file['bytes'] >= 0,
        'invalid archive inventory');
    files[path] = file;
  }
  _require(files.isNotEmpty, 'empty archive inventory');
  final retained = <String, List<int>>{};
  for (final file in row['retainedFiles'] as List) {
    final path = file['archivePath'] as String;
    _safe(path);
    _require(
        !retained.containsKey(path) &&
            files.containsKey(path) &&
            file['path'] == '${locked.name}/source/$path',
        'invalid retained source mapping');
    final bytes = payload(file['path'] as String);
    _require(
        sha256.convert(bytes).toString() == file['sha256'] &&
            file['sha256'] == files[path]!['sha256'] &&
            bytes.length == files[path]!['bytes'],
        'retained source hash mismatch');
    retained[path] = bytes;
  }
  final noticeNames = {
    'LICENSE',
    'LICENCE',
    'NOTICE',
    'COPYING',
    'COPYRIGHT',
    'AUTHORS'
  };
  for (final path in files.keys) {
    if (noticeNames.contains(path.split('/').last.toUpperCase())) {
      _require(retained.containsKey(path), 'missing complete supplied notice');
    }
  }
  _require(
      retained.containsKey('LICENSE') && retained.containsKey('pubspec.yaml'),
      'missing root licence or pubspec');
  _require((row['conditions'] as List).isNotEmpty, 'missing limitations');
  final terms = (row['terms'] as List).cast<Map>();
  if (row['classification'] == 'Needs Verification' ||
      row['classification'] == 'Counsel Review Required') {
    _require(
        row['declaration'] == 'NOASSERTION' &&
            row['operator'] == 'UNRESOLVED' &&
            terms.isEmpty &&
            (row['unresolvedReasons'] as List).isNotEmpty,
        'ambiguous evidence cannot promote a declaration');
    return 'NOASSERTION';
  }
  _require(
      row['classification'] == 'Verified with conditions' &&
          (row['unresolvedReasons'] as List).isEmpty &&
          terms.isNotEmpty,
      'unreviewed declaration');
  final ids = <String>{};
  for (final term in terms) {
    final id = term['spdx'] as String;
    _require(ids.add(id), 'duplicate grant');
    final bytes = retained[term['licencePath']];
    _require(bytes != null, 'unretained grant text');
    // Preserve line endings when selecting the exact reviewed grant bytes.
    final lines = RegExp(r'[^\n]*\n|[^\n]+$')
        .allMatches(utf8.decode(bytes!))
        .map((m) => m.group(0)!)
        .toList();
    final start = term['startLine'] as int;
    final end = term['endLine'] as int;
    _require(start >= 1 && end >= start && end <= lines.length,
        'invalid grant range');
    final text = lines.sublist(start - 1, end).join();
    _require(
        sha256.convert(utf8.encode(text)).toString() == term['textSha256'] &&
            classifyLicenseText(text) == id,
        'unsupported or changed grant normalisation');
    final scope = (term['scopeFiles'] as List).cast<String>();
    _require(
        scope.isNotEmpty &&
            scope.toSet().length == scope.length &&
            scope.every(retained.containsKey),
        'missing retained source scope');
  }
  final sourceScope = (row['sourceScope'] as List).cast<Map>();
  _require(
      sourceScope.map((s) => s['term']).toSet().length == ids.length &&
          sourceScope.length == ids.length,
      'incomplete source-to-grant coverage');
  for (final scope in sourceScope) {
    _require(
        ids.contains(scope['term']) &&
            (scope['basis'] as String).isNotEmpty &&
            (scope['paths'] as List).isNotEmpty &&
            (scope['paths'] as List).every(files.containsKey),
        'invalid reviewed source scope');
    final term = terms.singleWhere((t) => t['spdx'] == scope['term']);
    _require(
        (term['scopeFiles'] as List).every((scope['paths'] as List).contains),
        'grant source witnesses outside reviewed scope');
  }
  final sorted = ids.toList()..sort();
  final expression = sorted.join(' AND ');
  _require(
      row['operator'] == (ids.length == 1 ? 'SINGLE' : 'AND') &&
          row['declaration'] == expression,
      'no OR choice or simplified aggregate supported');
  if (row['mode'] == 'wrapper-with-external-notices') {
    _require(
        ids.length == 1 &&
            retained.length == files.length &&
            (sourceScope.single['paths'] as List).toSet().length ==
                files.length,
        'wrapper archive coverage incomplete');
  } else {
    _require(row['mode'] == 'simultaneous-by-file' && ids.length > 1,
        'unsupported source-scope mode');
  }
  return expression;
}

Map<String, Map<String, dynamic>> verifyPubCompositeEvidence(
    Directory root, List<PubLockEntry> locked) {
  final folder = Directory('${root.path}/$pubCompositeEvidencePath');
  final manifest =
      jsonDecode(File('${folder.path}/manifest.json').readAsStringSync())
          as Map;
  _require(
      manifest['schemaVersion'] == 1 && manifest['releaseClearance'] == false,
      'unsupported manifest');
  final records = <String, Map<String, dynamic>>{};
  for (final row
      in (manifest['records'] as List).cast<Map<String, dynamic>>()) {
    final name = row['name'] as String;
    _require(!records.containsKey(name), 'duplicate package review');
    final entry = locked.singleWhere((e) => e.name == name);
    validatePubCompositeRecord(
        row, entry, (path) => File('${folder.path}/$path').readAsBytesSync());
    records[name] = row;
  }
  _require(records.isNotEmpty, 'empty reviewed package set');
  return records;
}
