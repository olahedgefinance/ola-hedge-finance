import 'dart:convert';

abstract final class ComponentRelationship {
  static const String root = 'root';
  static const String directRuntime = 'direct-runtime';
  static const String directDevelopment = 'direct-development';
  static const String transitive = 'transitive';
  static const String buildTool = 'build-tool';
  static const String bundledAsset = 'bundled-asset';
}

class PubLockEntry {
  const PubLockEntry({
    required this.name,
    required this.version,
    required this.relationship,
    required this.source,
    this.sourceUrl,
    this.sourcePath,
    this.resolvedRevision,
    this.checksumSha256,
  });

  final String name;
  final String version;
  final String relationship;
  final String source;
  final String? sourceUrl;
  final String? sourcePath;
  final String? resolvedRevision;
  final String? checksumSha256;
}

class PodLockEntry {
  const PodLockEntry({
    required this.name,
    required this.version,
    required this.specChecksum,
  });

  final String name;
  final String version;
  final String specChecksum;
}

class ComplianceComponent {
  const ComplianceComponent({
    required this.id,
    required this.name,
    required this.version,
    required this.ecosystem,
    required this.relationship,
    required this.source,
    required this.downloadLocation,
    required this.licenseDeclared,
    required this.licenseEvidence,
    required this.distributed,
    required this.modified,
    required this.reviewStatus,
    required this.dependencies,
    this.checksumSha256,
    this.sourceRepository,
    this.notes,
  });

  final String id;
  final String name;
  final String version;
  final String ecosystem;
  final String relationship;
  final String source;
  final String downloadLocation;
  final String licenseDeclared;
  final String licenseEvidence;
  final bool distributed;
  final bool modified;
  final String reviewStatus;
  final List<String> dependencies;
  final String? checksumSha256;
  final String? sourceRepository;
  final String? notes;

  Map<String, dynamic> toInventoryJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'version': version,
        'ecosystem': ecosystem,
        'relationship': relationship,
        'source': source,
        'downloadLocation': downloadLocation,
        'licenseDeclared': licenseDeclared,
        'licenseEvidence': licenseEvidence,
        'distributed': distributed,
        'modified': modified,
        'reviewStatus': reviewStatus,
        'dependencies': dependencies.toList()..sort(),
        if (checksumSha256 != null) 'checksumSha256': checksumSha256,
        if (sourceRepository != null) 'sourceRepository': sourceRepository,
        if (notes != null) 'notes': notes,
      };
}

List<PubLockEntry> parsePubLock(String content) {
  final entries = <PubLockEntry>[];
  String? name;
  String? dependency;
  String? source;
  String? version;
  final description = <String, String>{};
  var inPackages = false;

  void finish() {
    if (name == null) return;
    if (source == null || version == null || dependency == null) {
      throw FormatException('Incomplete Pub lock entry for $name');
    }
    entries.add(PubLockEntry(
      name: name!,
      version: version!,
      relationship: _pubRelationship(dependency!),
      source: source!,
      sourceUrl: description['url'],
      sourcePath: description['path'],
      resolvedRevision: description['resolved-ref'],
      checksumSha256: description['sha256'],
    ));
    name = null;
    dependency = null;
    source = null;
    version = null;
    description.clear();
  }

  for (final line in const LineSplitter().convert(content)) {
    if (line == 'packages:') {
      inPackages = true;
      continue;
    }
    if (!inPackages) continue;
    if (line == 'sdks:') {
      finish();
      break;
    }
    final packageMatch = RegExp(r'^  ([A-Za-z0-9_]+):$').firstMatch(line);
    if (packageMatch != null) {
      finish();
      name = packageMatch.group(1)!;
      continue;
    }
    if (name == null) continue;
    final propertyMatch =
        RegExp(r'^    ([a-zA-Z0-9_-]+):\s*(.*)$').firstMatch(line);
    if (propertyMatch != null) {
      final key = propertyMatch.group(1)!;
      final value = _unquote(propertyMatch.group(2)!);
      if (key == 'dependency') dependency = value;
      if (key == 'source') source = value;
      if (key == 'version') version = value;
      continue;
    }
    final descriptionMatch =
        RegExp(r'^      ([a-zA-Z0-9_-]+):\s*(.*)$').firstMatch(line);
    if (descriptionMatch != null) {
      description[descriptionMatch.group(1)!] =
          _unquote(descriptionMatch.group(2)!);
    }
  }
  if (inPackages) finish();
  entries.sort((a, b) => a.name.compareTo(b.name));
  return entries;
}

String _pubRelationship(String dependency) {
  if (dependency == 'direct main') return ComponentRelationship.directRuntime;
  if (dependency == 'direct dev') {
    return ComponentRelationship.directDevelopment;
  }
  return ComponentRelationship.transitive;
}

