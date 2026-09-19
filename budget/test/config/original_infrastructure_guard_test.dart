import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _normalizedPath(File file) => file.path.replaceAll('\\', '/');

void main() {
  test('active sources contain no original Cashew service identity', () {
    final roots = [
      Directory('lib'),
      Directory('android'),
      Directory('ios'),
      Directory('web'),
    ];
    final files = <File>[
      for (final root in roots)
        ...root.listSync(recursive: true).whereType<File>().where((file) {
          final path = _normalizedPath(file);
          const textExtensions = {
            '.dart',
            '.xml',
            '.gradle',
            '.properties',
            '.plist',
            '.entitlements',
            '.pbxproj',
            '.html',
            '.json',
            '.js',
            '.yaml',
            '.yml',
            '.kt',
            '.java'
          };
          return !path.contains('/build/') &&
              !path.contains('/Pods/') &&
              textExtensions.any(path.endsWith);
        }),
      if (File('.firebaserc').existsSync()) File('.firebaserc'),
      if (File('firebase.json').existsSync()) File('firebase.json'),
    ];

    const forbidden = <String, String>{
      'budget-app-flutter': 'upstream Firebase project',
      'cashewapp.web.app': 'upstream app-link host',
      'budget-track.web.app': 'upstream hosting URL',
      'cashew.pro.': 'upstream store product',
      'ko-fi.com/dapperappdeveloper': 'upstream donation identity',
      'dapperappdeveloper@gmail.com': 'upstream support identity',
      'folderName = "Cashew"': 'upstream Drive folder',
      '267621253497': 'upstream Google/Firebase numeric identity',
      'com.budget.tracker_app': 'temporary Android application ID',
      'com.budget.tracker-app': 'temporary iOS bundle ID',
    };
    final violations = <String>[];

    for (final file in files) {
      final path = _normalizedPath(file);
      final contents = file.readAsStringSync();
      for (final entry in forbidden.entries) {
        final temporaryAndroidId = entry.key == 'com.budget.tracker_app' &&
            path.startsWith('android/app/');
        final temporaryIosId = entry.key == 'com.budget.tracker-app' &&
            path.endsWith('ios/Runner.xcodeproj/project.pbxproj');
        if (contents.contains(entry.key) &&
            !temporaryAndroidId &&
            !temporaryIosId) {
          violations.add('$path: ${entry.value}');
        }
      }
    }

    expect(violations, isEmpty);
  });

  test('superseded product names are absent from active product metadata', () {
    const bannedNames = ['OLA Edge Finance', 'Ola Edge', 'OLA Finance'];
    final files = [
      File('lib/brand/brand_identity.dart'),
      File('brand/brand_manifest.json'),
      File('android/app/src/main/AndroidManifest.xml'),
      File('ios/Runner/Info.plist'),
      File('web/manifest.json'),
      File('web/index.html'),
    ];
    final violations = <String>[];
    for (final file in files) {
      final contents = file.readAsStringSync();
      for (final bannedName in bannedNames) {
        if (contents.contains(bannedName)) {
          violations.add('${_normalizedPath(file)}: $bannedName');
        }
      }
    }

    expect(violations, isEmpty);
  });

  test('Firebase integration never falls back to anonymous authentication', () {
    final firebaseAuth =
        File('lib/struct/firebaseAuthGlobal.dart').readAsStringSync();
    final feedback = File('lib/widgets/ratingPopup.dart').readAsStringSync();

    expect(firebaseAuth, isNot(contains('signInAnonymously')));
    expect(firebaseAuth, contains('identityOnly: true'));
    expect(feedback, isNot(contains('firebaseGetDBInstanceAnonymous')));
  });

  test('background lifecycle gates Drive and Gmail independently', () {
    final navigation =
        File('lib/widgets/navigationFramework.dart').readAsStringSync();

    expect(navigation, contains('canUseGoogleDrive'));
    expect(navigation, contains('canUseGmail'));
  });
}
