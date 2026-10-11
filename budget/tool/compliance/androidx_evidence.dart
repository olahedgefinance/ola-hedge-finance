import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:archive/archive.dart';
import 'sbom_lib.dart' show encodeCanonicalJson;

const androidXEvidencePath =
    'compliance/evidence/reconstruction-2026-10-09/androidx-2026-10-11';

void _require(bool ok, String message) {
  if (!ok) throw StateError('AndroidX evidence: $message');
}

List<int> _payload(Map f, List<int> Function(String) read) {
  final path = f['path'] as String;
  _require(
      RegExp(r'^blobs/[a-f0-9]{64}\.bin$').hasMatch(path) &&
          path == 'blobs/${f['sha256']}.bin',
      'unsafe/content-address mismatch');
  final bytes = read(path);
  _require(
      bytes.length == f['bytes'] &&
          sha256.convert(bytes).toString() == f['sha256'],
      'payload hash mismatch');
  return bytes;
}

String _tag(String text, String name) =>
    RegExp('<$name>([^<]*)</$name>').firstMatch(text)?.group(1) ?? '';

/// Recompute scope from exact archives before accepting reviewed conclusions.
/// Uses the already locked archive 3.3.7 tooling dependency; no resolution change.
Map<String, dynamic> inspectAndroidXArchive(List<int> data,
    {bool source = false}) {
  final entries = <Map<String, dynamic>>[];
  final headers = <Map<String, dynamic>>[];
  final notices = <String>[];
  final risks = <Map<String, dynamic>>[];
  final lineage = <Map<String, dynamic>>[];
  void walk(List<int> payload, String prefix, int depth) {
    _require(depth <= 4, 'excessive nested archive depth');
    final decoder = ZipDecoder();
    final archive = decoder.decodeBytes(payload, verify: true);
    final names = decoder.directory.fileHeaders.map((f) => f.filename).toList();
    _require(names.toSet().length == names.length, 'duplicate ZIP entries');
    final files = archive.files.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    for (final file in files) {
      final name = file.name;
      if (name.endsWith('/')) continue;
      _require(
          !name.startsWith('/') &&
              !name.contains('\\') &&
              !name.contains(':') &&
              !name.split('/').contains('..'),
          'unsafe ZIP entry');
      final value = file.content as List<int>;
      final path = '$prefix$name';
      entries.add({
        'path': path,
        'bytes': value.length,
        'sha256': sha256.convert(value).toString()
      });
      if (RegExp(r'license|licence|notice|copying|copyright|third.party',
              caseSensitive: false)
          .hasMatch(name)) notices.add(path);
      void risk(String reason) => risks.add({'path': path, 'reason': reason});
      if (['.png', '.jpg', '.jpeg', '.webp', '.ttf', '.otf', '.so']
          .any(name.endsWith)) {
        risk(
            'Binary resource has no exact source/licence mapping in this review');
      }
      if (name.endsWith('.dex')) {
        risk(
            'Bundled DEX/tooling implementations require their own source/licence scope review');
      }
      if (name.endsWith('.class') &&
          (RegExp(r'(^|/)(protobuf|external|shaded|repackaged)/')
                  .hasMatch(name) ||
              ['kotlin/', 'kotlinx/', 'org/jetbrains/', 'org/intellij/']
                  .any(name.startsWith))) {
        risk(
            'Embedded third-party or relocated implementation; top-level POM is insufficient');
      }
      if (source &&
          ['.java', '.kt', '.aidl', '.proto', '.c', '.cpp', '.h', '.js']
              .any(name.endsWith)) {
        final text = utf8.decode(value, allowMalformed: true);
        final start =
            text.substring(0, text.length < 6000 ? text.length : 6000);
        final apache =
            start.contains('Licensed under the Apache License, Version 2.0') ||
                start.contains('SPDX-License-Identifier: Apache-2.0');
        final noncomment = text
            .replaceAll(RegExp(r'/\*.*?\*/|//[^\n]*', dotAll: true), '')
            .trim();
        final declaration = RegExp(
                r'^(?:package\s+[\w.]+\s*;\s*)?(?:parcelable\s+\w+\s*;\s*)?$')
            .hasMatch(noncomment);
        headers.add({
          'path': path,
          'apacheHeader': apache,
          'empty': value.isEmpty,
          'declarationOnly': declaration
        });
        if (!apache && !declaration && value.isNotEmpty) {
          risk(
              'Source implementation lacks a directly matched Apache header; needs separate review');
        }
        if (name.contains('/external/')) {
          risk(
              'Vendored external source refers to separately scoped upstream evidence');
        }
        for (final match in RegExp(
                r'^.*(?:cloned from|copied from|versions of Guava|adapted from|github.com/Kotlin/kotlinx.collections).*$',
                multiLine: true,
                caseSensitive: false)
            .allMatches(text)) {
          lineage.add({'path': path, 'text': match.group(0)!.trim()});
        }
      }
      if (name.endsWith('.jar')) walk(value, '$path!', depth + 1);
    }
  }

  walk(data, '', 0);
  return {
    'entries': entries,
    'sourceHeaders': headers,
    'noticeNamedEntries': notices,
    'risks': risks,
    'lineage': lineage
  };
}

