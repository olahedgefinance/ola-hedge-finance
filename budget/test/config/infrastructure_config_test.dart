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
        'OLA_ENVIRONMENT': 'staging',
        'OLA_FIREBASE_ENABLED': 'true',
        'OLA_FIREBASE_API_KEY': 'public-client-value',
        'OLA_FIREBASE_APP_ID': 'owned-app-id',
        'OLA_FIREBASE_MESSAGING_SENDER_ID': 'owned-sender-id',
        'OLA_FIREBASE_PROJECT_ID': 'owned-staging-project',
      });

      final options = firebaseOptionsFrom(config);
      expect(config.canInitializeFirebase, isTrue);
      expect(options.projectId, 'owned-staging-project');
      expect(options.appId, 'owned-app-id');
    });

    test('Google and store features fail closed when identifiers are absent',
        () {
      final config = InfrastructureConfig.fromValues(const {
        'OLA_GOOGLE_ACCOUNT_ENABLED': 'true',
        'OLA_STORE_ENABLED': 'true',
      });

      expect(config.canUseGoogleAccount, isFalse);
      expect(config.canUseStore, isFalse);
    });
  });
}
