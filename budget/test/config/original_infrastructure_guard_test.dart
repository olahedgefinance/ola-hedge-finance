import 'dart:convert';
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
      Directory('../.github'),
      Directory('../scripts'),
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
            '.bat',
            '.ps1',
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
      'FIREBASE_SERVICE_ACCOUNT_BUDGET_APP_FLUTTER':
          'upstream Firebase service-account secret',
      'com.budget.tracker_app': 'temporary Android application ID',
      'com.budget.tracker-app': 'temporary iOS bundle ID',
    };
    final violations = <String>[];

    for (final file in files) {
      final path = _normalizedPath(file);
      final contents = file.readAsStringSync();
      for (final entry in forbidden.entries) {
        if (contents.contains(entry.key)) {
          violations.add('$path: ${entry.value}');
        }
      }
    }

    expect(violations, isEmpty);
  });

  test('deployment helpers require explicit owned environment identity', () {
    final inheritedWorkflow =
        File('../.github/workflows/firebase-hosting-pull-request.yml');
    final windowsBuild = File('../scripts/deploy_and_build_windows.bat')
        .readAsStringSync();

    expect(inheritedWorkflow.existsSync(), isFalse);
    expect(windowsBuild, isNot(contains('firebase deploy')));
    expect(
      windowsBuild,
      contains('flutter build appbundle --flavor production --release'),
    );
    expect(
      windowsBuild,
      contains('flutter build apk --flavor production --release'),
    );
  });

  test('owner-controlled service configuration remains untracked', () {
    final result = Process.runSync(
      'git',
      const ['ls-files'],
      workingDirectory: '..',
    );
    expect(result.exitCode, 0, reason: result.stderr.toString());

    final trackedSecrets = LineSplitter.split(result.stdout.toString())
        .where((path) =>
            path.endsWith('google-services.json') ||
            path.endsWith('GoogleService-Info.plist') ||
            path.contains('dart_defines.dev.local.json') ||
            path.endsWith('.env'))
        .toList();
    expect(trackedSecrets, isEmpty);
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

  test('interactive login does not require the Drive capability', () {
    final accountAndBackup =
        File('lib/widgets/accountAndBackup.dart').readAsStringSync();

    expect(
      accountAndBackup,
      contains('identityOnly: !appInfrastructure.canUseGoogleDrive'),
    );
    expect(
      accountAndBackup,
      contains('if (appInfrastructure.canUseGoogleDrive) {'),
    );
  });

  test('development auth diagnostics preserve failure stage and stack', () {
    final googleSignIn =
        File('lib/widgets/accountAndBackup.dart').readAsStringSync();
    final firebaseAuth =
        File('lib/struct/firebaseAuthGlobal.dart').readAsStringSync();

    for (final source in [googleSignIn, firebaseAuth]) {
      expect(source, contains('DeploymentEnvironment.development'));
      expect(source, contains('catch (error, stackTrace)'));
      expect(source, contains('debugPrintStack('));
    }
    expect(googleSignIn, contains('[GoogleSignIn]['));
    expect(firebaseAuth, contains('[FirebaseAuth]['));
  });
}