/// Explicit reviewed records, never a namespace-based licence classifier.
String validateAndroidXRecord(Map<String, dynamic> row, Map component,
    Set<String> graphArtifactHashes, List<int> Function(String) read,
    {Map<String, Map<String, dynamic>> records = const {}}) {
  final coordinate = row['coordinate'] as String;
  final parts = coordinate.split(':');
  _require(
      parts.length == 3 &&
          parts.first.startsWith('androidx.') &&
          row['id'] == 'maven:${parts.take(2).join(':')}' &&
          component['id'] == row['id'] &&
          component['version'] == parts.last &&
          row['version'] == parts.last,
      'unselected or mismatched module/version');
  _require(
      row['legalClearance'] == false &&
          row['releaseClearance'] == false &&
          (row['conditions'] as List).isNotEmpty,
      'unsupported clearance/conditions');
  final files = (row['files'] as List).cast<Map>();
  final names = <String>{};
  final payloads = <String, List<int>>{};
  final binaryHashes = <String>{};
  final base =
      'https://dl.google.com/dl/android/maven2/${parts[0].replaceAll('.', '/')}/${parts[1]}/${parts[2]}/';
  final stem = '${parts[1]}-${parts[2]}';
  for (final f in files) {
    final name = f['filename'] as String;
    _require(
        names.add(name) &&
            !name.contains('/') &&
            !name.contains('\\') &&
            f['url'] == '$base$name',
        'duplicate or wrong publisher URL');
    final role = f['role'];
    _require(
        (role == 'pom' && name == '$stem.pom') ||
            (role == 'module' && name == '$stem.module') ||
            (role == 'source' && name == '$stem-sources.jar') ||
            (role == 'binary' && ['$stem.aar', '$stem.jar'].contains(name)),
        'role or release filename mismatch');
    payloads[name] = _payload(f, read);
    if (role == 'binary') binaryHashes.add(f['sha256'] as String);
  }
  _require(
      files.where((f) => f['role'] == 'pom').length == 1 &&
          files.where((f) => f['role'] == 'source').length == 1 &&
          files.where((f) => f['role'] == 'module').length <= 1,
      'missing or duplicate exact source/POM');
  _require(
      binaryHashes.length == graphArtifactHashes.length &&
          binaryHashes.containsAll(graphArtifactHashes),
      'binary graph hash mismatch');
  final pom = utf8.decode(payloads['$stem.pom']!);
  _require(
      ['groupId', 'artifactId', 'version'].map((k) => _tag(pom, k)).join(':') ==
          coordinate,
      'POM coordinate mismatch');
  final licences =
      RegExp(r'<licenses>([\s\S]*?)</licenses>').firstMatch(pom)?.group(1) ??
          '';
  _require(
      RegExp(r'<license>').allMatches(licences).length == 1 &&
          _tag(licences, 'name') ==
              'The Apache Software License, Version 2.0' &&
          [
            'http://www.apache.org/licenses/LICENSE-2.0.txt',
            'https://www.apache.org/licenses/LICENSE-2.0.txt'
          ].contains(_tag(licences, 'url')) &&
          _tag(pom, 'connection') ==
              'scm:git:https://android.googlesource.com/platform/frameworks/support',
      'POM licence or upstream mismatch');
  if (payloads.containsKey('$stem.module')) {
    final module = jsonDecode(utf8.decode(payloads['$stem.module']!)) as Map;
    final identity = module['component'] as Map;
    final declared =
        ['group', 'module', 'version'].map((k) => identity[k]).join(':');
    if (declared != coordinate) {
      final parent = records[declared];
      _require(parent != null && identity['url'] is String,
          'unbound multiplatform parent');
      final parentFile = (parent!['files'] as List)
          .cast<Map>()
          .singleWhere((f) => f['role'] == 'module');
      final parentModule =
          jsonDecode(utf8.decode(_payload(parentFile, read))) as Map;
      final parentIdentity = parentModule['component'] as Map;
      final childUrl = '$base$stem.module';
      _require(
          ['group', 'module', 'version']
                      .map((k) => parentIdentity[k])
                      .join(':') ==
                  declared &&
              Uri.parse(childUrl).resolve(identity['url']).toString() ==
                  parentFile['url'],
          'parent publication identity mismatch');
      final links = (parentModule['variants'] as List)
          .cast<Map>()
          .where((v) => v.containsKey('available-at'))
          .map((v) => v['available-at'] as Map);
      _require(
          links.any((l) =>
              ['group', 'module', 'version'].map((k) => l[k]).join(':') ==
                  coordinate &&
              Uri.parse(parentFile['url']).resolve(l['url']).toString() ==
                  childUrl),
          'missing reciprocal publication mapping');
    }
    for (final variant in (module['variants'] as List).cast<Map>()) {
      for (final f in (variant['files'] as List? ?? const []).cast<Map>()) {
        final bytes = payloads[f['name']];
        if (bytes != null) {
          for (final entry in {
            'sha256': sha256,
            'sha512': sha512,
            'sha1': sha1,
            'md5': md5
          }.entries) {
            if (f.containsKey(entry.key)) {
              _require(entry.value.convert(bytes).toString() == f[entry.key],
                  'module artifact checksum mismatch');
            }
          }
        }
      }
    }
  }
  final audit = jsonDecode(utf8.decode(_payload(row['audit'], read))) as Map;
  final archives = audit['archives'] as Map;
  final archiveNames = files
      .where((f) => ['source', 'binary'].contains(f['role']))
      .map((f) => f['filename'])
      .toSet();
  _require(
      archives.length == archiveNames.length &&
          archives.keys.toSet().containsAll(archiveNames),
      'archive audit coverage mismatch');
  for (final f
      in files.where((f) => ['source', 'binary'].contains(f['role']))) {
    final replay = inspectAndroidXArchive(payloads[f['filename']]!,
        source: f['role'] == 'source');
    _require(
        encodeCanonicalJson(replay) ==
            encodeCanonicalJson(archives[f['filename']]),
        'archive audit differs from exact payload replay');
  }
  final risks = <dynamic>[];
  for (final a in archives.values.cast<Map>()) {
    _require(
        (a['entries'] as List).isNotEmpty &&
            a['noticeNamedEntries'] is List &&
            a['sourceHeaders'] is List &&
            a['risks'] is List,
        'incomplete archive audit');
    risks.addAll(a['risks']);
  }
  if (row['licenseDeclared'] == 'Apache-2.0') {
    _require(
        row['classification'] == 'Verified with conditions' && risks.isEmpty,
        'unreviewed embedded/resource scope cannot be cleared');
    return 'Apache-2.0';
  }
  _require(
      row['licenseDeclared'] == 'NOASSERTION' &&
          row['classification'] == 'Needs Verification',
      'unsupported classification');
  return 'NOASSERTION';
}

