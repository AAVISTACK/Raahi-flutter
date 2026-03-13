// ============================================================
// FILE 1: lib/services/google_auth_service.dart  (NEW)
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
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';

class GoogleAuthService {
  // ── Singleton ──────────────────────────────────────────
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // serverClientId optional — only needed if you want server-side verification
    // serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
  );
  final _firebaseAuth = FirebaseAuth.instance;

  // ── Main Sign-In Method ─────────────────────────────────
  /// Returns: 'new_user' | 'existing_user' | throws Exception
  Future<GoogleSignInResult> signIn() async {
    try {
      // Step 1: Google Account picker dikhao
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User ne cancel kiya
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
      throw Exception('Google login mein error aaya. Dobara try karo.');
    }
  }

  // ── Sign Out ────────────────────────────────────────────
  Future<void> signOut() async {
    await Future.wait([
      _googleSignIn.signOut(),
      _firebaseAuth.signOut(),
    ]);
    // Clear stored JWT
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
