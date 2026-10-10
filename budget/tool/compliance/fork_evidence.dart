import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'sbom_lib.dart';

const forkEvidencePath = 'compliance/evidence/reconstruction-2026-10-09/forks';
void _require(bool ok, String message) {
  if (!ok) throw StateError('Fork evidence: $message');
}

void validateForkIdentity(Map<String, dynamic> row, PubLockEntry entry) {
  _require(
      row['name'] == entry.name &&
          row['version'] == entry.version &&
          row['source'] == entry.source,
      'stale package identity');
  _require(
      row['modified'] == true &&
          row['distributed'] == true &&
          row['licence'] == 'MIT' &&
          row['releaseClearance'] == false,
      'unsupported scope or clearance');
  if (entry.source == 'git') {
    _require(
        row['forkRepository'] == entry.sourceUrl &&
            row['forkCommit'] == entry.resolvedRevision &&
            row['comparisonKind'] == 'git-ancestor',
        'locked Git identity mismatch');
    _require(
        RegExp(r'^[0-9a-f]{40}$')
            .hasMatch(row['upstreamCommit'] as String? ?? ''),
        'missing upstream commit');
  } else {
    _require(
        entry.source == 'path' &&
            row['localPath'] == 'budget/${entry.sourcePath}' &&
            row['comparisonKind'] == 'published-archive',
        'path identity mismatch');
    _require(
        row['upstreamCommit'] == null &&
            (row['historicalGitBase'] as String).startsWith('UNAVAILABLE'),
        'unproven historical Git ancestry');
    _require(
        row['upstreamVersion'] == entry.version &&
            row['archiveUrl'] ==
                'https://pub.dev/api/archives/${entry.name}-${entry.version}.tar.gz' &&
            RegExp(r'^[a-f0-9]{64}$')
                .hasMatch(row['archiveSha256'] as String? ?? ''),
        'published release baseline mismatch');
  }
}

void validateForkProvenance(
    Map<String, dynamic> row, Map<String, dynamic> proof) {
  if (row['source'] == 'git') {
    for (final pair in [
      ['name', 'name'],
      ['upstreamRepository', 'repository'],
      ['upstreamCommit', 'base'],
      ['forkCommit', 'fork'],
      ['verifiedUpstreamTip', 'verifiedUpstreamTip']
    ]) {
      _require(row[pair[0]] == proof[pair[1]], 'Git provenance mismatch');
    }
    _require(
        proof['baseAncestorOfUpstream'] == true &&
            proof['baseAncestorOfFork'] == true,
        'unverified ancestry');
  } else {
    final pubspec = proof['pubspec'] as Map;
    _require(
        row['archiveUrl'] == proof['archive_url'] &&
            row['archiveSha256'] == proof['archive_sha256'],
        'archive provenance mismatch');
    _require(
        row['name'] == pubspec['name'] &&
            row['version'] == pubspec['version'] &&
            row['upstreamVersion'] == pubspec['version'],
        'published package mismatch');
    _require(
        row['upstreamRepository'] ==
            (pubspec['homepage'] as String).split('/tree/').first,
        'published repository mismatch');
  }
}

String _git(Directory dir, List<String> args) {
  final result = Process.runSync('git', [
    '-c',
    'safe.directory=${dir.path.replaceAll('\\', '/')}',
    '-C',
    dir.path,
    ...args
  ]);
  _require(result.exitCode == 0, 'Git source check failed: ${args.first}');
  return (result.stdout as String).trim();
}