void applyAndroidXLicences(Directory root,
    List<Map<String, dynamic>> components, Map<String, dynamic> graph) {
  List<int> read(String p) =>
      File('${root.path}/$androidXEvidencePath/$p').readAsBytesSync();
  final manifest = jsonDecode(utf8.decode(read('manifest.json'))) as Map;
  _require(
      manifest['schemaVersion'] == 1 &&
          manifest['legalClearance'] == false &&
          manifest['releaseClearance'] == false,
      'unsupported manifest');
  const graphPath =
      'compliance/evidence/reconstruction-2026-10-09/android-graph-2026-10-11/resolved-graph.json';
  _require(
      manifest['graphPath'] == graphPath &&
          sha256
                  .convert(File('${root.path}/$graphPath').readAsBytesSync())
                  .toString() ==
              manifest['graphSha256'],
      'stale graph binding');
  final licence = utf8.decode(_payload(manifest['sharedLicence'], read));
  _require(
      licence.contains('Apache License') &&
          licence.contains('Version 2.0') &&
          licence.contains('END OF TERMS AND CONDITIONS'),
      'missing full licence text');
  _payload(manifest['upstreamContext'], read);
  _payload(manifest['upstreamCommitResponse'], read);
  final rows = (manifest['records'] as List).cast<Map<String, dynamic>>();
  final records = {for (final r in rows) r['coordinate'] as String: r};
  _require(
      records.isNotEmpty &&
          records.length == rows.length &&
          (manifest['cohortCoordinates'] as List).length == records.length &&
          records.keys.toSet().containsAll(
              (manifest['cohortCoordinates'] as List).cast<String>()),
      'duplicate or incomplete cohort');
  final hashes = <String, Set<String>>{};
  for (final config in graph['configurations'] as List) {
    for (final a in config['artifacts'] as List) {
      hashes.putIfAbsent(a['module'], () => <String>{}).add(a['sha256']);
    }
  }
  for (final r in rows) {
    final component = components.singleWhere((c) => c['id'] == r['id']);
    final declaration = validateAndroidXRecord(
        r, component, hashes[r['coordinate']] ?? {}, read,
        records: records);
    component['licenseDeclared'] = declaration;
    component['reviewStatus'] = declaration == 'NOASSERTION'
        ? 'review-required'
        : 'verified-with-conditions';
    component['licenseEvidence'] =
        '$androidXEvidencePath/manifest.json#${r['coordinate']}; exact POM/source/artifact mapping, shared licence text, source copyrights and recursive scope audit.';
    final files = (r['files'] as List).cast<Map>();
    component['downloadLocation'] = files.firstWhere((f) =>
        f['role'] ==
        (hashes.containsKey(r['coordinate']) ? 'binary' : 'pom'))['url'];
    component['notes'] =
        '${r['classification']}. ${(r['conditions'] as List).join(' ')} ${(r['risksSummary'] as List).join(' ')}';
  }
}
