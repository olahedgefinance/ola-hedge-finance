import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  group('Android application identity', () {
    final gradle = _read('android/app/build.gradle');

    test('derives exact environment IDs from one canonical namespace', () {
      expect(
        RegExp(r'''namespace\s+["']com\.olahedgefinance\.app["']''')
            .hasMatch(gradle),
        isTrue,
      );
      expect(
        RegExp(r'''applicationId\s+["']com\.olahedgefinance\.app["']''')
            .allMatches(gradle)
            .length,
        1,
      );
      expect(gradle, contains('flavorDimensions "environment"'));

      expect(
        gradle,
        contains(RegExp(
          r'''development\s*\{[^}]*dimension\s+["']environment["'][^}]*applicationIdSuffix\s+["']\.dev["']''',
          dotAll: true,
        )),
      );
      expect(
        gradle,
        contains(RegExp(
          r'''staging\s*\{[^}]*dimension\s+["']environment["'][^}]*applicationIdSuffix\s+["']\.staging["']''',
          dotAll: true,
        )),
      );
      expect(
        gradle,
        contains(RegExp(
          r'''production\s*\{[^}]*dimension\s+["']environment["'][^}]*\}''',
          dotAll: true,
        )),
      );
      expect(
        RegExp(r'''applicationIdSuffix\s+["']\.dev["']''')
            .allMatches(gradle)
            .length,
        1,
      );
      expect(
        RegExp(r'''applicationIdSuffix\s+["']\.staging["']''')
            .allMatches(gradle)
            .length,
        1,
      );
      expect(gradle, isNot(contains('.production')));
    });

    test('keeps native Firebase configuration optional per source set', () {
      expect(gradle, contains("file('google-services.json')"));
      expect(
        gradle,
        contains("file('src/development/google-services.json')"),
      );
      expect(
        gradle,
        contains("file('src/staging/google-services.json')"),
      );
      expect(
        gradle,
        contains("file('src/production/google-services.json')"),
      );
      expect(gradle, contains('googleServicesFiles.any { it.exists() }'));
    });

    test('uses the namespace rather than manifest package attributes', () {
      for (final path in <String>[
        'android/app/src/main/AndroidManifest.xml',
        'android/app/src/debug/AndroidManifest.xml',
        'android/app/src/profile/AndroidManifest.xml',
      ]) {
        expect(_read(path), isNot(contains('package=')), reason: path);
      }
    });

    test('owns every Kotlin component under the canonical package path', () {
      const files = <String>[
        'MainActivity.kt',
        'PlusWidgetProvider.kt',
        'TransferWidgetProvider.kt',
        'NetWorthWidgetProvider.kt',
        'NetWorthPlusWidgetProvider.kt',
      ];

      for (final name in files) {
        final path = 'android/app/src/main/kotlin/com/olahedgefinance/app/$name';
        expect(File(path).existsSync(), isTrue, reason: path);
        if (File(path).existsSync()) {
          expect(
            _read(path),
            startsWith('package com.olahedgefinance.app'),
            reason: path,
          );
        }
      }

      final oldDirectory =
          Directory('android/app/src/main/kotlin/com/example/budget');
      expect(
        oldDirectory.existsSync()
            ? oldDirectory.listSync().whereType<File>().where(
                  (file) => file.path.endsWith('.kt'),
                ).isEmpty
            : true,
        isTrue,
      );
      expect(gradle, isNot(contains('com.budget.tracker_app')));
    });
  });
}
