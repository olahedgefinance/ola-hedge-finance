import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../tool/compliance/release_compliance.dart';
import '../../tool/compliance/generate_sbom.dart';

void main() {
  final root = Directory.current.parent;
  test('mixed BSD and Apache notice is not collapsed to Apache', () {
    expect(
        classifyLicenseText(
            'Redistribution and use in source and binary forms. Neither the name. Apache License Version 2.0'),
        'NOASSERTION');
  });
  test('mixed MPL versions remain unresolved', () {
    expect(
        classifyLicenseText(
            'Mozilla Public License Version 2.0 and Mozilla Public License Version 1.1'),
        'NOASSERTION');
  });
  test('an actually cleared inventory can have no unresolved gaps', () {
    expect(
        validateInventoryContract(<String, dynamic>{
          'schemaVersion': 1,
          'summary': {'components': 1},
          'components': [
            {
              'id': 'app:example',
              'relationship': 'root',
              'licenseDeclared': 'GPL-3.0-or-later',
              'reviewStatus': 'verified',
              'distributed': true
            }
          ],
          'auditGaps': []
        }),
        isEmpty);
  });
  test('conditional declaration is not an SPDX concluded licence', () async {
    final b = await createComplianceArtifactBundle(repositoryRoot: root);
    final spdx = jsonDecode(b.files['compliance/sbom/current.spdx.json']!)
        as Map<String, dynamic>;
    final p =
        (spdx['packages'] as List).singleWhere((p) => p['name'] == 'crypto');
    expect(p['licenseConcluded'], 'NOASSERTION');
  });
  test('mutable cache cannot change retained dependency metadata', () async {
    final configFile =
        File('${root.path}/budget/.dart_tool/package_config.json');
    final original = configFile.readAsBytesSync();
    final config = jsonDecode(utf8.decode(original)) as Map<String, dynamic>;
    final entry =
        (config['packages'] as List).singleWhere((p) => p['name'] == 'crypto');
    final temp = Directory.systemTemp.createTempSync('ola-cache-drift-');
    addTearDown(() => temp.deleteSync(recursive: true));
    final old = Directory.fromUri(
        configFile.parent.uri.resolve(entry['rootUri'] as String));
    for (final name in ['pubspec.yaml', 'LICENSE']) {
      File('${old.path}/$name').copySync('${temp.path}/$name');
    }
    final spec = File('${temp.path}/pubspec.yaml');
    spec.writeAsStringSync(
        spec.readAsStringSync().replaceAll('typed_data:', 'fake_dependency:'));
    // The clone, never the shared cache, is modified; config restored in finally.
    entry['rootUri'] = temp.uri.toString();
    final before = await createComplianceArtifactBundle(repositoryRoot: root);
    try {
      configFile.writeAsStringSync(jsonEncode(config));
      final after = await createComplianceArtifactBundle(repositoryRoot: root);
      expect(after.files, before.files);
    } finally {
      configFile.writeAsBytesSync(original);
    }
  });
}
