import 'dart:convert';
import 'dart:io';

import 'package:budget/brand/brand_identity.dart';
import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

String _normalizedPath(File file) => file.path.replaceAll('\\', '/');

bool _isAllowedCashewReference(String path, String line) {
  if (path.endsWith('lib/main.dart') && line.contains('CashewAppMain')) {
    return true;
  }
  if (path.endsWith('lib/widgets/showChangelog.dart')) {
    return true;
  }
  if (path.endsWith('lib/pages/premiumPage.dart') &&
      line.contains('CashewProBanner')) {
    return true;
  }
  if (path.endsWith('lib/struct/uploadAttachment.dart') &&
      line.contains('folderName = "Cashew"')) {
    return true;
  }
  if (path.endsWith('lib/widgets/util/appLinks.dart') &&
      line.contains('Cashew website')) {
    return true;
  }
  if (line.contains('github.com/jameskokoska/Cashew')) {
    return true;
  }
  if ((path.endsWith('assets/translations/translations.csv') ||
          path.contains('assets/translations/generated/')) &&
      line.contains('import-warning-description')) {
    return true;
  }
  return false;
}

List<String> _unexpectedCashewReferences() {
  final files = <File>[
    ...Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart')),
    File('assets/translations/translations.csv'),
    ...Directory('assets/translations/generated')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json')),
    File('android/app/src/main/AndroidManifest.xml'),
    File('ios/Runner/Info.plist'),
    File('ios/Runner.xcodeproj/project.pbxproj'),
    File('web/manifest.json'),
    File('web/index.html'),
  ];
  final unexpected = <String>[];

  for (final file in files) {
    final path = _normalizedPath(file);
    final lines = file.readAsLinesSync();
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (line.contains('Cashew') && !_isAllowedCashewReference(path, line)) {
        unexpected.add('$path:${index + 1}: ${line.trim()}');
      }
    }
  }
  return unexpected;
}

void main() {
  final Map<String, dynamic> manifest = jsonDecode(
    _read('brand/brand_manifest.json'),
  ) as Map<String, dynamic>;

  test('brand manifest matches the typed Flutter identity', () {
    expect(manifest['schemaVersion'], 1);
    expect(manifest['brandKey'], 'ola-edge-finance');
    expect(manifest['productName'], appBrand.productName);
    expect(manifest['shortName'], appBrand.shortName);
    expect(manifest['description'], appBrand.description);

    final license = manifest['license'] as Map<String, dynamic>;
    expect(license['spdx'], 'GPL-3.0-or-later');
    expect(license['upstreamProduct'], 'Cashew');
    expect(
      license['upstreamRepository'],
      'https://github.com/jameskokoska/Cashew',
    );
  });

  test('Android display metadata uses the approved product name', () {
    final androidManifest = _read('android/app/src/main/AndroidManifest.xml');
    expect(androidManifest, contains('android:label="OLA Edge Finance"'));
  });

  test('iOS display metadata uses the approved product name', () {
    final iosPlist = _read('ios/Runner/Info.plist');
    final iosProject = _read('ios/Runner.xcodeproj/project.pbxproj');

    expect(
      RegExp(
        r'<key>CFBundleDisplayName</key>\s*<string>OLA Edge Finance</string>',
      ).hasMatch(iosPlist),
      isTrue,
    );
    expect(
      iosPlist,
      contains(
        'OLA Edge Finance uses photos to attach to a transaction entry',
      ),
    );
    expect(
      iosPlist,
      contains(
        'OLA Edge Finance uses the camera to capture a photo to be used as a transaction attachment',
      ),
    );
    expect(
      RegExp('INFOPLIST_KEY_CFBundleDisplayName = OLA Edge Finance;')
          .allMatches(iosProject)
          .length,
      3,
    );
  });

  test('web display metadata uses the approved product name', () {
    final webManifest = jsonDecode(_read('web/manifest.json'))
        as Map<String, dynamic>;
    final webIndex = _read('web/index.html');

    expect(webManifest['name'], appBrand.productName);
    expect(webManifest['short_name'], appBrand.shortName);
    expect(webManifest['description'], appBrand.description);
    expect(webIndex, contains('<title>OLA Edge Finance</title>'));
    expect(
      webIndex,
      contains('<meta name="apple-mobile-web-app-title" content="OLA Edge Finance">'),
    );
    expect(
      RegExp('content="OLA Edge Finance"').allMatches(webIndex).length,
      greaterThanOrEqualTo(3),
    );
    expect(
      RegExp(RegExp.escape(appBrand.description)).allMatches(webIndex).length,
      greaterThanOrEqualTo(3),
    );
  });

  test('protected compatibility identifiers remain unchanged', () {
    final androidGradle = _read('android/app/build.gradle');
    final androidManifest = _read('android/app/src/main/AndroidManifest.xml');
    final iosProject = _read('ios/Runner.xcodeproj/project.pbxproj');
    final iosEntitlements = _read('ios/Runner/Runner.entitlements');
    final firebaseOptions = _read('lib/firebase_options.dart');
    final databaseSource = _read('lib/database/tables.dart');
    final premiumSource = _read('lib/pages/premiumPage.dart');
    final uploadSource = _read('lib/struct/uploadAttachment.dart');
    final license = _read('../LICENSE');

    expect(
      androidGradle,
      contains('applicationId "com.budget.tracker_app"'),
    );
    expect(androidManifest, contains('package="com.budget.tracker_app"'));
    expect(androidManifest, contains('android:host="cashewapp.web.app"'));
    expect(
      iosProject,
      contains('PRODUCT_BUNDLE_IDENTIFIER = "com.budget.tracker-app"'),
    );
    expect(iosEntitlements, contains('applinks:cashewapp.web.app'));
    expect(firebaseOptions, contains("projectId: 'budget-app-flutter'"));
    expect(databaseSource, contains('schemaVersionGlobal = 47'));
    expect(premiumSource, contains("'cashew.pro.monthly'"));
    expect(uploadSource, contains('String folderName = "Cashew"'));
    expect(license, contains('GNU GENERAL PUBLIC LICENSE'));
    expect(license, contains('Cashew: an expense budget tracking application'));
    expect(
      _read('lib/pages/aboutPage.dart'),
      contains('https://github.com/jameskokoska/Cashew'),
    );
  });

  test('Cashew references are limited to approved compatibility contexts', () {
    expect(
      _unexpectedCashewReferences(),
      isEmpty,
      reason: 'Unexpected current-product Cashew references were found.',
    );
  });
}
