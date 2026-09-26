import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'generate_sbom.dart';

Future<String> sha256File(File file) async =>
    (await sha256.bind(file.openRead()).first).toString();

List<String> validateReleaseManifestStructure(Map<String, dynamic> manifest) {
  final errors = <String>[];
  if (manifest['schemaVersion'] != 1) {
    errors.add('schemaVersion must be 1.');
  }
  final releaseVersion = manifest['releaseVersion'];
  if (!_realValue(releaseVersion)) {
    errors.add('releaseVersion must replace the template placeholder.');
  }
  final sourceCommit = manifest['sourceCommit'];
  if (sourceCommit is! String ||
      !RegExp(r'^[0-9a-f]{40}$').hasMatch(sourceCommit)) {
    errors.add('sourceCommit must be a full lowercase 40-character Git hash.');
  }
  if (!_realValue(manifest['sourceTag'])) {
    errors.add('sourceTag must identify an immutable release tag.');
  }
  final sourceUrl = manifest['correspondingSourceUrl'];
  if (!_realValue(sourceUrl) || !_validHttpsUrl(sourceUrl as String?)) {
    errors.add('correspondingSourceUrl must be a non-placeholder HTTPS URL.');
  }
  final repositoryUrl = manifest['sourceRepositoryUrl'];
  if (!_realValue(repositoryUrl) || !_validHttpsUrl(repositoryUrl as String?)) {
    errors.add('sourceRepositoryUrl must be a non-placeholder HTTPS URL.');
  }

  final sourceArchive = manifest['sourceArchive'];
  if (sourceArchive is! Map<String, dynamic>) {
    errors.add('sourceArchive must describe the Corresponding Source archive.');
  } else {
    if (!_safeRelativePath(sourceArchive['path'])) {
      errors.add('sourceArchive.path must be a safe repository-relative path.');
    }
    if (!_validSha256(sourceArchive['sha256'])) {
      errors.add('sourceArchive.sha256 must be a real 64-character SHA-256.');
    }
  }

  final binaries = manifest['binaryArtifacts'];
  if (binaries is! List || binaries.isEmpty) {
    errors.add('binaryArtifacts must contain at least one released artifact.');
  } else {
    for (var index = 0; index < binaries.length; index++) {
      final item = binaries[index];
      if (item is! Map<String, dynamic>) {
        errors.add('binaryArtifacts[$index] must be an object.');
        continue;
      }
      if (!_realValue(item['platform'])) {
        errors.add('binaryArtifacts[$index].platform is required.');
      }
      if (!_safeRelativePath(item['path'])) {
        errors.add(
            'binaryArtifacts[$index].path must be a safe repository-relative path.');
      }
      if (!_validSha256(item['sha256'])) {
        errors.add(
            'binaryArtifacts[$index].sha256 must be a real 64-character SHA-256.');
      }
    }
  }

  if (!_safeRelativePath(manifest['sbomPath']) ||
      !(manifest['sbomPath'] as String? ?? '').endsWith('.spdx.json')) {
    errors.add('sbomPath must point to a versioned SPDX JSON file.');
  }
  for (final field in <String>[
    'dependencyLicenceReportPath',
    'thirdPartyNoticesPath',
    'buildReference',
  ]) {
    if (!_safeRelativePath(manifest[field])) {
      errors.add('$field must be a safe repository-relative path.');
    }
  }
  for (final field in <String>[
    'noticesIncluded',
    'gplSourceOfferReviewed',
    'assetAndFontRightsCleared',
    'storeTermsReviewed',
    'complianceChecklistComplete',
  ]) {
    if (manifest[field] != true) errors.add('$field must be confirmed true.');
  }
  final legalReview = manifest['legalReview'];
  if (legalReview is! Map<String, dynamic> ||
      legalReview['approved'] != true ||
      !_realValue(legalReview['reviewer']) ||
      legalReview['reviewDate'] is! String ||
      !RegExp(r'^\d{4}-\d{2}-\d{2}$')
          .hasMatch(legalReview['reviewDate'] as String)) {
    errors.add(
        'legalReview must be approved with a real reviewer and YYYY-MM-DD date.');
  }
  return errors;
}

