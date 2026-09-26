import 'dart:convert';
import 'dart:io';

import 'sbom_lib.dart';
export 'sbom_lib.dart';

class ComplianceArtifactBundle {
  const ComplianceArtifactBundle({
    required this.components,
    required this.files,
    required this.provenance,
    required this.auditGaps,
  });

  final List<ComplianceComponent> components;
  final Map<String, String> files;
  final Map<String, dynamic> provenance;
  final List<dynamic> auditGaps;
}

Future<ComplianceArtifactBundle> createComplianceArtifactBundle({
  required Directory repositoryRoot,
}) async {
  final budgetRoot = Directory(_join(repositoryRoot.path, 'budget'));
  final manifestFile = File(_join(
      repositoryRoot.path, 'compliance/components/non_pub_components.json'));
  final provenanceFile = File(
      _join(repositoryRoot.path, 'compliance/provenance/cashew-upstream.json'));
  final pubLockFile = File(_join(budgetRoot.path, 'pubspec.lock'));
  final packageConfigFile =
      File(_join(budgetRoot.path, '.dart_tool/package_config.json'));
  final podLockFile = File(_join(budgetRoot.path, 'ios/Podfile.lock'));

  for (final requiredFile in <File>[
    manifestFile,
    provenanceFile,
    pubLockFile,
    packageConfigFile,
    podLockFile,
  ]) {
    if (!requiredFile.existsSync()) {
      throw StateError('Required compliance input is missing: '
          '${_relative(repositoryRoot, requiredFile.path)}');
    }
  }

  final manifest =
      jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
  final provenance =
      jsonDecode(await provenanceFile.readAsString()) as Map<String, dynamic>;
  final pubEntries = parsePubLock(await pubLockFile.readAsString());
  final podEntries = parsePodfileLock(await podLockFile.readAsString());
  final packageConfig = jsonDecode(await packageConfigFile.readAsString())
      as Map<String, dynamic>;
  final packageRoots = _packageRoots(packageConfigFile, packageConfig);
  final packageDependencies = <String, List<String>>{};
  final packageMetadata = <String, Map<String, String>>{};
  for (final entry in pubEntries) {
    final root = packageRoots[entry.name];
    if (root == null) {
      throw StateError('Resolved package root missing for ${entry.name}. '
          'Run flutter pub get with the committed lockfile.');
    }
    final pubspec = File(_join(root.path, 'pubspec.yaml'));
    if (!pubspec.existsSync()) {
      throw StateError('Resolved pubspec missing for ${entry.name}.');
    }
    final content = await pubspec.readAsString();
    packageDependencies[entry.name] = _parsePubspecDependencies(content);
    packageMetadata[entry.name] = _parsePubspecMetadata(content);
  }

  final runtimeReachable = _runtimeReachable(pubEntries, packageDependencies);
  final overrides = (manifest['pubOverrides'] as Map<String, dynamic>? ??
      <String, dynamic>{});
  final pubComponents = <ComplianceComponent>[];
  for (final entry in pubEntries) {
    final root = packageRoots[entry.name]!;
    final evidence = _readLicenceEvidence(root, entry);
    final override = overrides[entry.name] as Map<String, dynamic>?;
    final sourceRepository = packageMetadata[entry.name]?['repository'] ??
        packageMetadata[entry.name]?['homepage'] ??
        entry.sourceUrl;
    final dependencies = (packageDependencies[entry.name] ?? const <String>[])
        .where((name) => pubEntries.any((candidate) => candidate.name == name))
        .map((name) => 'pub:$name')
        .toList()
      ..sort();
    final license = classifyLicenseText(evidence.text);
    pubComponents.add(ComplianceComponent(
      id: 'pub:${entry.name}',
      name: entry.name,
      version: entry.version,
      ecosystem: 'pub',
      relationship: entry.relationship,
      source: entry.source,
      downloadLocation: _pubDownloadLocation(entry),
      sourceRepository: sourceRepository,
      licenseDeclared: license,
      licenseEvidence: evidence.label,
      distributed: runtimeReachable.contains(entry.name),
      modified: override?['modified'] == true,
      reviewStatus: license == 'NOASSERTION' ? 'review-required' : 'verified',
      dependencies: dependencies,
      checksumSha256: entry.checksumSha256,
      notes: override?['notes'] as String?,
    ));
  }

  final podComponents = podEntries
      .map((pod) => ComplianceComponent(
            id: 'cocoapods:${pod.name}',
            name: pod.name,
            version: pod.version,
            ecosystem: 'cocoapods',
            relationship: ComponentRelationship.transitive,
            source: 'Podfile.lock',
            downloadLocation:
                'https://cocoapods.org/pods/${Uri.encodeComponent(pod.name)}',
            licenseDeclared: 'NOASSERTION',
            licenseEvidence:
                'Podfile.lock spec checksum ${pod.specChecksum}; licence text not committed.',
            distributed: true,
            modified: false,
            reviewStatus: 'review-required',
            dependencies: const <String>[],
          ))
      .toList();

  final manualComponents = (manifest['components'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .map(_componentFromJson)
      .toList();
  final rootDependencies = <String>[
    ...pubEntries
        .where((entry) => entry.relationship.startsWith('direct-'))
        .map((entry) => 'pub:${entry.name}'),
    ...manualComponents
        .where((component) =>
            component.distributed &&
            (component.relationship == ComponentRelationship.directRuntime ||
                component.relationship == ComponentRelationship.bundledAsset))
        .map((component) => component.id),
  ]..sort();
  final rootComponent = ComplianceComponent(
    id: 'application:ola-hedge-finance',
    name: 'ola-hedge-finance',
    version: _rootVersion(
        await File(_join(budgetRoot.path, 'pubspec.yaml')).readAsString()),
    ecosystem: 'application',
    relationship: ComponentRelationship.root,
    source: 'git',
    downloadLocation: provenance['olaRepository'] as String,
    sourceRepository: provenance['olaRepository'] as String,
    licenseDeclared: provenance['upstreamLicense'] as String,
    licenseEvidence: provenance['rootLicensePath'] as String,
    distributed: true,
    modified: true,
    reviewStatus: 'verified',
    dependencies: rootDependencies,
    notes: 'Modified Cashew fork; upstream provenance is recorded separately.',
  );

  final components = <ComplianceComponent>[
    rootComponent,
    ...pubComponents,
    ...podComponents,
    ...manualComponents,
  ]..sort(_componentSort);
  _assertUniqueComponentIds(components);

  final createdUtc =
      DateTime.parse(manifest['documentCreatedUtc'] as String).toUtc();
  final auditGaps = manifest['auditGaps'] as List<dynamic>? ?? <dynamic>[];
  final inventory = _buildInventory(
    components: components,
    auditGaps: auditGaps,
    createdUtc: createdUtc,
  );
  final spdx = buildSpdxDocument(
    components: components,
    documentName: 'ola-hedge-finance-${rootComponent.version}',
    createdUtc: createdUtc,
  );
  final markdownReport = _renderMarkdownReport(
    components: components,
    auditGaps: auditGaps,
    createdUtc: createdUtc,
  );
  final files = <String, String>{
    'compliance/OPEN_SOURCE_COMPONENTS.md': markdownReport,
    'compliance/inventory/current-components.json':
        encodeCanonicalJson(inventory),
    'compliance/reports/current-components.md': markdownReport,
    'compliance/sbom/current.spdx.json': encodeCanonicalJson(spdx),
  };

  return ComplianceArtifactBundle(
    components: components,
    files: files,
    provenance: provenance,
    auditGaps: auditGaps,
  );
}

Map<String, String> versionedArtifactFiles(
  ComplianceArtifactBundle bundle,
  String releaseVersion,
) =>
    <String, String>{
      'compliance/sbom/$releaseVersion.spdx.json':
          bundle.files['compliance/sbom/current.spdx.json']!,
      'compliance/releases/$releaseVersion/sbom.spdx.json':
          bundle.files['compliance/sbom/current.spdx.json']!,
      'compliance/releases/$releaseVersion/dependency-licence-report.md':
          bundle.files['compliance/OPEN_SOURCE_COMPONENTS.md']!,
    };

List<String> findStaleArtifactPaths(
  Map<String, String> expected,
  Map<String, String?> actual,
) {
  final stale = <String>[];
  for (final path in expected.keys.toList()..sort()) {
    if (actual[path] != expected[path]) stale.add(path);
  }
  return stale;
}

Future<void> main(List<String> arguments) async {
  final checkOnly = arguments.contains('--check');
  String? releaseVersion;
  final versionIndex = arguments.indexOf('--version');
  if (versionIndex >= 0) {
    if (versionIndex + 1 >= arguments.length) {
      stderr.writeln('--version requires a value.');
      exitCode = 64;
      return;
    }
    releaseVersion = arguments[versionIndex + 1];
    if (!RegExp(r'^[A-Za-z0-9.+_-]+$').hasMatch(releaseVersion)) {
      stderr.writeln('Invalid release version: $releaseVersion');
      exitCode = 64;
      return;
    }
  }
  final repositoryRoot = _findRepositoryRoot(Directory.current);
  final bundle =
      await createComplianceArtifactBundle(repositoryRoot: repositoryRoot);
  final outputs = Map<String, String>.from(bundle.files);
  if (releaseVersion != null) {
    outputs.addAll(versionedArtifactFiles(bundle, releaseVersion));
  }

  if (checkOnly) {
    final actual = <String, String?>{};
    for (final path in outputs.keys) {
      final file = File(_join(repositoryRoot.path, path));
      actual[path] = file.existsSync() ? await file.readAsString() : null;
    }
    final stale = findStaleArtifactPaths(outputs, actual);
    if (stale.isNotEmpty) {
      stderr.writeln('Compliance artifacts are missing or stale:');
      for (final path in stale) {
        stderr.writeln('- $path');
      }
      exitCode = 1;
      return;
    }
    stdout.writeln(
        'Compliance artifacts are current (${bundle.components.length} components).');
    return;
  }

  for (final entry in outputs.entries) {
    final file = File(_join(repositoryRoot.path, entry.key));
    await file.parent.create(recursive: true);
    await file.writeAsString(entry.value);
    stdout.writeln('Wrote ${entry.key}');
  }
}

Map<String, Directory> _packageRoots(
  File packageConfigFile,
  Map<String, dynamic> packageConfig,
) {
  final roots = <String, Directory>{};
  for (final package in (packageConfig['packages'] as List<dynamic>)
      .cast<Map<String, dynamic>>()) {
    final rootUri =
        packageConfigFile.parent.uri.resolve(package['rootUri'] as String);
    roots[package['name'] as String] = Directory.fromUri(rootUri);
  }
  return roots;
}

List<String> _parsePubspecDependencies(String content) {
  final dependencies = <String>[];
  var section = '';
  for (final line in const LineSplitter().convert(content)) {
    final topLevel = RegExp(r'^([A-Za-z0-9_]+):').firstMatch(line);
    if (topLevel != null) {
      section = topLevel.group(1)!;
      continue;
    }
    if (section != 'dependencies') continue;
    final dependency = RegExp(r'^  ([A-Za-z0-9_]+):').firstMatch(line);
    if (dependency != null) dependencies.add(dependency.group(1)!);
  }
  return dependencies..sort();
}

Map<String, String> _parsePubspecMetadata(String content) {
  final metadata = <String, String>{};
  for (final line in const LineSplitter().convert(content)) {
    final match =
        RegExp(r'''^(repository|homepage):\s*["']?([^"']+)["']?\s*$''')
            .firstMatch(line);
    if (match != null) metadata[match.group(1)!] = match.group(2)!.trim();
  }
  return metadata;
}

Set<String> _runtimeReachable(
  List<PubLockEntry> entries,
  Map<String, List<String>> dependencies,
) {
  final known = entries.map((entry) => entry.name).toSet();
  final queue = entries
      .where(
          (entry) => entry.relationship == ComponentRelationship.directRuntime)
      .map((entry) => entry.name)
      .toList();
  final reachable = <String>{};
  while (queue.isNotEmpty) {
    final current = queue.removeLast();
    if (!reachable.add(current)) continue;
    queue.addAll((dependencies[current] ?? const <String>[])
        .where((dependency) => known.contains(dependency)));
  }
  return reachable;
}

_LicenceEvidence _readLicenceEvidence(Directory root, PubLockEntry entry) {
  File? licence = _licenceIn(root);
  if (licence == null && entry.source == 'sdk') {
    var candidate = root;
    for (var depth = 0; depth < 8; depth++) {
      if (File(_join(candidate.path, 'bin/flutter.bat')).existsSync() ||
          File(_join(candidate.path, 'bin/flutter')).existsSync()) {
        licence = _licenceIn(candidate);
        break;
      }
      candidate = candidate.parent;
    }
  }
  if (licence == null) {
    return const _LicenceEvidence(
      text: '',
      label: 'No resolved package licence file.',
    );
  }
  final label = switch (entry.source) {
    'path' =>
      '${entry.sourcePath ?? entry.name}/${licence.uri.pathSegments.last}',
    'git' => 'git-cache:${entry.name}@${entry.resolvedRevision ?? 'UNKNOWN'}/'
        '${licence.uri.pathSegments.last}',
    'sdk' => 'flutter-sdk/${licence.uri.pathSegments.last}',
    _ => 'pub-cache:${entry.name}-${entry.version}/'
        '${licence.uri.pathSegments.last}',
  };
  return _LicenceEvidence(text: licence.readAsStringSync(), label: label);
}

File? _licenceIn(Directory directory) {
  if (!directory.existsSync()) return null;
  final candidates = directory
      .listSync(followLinks: false)
      .whereType<File>()
      .where((file) => RegExp(r'^(LICENSE|LICENCE|COPYING)(\..*)?$')
          .hasMatch(file.uri.pathSegments.last.toUpperCase()))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return candidates.isEmpty ? null : candidates.first;
}

String _pubDownloadLocation(PubLockEntry entry) {
  if (entry.source == 'hosted') {
    return 'https://pub.dev/packages/${entry.name}/versions/${entry.version}';
  }
  if (entry.source == 'git' && entry.sourceUrl != null) {
    final revision = entry.resolvedRevision ?? entry.version;
    return '${entry.sourceUrl}#$revision';
  }
  if (entry.source == 'sdk') return 'https://github.com/flutter/flutter';
  if (entry.source == 'path') {
    return 'https://github.com/olahedgefinance/ola-hedge-finance';
  }
  return 'NOASSERTION';
}

ComplianceComponent _componentFromJson(Map<String, dynamic> value) =>
    ComplianceComponent(
      id: value['id'] as String,
      name: value['name'] as String,
      version: value['version'] as String,
      ecosystem: value['ecosystem'] as String,
      relationship: value['relationship'] as String,
      source: value['source'] as String,
      downloadLocation: value['downloadLocation'] as String,
      licenseDeclared: value['licenseDeclared'] as String,
      licenseEvidence: value['licenseEvidence'] as String,
      distributed: value['distributed'] as bool,
      modified: value['modified'] as bool,
      reviewStatus: value['reviewStatus'] as String,
      dependencies: (value['dependencies'] as List<dynamic>).cast<String>(),
      checksumSha256: value['checksumSha256'] as String?,
      sourceRepository: value['sourceRepository'] as String?,
      notes: value['notes'] as String?,
    );

Map<String, dynamic> _buildInventory({
  required List<ComplianceComponent> components,
  required List<dynamic> auditGaps,
  required DateTime createdUtc,
}) {
  final ecosystems = <String, int>{};
  for (final component in components) {
    ecosystems.update(component.ecosystem, (count) => count + 1,
        ifAbsent: () => 1);
  }
  return <String, dynamic>{
    'schemaVersion': 1,
    'generatedAtUtc': _isoSeconds(createdUtc),
    'sourceInputs': <String>[
      'budget/pubspec.yaml',
      'budget/pubspec.lock',
      'budget/.dart_tool/package_config.json (resolved, not committed)',
      'budget/ios/Podfile.lock',
      'budget/android/build.gradle',
      'budget/android/app/build.gradle',
      'compliance/components/non_pub_components.json',
      'compliance/provenance/cashew-upstream.json',
    ],
    'summary': <String, dynamic>{
      'components': components.length,
      'distributed': components.where((item) => item.distributed).length,
      'modified': components.where((item) => item.modified).length,
      'licenseReviewRequired': components
          .where((item) => item.licenseDeclared == 'NOASSERTION')
          .length,
      'ecosystems': ecosystems,
    },
    'components': components.map((item) => item.toInventoryJson()).toList(),
    'auditGaps': auditGaps,
  };
}

String _renderMarkdownReport({
  required List<ComplianceComponent> components,
  required List<dynamic> auditGaps,
  required DateTime createdUtc,
}) {
  final buffer = StringBuffer()
    ..writeln('# Current third-party component and licence inventory')
    ..writeln()
    ..writeln('Generated deterministically from committed dependency inputs on '
        '${_isoSeconds(createdUtc)}. `NOASSERTION` means evidence is missing or '
        'ambiguous; it is not a licence conclusion.')
    ..writeln()
    ..writeln('- Components: ${components.length}')
    ..writeln(
        '- Distributed: ${components.where((item) => item.distributed).length}')
    ..writeln('- Modified/forked: '
        '${components.where((item) => item.modified).length}')
    ..writeln('- Licence review required: '
        '${components.where((item) => item.licenseDeclared == 'NOASSERTION').length}')
    ..writeln()
    ..writeln('## Components')
    ..writeln()
    ..writeln(
        '| ID | Version | Relationship | Distributed | Modified | Licence | Evidence |')
    ..writeln('|---|---:|---|:---:|:---:|---|---|');
  for (final component in components) {
    buffer.writeln('| ${_md(component.id)} | ${_md(component.version)} | '
        '${_md(component.relationship)} | ${component.distributed ? 'yes' : 'no'} | '
        '${component.modified ? 'yes' : 'no'} | ${_md(component.licenseDeclared)} | '
        '${_md(component.licenseEvidence)} |');
  }
  buffer
    ..writeln()
    ..writeln('## Audit gaps')
    ..writeln()
    ..writeln('| Scope | Finding | Required action | Release gate |')
    ..writeln('|---|---|---|---|');
  for (final gap in auditGaps.cast<Map<String, dynamic>>()) {
    buffer.writeln('| ${_md(gap['scope'] as String)} | '
        '${_md(gap['finding'] as String)} | '
        '${_md(gap['requiredAction'] as String)} | '
        '${_md(gap['releaseGate'] as String)} |');
  }
  return buffer.toString();
}

int _componentSort(ComplianceComponent a, ComplianceComponent b) {
  final rootOrder = (a.relationship == ComponentRelationship.root ? 0 : 1)
      .compareTo(b.relationship == ComponentRelationship.root ? 0 : 1);
  if (rootOrder != 0) return rootOrder;
  return a.id.compareTo(b.id);
}

void _assertUniqueComponentIds(List<ComplianceComponent> components) {
  final seen = <String>{};
  for (final component in components) {
    if (!seen.add(component.id)) {
      throw StateError('Duplicate compliance component ID: ${component.id}');
    }
  }
}

String _rootVersion(String pubspec) {
  final match =
      RegExp(r'^version:\s*([^\s]+)\s*$', multiLine: true).firstMatch(pubspec);
  if (match == null) throw const FormatException('Root version is missing.');
  return match.group(1)!;
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

String _relative(Directory root, String path) {
  final rootPath = root.absolute.path.replaceAll('\\', '/');
  final normalized = File(path).absolute.path.replaceAll('\\', '/');
  return normalized.startsWith('$rootPath/')
      ? normalized.substring(rootPath.length + 1)
      : normalized;
}

String _join(String first, String second) =>
    '$first${Platform.pathSeparator}${second.replaceAll('/', Platform.pathSeparator)}';

String _isoSeconds(DateTime value) =>
    value.toUtc().toIso8601String().replaceFirst('.000Z', 'Z');

String _md(String value) => value.replaceAll('|', '\\|').replaceAll('\n', ' ');

class _LicenceEvidence {
  const _LicenceEvidence({required this.text, required this.label});

  final String text;
  final String label;
}
