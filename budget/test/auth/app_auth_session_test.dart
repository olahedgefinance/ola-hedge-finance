import 'package:budget/auth/app_auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthSessionBackend implements AuthSessionBackend {
  _FakeAuthSessionBackend({this.restoredProfile});

  final AuthSessionProfile? restoredProfile;
  bool? requestedLocalPersistence;
  ({String? accessToken, String? idToken})? receivedTokens;
  var signedOut = false;

  @override
  Future<AuthSessionProfile?> restore({
    required bool useLocalPersistence,
  }) async {
    requestedLocalPersistence = useLocalPersistence;
    return restoredProfile;
  }

  @override
  Future<AuthSessionProfile> signInWithGoogle({
    String? accessToken,
    String? idToken,
  }) async {
    receivedTokens = (accessToken: accessToken, idToken: idToken);
    return const AuthSessionProfile(
      email: 'person@example.test',
      displayName: 'Person',
    );
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

void main() {
  test('restore exposes the persisted Firebase identity to presentation',
      () async {
    const restored = AuthSessionProfile(
      email: 'restored@example.test',
      displayName: 'Restored User',
    );
    final backend = _FakeAuthSessionBackend(restoredProfile: restored);
    final session = AppAuthSession(backend);

    await session.restore(useLocalPersistence: true);

    expect(backend.requestedLocalPersistence, isTrue);
    expect(session.profile, restored);
    expect(session.isSignedIn, isTrue);
  });

  test('Google tokens establish the Firebase-backed application session',
      () async {
    final backend = _FakeAuthSessionBackend();
    final session = AppAuthSession(backend);

    await session.signInWithGoogle(
      accessToken: 'access-token',
      idToken: 'id-token',
    );

    expect(
      backend.receivedTokens,
      (accessToken: 'access-token', idToken: 'id-token'),
    );
    expect(session.profile?.displayName, 'Person');
  });

  test('sign-out clears both the backend and presented identity', () async {
    final backend = _FakeAuthSessionBackend(
      restoredProfile: const AuthSessionProfile(
        email: 'person@example.test',
        displayName: 'Person',
      ),
    );
    final session = AppAuthSession(backend);
    await session.restore(useLocalPersistence: true);

    await session.signOut();

    expect(backend.signedOut, isTrue);
    expect(session.profile, isNull);
    expect(session.isSignedIn, isFalse);
  });

  test('sign-out hides an account-derived dashboard name', () async {
    const storedName = 'Person';
    final session = AppAuthSession(
      _FakeAuthSessionBackend(
        restoredProfile: const AuthSessionProfile(
          email: 'person@example.test',
          displayName: storedName,
        ),
      ),
    );
    await session.restore(useLocalPersistence: true);

    expect(
      shouldShowDashboardUsername(
        username: storedName,
        isAccountIdentity: true,
        hasAccountIdentity: session.isSignedIn,
      ),
      isTrue,
    );

    await session.signOut();

    expect(session.isSignedIn, isFalse);
    expect(
      shouldShowDashboardUsername(
        username: storedName,
        isAccountIdentity: true,
        hasAccountIdentity: session.isSignedIn,
      ),
      isFalse,
    );
    expect(storedName, 'Person');
  });

  test('sign-out preserves a user-entered local dashboard name', () {
    expect(
      shouldShowDashboardUsername(
        username: 'My local nickname',
        isAccountIdentity: false,
        hasAccountIdentity: false,
      ),
      isTrue,
    );
  });
}