List<PodLockEntry> parsePodfileLock(String content) {
  final versions = <String, String>{};
  final checksums = <String, String>{};
  var section = '';

  for (final line in const LineSplitter().convert(content)) {
    if (line.isNotEmpty && !line.startsWith(' ')) {
      section = line.endsWith(':')
          ? line.substring(0, line.length - 1)
          : line.split(':').first;
      continue;
    }
    if (section == 'PODS' && line.startsWith('  - ')) {
      var value = line.substring(4).trim();
      if (value.endsWith(':')) value = value.substring(0, value.length - 1);
      value = _unquote(value);
      final versionStart = value.lastIndexOf(' (');
      if (versionStart <= 0 || !value.endsWith(')')) continue;
      final fullName = value.substring(0, versionStart);
      final version = value.substring(versionStart + 2, value.length - 1);
      final rootName = fullName.split('/').first;
      versions.putIfAbsent(rootName, () => version);
      continue;
    }
    if (section == 'SPEC CHECKSUMS') {
      final match = RegExp(r'^  (.+):\s*([^\s]+)$').firstMatch(line);
      if (match != null) {
        checksums[_unquote(match.group(1)!.trim())] = match.group(2)!;
      }
    }
  }

  final entries = checksums.entries
      .map((entry) => PodLockEntry(
            name: entry.key,
            version: versions[entry.key] ?? 'UNKNOWN',
            specChecksum: entry.value,
          ))
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  return entries;
}

String classifyLicenseText(String text) {
  final normalized = text.toLowerCase().replaceAll('\r\n', '\n');
  final families = <bool>[
    normalized.contains('apache license') && normalized.contains('version 2.0'),
    normalized.contains('permission is hereby granted, free of charge'),
    normalized.contains('redistribution and use in source and binary forms'),
    normalized.contains('mozilla public license'),
    normalized.contains('gnu general public license'),
    normalized.contains(
        'permission to use, copy, modify, and/or distribute this software for any purpose with or without fee'),
    normalized.contains("this software is provided 'as-is'") &&
        normalized.contains('altered source versions must be plainly marked'),
  ];
  if (families.where((v) => v).length > 1 ||
      (normalized.contains('mozilla public license') &&
          normalized.contains('1.1') &&
          normalized.contains('2.0'))) {
    return 'NOASSERTION'; // Never collapse composite text or mixed versions.
  }
  if (normalized.contains('apache license') &&
      normalized.contains('version 2.0')) {
    return 'Apache-2.0';
  }
  if (normalized.contains('mozilla public license version 2.0')) {
    return 'MPL-2.0';
  }
  if (normalized.contains('permission is hereby granted, free of charge')) {
    return 'MIT';
  }
  if (normalized
      .contains('redistribution and use in source and binary forms')) {
    if (normalized.contains('neither the name')) return 'BSD-3-Clause';
    return 'BSD-2-Clause';
  }
  if (normalized.contains(
      'permission to use, copy, modify, and/or distribute this software for any purpose with or without fee')) {
    return 'ISC';
  }
  if (normalized.contains('mozilla public license') &&
      normalized.contains('2.0')) {
    return 'MPL-2.0';
  }
  if (normalized.contains('gnu general public license') &&
      normalized.contains('version 3')) {
    return 'GPL-3.0-only';
  }
  if (normalized.contains("this software is provided 'as-is'") &&
      normalized.contains('altered source versions must be plainly marked')) {
    return 'Zlib';
  }
  return 'NOASSERTION';
}

