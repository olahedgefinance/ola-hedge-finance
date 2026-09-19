enum DeploymentEnvironment { development, staging, production }

class InfrastructureConfig {
  InfrastructureConfig._({
    required this.environment,
    required this.firebaseEnabled,
    required this.googleAccountEnabled,
    required this.googleDriveEnabled,
    required this.gmailEnabled,
    required this.storeEnabled,
    required this.firebaseApiKey,
    required this.firebaseAppId,
    required this.firebaseMessagingSenderId,
    required this.firebaseProjectId,
    required this.firebaseAuthDomain,
    required this.firebaseStorageBucket,
    required this.firebaseIosBundleId,
    required this.googleWebClientId,
    required this.googleIosClientId,
    required this.googleDriveFolder,
    required this.storeMonthlyId,
    required this.storeYearlyId,
    required this.storeLifetimeId,
    required this.iosAppStoreId,
    required this.supportUrl,
    required this.privacyUrl,
    required this.supportEmail,
    required this.donationUrl,
    required this.appLinkHost,
    required String? environmentError,
  }) : _environmentError = environmentError;

  factory InfrastructureConfig.fromEnvironment() {
    return InfrastructureConfig.fromValues(const {
      'OLA_ENVIRONMENT': String.fromEnvironment('OLA_ENVIRONMENT'),
      'OLA_FIREBASE_ENABLED': String.fromEnvironment('OLA_FIREBASE_ENABLED'),
      'OLA_FIREBASE_API_KEY': String.fromEnvironment('OLA_FIREBASE_API_KEY'),
      'OLA_FIREBASE_APP_ID': String.fromEnvironment('OLA_FIREBASE_APP_ID'),
      'OLA_FIREBASE_MESSAGING_SENDER_ID':
          String.fromEnvironment('OLA_FIREBASE_MESSAGING_SENDER_ID'),
      'OLA_FIREBASE_PROJECT_ID':
          String.fromEnvironment('OLA_FIREBASE_PROJECT_ID'),
      'OLA_FIREBASE_AUTH_DOMAIN':
          String.fromEnvironment('OLA_FIREBASE_AUTH_DOMAIN'),
      'OLA_FIREBASE_STORAGE_BUCKET':
          String.fromEnvironment('OLA_FIREBASE_STORAGE_BUCKET'),
      'OLA_FIREBASE_IOS_BUNDLE_ID':
          String.fromEnvironment('OLA_FIREBASE_IOS_BUNDLE_ID'),
      'OLA_GOOGLE_ACCOUNT_ENABLED':
          String.fromEnvironment('OLA_GOOGLE_ACCOUNT_ENABLED'),
      'OLA_GOOGLE_DRIVE_ENABLED':
          String.fromEnvironment('OLA_GOOGLE_DRIVE_ENABLED'),
      'OLA_GMAIL_ENABLED': String.fromEnvironment('OLA_GMAIL_ENABLED'),
      'OLA_GOOGLE_WEB_CLIENT_ID':
          String.fromEnvironment('OLA_GOOGLE_WEB_CLIENT_ID'),
      'OLA_GOOGLE_IOS_CLIENT_ID':
          String.fromEnvironment('OLA_GOOGLE_IOS_CLIENT_ID'),
      'OLA_GOOGLE_DRIVE_FOLDER':
          String.fromEnvironment('OLA_GOOGLE_DRIVE_FOLDER'),
      'OLA_STORE_ENABLED': String.fromEnvironment('OLA_STORE_ENABLED'),
      'OLA_STORE_MONTHLY_ID': String.fromEnvironment('OLA_STORE_MONTHLY_ID'),
      'OLA_STORE_YEARLY_ID': String.fromEnvironment('OLA_STORE_YEARLY_ID'),
      'OLA_STORE_LIFETIME_ID': String.fromEnvironment('OLA_STORE_LIFETIME_ID'),
      'OLA_IOS_APP_STORE_ID': String.fromEnvironment('OLA_IOS_APP_STORE_ID'),
      'OLA_SUPPORT_URL': String.fromEnvironment('OLA_SUPPORT_URL'),
      'OLA_PRIVACY_URL': String.fromEnvironment('OLA_PRIVACY_URL'),
      'OLA_SUPPORT_EMAIL': String.fromEnvironment('OLA_SUPPORT_EMAIL'),
      'OLA_DONATION_URL': String.fromEnvironment('OLA_DONATION_URL'),
      'OLA_APP_LINK_HOST': String.fromEnvironment('OLA_APP_LINK_HOST'),
    });
  }