List<String> validateInventoryContract(Map<String, dynamic> inventory) {
  final errors = <String>[];
  if (inventory['schemaVersion'] != 1) {
    errors.add('Inventory schemaVersion must be 1.');
  }
  final rawComponents = inventory['components'];
  if (rawComponents is! List || rawComponents.isEmpty) {
    errors.add('Inventory components must not be empty.');
    return errors;
  }
  final components = rawComponents.cast<Map<String, dynamic>>();
  final ids = <String>{};
  for (final component in components) {
    final id = component['id'];
    if (id is! String || id.isEmpty) {
      errors.add('Every inventory component requires an ID.');
      continue;
    }
    if (!ids.add(id)) errors.add('Duplicate inventory component ID: $id.');
    if (component['licenseDeclared'] == 'NOASSERTION') {
      if (component['reviewStatus'] != 'review-required') {
        errors.add('$id with NOASSERTION must remain review-required.');
      }
      if (!_realValue(component['licenseEvidence'])) {
        errors
            .add('$id with NOASSERTION requires an evidence-gap explanation.');
      }
    }
  }
  final root = components
      .where((component) => component['relationship'] == 'root')
      .toList();
  if (root.length != 1 ||
      root.single['licenseDeclared'] != 'GPL-3.0-or-later') {
    errors.add('Inventory must contain one GPL-3.0-or-later root component.');
  }
  final summary = inventory['summary'];
  if (summary is! Map<String, dynamic> ||
      summary['components'] != components.length) {
    errors.add(
        'Inventory summary component count must match the component list.');
  }
  final gaps = inventory['auditGaps'];
  if (gaps is! List || gaps.isEmpty) {
    errors.add('Inventory must retain at least one explicit audit gap until '
        'all missing evidence is cleared.');
  } else {
    for (final gap in gaps) {
      if (gap is! Map<String, dynamic> ||
          !_realValue(gap['requiredAction']) ||
          !_realValue(gap['releaseGate'])) {
        errors.add('Every audit gap needs a required action and release gate.');
      }
    }
  }
  return errors;
}

