import 'dart:convert';
import 'dart:io';

import 'package:budget/brand/brand_identity.dart';
import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

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
}
