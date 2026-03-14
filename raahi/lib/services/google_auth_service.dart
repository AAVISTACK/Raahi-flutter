// ============================================================
// lib/services/google_auth_service.dart
// ============================================================
// Handles: Google Sign-In → Firebase Auth → Backend JWT token
//
// FLOW:
//   User taps "Google se Login" button
//       ↓
//   Google Account Picker opens (native OS dialog)
//       ↓
//   Google ID Token milta hai
//       ↓
//   Firebase Auth se verify hota hai
//       ↓
//   Backend ko Firebase token bhejte hain → JWT milta hai
//       ↓
//   ApiService mein JWT save → HomeScreen
//
// FIX: Removed incorrect serverClientId — was using Android OAuth client ID
//      (client_type: 1) which caused Google Sign-In to fail silently.
//      serverClientId must be the WEB OAuth client ID (client_type: 3).
//      To get the web client ID:
//        1. Firebase Console → Project Settings → General
//        2. Scroll to "Your apps" → Web app (add one if missing)
//        3. Or: console.cloud.google.com → APIs → Credentials →
//           Look for "Web client (auto created by Google Service)" OAuth 2.0 ID
//        4. Set WEB_CLIENT_ID below.
//      Until then, GoogleSignIn works without serverClientId on Android
//      because Firebase handles the credential verification server-side.
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';

// Web OAuth 2.0 Client ID from google-services.json (client_type: 3)
const String _webClientId = '208965739273-0m50fpgsronmjc78ngck7a8fu8koa551.apps.googleusercontent.com';

class GoogleAuthService {
  // ── Singleton ──────────────────────────────────────────
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: _webClientId,
  );
  final _firebaseAuth = FirebaseAuth.instance;

  // ── Main Sign-In Method ─────────────────────────────────
  /// Returns: GoogleSignInResult | throws Exception
  Future<GoogleSignInResult> signIn() async {
    try {
      // Step 1: Google Account picker dikhao
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw GoogleSignInCancelledException();
      }

      // Step 2: Google Auth tokens lo
      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw Exception('Google ID token nahi mila. Try again.');
      }

      // Step 3: Firebase credential banao
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Step 4: Firebase mein sign in karo
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;

      // Step 5: Firebase ID token backend ko bhejo → apna JWT lo
      final firebaseToken = await firebaseUser.getIdToken();
      final result = await ApiService().googleSignIn(
        firebaseToken: firebaseToken!,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? '',
        photoUrl: firebaseUser.photoURL ?? '',
        googleId: firebaseUser.uid,
      );

      // Step 6: JWT save karo
      await ApiService().setToken(result['token']);

      final isNewUser = result['is_new_user'] == true ||
          userCredential.additionalUserInfo?.isNewUser == true;

      return GoogleSignInResult(
        isNewUser: isNewUser,
        name: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        photoUrl: firebaseUser.photoURL ?? '',
        token: result['token'],
      );
    } on GoogleSignInCancelledException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw Exception(_firebaseErrorMessage(e.code));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Google login mein error aaya. Dobara try karo.');
    }
  }

  // ── Sign Out ────────────────────────────────────────────
  Future<void> signOut() async {
    await Future.wait([
      _googleSignIn.signOut(),
      _firebaseAuth.signOut(),
    ]);
    await ApiService().clearToken();
  }

  // ── Currently signed-in user ────────────────────────────
  User? get currentUser => _firebaseAuth.currentUser;
  bool get isSignedIn => currentUser != null;

  // ── Firebase error → Hinglish message ──────────────────
  String _firebaseErrorMessage(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'Yeh email pehle se alag method se register hai.';
      case 'network-request-failed':
        return 'Internet connection check karo.';
      case 'too-many-requests':
        return 'Bahut zyada attempts. Thodi der baad try karo.';
      case 'sign_in_failed':
        return 'Google Sign-In fail hua. Firebase Console mein SHA-1 fingerprint add kiya?';
      default:
        return 'Login fail hua ($code). Dobara try karo.';
    }
  }
}

// ── Result model ───────────────────────────────────────────
class GoogleSignInResult {
  final bool isNewUser;
  final String name;
  final String email;
  final String photoUrl;
  final String token;

  const GoogleSignInResult({
    required this.isNewUser,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.token,
  });
}

// ── Custom exception for user cancellation ─────────────────
class GoogleSignInCancelledException implements Exception {
  @override
  String toString() => 'User ne Google login cancel kiya.';
}