Future<List<String>> runRepositoryComplianceAudit({
  required Directory repositoryRoot,
}) async {
  final errors = <String>[];
  for (final requiredPath in <String>[
    'budget/pubspec.lock',
    'compliance/OPEN_SOURCE_COMPONENTS.md',
    'compliance/dependency-review.template.md',
    'compliance/release/release-manifest.template.json',
    'compliance/releases/README.md',
    'legal/THIRD_PARTY_NOTICES.md',
    'legal/OPEN_SOURCE_POLICY.md',
  ]) {
    if (!File(_join(repositoryRoot.path, requiredPath)).existsSync()) {
      errors.add('Required compliance evidence is missing: $requiredPath.');
    }
  }
  errors.addAll(await validateComplianceArtifactSafety(repositoryRoot));
  errors.addAll(await _validateOriginalServiceIdentity(repositoryRoot));
  ComplianceArtifactBundle bundle;
  try {
    bundle =
        await createComplianceArtifactBundle(repositoryRoot: repositoryRoot);
  } catch (error) {
    return <String>['Unable to generate compliance artifacts: $error'];
  }

  final actual = <String, String?>{};
  for (final path in bundle.files.keys) {
    final file = File(_join(repositoryRoot.path, path));
    actual[path] = file.existsSync() ? await file.readAsString() : null;
  }
  for (final path in findStaleArtifactPaths(bundle.files, actual)) {
    errors.add('Generated compliance artifact is missing or stale: $path.');
  }

  final inventoryFile = File(_join(
      repositoryRoot.path, 'compliance/inventory/current-components.json'));
  if (inventoryFile.existsSync()) {
    final inventory =
        jsonDecode(await inventoryFile.readAsString()) as Map<String, dynamic>;
    errors.addAll(validateInventoryContract(inventory));
  }

  final spdxFile =
      File(_join(repositoryRoot.path, 'compliance/sbom/current.spdx.json'));
  if (spdxFile.existsSync()) {
    final spdx =
        jsonDecode(await spdxFile.readAsString()) as Map<String, dynamic>;
    errors.addAll(_validateSpdx(spdx));
  }

  final provenance = bundle.provenance;
  if (provenance['upstreamProject'] != 'Cashew' ||
      provenance['upstreamRepository'] !=
          'https://github.com/jameskokoska/Cashew' ||
      provenance['upstreamLicense'] != 'GPL-3.0-or-later' ||
      provenance['claimsOriginalCashewOwnership'] != false ||
      provenance['historyRetained'] != true ||
      provenance['tagsRetained'] != true) {
    errors.add('Cashew GPL provenance record is incomplete or contradictory.');
  }

  final license = File(_join(repositoryRoot.path, 'LICENSE'));
  if (!license.existsSync()) {
    errors.add('Root GPL LICENSE is missing.');
  } else {
    final text = await license.readAsString();
    if (!text.contains('GNU GENERAL PUBLIC LICENSE') ||
        !text.contains('Version 3, 29 June 2007') ||
        !text.contains('Cashew: an expense budget tracking application') ||
        !text.contains('Copyright (C) 2023  James Kokoska') ||
        !text.contains('(at your option) any later version')) {
      errors.add('Root GPL/Cashew copyright and or-later notice changed.');
    }
  }

  final gitChecks = <Future<void>>[
    _expectGitOutput(
      repositoryRoot,
      <String>['hash-object', 'LICENSE'],
      provenance['rootLicenseGitBlob'] as String?,
      'Root LICENSE Git blob does not match the provenance record.',
      errors,
    ),
    _expectGitOutput(
      repositoryRoot,
      <String>['remote', 'get-url', 'upstream'],
      provenance['upstreamFetchUrl'] as String?,
      'The upstream fetch remote is absent or incorrect.',
      errors,
    ),
    _expectGitOutput(
      repositoryRoot,
      <String>['remote', 'get-url', '--push', 'upstream'],
      provenance['expectedUpstreamPushUrl'] as String?,
      'The upstream push remote is not disabled as recorded.',
      errors,
    ),
    _expectGitOutput(
      repositoryRoot,
      <String>['remote', 'get-url', 'origin'],
      '${provenance['olaRepository']}.git',
      'The origin remote is not the ÓLA repository recorded in provenance.',
      errors,
    ),
  ];
  await Future.wait(gitChecks);

  final historyCount =
      await _git(repositoryRoot, <String>['rev-list', '--count', 'HEAD']);
  if (!historyCount.success ||
      (int.tryParse(historyCount.stdout.trim()) ?? 0) < 2) {
    errors.add('Git history is unavailable or appears truncated.');
  }
  final tags = await _git(repositoryRoot, <String>['tag', '--list']);
  if (!tags.success || tags.stdout.trim().isEmpty) {
    errors.add(
        'Upstream/release tags are unavailable; tag provenance is not retained.');
  }
  return errors;
}