void verifyForkEvidence(Directory root, List<PubLockEntry> entries) {
  final folder = Directory('${root.path}/$forkEvidencePath');
  File payload(String path) {
    _require(
        path.isNotEmpty &&
            !path.startsWith('/') &&
            !path.contains(':') &&
            !path.contains('\\') &&
            !path.split('/').contains('..'),
        'unsafe evidence path');
    return File('${folder.path}/$path');
  }

  final manifest = jsonDecode(payload('manifest.json').readAsStringSync())
      as Map<String, dynamic>;
  _require(manifest['schemaVersion'] == 1, 'schema mismatch');
  _require(
      sha256
              .convert(
                  File('${root.path}/budget/pubspec.lock').readAsBytesSync())
              .toString() ==
          manifest['pubLockSha256'],
      'stale dependency lock');
  final expected =
      entries.where((p) => p.source == 'git' || p.source == 'path').toList();
  final rows = (manifest['records'] as List).cast<Map<String, dynamic>>();
  _require(
      rows.length == expected.length &&
          rows.map((r) => r['name']).toSet().length == rows.length,
      'incomplete/duplicate fork coverage');
  final packages = (jsonDecode(
      File('${root.path}/budget/.dart_tool/package_config.json')
          .readAsStringSync())['packages'] as List);
  for (final entry in expected) {
    final row = rows.singleWhere((r) => r['name'] == entry.name);
    validateForkIdentity(row, entry);
    for (final item
        in (row['evidenceHashes'] as Map<String, dynamic>).entries) {
      _require(
          sha256.convert(payload(item.key).readAsBytesSync()).toString() ==
              item.value,
          'changed retained evidence: ${item.key}');
    }
    for (final field in [
      'patch',
      'delta',
      'upstreamInventory',
      'forkInventory',
      'upstreamLicence',
      'forkLicence',
      'modificationNotice'
    ]) {
      _require((row['evidenceHashes'] as Map).containsKey(row[field]),
          'unbound $field');
    }
    Map<String, dynamic> proof(String path) {
      _require(
          (row['evidenceHashes'] as Map).containsKey(path), 'unbound proof');
      return jsonDecode(payload(path).readAsStringSync())
          as Map<String, dynamic>;
    }

    final name = row['name'];
    validateForkProvenance(
        row,
        proof(
            '$name/${entry.source == 'git' ? 'ancestry.json' : 'pub-version.json'}'));
    final replay = proof('$name/patch-replay.json');
    _require(
        replay['exactTargetTreeMatched'] == true &&
            replay['patchSha256'] ==
                sha256
                    .convert(payload(row['patch'] as String).readAsBytesSync())
                    .toString() &&
            replay['replayedGitTree'] ==
                (row['forkGitTree'] ?? row['canonicalTree']),
        'invalid patch replay proof');
    final headerPath = '$name/header-review.json';
    _require((row['evidenceHashes'] as Map).containsKey(headerPath),
        'missing header proof');
    final headers = jsonDecode(payload(headerPath).readAsStringSync()) as List;
    _require(
        headers.every((h) =>
            h['preserved'] == true &&
            (h['upstreamStatements'] as List)
                .every((line) => (h['forkStatements'] as List).contains(line))),
        'source header loss');
    if (entry.source == 'git') {
      for (final pair in [
        ['upstream', 'upstreamCommit'],
        ['fork', 'forkCommit']
      ]) {
        final path = '$name/${pair[0]}-commit.txt';
        _require((row['evidenceHashes'] as Map).containsKey(path),
            'missing commit proof');
        final bytes = payload(path).readAsBytesSync();
        _require(
            sha1.convert([
                  ...utf8.encode('commit ${bytes.length}\u0000'),
                  ...bytes
                ]).toString() ==
                row[pair[1]],
            'commit object mismatch');
      }
    }
    if (entry.source == 'path') {
      final path = row['localPath'] as String;
      _require(_git(root, ['rev-parse', 'HEAD:$path']) == row['canonicalTree'],
          'changed vendored tree');
      _require(_git(root, ['status', '--porcelain', '--', path]).isEmpty,
          'dirty vendored source');
    } else {
      final package = packages.singleWhere((p) => p['name'] == entry.name);
      final uri = Uri.parse(package['rootUri'] as String);
      _require(uri.scheme == 'file', 'unsupported Git cache location');
      final dir = Directory.fromUri(uri);
      _require(_git(dir, ['rev-parse', 'HEAD']) == row['forkCommit'],
          'changed cache revision');
      _require(_git(dir, ['rev-parse', 'HEAD^{tree}']) == row['forkGitTree'],
          'changed Git tree');
      _require(_git(dir, ['status', '--porcelain']).isEmpty, 'dirty Git cache');
    }
  }
}
