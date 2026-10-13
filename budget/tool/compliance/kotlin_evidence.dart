import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:archive/archive.dart';
import 'sbom_lib.dart' show encodeCanonicalJson;

const kotlinEvidencePath =
    'compliance/evidence/reconstruction-2026-10-09/kotlin-2026-10-13';

void _require(bool ok, String message) {
  if (!ok) throw StateError('Kotlin evidence: $message');
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

/// Inventory exact publisher archives. Namespace is never licence evidence.
Map<String, dynamic> inspectKotlinArchive(List<int> bytes,
    {bool source = false}) {
  final decoder = ZipDecoder();
  final archive = decoder.decodeBytes(bytes, verify: true);
  final names = decoder.directory.fileHeaders.map((f) => f.filename).toList();
  _require(names.toSet().length == names.length, 'duplicate archive entry');
  final entries = <Map<String, dynamic>>[],
      headers = <Map<String, dynamic>>[],
      risks = <Map<String, dynamic>>[];
  final notices = <String>[];
  final files = archive.files.toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  for (final f in files) {
    final n = f.name;
    if (n.endsWith('/')) continue;
    _require(
        !n.startsWith('/') &&
            !n.contains('\\') &&
            !n.contains(':') &&
            !n.split('/').contains('..'),
        'unsafe archive path');
    final data = f.content as List<int>;
    entries.add({
      'path': n,
      'bytes': data.length,
      'sha256': sha256.convert(data).toString()
    });
    if (RegExp(r'license|licence|notice|copyright|copying|third.party',
            caseSensitive: false)
        .hasMatch(n)) notices.add(n);
    if (source && (n.endsWith('.java') || n.endsWith('.kt'))) {
      final text = utf8.decode(data);
      final start = text.substring(0, text.length < 6000 ? text.length : 6000);
      headers.add({
        'path': n,
        'apacheHeader': start.contains('JetBrains') &&
            (start.contains('Apache 2.0') ||
                start.contains('Apache License, Version 2.0')),
        'boost': text.contains(
            'implementations derived from boost special math functions')
      });
    }
    if (['.bin', '.dex', '.so', '.jar', '.png', '.ttf', '.otf']
        .any(n.endsWith)) {
      risks.add({
        'path': n,
        'reason':
            'Embedded binary payload requires separate exact source/build mapping'
      });
    }
  }
  return {
    'entries': entries,
    'sourceHeaders': headers,
    'noticeNamedEntries': notices,
    'risks': risks
  };
}

Map validateKotlinUpstream(
    Map row, Map manifest, List<int> Function(String) read) {
  final group = (row['coordinate'] as String).split(':').first;
  final repo = group == 'org.jetbrains.kotlin'
      ? 'JetBrains/kotlin'
      : 'Kotlin/kotlinx.coroutines';
  final tag =
      group == 'org.jetbrains.kotlin' ? 'v${row['version']}' : row['version'];
  final up = (manifest['upstreams'] as List).cast<Map>().singleWhere(
      (u) => u['tag'] == tag && u['repository'] == 'https://github.com/$repo');
  _require(
      row['upstreamKey'] == tag &&
          row['upstreamRepository'] == up['repository'],
      'upstream family/version differs');
  final commit = up['commit'];
  final response = up['response'] as Map;
  _require(
      RegExp(r'^[a-f0-9]{40}$').hasMatch(commit) &&
          response['url'] == 'https://api.github.com/repos/$repo/commits/$tag',
      'unbound upstream tag');
  _require(
      (jsonDecode(utf8.decode(_payload(response, read))) as Map)['sha'] ==
          commit,
      'upstream commit response differs');
  final files = <String, Map>{};
  for (final f in (up['files'] as List).cast<Map>()) {
    final path = f['sourcePath'] as String;
    _require(
        !files.containsKey(path) &&
            !path.split('/').contains('..') &&
            f['url'] == 'https://raw.githubusercontent.com/$repo/$commit/$path',
        'upstream URL/version/path differs');
    _payload(f, read);
    files[path] = f;
  }
  final licencePath =
      group == 'org.jetbrains.kotlin' ? 'license/LICENSE.txt' : 'LICENSE.txt';
  final licence = utf8.decode(_payload(files[licencePath]!, read));
  _require(
      licence.contains('Apache License') &&
          licence.contains('Version 2.0') &&
          licence.contains('END OF TERMS AND CONDITIONS'),
      'missing full Apache licence');
  final notice = utf8.decode(_payload(files['license/NOTICE.txt']!, read));
  _require(
      notice.contains(group == 'org.jetbrains.kotlin'
          ? 'Kotlin Compiler'
          : 'kotlinx.coroutines library'),
      'NOTICE scope missing');
  return files;
}

/// Explicit reviewed records, never a namespace-based licence classifier.
String validateKotlinRecord(Map<String, dynamic> row, Map component,
    Set<String> graphArtifactHashes, List<int> Function(String) read,
    {Map<String, Map<String, dynamic>> records = const {},
    required Map manifest}) {
  final coordinate = row['coordinate'] as String;
  final parts = coordinate.split(':');
  _require(
      parts.length == 3 &&
          ['org.jetbrains.kotlin', 'org.jetbrains.kotlinx']
              .contains(parts.first) &&
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
  final upstreamFiles = validateKotlinUpstream(row, manifest, read);
  final bom = parts[1].endsWith('-bom');
  final files = (row['files'] as List).cast<Map>();
  final names = <String>{};
  final payloads = <String, List<int>>{};
  final binaryHashes = <String>{};
  final base =
      'https://repo.maven.apache.org/maven2/${parts[0].replaceAll('.', '/')}/${parts[1]}/${parts[2]}/';
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
            (['binary', 'reference-binary'].contains(role) &&
                name == '$stem.jar'),
        'role or release filename mismatch');
    payloads[name] = _payload(f, read);
    if (role == 'binary') binaryHashes.add(f['sha256'] as String);
  }
  _require(
      files.where((f) => f['role'] == 'pom').length == 1 &&
          files.where((f) => f['role'] == 'source').length == (bom ? 0 : 1) &&
          files.where((f) => f['role'] == 'module').length <= 1,
      'missing or duplicate exact source/POM');
  _require(
      bom
          ? _tag(utf8.decode(payloads['$stem.pom']!), 'packaging') == 'pom' &&
              files.length == 1 &&
              graphArtifactHashes.isEmpty
          : files
                  .where(
                      (f) => ['binary', 'reference-binary'].contains(f['role']))
                  .length ==
              1,
      'metadata/runtime role differs');
  _require(
      !files.any((f) => f['role'] == 'reference-binary') ||
          (parts[1] == 'kotlinx-coroutines-core' &&
              graphArtifactHashes.isEmpty),
      'unsupported reference artifact');
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
          [
            'The Apache License, Version 2.0',
            'The Apache Software License, Version 2.0'
          ].contains(_tag(licences, 'name')) &&
          [
            'http://www.apache.org/licenses/LICENSE-2.0.txt',
            'https://www.apache.org/licenses/LICENSE-2.0.txt'
          ].contains(_tag(licences, 'url')) &&
          _tag(RegExp(r'<scm>([\s\S]*?)</scm>').firstMatch(pom)?.group(1) ?? '',
                  'url') ==
              row['upstreamRepository'],
      'POM licence or upstream mismatch');
  _require(
      !pom.contains('published-with-gradle-metadata') ||
          payloads.containsKey('$stem.module'),
      'published Gradle module metadata missing');
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
      .where(
          (f) => ['source', 'binary', 'reference-binary'].contains(f['role']))
      .map((f) => f['filename'])
      .toSet();
  _require(
      archives.length == archiveNames.length &&
          archives.keys.toSet().containsAll(archiveNames),
      'archive audit coverage mismatch');
  for (final f in files.where(
      (f) => ['source', 'binary', 'reference-binary'].contains(f['role']))) {
    final replay = inspectKotlinArchive(payloads[f['filename']]!,
        source: f['role'] == 'source');
    _require(
        encodeCanonicalJson(replay) ==
            encodeCanonicalJson(archives[f['filename']]),
        'archive audit differs from exact payload replay');
  }
  final mappings = (row['sourceMappings'] as List).cast<Map>();
  final usedMappings = <String>{};
  var boost = false;
  final risks = <dynamic>[];
  for (final archiveEntry in archives.entries) {
    final scan = archiveEntry.value as Map;
    for (final source in (scan['sourceHeaders'] as List).cast<Map>()) {
      boost |= source['boost'] == true;
      if (source['apacheHeader'] == true && source['boost'] != true) continue;
      final mapping = mappings.singleWhere((m) =>
          m['archive'] == archiveEntry.key && m['entry'] == source['path']);
      final path = mapping['upstreamPath'] as String;
      _require(
          parts[0] == 'org.jetbrains.kotlin'
              ? path.startsWith('libraries/stdlib/')
              : path.startsWith('kotlinx-coroutines-core/') ||
                  path.startsWith('ui/kotlinx-coroutines-android/'),
          'source mapping outside reviewed module');
      final entry = (scan['entries'] as List)
          .cast<Map>()
          .singleWhere((e) => e['path'] == source['path']);
      final upstream = upstreamFiles[path] as Map;
      _require(
          mapping['sha256'] == entry['sha256'] &&
              upstream['sha256'] == entry['sha256'],
          'source/upstream bytes differ');
      usedMappings.add('${archiveEntry.key}!${source['path']}');
    }
  }
  _require(mappings.length == usedMappings.length,
      'unused or duplicate source mappings');
  if (boost) {
    final licence = utf8.decode(
        _payload(upstreamFiles['license/third_party/boost_LICENSE.txt'], read));
    final context =
        utf8.decode(_payload(upstreamFiles['license/README.md'], read));
    _require(
        licence.contains('Boost Software License - Version 1.0') &&
            licence.contains('THE SOFTWARE IS PROVIDED') &&
            context
                .contains('libraries/stdlib/jvm/src/kotlin/util/MathJVM.kt') &&
            context.contains('Boost Software License 1.0'),
        'missing scoped Boost licence');
  }
  if (parts[1] == 'kotlin-stdlib' || parts[1] == 'kotlin-stdlib-common') {
    for (final p in [
      'license/third_party/guava_license.txt',
      'license/third_party/gwt_license.txt'
    ]) {
      final text = utf8.decode(_payload(upstreamFiles[p], read));
      _require(
          text.contains('Apache License') &&
              text.contains('END OF TERMS AND CONDITIONS'),
          'missing third-party Apache notice text');
    }
  }
  for (final a in archives.values.cast<Map>()) {
    _require(
        (a['entries'] as List).isNotEmpty &&
            a['noticeNamedEntries'] is List &&
            a['sourceHeaders'] is List &&
            a['risks'] is List,
        'incomplete archive audit');
    risks.addAll(a['risks']);
  }
  final expectedLicence = boost ? 'Apache-2.0 AND BSL-1.0' : 'Apache-2.0';
  if (row['licenseDeclared'] == expectedLicence) {
    _require(
        row['classification'] == 'Verified with conditions' && risks.isEmpty,
        'unreviewed embedded/resource scope cannot be cleared');
    return expectedLicence;
  }
  _require(
      row['licenseDeclared'] == 'NOASSERTION' &&
          row['classification'] == 'Needs Verification',
      'unsupported classification');
  return 'NOASSERTION';
}

void applyKotlinLicences(Directory root, List<Map<String, dynamic>> components,
    Map<String, dynamic> graph) {
  List<int> read(String p) =>
      File('${root.path}/$kotlinEvidencePath/$p').readAsBytesSync();
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
    final declaration = validateKotlinRecord(
        r, component, hashes[r['coordinate']] ?? {}, read,
        records: records, manifest: manifest);
    component['licenseDeclared'] = declaration;
    component['reviewStatus'] = declaration == 'NOASSERTION'
        ? 'review-required'
        : 'verified-with-conditions';
    component['licenseEvidence'] =
        '$kotlinEvidencePath/manifest.json#${r['coordinate']}; exact POM/source/artifact mapping, exact release licence/NOTICE texts, source copyrights and archive scope audit.';
    final files = (r['files'] as List).cast<Map>();
    component['downloadLocation'] = files.firstWhere((f) =>
        f['role'] ==
        (hashes.containsKey(r['coordinate']) ? 'binary' : 'pom'))['url'];
    component['notes'] =
        '${r['classification']}. ${(r['conditions'] as List).join(' ')} ${(r['risksSummary'] as List).join(' ')}';
  }
}
