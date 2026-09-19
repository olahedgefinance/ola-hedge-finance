import 'package:budget/config/infrastructure_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

@immutable
class AuthSessionProfile {
  const AuthSessionProfile({
    required this.email,
    required this.displayName,
    this.photoUrl,
  });

  final String? email;
  final String? displayName;
  final String? photoUrl;
}

bool shouldShowDashboardUsername({
  required String username,
  required bool isAccountIdentity,
  required bool hasAccountIdentity,
}) {
  return username.trim().isNotEmpty &&
      (!isAccountIdentity || hasAccountIdentity);
}

abstract interface class AuthSessionBackend {
  Future<AuthSessionProfile?> restore({
    required bool useLocalPersistence,
  });

  Future<AuthSessionProfile> signInWithGoogle({
    String? accessToken,
    String? idToken,
  });

  Future<void> signOut();
}

class FirebaseAuthSessionBackend implements AuthSessionBackend {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  Future<AuthSessionProfile?> restore({
    required bool useLocalPersistence,
  }) async {
    if (useLocalPersistence) {
      await _auth.setPersistence(Persistence.LOCAL);
    }
    return _profileFromUser(await _auth.authStateChanges().first);
  }

  @override
  Future<AuthSessionProfile> signInWithGoogle({
    String? accessToken,
    String? idToken,
  }) async {
    if (accessToken == null && idToken == null) {
      throw StateError('Google authentication returned no Firebase tokens.');
    }
    final credential = GoogleAuthProvider.credential(
      accessToken: accessToken,
      idToken: idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    final profile = _profileFromUser(result.user);
    if (profile == null) {
      throw StateError('Firebase authentication returned no user.');
    }
    return profile;
  }

  @override
  Future<void> signOut() => _auth.signOut();

  AuthSessionProfile? _profileFromUser(User? user) {
    if (user == null || user.isAnonymous) return null;
    return AuthSessionProfile(
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }
}

class AppAuthSession extends ChangeNotifier {
  AppAuthSession(this._backend);

  final AuthSessionBackend _backend;
  AuthSessionProfile? _profile;

  AuthSessionProfile? get profile => _profile;
  bool get isSignedIn => _profile != null;

  Future<void> restore({required bool useLocalPersistence}) async {
    _setProfile(await _backend.restore(
      useLocalPersistence: useLocalPersistence,
    ));
  }

  Future<void> signInWithGoogle({
    String? accessToken,
    String? idToken,
  }) async {
    _setProfile(await _backend.signInWithGoogle(
      accessToken: accessToken,
      idToken: idToken,
    ));
  }

  Future<void> signOut() async {
    await _backend.signOut();
    _setProfile(null);
  }

  void _setProfile(AuthSessionProfile? profile) {
    _profile = profile;
    notifyListeners();
  }
}

final AppAuthSession appAuthSession =
    AppAuthSession(FirebaseAuthSessionBackend());

Future<void> initializeAppAuthSession() async {
  if (!appInfrastructure.canInitializeFirebase) return;
  const stage = 'startup-restoration';
  try {
    await appAuthSession.restore(useLocalPersistence: kIsWeb);
    if (appInfrastructure.environment == DeploymentEnvironment.development) {
      debugPrint(
        '[FirebaseAuth][$stage] currentUser=${appAuthSession.isSignedIn}',
      );
    }
  } catch (error, stackTrace) {
    if (appInfrastructure.environment == DeploymentEnvironment.development) {
      debugPrint('[FirebaseAuth][$stage] ${error.runtimeType}: $error');
      debugPrintStack(
        label: '[FirebaseAuth][$stage] stack trace',
        stackTrace: stackTrace,
      );
    }
    rethrow;
  }
}
