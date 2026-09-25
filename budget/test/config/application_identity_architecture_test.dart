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

  group('iOS application identity', () {
    final project = _read('ios/Runner.xcodeproj/project.pbxproj');
    final podfile = _read('ios/Podfile');
    final infoPlist = _read('ios/Runner/Info.plist');
    final entitlements = _read('ios/Runner/Runner.entitlements');

    const environments = <String, String>{
      'development': 'com.olahedgefinance.app.dev',
      'staging': 'com.olahedgefinance.app.staging',
      'production': 'com.olahedgefinance.app',
    };

    test('defines all environment build configurations and bundle IDs', () {
      for (final entry in environments.entries) {
        for (final mode in <String>['Debug', 'Profile', 'Release']) {
          final configuration = '$mode-${entry.key}';
          expect(
            RegExp('name = ${RegExp.escape(configuration)};')
                .allMatches(project)
                .length,
            3,
            reason: configuration,
          );
        }
        expect(
          RegExp(
            'PRODUCT_BUNDLE_IDENTIFIER = "?${RegExp.escape(entry.value)}"?;',
          ).allMatches(project).length,
          3,
          reason: '${entry.key} Runner bundle ID',
        );
        expect(
          RegExp(
            'PRODUCT_BUNDLE_IDENTIFIER = "?${RegExp.escape(entry.value)}\\.RunnerTests"?;',
          ).allMatches(project).length,
          3,
          reason: '${entry.key} RunnerTests bundle ID',
        );
      }

      expect(project, isNot(contains('com.budget.tracker-app')));
      expect(project, isNot(contains('com.budget.budget.RunnerTests')));
      expect(project, isNot(contains('HCL9V2D3XY')));
      expect(project, isNot(contains('DEVELOPMENT_TEAM =')));
    });

    test('maps CocoaPods to every custom build configuration', () {
      for (final environment in environments.keys) {
        expect(podfile, contains("'Debug-$environment' => :debug"));
        expect(podfile, contains("'Profile-$environment' => :release"));
        expect(podfile, contains("'Release-$environment' => :release"));
      }
    });

    test('maps each shared scheme to its environment configurations', () {
      for (final environment in environments.keys) {
        final path =
            'ios/Runner.xcodeproj/xcshareddata/xcschemes/$environment.xcscheme';
        expect(File(path).existsSync(), isTrue, reason: path);
        if (!File(path).existsSync()) continue;

        final scheme = _read(path);
        expect(
          RegExp(
            'TestAction\\s+buildConfiguration = "Debug-$environment"',
          ).hasMatch(scheme),
          isTrue,
        );
        expect(
          RegExp(
            'LaunchAction\\s+buildConfiguration = "Debug-$environment"',
          ).hasMatch(scheme),
          isTrue,
        );
        expect(
          RegExp(
            'ProfileAction\\s+buildConfiguration = "Profile-$environment"',
          ).hasMatch(scheme),
          isTrue,
        );
        expect(
          RegExp(
            'AnalyzeAction\\s+buildConfiguration = "Debug-$environment"',
          ).hasMatch(scheme),
          isTrue,
        );
        expect(
          RegExp(
            'ArchiveAction\\s+buildConfiguration = "Release-$environment"',
          ).hasMatch(scheme),
          isTrue,
        );
        expect(scheme, contains('BlueprintName = "Runner"'));
        expect(scheme, contains('BlueprintName = "RunnerTests"'));
      }
    });

    test('keeps unregistered Apple and Firebase capabilities absent', () {
      expect(
        RegExp(
          r'<key>CFBundleName</key>\s*<string>ÓLA HEDGE</string>',
        ).hasMatch(infoPlist),
        isTrue,
      );
      expect(infoPlist, isNot(contains('CFBundleURLTypes')));
      expect(entitlements, isNot(contains('com.apple.developer.associated-domains')));
      expect(
        File('ios/Runner/GoogleService-Info.plist').existsSync(),
        isFalse,
      );
    });
  });
}
