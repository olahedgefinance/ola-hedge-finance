import 'package:budget/config/infrastructure_config.dart';
import 'package:budget/config/firebase_bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InfrastructureConfig', () {
    test('development defaults are local only and valid', () {
      final config = InfrastructureConfig.fromValues(const {});

      expect(config.environment, DeploymentEnvironment.development);
      expect(config.firebaseEnabled, isFalse);
      expect(config.googleAccountEnabled, isFalse);
      expect(config.googleDriveEnabled, isFalse);
      expect(config.gmailEnabled, isFalse);
      expect(config.storeEnabled, isFalse);
      expect(config.validationErrors, isEmpty);
    });

    test('parses a staging environment', () {
      final config = InfrastructureConfig.fromValues(
        const {'OLA_ENVIRONMENT': 'staging'},
      );

      expect(config.environment, DeploymentEnvironment.staging);
    });

    test('rejects production during Phase 1', () {
      final config = InfrastructureConfig.fromValues(
        const {'OLA_ENVIRONMENT': 'production'},
      );

      expect(config.validationErrors,
          contains('Production is disabled in Phase 1.'));
    });

    test('enabled Firebase requires a complete owned configuration', () {
      final config = InfrastructureConfig.fromValues(
        const {'OLA_FIREBASE_ENABLED': 'true'},
      );

      expect(config.canInitializeFirebase, isFalse);
      expect(
        config.validationErrors,
        contains(
            'Firebase is enabled but its client configuration is incomplete.'),
      );
    });

    test('known upstream infrastructure is rejected', () {
      final config = InfrastructureConfig.fromValues(const {
        'OLA_FIREBASE_ENABLED': 'true',
        'OLA_FIREBASE_API_KEY': 'example',
        'OLA_FIREBASE_APP_ID': 'example',
        'OLA_FIREBASE_MESSAGING_SENDER_ID': 'example',
        'OLA_FIREBASE_PROJECT_ID': 'budget-app-flutter',
      });

      expect(config.validationErrors,
          contains('Upstream infrastructure is not allowed.'));
    });

    test('complete owned Firebase values produce explicit options', () {
      final config = InfrastructureConfig.fromValues(const {
        'OLA_ENVIRONMENT': 'development',
        'OLA_FIREBASE_ENABLED': 'true',
        'OLA_FIREBASE_API_KEY': 'public-client-value',
        'OLA_FIREBASE_APP_ID': 'owned-app-id',
        'OLA_FIREBASE_MESSAGING_SENDER_ID': 'owned-sender-id',
        'OLA_FIREBASE_PROJECT_ID': 'ola-hedge-finance-dev',
      });

      final options = firebaseOptionsFrom(config);
      expect(config.canInitializeFirebase, isTrue);
      expect(options.projectId, 'ola-hedge-finance-dev');
      expect(options.appId, 'owned-app-id');
    });

    test('Firebase rejects any project other than the verified dev project',
        () {
      final config = InfrastructureConfig.fromValues(const {
        'OLA_ENVIRONMENT': 'development',
        'OLA_FIREBASE_ENABLED': 'true',
        'OLA_FIREBASE_API_KEY': 'public-client-value',
        'OLA_FIREBASE_APP_ID': 'owned-app-id',
        'OLA_FIREBASE_MESSAGING_SENDER_ID': 'owned-sender-id',
        'OLA_FIREBASE_PROJECT_ID': 'lookalike-project',
      });

      expect(config.canInitializeFirebase, isFalse);
      expect(
        config.validationErrors,
        contains('Firebase is restricted to the verified development project.'),
      );
    });

    test('Google and store features fail closed when identifiers are absent',
        () {
      final config = InfrastructureConfig.fromValues(const {
        'OLA_GOOGLE_ACCOUNT_ENABLED': 'true',
        'OLA_STORE_ENABLED': 'true',
      });

      expect(config.canUseGoogleAccount, isFalse);
      expect(config.canUseGoogleDrive, isFalse);
      expect(config.canUseGmail, isFalse);
      expect(config.canUseStore, isFalse);
    });

    test('basic Google identity does not enable Drive or Gmail', () {
      final config = InfrastructureConfig.fromValues(const {
        'OLA_GOOGLE_ACCOUNT_ENABLED': 'true',
        'OLA_GOOGLE_WEB_CLIENT_ID': 'owned-web-client',
      });

      expect(config.canUseGoogleAccount, isTrue);
      expect(config.canUseGoogleDrive, isFalse);
      expect(config.canUseGmail, isFalse);
    });

    test('Drive and Gmail require explicit enablement and configuration', () {
      final config = InfrastructureConfig.fromValues(const {
        'OLA_GOOGLE_ACCOUNT_ENABLED': 'true',
        'OLA_GOOGLE_WEB_CLIENT_ID': 'owned-web-client',
        'OLA_GOOGLE_DRIVE_ENABLED': 'true',
        'OLA_GMAIL_ENABLED': 'true',
      });

      expect(config.canUseGoogleAccount, isFalse);
      expect(config.canUseGoogleDrive, isFalse);
      expect(config.canUseGmail, isFalse);
      expect(
        config.validationErrors,
        contains('Google Drive is enabled but its folder is not configured.'),
      );
    });
  });
}
