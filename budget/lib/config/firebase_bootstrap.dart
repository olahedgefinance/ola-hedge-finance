import 'package:budget/config/infrastructure_config.dart';
import 'package:firebase_core/firebase_core.dart';

FirebaseOptions firebaseOptionsFrom(InfrastructureConfig config) {
  if (!config.canInitializeFirebase) {
    throw StateError(
      'Firebase configuration is unavailable: ${config.validationErrors.join(' ')}',
    );
  }
  return FirebaseOptions(
    apiKey: config.firebaseApiKey,
    appId: config.firebaseAppId,
    messagingSenderId: config.firebaseMessagingSenderId,
    projectId: config.firebaseProjectId,
    authDomain:
        config.firebaseAuthDomain.isEmpty ? null : config.firebaseAuthDomain,
    storageBucket: config.firebaseStorageBucket.isEmpty
        ? null
        : config.firebaseStorageBucket,
    iosClientId:
        config.googleIosClientId.isEmpty ? null : config.googleIosClientId,
    iosBundleId:
        config.firebaseIosBundleId.isEmpty ? null : config.firebaseIosBundleId,
  );
}

Future<bool> initializeConfiguredFirebase({
  InfrastructureConfig? config,
}) async {
  final selected = config ?? appInfrastructure;
  if (!selected.firebaseEnabled) return false;
  await Firebase.initializeApp(options: firebaseOptionsFrom(selected));
  return true;
}
