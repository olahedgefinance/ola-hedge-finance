import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/compliance/generate_sbom.dart';

void main() {
  final repositoryRoot = Directory.current.parent;

  test('real repository inputs produce a complete evidence-based bundle',
      () async {
    final bundle = await createComplianceArtifactBundle(
      repositoryRoot: repositoryRoot,
    );
    final byId = <String, ComplianceComponent>{
      for (final component in bundle.components) component.id: component,
    };

    expect(bundle.components.length, greaterThan(300));
    expect(byId['application:ola-hedge-finance']!.licenseDeclared,
        'GPL-3.0-or-later');
    expect(byId['pub:firebase_auth']!.licenseDeclared, isNot('NOASSERTION'));
    expect(
        byId['pub:firebase_auth']!.sourceRepository, contains('flutterfire'));
    expect(byId['pub:file_picker']!.modified, isTrue);
    expect(byId['pub:file_picker']!.downloadLocation,
        contains('flutter_file_picker.git'));
    expect(byId['cocoapods:Firebase']!.licenseDeclared, 'Apache-2.0');
    expect(
        byId['cocoapods:Firebase']!.reviewStatus, 'verified-with-conditions');
    expect(byId['cocoapods:Firebase']!.licenseEvidence,
        contains('cocoapods-source-2026-10-09/manifest.json#Firebase'));
    expect(byId['font:Avenir']!.reviewStatus, 'review-required');
    expect(byId['web:sql-wasm.js']!.checksumSha256,
        '445a230a983e32656a548b1e13cceafaf4aeb2281361477af389243380e2f542');

    final directProduction = bundle.components.where((component) =>
        component.relationship == ComponentRelationship.directRuntime);
    final manifest = jsonDecode(File(
            '${repositoryRoot.path}/compliance/components/non_pub_components.json')
        .readAsStringSync());
    final graph = jsonDecode(File(
            '${repositoryRoot.path}/compliance/evidence/reconstruction-2026-10-09/android-graph-2026-10-11/resolved-graph.json')
        .readAsStringSync());
    final expectedDirect = <String>{
      ...parsePubLock(File('${repositoryRoot.path}/budget/pubspec.lock')
              .readAsStringSync())
          .where((p) => p.relationship == ComponentRelationship.directRuntime)
          .map((p) => 'pub:${p.name}'),
      ...(manifest['components'] as List)
          .where(
              (c) => c['relationship'] == ComponentRelationship.directRuntime)
          .map((c) => c['id'] as String),
      for (final config in graph['configurations'] as List)
        for (final node in config['components'] as List)
          if (node['id'] == 'project :app')
            for (final dep in node['dependencies'] as List)
              if (dep['constraint'] == false &&
                  !(dep['selected'] as String).startsWith('project :'))
                'maven:${(dep['selected'] as String).split(':').take(2).join(':')}',
    };
    expect(directProduction.map((c) => c.id), unorderedEquals(expectedDirect));
    for (final component in directProduction) {
      expect(component.licenseDeclared, isNotEmpty, reason: component.id);
      if (component.licenseDeclared == 'NOASSERTION') {
        expect(component.reviewStatus, 'review-required', reason: component.id);
        expect(component.licenseEvidence, isNotEmpty, reason: component.id);
      }
    }

    expect(
        bundle.files.keys,
        containsAll(<String>[
          'compliance/OPEN_SOURCE_COMPONENTS.md',
          'compliance/inventory/current-components.json',
          'compliance/reports/current-components.md',
          'compliance/sbom/current.spdx.json',
        ]));
    for (final content in bundle.files.values) {
      expect(content, isNot(contains(repositoryRoot.path)));
      expect(content.endsWith('\n'), isTrue);
    }

    final inventory = jsonDecode(
            bundle.files['compliance/inventory/current-components.json']!)
        as Map<String, dynamic>;
    expect(inventory['schemaVersion'], 1);
    expect((inventory['summary'] as Map<String, dynamic>)['components'],
        bundle.components.length);
    expect(inventory['auditGaps'], isNotEmpty);

    final spdx = jsonDecode(bundle.files['compliance/sbom/current.spdx.json']!)
        as Map<String, dynamic>;
    expect(spdx['spdxVersion'], 'SPDX-2.3');
    expect(
        (spdx['packages'] as List<dynamic>).length, bundle.components.length);
  });

  test('release generation produces canonical and bundle evidence paths',
      () async {
    final bundle = await createComplianceArtifactBundle(
      repositoryRoot: repositoryRoot,
    );

    final files = versionedArtifactFiles(bundle, '5.4.3+416');

    expect(
        files.keys,
        containsAll(<String>[
          'compliance/sbom/5.4.3+416.spdx.json',
          'compliance/releases/5.4.3+416/sbom.spdx.json',
          'compliance/releases/5.4.3+416/dependency-licence-report.md',
        ]));
    expect(files['compliance/releases/5.4.3+416/sbom.spdx.json'],
        bundle.files['compliance/sbom/current.spdx.json']);
  });

  test('generation is byte-for-byte stable for unchanged inputs', () async {
    final first = await createComplianceArtifactBundle(
      repositoryRoot: repositoryRoot,
    );
    final second = await createComplianceArtifactBundle(
      repositoryRoot: repositoryRoot,
    );

    expect(second.files, first.files);
  });

  test('stale artifact detection reports missing and changed paths', () {
    final stale = findStaleArtifactPaths(
      <String, String>{
        'same.json': 'same\n',
        'changed.json': 'expected\n',
        'missing.json': 'expected\n',
      },
      <String, String?>{
        'same.json': 'same\n',
        'changed.json': 'actual\n',
        'missing.json': null,
      },
    );

    expect(stale, <String>['changed.json', 'missing.json']);
  });

  test('generated text accepts Windows line endings but not changed evidence', () {
    expect(findStaleArtifactPaths(
      {'a': 'one\ntwo\n', 'b': 'one\r\ntwo\r\n', 'c': 'one\ntwo\r\n'},
      {'a': 'one\r\ntwo\r\n', 'b': 'one\ntwo\n', 'c': 'one\r\ntwo\n'},
    ), isEmpty);
    expect(findStaleArtifactPaths(
      {'a': 'one\ntwo\n', 'b': 'one\n', 'c': 'one\n', 'd': 'one\n'},
      {'a': 'one\r\nchanged\r\n', 'b': 'one \r\n', 'c': 'one', 'd': null},
    ), ['a', 'b', 'c', 'd']);
  });

  test('Cashew provenance records ownership boundaries without reassignment',
      () async {
    final bundle = await createComplianceArtifactBundle(
      repositoryRoot: repositoryRoot,
    );
    final provenance = bundle.provenance;

    expect(provenance['upstreamProject'], 'Cashew');
    expect(provenance['upstreamRepository'],
        'https://github.com/jameskokoska/Cashew');
    expect(provenance['upstreamLicense'], 'GPL-3.0-or-later');
    expect(provenance['historyRetained'], isTrue);
    expect(provenance['tagsRetained'], isTrue);
    expect(provenance['upstreamPushDisabled'], isTrue);
    expect(provenance['olaRepository'],
        'https://github.com/olahedgefinance/ola-hedge-finance');
    expect(provenance['ownershipBoundary'], contains('modifications'));
    expect(provenance['claimsOriginalCashewOwnership'], isFalse);
  });
}