Map<String, dynamic> buildSpdxDocument({
  required List<ComplianceComponent> components,
  required String documentName,
  required DateTime createdUtc,
}) {
  final sorted = components.toList()
    ..sort((a, b) {
      final rootOrder = (a.relationship == ComponentRelationship.root ? 0 : 1)
          .compareTo(b.relationship == ComponentRelationship.root ? 0 : 1);
      if (rootOrder != 0) return rootOrder;
      final ecosystemOrder = a.ecosystem.compareTo(b.ecosystem);
      if (ecosystemOrder != 0) return ecosystemOrder;
      final nameOrder = a.name.compareTo(b.name);
      if (nameOrder != 0) return nameOrder;
      return a.version.compareTo(b.version);
    });
  final ids = <String, String>{};
  for (final component in sorted) {
    ids[component.id] = component.relationship == ComponentRelationship.root
        ? 'SPDXRef-Package-${_spdxSafe(component.name)}'
        : 'SPDXRef-Package-${_spdxSafe(component.ecosystem)}-'
            '${_spdxSafe(component.name)}-${_spdxSafe(component.version)}';
  }
  final digestInput = sorted
      .map((component) => jsonEncode(component.toInventoryJson()))
      .join('\n');
  final root = sorted
      .where(
          (component) => component.relationship == ComponentRelationship.root)
      .toList();
  if (root.length != 1) {
    throw ArgumentError('Exactly one root component is required.');
  }

  final relationships = <Map<String, dynamic>>[
    <String, dynamic>{
      'spdxElementId': 'SPDXRef-DOCUMENT',
      'relationshipType': 'DESCRIBES',
      'relatedSpdxElement': ids[root.single.id],
    },
  ];
  for (final component in sorted) {
    for (final dependency in component.dependencies.toList()..sort()) {
      if (!ids.containsKey(dependency)) continue;
      relationships.add(<String, dynamic>{
        'spdxElementId': ids[component.id],
        'relationshipType': 'DEPENDS_ON',
        'relatedSpdxElement': ids[dependency],
      });
    }
  }

  return <String, dynamic>{
    'spdxVersion': 'SPDX-2.3',
    'dataLicense': 'CC0-1.0',
    'SPDXID': 'SPDXRef-DOCUMENT',
    'name': documentName,
    'documentNamespace':
        'https://github.com/olahedgefinance/ola-hedge-finance/sbom/'
            '${Uri.encodeComponent(documentName)}/${_stableDigest(digestInput)}',
    'creationInfo': <String, dynamic>{
      'created': _spdxDate(createdUtc),
      'creators': <String>[
        'Organization: ÓLA HEDGE FINANCE Inc.',
        'Tool: ola-hedge-finance-repository-sbom-generator/1',
      ],
      'licenseListVersion': '3.25',
    },
    'documentDescribes': <String>[ids[root.single.id]!],
    'packages': sorted
        .map((component) => <String, dynamic>{
              'SPDXID': ids[component.id],
              'name': component.name,
              'versionInfo': component.version,
              'downloadLocation': component.downloadLocation,
              'filesAnalyzed': false,
              'licenseConcluded': 'NOASSERTION',
              'licenseDeclared': component.licenseDeclared,
              'copyrightText': 'NOASSERTION',
              'supplier': 'NOASSERTION',
              if (component.checksumSha256 != null &&
                  RegExp(r'^[a-fA-F0-9]{64}$')
                      .hasMatch(component.checksumSha256!))
                'checksums': <Map<String, String>>[
                  <String, String>{
                    'algorithm': 'SHA256',
                    'checksumValue': component.checksumSha256!,
                  }
                ],
              'comment': <String>[
                'ecosystem=${component.ecosystem}',
                'relationship=${component.relationship}',
                'source=${component.source}',
                'distributed=${component.distributed}',
                'modified=${component.modified}',
                'reviewStatus=${component.reviewStatus}',
                'licenseEvidence=${component.licenseEvidence}',
                if (component.sourceRepository != null)
                  'sourceRepository=${component.sourceRepository}',
                if (component.notes != null) 'notes=${component.notes}',
              ].join('; '),
              if (component.ecosystem == 'pub')
                'externalRefs': <Map<String, String>>[
                  <String, String>{
                    'referenceCategory': 'PACKAGE-MANAGER',
                    'referenceType': 'purl',
                    'referenceLocator':
                        'pkg:pub/${component.name}@${component.version}',
                  }
                ],
              if (component.ecosystem == 'cocoapods')
                'externalRefs': <Map<String, String>>[
                  <String, String>{
                    'referenceCategory': 'PACKAGE-MANAGER',
                    'referenceType': 'purl',
                    'referenceLocator':
                        'pkg:cocoapods/${Uri.encodeComponent(component.name)}@${component.version}',
                  }
                ],
            })
        .toList(),
    'relationships': relationships,
  };
}

String encodeCanonicalJson(Object? value) {
  final canonical = _canonicalize(value);
  return '${const JsonEncoder.withIndent('  ').convert(canonical)}\n';
}

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return <String, dynamic>{
      for (final key in keys) key: _canonicalize(value[key]),
    };
  }
  if (value is List) return value.map(_canonicalize).toList();
  return value;
}

String _unquote(String value) {
  final trimmed = value.trim();
  if (trimmed.length >= 2 &&
      ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
          (trimmed.startsWith("'") && trimmed.endsWith("'")))) {
    return trimmed.substring(1, trimmed.length - 1);
  }
  return trimmed;
}

String _spdxSafe(String value) {
  final safe = value.replaceAll(RegExp(r'[^A-Za-z0-9.-]+'), '-');
  return safe.replaceAll(RegExp(r'^-+|-+$'), '');
}

String _spdxDate(DateTime value) =>
    value.toUtc().toIso8601String().replaceFirst('.000Z', 'Z');

String _stableDigest(String value) {
  var first = 0x811c9dc5;
  var second = 0x9e3779b9;
  for (final byte in utf8.encode(value)) {
    first = ((first ^ byte) * 0x01000193) & 0xffffffff;
    second = ((second + byte) * 0x85ebca6b) & 0xffffffff;
    second ^= second >> 13;
  }
  return first.toRadixString(16).padLeft(8, '0') +
      second.toRadixString(16).padLeft(8, '0');
}
