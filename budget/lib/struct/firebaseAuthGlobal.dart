import 'package:budget/config/infrastructure_config.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/accountAndBackup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/foundation.dart';

OAuthCredential? _credential;

void _logFirebaseAuthFailure(
  String stage,
  Object error,
  StackTrace stackTrace,
) {
  if (appInfrastructure.environment != DeploymentEnvironment.development) {
    return;
  }
  debugPrint('[FirebaseAuth][$stage] ${error.runtimeType}: $error');
  debugPrintStack(
    label: '[FirebaseAuth][$stage] stack trace',
    stackTrace: stackTrace,
  );
}

Future<FirebaseFirestore?> firebaseGetExistingDBInstance() async {
  if (!appInfrastructure.canInitializeFirebase) return null;
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null || currentUser.isAnonymous) return null;
  return FirebaseFirestore.instance;
}

// returns null if authentication unsuccessful
Future<FirebaseFirestore?> firebaseGetDBInstance() async {
  if (!appInfrastructure.canInitializeFirebase ||
      !appInfrastructure.canUseGoogleAccount) return null;
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null && !currentUser.isAnonymous) {
    return FirebaseFirestore.instance;
  }
  if (_credential != null) {
    const stage = 'firebase-sign-in-cached-credential';
    try {
      await FirebaseAuth.instance.signInWithCredential(_credential!);
      updateSettings(
        "currentUserEmail",
        FirebaseAuth.instance.currentUser!.email,
        pagesNeedingRefresh: [],
        updateGlobalState: false,
      );
      return FirebaseFirestore.instance;
    } catch (error, stackTrace) {
      _logFirebaseAuthFailure(stage, error, stackTrace);
      print("There was an error with firebase login");
      print(error.toString());
      print("will retry with a new credential");
      _credential = null;
      googleUser = null;
      return await firebaseGetDBInstance();
    }
  } else {
    var stage = 'google-authentication-token';
    try {
      if (googleUser == null) {
        await signInGoogle(silentSignIn: true, identityOnly: true);
      }
      // GoogleSignInAccount? googleUser = googleUser;

      GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      stage = 'firebase-credential-creation';
      _credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      stage = 'firebase-sign-in-with-credential';
      await FirebaseAuth.instance.signInWithCredential(_credential!);
      stage = 'firebase-authenticated-state';
      updateSettings(
          "currentUserEmail", FirebaseAuth.instance.currentUser!.email,
          updateGlobalState: true);
      return FirebaseFirestore.instance;
    } catch (error, stackTrace) {
      _logFirebaseAuthFailure(stage, error, stackTrace);
      print("There was an error with firebase login and possibly google");
      print(error.toString());
      return null;
    }
  }
}