Future<List<String>> runReleaseComplianceChecks({
  required Directory repositoryRoot,
  required File releaseManifestFile,
}) async {
  final errors = await runRepositoryComplianceAudit(
    repositoryRoot: repositoryRoot,
  );
  if (!releaseManifestFile.existsSync()) {
    return <String>[...errors, 'Release manifest file does not exist.'];
  }
  final manifest = jsonDecode(await releaseManifestFile.readAsString())
      as Map<String, dynamic>;
  final structural = validateReleaseManifestStructure(manifest);
  errors.addAll(structural);
  if (structural.isNotEmpty) return errors;

  final version = manifest['releaseVersion'] as String;
  final pubspec = await File(_join(repositoryRoot.path, 'budget/pubspec.yaml'))
      .readAsString();
  final appVersion = RegExp(r'^version:\s*([^\s]+)\s*$', multiLine: true)
      .firstMatch(pubspec)
      ?.group(1);
  if (version != appVersion) {
    errors.add(
        'releaseVersion $version does not match pubspec version $appVersion.');
  }

  final sourceCommit = manifest['sourceCommit'] as String;
  final head = await _git(repositoryRoot, <String>['rev-parse', 'HEAD']);
  if (!head.success || head.stdout.trim() != sourceCommit) {
    errors.add('sourceCommit does not match the checked-out release commit.');
  }
  final tag = manifest['sourceTag'] as String;
  final tagged = await _git(
      repositoryRoot, <String>['rev-parse', '--verify', '$tag^{commit}']);
  if (!tagged.success || tagged.stdout.trim() != sourceCommit) {
    errors.add('sourceTag does not resolve to sourceCommit.');
  }
  final status = await _git(repositoryRoot, <String>['status', '--porcelain']);
  if (!status.success || status.stdout.trim().isNotEmpty) {
    errors.add('Release checks require a clean Git working tree.');
  }

  final expectedSbom = 'compliance/sbom/$version.spdx.json';
  final expectedBundleSbom = 'compliance/releases/$version/sbom.spdx.json';
  if (manifest['sbomPath'] != expectedBundleSbom) {
    errors.add('sbomPath must be $expectedBundleSbom for this release.');
  } else {
    final canonicalVersioned = File(_join(repositoryRoot.path, expectedSbom));
    final versioned = File(_join(repositoryRoot.path, expectedBundleSbom));
    final current =
        File(_join(repositoryRoot.path, 'compliance/sbom/current.spdx.json'));
    if (!versioned.existsSync() ||
        !canonicalVersioned.existsSync() ||
        await canonicalVersioned.readAsString() !=
            await current.readAsString() ||
        await versioned.readAsString() != await current.readAsString()) {
      errors.add(
          'Canonical or release-bundle SPDX SBOM is missing or differs from current.spdx.json.');
    }
  }

  if (manifest['sourceRepositoryUrl'] !=
      bundleSourceRepositoryUrl(repositoryRoot)) {
    errors
        .add('sourceRepositoryUrl does not match the recorded ÓLA repository.');
  }
  for (final field in <String>[
    'dependencyLicenceReportPath',
    'thirdPartyNoticesPath',
    'buildReference',
  ]) {
    final path = manifest[field] as String;
    if (!File(_join(repositoryRoot.path, path)).existsSync()) {
      errors.add('$field does not exist at $path.');
    }
  }

  final archive = manifest['sourceArchive'] as Map<String, dynamic>;
  await _checkArtifactHash(
    repositoryRoot,
    archive['path'] as String,
    archive['sha256'] as String,
    'Corresponding Source archive',
    errors,
  );
  for (final binary in (manifest['binaryArtifacts'] as List<dynamic>)
      .cast<Map<String, dynamic>>()) {
    await _checkArtifactHash(
      repositoryRoot,
      binary['path'] as String,
      binary['sha256'] as String,
      '${binary['platform']} binary',
      errors,
    );
  }
  return errors;
}

String bundleSourceRepositoryUrl(Directory repositoryRoot) {
  final file = File(
      _join(repositoryRoot.path, 'compliance/provenance/cashew-upstream.json'));
  if (!file.existsSync()) return '';
  final value = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return value['olaRepository'] as String? ?? '';
}

Future<List<String>> validateComplianceArtifactSafety(
    Directory repositoryRoot) async {
  final errors = <String>[];
  final forbiddenNames = RegExp(
      r'(^|[\\/])(google-services\.json|GoogleService-Info\.plist|\.env|id_rsa|[^\\/]+\.(pem|p12|pfx|jks|keystore))$',
      caseSensitive: false);
  final secretContent = <RegExp>[
    RegExp(r'-----BEGIN [A-Z ]*PRIVATE KEY-----'),
    RegExp(r'"private_key"\s*:\s*"-----BEGIN'),
    RegExp(r'AIza[0-9A-Za-z_-]{30,}'),
    RegExp(r'gh[oprsu]_[0-9A-Za-z]{30,}'),
  ];
  final proprietaryOnly = RegExp(
      r'\b(proprietary[- ]only|closed[- ]source[- ]only)\b',
      caseSensitive: false);

  for (final directoryName in <String>['compliance', 'legal']) {
    final directory = Directory(_join(repositoryRoot.path, directoryName));
    if (!directory.existsSync()) continue;
    for (final entity
        in directory.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final relative = _relativePath(repositoryRoot, entity.path);
      if (forbiddenNames.hasMatch(relative)) {
        errors.add(
            'Secret/private-key file is forbidden in compliance evidence: $relative.');
        continue;
      }
      final bytes = await entity.readAsBytes();
      if (bytes.contains(0)) continue;
      final text = utf8.decode(bytes, allowMalformed: true);
      if (secretContent.any((pattern) => pattern.hasMatch(text))) {
        errors.add('Potential secret/private-key material found in $relative.');
      }
      if (proprietaryOnly.hasMatch(text)) {
        errors.add(
            'GPL release material must not describe the client as proprietary-only: $relative.');
      }
    }
  }
  return errors;
}