  factory InfrastructureConfig.fromValues(Map<String, String> values) {
    final parsedEnvironment = _parseEnvironment(values['OLA_ENVIRONMENT']);
    return InfrastructureConfig._(
      environment: parsedEnvironment.$1,
      environmentError: parsedEnvironment.$2,
      firebaseEnabled: _enabled(values['OLA_FIREBASE_ENABLED']),
      googleAccountEnabled: _enabled(values['OLA_GOOGLE_ACCOUNT_ENABLED']),
      googleDriveEnabled: _enabled(values['OLA_GOOGLE_DRIVE_ENABLED']),
      gmailEnabled: _enabled(values['OLA_GMAIL_ENABLED']),
      storeEnabled: _enabled(values['OLA_STORE_ENABLED']),
      firebaseApiKey: _value(values, 'OLA_FIREBASE_API_KEY'),
      firebaseAppId: _value(values, 'OLA_FIREBASE_APP_ID'),
      firebaseMessagingSenderId:
          _value(values, 'OLA_FIREBASE_MESSAGING_SENDER_ID'),
      firebaseProjectId: _value(values, 'OLA_FIREBASE_PROJECT_ID'),
      firebaseAuthDomain: _value(values, 'OLA_FIREBASE_AUTH_DOMAIN'),
      firebaseStorageBucket: _value(values, 'OLA_FIREBASE_STORAGE_BUCKET'),
      firebaseIosBundleId: _value(values, 'OLA_FIREBASE_IOS_BUNDLE_ID'),
      googleWebClientId: _value(values, 'OLA_GOOGLE_WEB_CLIENT_ID'),
      googleIosClientId: _value(values, 'OLA_GOOGLE_IOS_CLIENT_ID'),
      googleDriveFolder: _value(values, 'OLA_GOOGLE_DRIVE_FOLDER'),
      storeMonthlyId: _value(values, 'OLA_STORE_MONTHLY_ID'),
      storeYearlyId: _value(values, 'OLA_STORE_YEARLY_ID'),
      storeLifetimeId: _value(values, 'OLA_STORE_LIFETIME_ID'),
      iosAppStoreId: _value(values, 'OLA_IOS_APP_STORE_ID'),
      supportUrl: _value(values, 'OLA_SUPPORT_URL'),
      privacyUrl: _value(values, 'OLA_PRIVACY_URL'),
      supportEmail: _value(values, 'OLA_SUPPORT_EMAIL'),
      donationUrl: _value(values, 'OLA_DONATION_URL'),
      appLinkHost: _value(values, 'OLA_APP_LINK_HOST'),
    );
  }

  final DeploymentEnvironment environment;
  final bool firebaseEnabled;
  final bool googleAccountEnabled;
  final bool googleDriveEnabled;
  final bool gmailEnabled;
  final bool storeEnabled;
  final String firebaseApiKey;
  final String firebaseAppId;
  final String firebaseMessagingSenderId;
  final String firebaseProjectId;
  final String firebaseAuthDomain;
  final String firebaseStorageBucket;
  final String firebaseIosBundleId;
  final String googleWebClientId;
  final String googleIosClientId;
  final String googleDriveFolder;
  final String storeMonthlyId;
  final String storeYearlyId;
  final String storeLifetimeId;
  final String iosAppStoreId;
  final String supportUrl;
  final String privacyUrl;
  final String supportEmail;
  final String donationUrl;
  final String appLinkHost;
  final String? _environmentError;

