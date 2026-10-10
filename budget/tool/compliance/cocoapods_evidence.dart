import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'sbom_lib.dart';

const cocoaPodsEvidencePath =
    'compliance/evidence/reconstruction-2026-10-09/native/cocoapods-source-2026-10-09';

// A podspec's licence field is only corroboration. The retained source text
// must independently support the same declaration; composite/custom text
// remains unresolved. This does not conclude a licence or certify a binary.
String cocoaPodsDeclaration(dynamic metadata, String? sourceText) {
  if (sourceText == null) return 'NOASSERTION';
  final type = metadata is String ? metadata : (metadata as Map?)?['type'];
  const aliases = <String, String>{
    'Apache License, Version 2.0': 'Apache-2.0',
    'Apache-2.0': 'Apache-2.0',
    'Apache': 'Apache-2.0',
    'MIT': 'MIT',
    'New BSD': 'BSD-3-Clause',
    'zlib': 'Zlib',
    'Mozilla Public License': 'MPL-2.0',
  };
  final expected = aliases[type];
  return expected != null && classifyLicenseText(sourceText) == expected
      ? expected
      : 'NOASSERTION';
}

void verifyCocoaPodRecord({
  required Map<String, dynamic> record,
  required PodLockEntry locked,
  required List<int> specBytes,
  String? licenceText,
  String? refReceipt,
  List<int>? licenceResponse,
}) {
  void require(bool condition, String message) {
    if (!condition) throw StateError('CocoaPods ${locked.name}: $message');
  }

  require(record['name'] == locked.name && record['version'] == locked.version,
      'stale identity');
  require(
      record['lockedSpecChecksum'] == locked.specChecksum &&
          sha1.convert(specBytes).toString() == locked.specChecksum &&
          sha256.convert(specBytes).toString() == record['specSha256'],
      'podspec checksum mismatch');
  final spec = jsonDecode(utf8.decode(specBytes)) as Map<String, dynamic>;
  require(spec['name'] == locked.name && spec['version'] == locked.version,
      'spec identity mismatch');
  require(
      encodeCanonicalJson(spec['source']) ==
              encodeCanonicalJson(record['source']) &&
          encodeCanonicalJson(spec['license']) ==
              encodeCanonicalJson(record['licenceMetadata']),
      'source/licence metadata differs from authenticated spec');
  final source = spec['source'] as Map<String, dynamic>;
  if (source['git'] is String) {
    final revision = record['resolvedCommit'] as String? ?? '';
    require(
        RegExp(r'^[a-f0-9]{40}$').hasMatch(revision), 'missing exact revision');
    require(record['sourceRepository'] == source['git'],
        'source repository mismatch');
    final repo = (source['git'] as String).replaceFirst(RegExp(r'\.git$'), '');
    require(record['downloadLocation'] == '$repo/tree/$revision',
        'source URL mismatch');
    if (source['commit'] != null) {
      require(source['commit'] == revision, 'fixed source revision mismatch');
    } else {
      require(
          source['tag'] is String && refReceipt != null, 'tag receipt missing');
      final refs = <String, String>{};
      for (final line in const LineSplitter().convert(refReceipt!)) {
        final fields = line.trim().split(RegExp(r'\s+'));
        require(fields.length == 2, 'malformed tag receipt');
        refs[fields[1]] = fields[0];
      }
      final tag = 'refs/tags/${source['tag']}';
      require(
          (refs['$tag^{}'] ?? refs[tag]) == revision, 'tag/revision mismatch');
    }
  } else {
    require(
        source['http'] is String &&
            record['downloadLocation'] == source['http'],
        'unsupported source or archive URL mismatch');
    require(
        RegExp(r'^[a-f0-9]{64}$')
            .hasMatch(record['archiveSha256'] as String? ?? ''),
        'archive acquisition digest missing');
  }
  if (record['licenceFile'] != null) {
    require(
        licenceText != null &&
            sha256.convert(utf8.encode(licenceText)).toString() ==
                record['licenceSha256'],
        'source licence hash mismatch');
    final declaredPath =
        spec['license'] is Map ? spec['license']['file'] : null;
    if (declaredPath != null && source['git'] != null) {
      require(
          record['licencePath'] == declaredPath, 'licence location mismatch');
    }
  } else {
    require(licenceText == null, 'unbound source licence text');
  }
  if (source['git'] != null && record['licenceFile'] != null) {
    final path = record['licencePath'] as String? ?? '';
    require(
        path.isNotEmpty &&
            !path.startsWith('/') &&
            !path.contains(':') &&
            !path.contains('\\') &&
            !path.split('/').contains('..'),
        'unsafe source licence path');
    final repo = (source['git'] as String).replaceFirst(RegExp(r'\.git$'), '');
    require(repo.startsWith('https://github.com/'),
        'unsupported source licence host');
    final slug = repo.substring('https://github.com/'.length);
    final revision = record['resolvedCommit'];
    if (record['licenceTransport'] == 'github-contents-api') {
      require(
          record['licenceUrl'] ==
              'https://api.github.com/repos/$slug/contents/$path?ref=$revision',
          'licence API origin mismatch');
      require(
          licenceResponse != null &&
              sha256.convert(licenceResponse).toString() ==
                  record['licenceResponseSha256'],
          'licence response mismatch');
      final proof = jsonDecode(utf8.decode(licenceResponse!)) as Map;
      require(proof['encoding'] == 'base64' && proof['path'] == path,
          'licence API path/encoding mismatch');
      final bytes = base64
          .decode((proof['content'] as String).replaceAll(RegExp(r'\s'), ''));
      require(
          sha256.convert(bytes).toString() == record['licenceSha256'] &&
              sha1.convert([
                    ...utf8.encode('blob ${bytes.length}\u0000'),
                    ...bytes
                  ]).toString() ==
                  proof['sha'],
          'licence Git blob mismatch');
    } else {
      require(
          record['licenceTransport'] == null &&
              record['licenceUrl'] ==
                  'https://raw.githubusercontent.com/$slug/$revision/$path',
          'licence origin mismatch');
    }
  }
  // HTTP archives remain unresolved until archive-member licensing can be
  // evaluated with equivalent origin binding; an observed digest is not a grant.
  final declaration = source['git'] == null
      ? 'NOASSERTION'
      : cocoaPodsDeclaration(spec['license'], licenceText);
  require(record['licenseDeclared'] == declaration,
      'unsupported licence classification');
  require(
      record['status'] ==
          (declaration == 'NOASSERTION'
              ? 'review-required'
              : 'verified-with-conditions'),
      'unsupported review status');
}