Future<List<String>> _validateOriginalServiceIdentity(
    Directory repositoryRoot) async {
  const forbidden = <String>[
    'budget-app-flutter',
    'cashewapp.web.app',
    'budget-track.web.app',
    'cashew.pro.',
    'ko-fi.com/dapperappdeveloper',
    'dapperappdeveloper@gmail.com',
    'folderName = "Cashew"',
    '267621253497',
    'FIREBASE_SERVICE_ACCOUNT_BUDGET_APP_FLUTTER',
    'com.budget.tracker_app',
    'com.budget.tracker-app',
  ];
  const extensions = <String>[
    '.dart',
    '.xml',
    '.gradle',
    '.properties',
    '.plist',
    '.entitlements',
    '.pbxproj',
    '.html',
    '.json',
    '.js',
    '.yaml',
    '.yml',
    '.bat',
    '.ps1',
    '.kt',
    '.java'
  ];
  final errors = <String>[];
  final files = <File>[];
  for (final rootPath in <String>[
    'budget/lib',
    'budget/android',
    'budget/ios',
    'budget/web',
    '.github',
    'scripts'
  ]) {
    final root = Directory(_join(repositoryRoot.path, rootPath));
    if (!root.existsSync()) continue;
    for (final entity in root.listSync(recursive: true, followLinks: false)) {
      if (entity is! File ||
          !extensions.any((extension) => entity.path.endsWith(extension)) ||
          entity.path.replaceAll('\\', '/').contains('/build/') ||
          entity.path.replaceAll('\\', '/').contains('/Pods/')) {
        continue;
      }
      files.add(entity);
    }
  }
  for (final path in <String>['.firebaserc', 'firebase.json']) {
    final file = File(_join(repositoryRoot.path, path));
    if (file.existsSync()) files.add(file);
  }
  for (final file in files) {
    final content = await file.readAsString();
    for (final identity in forbidden) {
      if (content.contains(identity)) {
        errors.add('Original Cashew service identity reintroduced in '
            '${_relativePath(repositoryRoot, file.path)}: $identity.');
      }
    }
  }
  return errors;
}

Future<void> main(List<String> arguments) async {
  final repositoryRoot = _findRepositoryRoot(Directory.current);
  List<String> errors;
  final manifestIndex = arguments.indexOf('--release-manifest');
  if (manifestIndex >= 0) {
    if (manifestIndex + 1 >= arguments.length) {
      stderr.writeln('--release-manifest requires a path.');
      exitCode = 64;
      return;
    }
    errors = await runReleaseComplianceChecks(
      repositoryRoot: repositoryRoot,
      releaseManifestFile: File(arguments[manifestIndex + 1]),
    );
  } else {
    errors = await runRepositoryComplianceAudit(repositoryRoot: repositoryRoot);
  }
  if (errors.isNotEmpty) {
    stderr.writeln('Compliance check failed:');
    for (final error in errors) {
      stderr.writeln('- $error');
    }
    exitCode = 1;
    return;
  }
  stdout.writeln(manifestIndex >= 0
      ? 'Release compliance checks passed.'
      : 'Repository compliance audit passed.');
}

