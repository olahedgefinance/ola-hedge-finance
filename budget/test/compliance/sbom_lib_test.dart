import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/compliance/sbom_lib.dart';

void main() {
  group('Pub lock parsing', () {
    test('preserves directness and locked hosted, git, and path evidence', () {
      const lock = '''
packages:
  hosted_pkg:
    dependency: "direct main"
    description:
      name: hosted_pkg
      sha256: abc123
      url: "https://pub.dev"
    source: hosted
    version: "1.2.3"
  git_pkg:
    dependency: transitive
    description:
      path: packages/git_pkg
      ref: main
      resolved-ref: deadbeef
      url: "https://example.test/repository.git"
    source: git
    version: "2.0.0"
  local_pkg:
    dependency: "direct main"
    description:
      path: packages/local_pkg
      relative: true
    source: path
    version: "3.0.0"
sdks:
  dart: ">=3.3.0 <4.0.0"
''';

      final entries = parsePubLock(lock);
      final byName = <String, PubLockEntry>{
        for (final entry in entries) entry.name: entry,
      };

      expect(entries, hasLength(3));
      expect(byName['hosted_pkg']!.relationship,
          ComponentRelationship.directRuntime);
      expect(byName['hosted_pkg']!.source, 'hosted');
      expect(byName['hosted_pkg']!.checksumSha256, 'abc123');
      expect(byName['git_pkg']!.relationship, ComponentRelationship.transitive);
      expect(
          byName['git_pkg']!.sourceUrl, 'https://example.test/repository.git');
      expect(byName['git_pkg']!.resolvedRevision, 'deadbeef');
      expect(byName['git_pkg']!.sourcePath, 'packages/git_pkg');
      expect(byName['local_pkg']!.source, 'path');
      expect(byName['local_pkg']!.sourcePath, 'packages/local_pkg');
    });
  });

  group('licence evidence classification', () {
    test('recognizes exact common templates and refuses unknown text', () {
      expect(
        classifyLicenseText(
          'MIT License\nPermission is hereby granted, free of charge, to any person obtaining a copy',
        ),
        'MIT',
      );
      expect(
        classifyLicenseText(
          'Redistribution and use in source and binary forms, with or without modification, are permitted. '
          'Neither the name of Example nor the names of its contributors may be used.',
        ),
        'BSD-3-Clause',
      );
      expect(
        classifyLicenseText('Apache License\nVersion 2.0, January 2004'),
        'Apache-2.0',
      );
      expect(classifyLicenseText('custom terms pending review'), 'NOASSERTION');
      expect(classifyLicenseText(''), 'NOASSERTION');
    });
  });

  group('CocoaPods lock parsing', () {
    test('collapses subspec rows to one versioned component per spec checksum',
        () {
      const lock = '''
PODS:
  - Firebase/Auth (10.29.0):
    - Firebase/CoreOnly
  - Firebase/CoreOnly (10.29.0)
  - GoogleUtilities/Environment (7.13.3)
DEPENDENCIES:
  - Firebase/Auth
SPEC CHECKSUMS:
  Firebase: 1234
  GoogleUtilities: 5678
PODFILE CHECKSUM: abcd
COCOAPODS: 1.15.2
''';

      final pods = parsePodfileLock(lock);

      expect(pods, hasLength(2));
      expect(pods[0].name, 'Firebase');
      expect(pods[0].version, '10.29.0');
      expect(pods[0].specChecksum, '1234');
      expect(pods[1].name, 'GoogleUtilities');
      expect(pods[1].version, '7.13.3');
    });
  });

  group('SPDX output', () {
    test('is deterministic, sorted, and keeps missing evidence explicit', () {
      final components = <ComplianceComponent>[
        const ComplianceComponent(
          id: 'pub:zeta',
          name: 'zeta',
          version: '2.0.0',
          ecosystem: 'pub',
          relationship: ComponentRelationship.transitive,
          source: 'hosted',
          downloadLocation: 'https://pub.dev/packages/zeta',
          licenseDeclared: 'NOASSERTION',
          licenseEvidence: 'No licence file was resolved.',
          distributed: true,
          modified: false,
          reviewStatus: 'review-required',
          dependencies: <String>[],
        ),
        const ComplianceComponent(
          id: 'application:ola-hedge-finance',
          name: 'ola-hedge-finance',
          version: '5.4.3+416',
          ecosystem: 'application',
          relationship: ComponentRelationship.root,
          source: 'git',
          downloadLocation:
              'https://github.com/olahedgefinance/ola-hedge-finance',
          licenseDeclared: 'GPL-3.0-or-later',
          licenseEvidence: 'LICENSE',
          distributed: true,
          modified: true,
          reviewStatus: 'verified',
          dependencies: <String>['pub:zeta'],
        ),
      ];

      final first = encodeCanonicalJson(buildSpdxDocument(
        components: components,
        documentName: 'ola-hedge-finance-5.4.3+416',
        createdUtc: DateTime.utc(2026, 9, 25),
      ));
      final second = encodeCanonicalJson(buildSpdxDocument(
        components: components.reversed.toList(),
        documentName: 'ola-hedge-finance-5.4.3+416',
        createdUtc: DateTime.utc(2026, 9, 25),
      ));

      expect(second, first);
      final decoded = jsonDecode(first) as Map<String, dynamic>;
      expect(decoded['spdxVersion'], 'SPDX-2.3');
      expect(decoded['dataLicense'], 'CC0-1.0');
      final packages = decoded['packages'] as List<dynamic>;
      expect(
          (packages[0] as Map<String, dynamic>)['name'], 'ola-hedge-finance');
      expect((packages[1] as Map<String, dynamic>)['name'], 'zeta');
      expect((packages[1] as Map<String, dynamic>)['licenseDeclared'],
          'NOASSERTION');
      expect(
          decoded['documentNamespace'],
          startsWith(
              'https://github.com/olahedgefinance/ola-hedge-finance/sbom/'));
      expect(first.endsWith('\n'), isTrue);
    });
  });
}