Map<String, Map<String, dynamic>> loadCocoaPodsSourceEvidence(
    Directory repositoryRoot, List<PodLockEntry> pods) {
  final folder = Directory('${repositoryRoot.path}/$cocoaPodsEvidencePath');
  final manifest =
      jsonDecode(File('${folder.path}/manifest.json').readAsStringSync())
          as Map<String, dynamic>;
  if (manifest['schemaVersion'] != 1)
    throw StateError('Unsupported CocoaPods evidence schema');
  final lockBytes =
      File('${repositoryRoot.path}/budget/ios/Podfile.lock').readAsBytesSync();
  if (sha256.convert(lockBytes).toString() != manifest['podLockSha256']) {
    throw StateError('Stale CocoaPods lock evidence');
  }
  final registry = <String>{};
  var inRepos = false;
  for (final line in const LineSplitter().convert(utf8.decode(lockBytes))) {
    if (line == 'SPEC REPOS:') {
      inRepos = true;
      continue;
    }
    if (line.isNotEmpty && !line.startsWith(' ')) inRepos = false;
    if (inRepos && line.startsWith('    - ')) {
      registry.add(line.substring(6).replaceAll('"', ''));
    }
  }
  File evidenceFile(dynamic value) {
    if (value is! String ||
        value.isEmpty ||
        value.startsWith('/') ||
        value.contains(':') ||
        value.contains('\\') ||
        value.split('/').contains('..')) {
      throw StateError('Unsafe CocoaPods evidence path');
    }
    return File('${folder.path}/$value');
  }

  final result = <String, Map<String, dynamic>>{};
  for (final row
      in (manifest['records'] as List).cast<Map<String, dynamic>>()) {
    final name = row['name'] as String;
    if (!registry.contains(name) || result.containsKey(name)) {
      throw StateError('Unexpected/duplicate CocoaPods evidence: $name');
    }
    verifyCocoaPodRecord(
        record: row,
        locked: pods.singleWhere((p) => p.name == name),
        specBytes: evidenceFile(row['specFile']).readAsBytesSync(),
        licenceText: row['licenceFile'] == null
            ? null
            : evidenceFile(row['licenceFile']).readAsStringSync(),
        licenceResponse: row['licenceResponseFile'] == null
            ? null
            : evidenceFile(row['licenceResponseFile']).readAsBytesSync(),
        refReceipt: row['refReceipt'] == null
            ? null
            : evidenceFile(row['refReceipt']).readAsStringSync());
    result[name] = row;
  }
  if (result.length != registry.length || registry.isEmpty) {
    throw StateError('Incomplete registry CocoaPods evidence');
  }
  return result;
}