  List<String> get validationErrors {
    final errors = <String>[];
    if (_environmentError != null) errors.add(_environmentError!);
    if (environment == DeploymentEnvironment.production) {
      errors.add('Production is disabled in Phase 1.');
    }
    if (firebaseEnabled &&
        [
          firebaseApiKey,
          firebaseAppId,
          firebaseMessagingSenderId,
          firebaseProjectId,
        ].any((value) => value.isEmpty)) {
      errors.add(
          'Firebase is enabled but its client configuration is incomplete.');
    }
    if (firebaseEnabled &&
        (environment != DeploymentEnvironment.development ||
            firebaseProjectId != 'ola-hedge-finance-dev')) {
      errors.add('Firebase is restricted to the verified development project.');
    }
    if (googleAccountEnabled &&
        (googleWebClientId.isEmpty && googleIosClientId.isEmpty)) {
      errors.add(
          'Google account services are enabled but their configuration is incomplete.');
    }
    if ((googleDriveEnabled || gmailEnabled) && !googleAccountEnabled) {
      errors.add('Google data services require Google identity to be enabled.');
    }
    if (googleDriveEnabled && googleDriveFolder.isEmpty) {
      errors.add('Google Drive is enabled but its folder is not configured.');
    }
    if (storeEnabled &&
        [storeMonthlyId, storeYearlyId, storeLifetimeId]
            .any((value) => value.isEmpty)) {
      errors.add(
          'Store services are enabled but product identifiers are incomplete.');
    }
    if (_allValues.any(_isUpstreamValue)) {
      errors.add('Upstream infrastructure is not allowed.');
    }
    return List.unmodifiable(errors);
  }

  bool get canInitializeFirebase => firebaseEnabled && validationErrors.isEmpty;
  bool get canUseGoogleAccount =>
      googleAccountEnabled && validationErrors.isEmpty;
  bool get canUseGoogleDrive => googleDriveEnabled && canUseGoogleAccount;
  bool get canUseGmail => gmailEnabled && canUseGoogleAccount;
  bool get canUseStore => storeEnabled && validationErrors.isEmpty;

  List<String> get _allValues => [
        firebaseApiKey,
        firebaseAppId,
        firebaseMessagingSenderId,
        firebaseProjectId,
        firebaseAuthDomain,
        firebaseStorageBucket,
        firebaseIosBundleId,
        googleWebClientId,
        googleIosClientId,
        googleDriveFolder,
        storeMonthlyId,
        storeYearlyId,
        storeLifetimeId,
        iosAppStoreId,
        supportUrl,
        privacyUrl,
        supportEmail,
        donationUrl,
        appLinkHost,
      ];

  static bool _enabled(String? value) => value?.toLowerCase() == 'true';

  static String _value(Map<String, String> values, String key) =>
      values[key]?.trim() ?? '';

  static (DeploymentEnvironment, String?) _parseEnvironment(String? value) {
    switch (value?.trim().toLowerCase()) {
      case null:
      case '':
      case 'development':
        return (DeploymentEnvironment.development, null);
      case 'staging':
        return (DeploymentEnvironment.staging, null);
      case 'production':
        return (DeploymentEnvironment.production, null);
      default:
        return (
          DeploymentEnvironment.development,
          'Unknown deployment environment.',
        );
    }
  }

  static bool _isUpstreamValue(String value) {
    final normalized = value.toLowerCase();
    const signatures = <({int length, int hash})>[
      (length: 18, hash: 701752808),
      (length: 17, hash: 2465217909),
      (length: 20, hash: 2710597212),
      (length: 11, hash: 2669675594),
      (length: 18, hash: 2511516787),
      (length: 12, hash: 1837627940),
    ];
    return signatures.any((signature) {
      for (var start = 0;
          start + signature.length <= normalized.length;
          start++) {
        if (_stableHash(
              normalized.substring(start, start + signature.length),
            ) ==
            signature.hash) return true;
      }
      return false;
    });
  }

  static int _stableHash(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0xffffffff;
    }
    return hash;
  }
}

final InfrastructureConfig appInfrastructure =
    InfrastructureConfig.fromEnvironment();