List<String> _validateSpdx(Map<String, dynamic> spdx) {
  final errors = <String>[];
  if (spdx['spdxVersion'] != 'SPDX-2.3' ||
      spdx['dataLicense'] != 'CC0-1.0' ||
      spdx['SPDXID'] != 'SPDXRef-DOCUMENT') {
    errors.add('SPDX document header is invalid.');
  }
  final packages = spdx['packages'];
  if (packages is! List || packages.isEmpty) {
    errors.add('SPDX packages must not be empty.');
    return errors;
  }
  final ids = packages
      .cast<Map<String, dynamic>>()
      .map((package) => package['SPDXID'])
      .whereType<String>()
      .toSet();
  if (ids.length != packages.length) {
    errors.add('SPDX package IDs must be present and unique.');
  }
  for (final relationship
      in (spdx['relationships'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>()) {
    final from = relationship['spdxElementId'];
    final to = relationship['relatedSpdxElement'];
    if (from != 'SPDXRef-DOCUMENT' && !ids.contains(from)) {
      errors.add('SPDX relationship has unknown source element $from.');
    }
    if (!ids.contains(to)) {
      errors.add('SPDX relationship has unknown target element $to.');
    }
  }
  return errors;
}

Future<void> _expectGitOutput(
  Directory root,
  List<String> arguments,
  String? expected,
  String message,
  List<String> errors,
) async {
  final result = await _git(root, arguments);
  if (!result.success || expected == null || result.stdout.trim() != expected) {
    errors.add(message);
  }
}

Future<_CommandResult> _git(Directory root, List<String> arguments) async {
  try {
    final result = await Process.run(
      'git',
      arguments,
      workingDirectory: root.path,
      runInShell: Platform.isWindows,
    );
    return _CommandResult(
      success: result.exitCode == 0,
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
    );
  } catch (error) {
    return _CommandResult(
      success: false,
      stdout: '',
      stderr: error.toString(),
    );
  }
}

Future<void> _checkArtifactHash(
  Directory repositoryRoot,
  String relativePath,
  String expectedSha256,
  String label,
  List<String> errors,
) async {
  final file = File(_join(repositoryRoot.path, relativePath));
  if (!file.existsSync()) {
    errors.add('$label is missing at $relativePath.');
    return;
  }
  if (await sha256File(file) != expectedSha256) {
    errors.add('$label SHA-256 does not match the release manifest.');
  }
}

bool _realValue(Object? value) =>
    value is String && value.trim().isNotEmpty && !_placeholder(value);

bool _placeholder(String value) =>
    RegExp(r'^(required|replace|placeholder|todo|tbd)(_|$)',
            caseSensitive: false)
        .hasMatch(value);

bool _validHttpsUrl(String? value) {
  if (value == null) return false;
  final uri = Uri.tryParse(value);
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
}

bool _validSha256(Object? value) =>
    value is String &&
    RegExp(r'^[0-9a-f]{64}$').hasMatch(value) &&
    !_placeholder(value);

bool _safeRelativePath(Object? value) {
  if (!_realValue(value)) return false;
  final path = value as String;
  if (path.startsWith('/') || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path)) {
    return false;
  }
  return !path.replaceAll('\\', '/').split('/').contains('..');
}

Directory _findRepositoryRoot(Directory start) {
  var current = start.absolute;
  while (true) {
    if (File(_join(current.path, 'LICENSE')).existsSync() &&
        File(_join(current.path, 'budget/pubspec.lock')).existsSync()) {
      return current;
    }
    if (current.parent.path == current.path) {
      throw StateError('Could not locate the repository root.');
    }
    current = current.parent;
  }
}

String _join(String first, String second) =>
    '$first${Platform.pathSeparator}${second.replaceAll('/', Platform.pathSeparator)}';

String _relativePath(Directory root, String path) {
  final prefix = root.absolute.path.replaceAll('\\', '/');
  final normalized = File(path).absolute.path.replaceAll('\\', '/');
  return normalized.startsWith('$prefix/')
      ? normalized.substring(prefix.length + 1)
      : normalized;
}

class _CommandResult {
  const _CommandResult({
    required this.success,
    required this.stdout,
    required this.stderr,
  });

  final bool success;
  final String stdout;
  final String stderr;
}
