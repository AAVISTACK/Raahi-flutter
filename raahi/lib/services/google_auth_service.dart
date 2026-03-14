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
// FIX 1: Removed serverClientId from GoogleSignIn() for Android.
//         Setting serverClientId causes ApiException: 10 (DEVELOPER_ERROR)
//         when the value doesn't match what Firebase expects.
//         Firebase resolves OAuth credentials automatically via google-services.json.
//
// FIX 2: Added step-by-step debug logs — visible in: flutter run / logcat.
//         Each step prints OK or the exact failure point so you can diagnose fast.
//
// IMPORTANT — If ApiException: 10 still occurs after this fix:
//   Your SHA-1 fingerprint is not registered in Firebase Console.
//   Steps to fix:
//     1. Run: keytool -list -v -keystore ~/.android/debug.keystore
//              -alias androiddebugkey -storepass android -keypass android
//     2. Copy the SHA-1 fingerprint shown
//     3. Firebase Console → Project Settings → Android App (com.raahi.app)
//        → Add fingerprint → paste SHA-1 → Save
//     4. Re-download google-services.json → replace android/app/google-services.json
//     5. flutter clean && flutter pub get && flutter run
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';

class GoogleAuthService {
  // ── Singleton ──────────────────────────────────────────
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  // FIX: serverClientId removed — it was causing ApiException: 10.
  // Firebase handles credential verification automatically via google-services.json.
  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final _firebaseAuth = FirebaseAuth.instance;

  // ── Main Sign-In Method ─────────────────────────────────
  /// Returns: GoogleSignInResult | throws Exception
  Future<GoogleSignInResult> signIn() async {
    try {
      // Step 1: Google Account picker dikhao
      print('[GoogleAuth] Step 1: Opening Google account picker...');
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('[GoogleAuth] Step 1: User cancelled sign-in.');
        throw GoogleSignInCancelledException();
      }
      print('[GoogleAuth] Step 1 OK: email=${googleUser.email}');

      // Step 2: Google Auth tokens lo
      print('[GoogleAuth] Step 2: Fetching Google auth tokens...');
      final googleAuth = await googleUser.authentication;
      print('[GoogleAuth] Step 2 OK: idToken=${googleAuth.idToken != null ? "present" : "NULL — SHA-1 issue!"}');
      print('[GoogleAuth] Step 2 OK: accessToken=${googleAuth.accessToken != null ? "present" : "NULL"}');

      if (googleAuth.idToken == null) {
        throw Exception(
          'Google ID token nahi mila. '
          'Firebase Console mein SHA-1 fingerprint add karo aur google-services.json update karo.',
        );
      }

      // Step 3: Firebase credential banao
      print('[GoogleAuth] Step 3: Creating Firebase credential...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print('[GoogleAuth] Step 3 OK');

      // Step 4: Firebase mein sign in karo
      print('[GoogleAuth] Step 4: Signing into Firebase...');
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;
      print('[GoogleAuth] Step 4 OK: uid=${firebaseUser.uid}, email=${firebaseUser.email}');

      // Step 5: Firebase ID token backend ko bhejo → apna JWT lo
      print('[GoogleAuth] Step 5: Getting Firebase ID token for backend...');
      final firebaseToken = await firebaseUser.getIdToken();
      print('[GoogleAuth] Step 5 OK: firebaseToken=${firebaseToken != null ? "present" : "NULL"}');

      print('[GoogleAuth] Step 6: Calling backend googleSignIn API...');
      final result = await ApiService().googleSignIn(
        firebaseToken: firebaseToken!,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? '',
        photoUrl: firebaseUser.photoURL ?? '',
        googleId: firebaseUser.uid,
      );
      print('[GoogleAuth] Step 6 OK: backend token=${result['token'] != null ? "present" : "NULL"}');

      // Step 7: JWT save karo
      await ApiService().setToken(result['token']);

      final isNewUser = result['is_new_user'] == true ||
          userCredential.additionalUserInfo?.isNewUser == true;

      print('[GoogleAuth] Sign-in complete! isNewUser=$isNewUser');

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
      print('[GoogleAuth] FirebaseAuthException: code=${e.code}, message=${e.message}');
      throw Exception(_firebaseErrorMessage(e.code));
    } catch (e) {
      print('[GoogleAuth] Unexpected error: $e');
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
    print('[GoogleAuth] Signed out successfully.');
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
        return 'Google Sign-In fail hua. Firebase Console mein SHA-1 fingerprint add karo.';
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
