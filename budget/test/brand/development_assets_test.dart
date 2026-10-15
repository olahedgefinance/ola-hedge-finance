import 'dart:convert';
import 'dart:io';
import 'package:budget/brand/development_brand.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'development UI resolves actual DEV bytes without rewriting historical assets',
      () async {
    final overlay = DevelopmentBrandAssetBundle(rootBundle);
    for (final entry in DevelopmentBrandAssetBundle.aliases.entries) {
      final loaded = await overlay.load(entry.key);
      final expected = File(entry.value).readAsBytesSync();
      expect(
          loaded.buffer.asUint8List(loaded.offsetInBytes, loaded.lengthInBytes),
          expected);
      expect(File(entry.key).readAsBytesSync(), isNot(expected));
    }
    final ordinary = await overlay.load('assets/static/language-names.json');
    expect(ordinary.lengthInBytes, greaterThan(0));
  });
  test('current development manifest and active PWA use compact brand', () {
    final evidence =
        jsonDecode(File('brand/development_assets.json').readAsStringSync());
    final web =
        jsonDecode(File('web/branding/dev/manifest.json').readAsStringSync());
    expect(evidence['shortName'], developmentBrand.shortName);
    expect(web['short_name'], developmentBrand.shortName);
    expect(File('web/index.html').readAsStringSync(),
        contains('branding/dev/manifest.json'));
    expect(evidence['status'], 'DEV ONLY / NOT RELEASE CLEARED');
  });
}
