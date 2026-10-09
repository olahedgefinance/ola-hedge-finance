import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/compliance/generate_sbom.dart';

void main() {
  final root = Directory.current.parent;
  String licence(String package) => File('${root.path}/compliance/evidence/'
          'reconstruction-2026-10-09/pub/$package/LICENSE')
      .readAsStringSync();

  for (final package in ['dbus', 'gtk']) {
    test('$package full MPL 2.0 text is not confused by internal references',
        () {
      expect(classifyLicenseText(licence(package)), 'MPL-2.0');
    });
  }

  test('standard MPL text tolerates whitespace and the official HTTPS URL', () {
    final text = licence('dbus');
    expect(classifyLicenseText(text.replaceAll('\n', '\r\n')), 'MPL-2.0');
    expect(classifyLicenseText('  ${text.replaceAll(RegExp(r'\s+'), '\t ')}\n'),
        'MPL-2.0');
    expect(
        classifyLicenseText(text.replaceAll(
            'http://mozilla.org/MPL/2.0/', 'https://mozilla.org/MPL/2.0/')),
        'MPL-2.0');
  });

  test(
      'MPL heading, truncation, changed terms and appended grants stay unresolved',
      () {
    final text = licence('dbus');
    for (final unsupported in [
      'Mozilla Public License Version 2.0',
      'Mozilla Public License Version 1.1',
      text.substring(0, text.indexOf('2. License Grants')),
      text.replaceFirst('royalty-free', 'royalty-bearing'),
      '$text\nAdditional restriction: commercial use prohibited.',
      '$text\nGNU General Public License Version 3',
      '$text\nMozilla Public License Version 1.1',
      '$text\nPermission is hereby granted, free of charge',
      'Apache License Version 2.0\n$text',
      '$text\n$text',
      'custom terms pending review',
      '',
    ]) {
      expect(classifyLicenseText(unsupported), 'NOASSERTION');
    }
  });

  test('existing non-MPL licence families retain their classifications', () {
    const cases = <String, String>{
      'Permission is hereby granted, free of charge': 'MIT',
      'Apache License Version 2.0': 'Apache-2.0',
      'Redistribution and use in source and binary forms': 'BSD-2-Clause',
      'Redistribution and use in source and binary forms. Neither the name':
          'BSD-3-Clause',
      'permission to use, copy, modify, and/or distribute this software for any purpose with or without fee':
          'ISC',
      'GNU General Public License Version 3': 'GPL-3.0-only',
      "This software is provided 'as-is'. Altered source versions must be plainly marked":
          'Zlib',
    };
    for (final entry in cases.entries) {
      expect(classifyLicenseText(entry.key), entry.value);
    }
  });

  test('retained composite notice sets are not flattened by MPL recognition',
      () {
    final manifest = jsonDecode(File('${root.path}/compliance/evidence/'
            'reconstruction-2026-10-09/pub/manifest.json')
        .readAsStringSync());
    for (final package in [
      'flutter_charset_detector',
      'flutter_charset_detector_android',
      'flutter_charset_detector_ios',
      'flutter_charset_detector_platform_interface',
      'image_picker',
      'image_picker_android',
      'image_picker_ios',
      'sky_engine',
      'universal_html',
      'url_launcher_web',
      'vector_math',
    ]) {
      final record = (manifest['records'] as List)
          .singleWhere((r) => r['id'] == 'pub:$package');
      final text = (record['files'] as List)
          .map((f) => File('${root.path}/${f['path']}').readAsStringSync())
          .join('\n');
      expect(classifyLicenseText(text), 'NOASSERTION', reason: package);
    }
  });

  test(
      'generator records exact-version MPL declarations without legal clearance',
      () async {
    final bundle = await createComplianceArtifactBundle(repositoryRoot: root);
    final spdx = jsonDecode(bundle.files['compliance/sbom/current.spdx.json']!);
    for (final entry in {'dbus': '0.7.8', 'gtk': '2.1.0'}.entries) {
      final component =
          bundle.components.singleWhere((c) => c.id == 'pub:${entry.key}');
      expect(component.version, entry.value);
      expect(component.licenseDeclared, 'MPL-2.0');
      expect(component.reviewStatus, 'verified-with-conditions');
      final package =
          (spdx['packages'] as List).singleWhere((p) => p['name'] == entry.key);
      expect(package['licenseConcluded'], 'NOASSERTION');
    }
  });
}
