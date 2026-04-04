// ============================================================
// lib/providers/auth_provider.dart
// Fix: Complete separation of auth business logic from UI
// Uses AsyncNotifier — no setState, no bool _isLoading anywhere
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/google_auth_service.dart';

// ── Auth State ────────────────────────────────────────────────

enum AuthStatus {
  initial,        // App just launched — checking session
  unauthenticated,
  phoneEntered,   // OTP code was sent
  authenticated,
  newUser,        // Authenticated but profile not set up
  suspended,      // Account banned
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? role;          // "DRIVER" | "MECHANIC" | "HELPER"
  final String? redirectTo;   // Backend-driven redirect hint
  final String? verificationId; // During OTP flow
  final String? phone;           // During OTP flow
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.role,
    this.redirectTo,
    this.verificationId,
    this.phone,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? role,
    String? redirectTo,
    String? verificationId,
    String? phone,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      role: role ?? this.role,
      redirectTo: redirectTo ?? this.redirectTo,
      verificationId: verificationId ?? this.verificationId,
      phone: phone ?? this.phone,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isAuthenticated =>
      status == AuthStatus.authenticated || status == AuthStatus.newUser;

  bool get isLoading => status == AuthStatus.initial;

  @override
  String toString() => 'AuthState(status: $status, role: $role)';
}

// ── Auth Notifier ─────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    // Called once on app start — restores session
    return _restoreSession();
  }

  // ── Session Restore (App Restart Fix) ──────────────────────
  // Old bug: app always went to splash → login on restart
  // Fix: checks Firebase currentUser + calls /auth/me to validate

  Future<AuthState> _restoreSession() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      return const AuthState(status: AuthStatus.unauthenticated);
    }

    try {
      // Get fresh ID token (Firebase auto-refreshes if needed)
      final idToken = await firebaseUser.getIdToken(true);
      await ApiService().setToken(idToken);

      // Validate with our backend — gets role, subscription status
      final result = await ApiService().get('/auth/me');
      final userModel = UserModel.fromJson(result['user']);

      return AuthState(
        status: AuthStatus.authenticated,
        user: userModel,
        role: result['role'] as String?,
        redirectTo: _redirectForRole(result['role'] as String?),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 404) {
        // Token invalid or user deleted — clear local state
        await _signOut();
        return const AuthState(status: AuthStatus.unauthenticated);
      }
      // Network error — keep user logged in optimistically
      // (Better UX than forcing login on every network blip)
      return const AuthState(
        status: AuthStatus.authenticated,
        errorMessage: 'Could not sync profile — showing cached data',
      );
    }
  }

  // ── Phone OTP — Send ───────────────────────────────────────

  Future<void> sendOtp(String phone) async {
    state = const AsyncValue.loading();

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91$phone',
      timeout: const Duration(seconds: 60),

      // Instant verification (mostly on emulators / some devices)
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _signInWithCredential(credential, phone: '+91$phone');
      },

      verificationFailed: (FirebaseAuthException e) {
        state = AsyncValue.data(AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: _mapFirebaseError(e.code),
        ));
      },

      codeSent: (String verificationId, int? resendToken) {
        state = AsyncValue.data(AuthState(
          status: AuthStatus.phoneEntered,
          verificationId: verificationId,
          phone: '+91$phone',
        ));
      },

      codeAutoRetrievalTimeout: (_) {
        // Silently ignored — user can still enter OTP manually
      },
    );
  }

  // ── Phone OTP — Verify ─────────────────────────────────────

  Future<void> verifyOtp(String verificationId, String phone, String otp) async {
    state = const AsyncValue.loading();

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      await _signInWithCredential(credential, phone: phone);
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.data(AuthState(
        status: AuthStatus.phoneEntered,
        verificationId: verificationId,
        phone: phone,
        errorMessage: _mapFirebaseError(e.code),
      ));
    } catch (e) {
      state = AsyncValue.data(AuthState(
        status: AuthStatus.phoneEntered,
        verificationId: verificationId,
        phone: phone,
        errorMessage: 'Something went wrong. Please try again.',
      ));
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();

    try {
      final result = await GoogleAuthService().signIn();

      // Get Firebase ID token and verify with our backend
      final firebaseUser = FirebaseAuth.instance.currentUser!;
      final idToken = await firebaseUser.getIdToken();
      await _verifyWithBackend(idToken, isNewUser: result.isNewUser);
    } on GoogleSignInCancelledException {
      state = AsyncValue.data(const AuthState(status: AuthStatus.unauthenticated));
    } catch (e) {
      state = AsyncValue.data(AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  // ── Sign Out ───────────────────────────────────────────────

  Future<void> signOut() async {
    await _signOut();
    state = AsyncValue.data(const AuthState(status: AuthStatus.unauthenticated));
  }

  // ── Internal Helpers ───────────────────────────────────────

  Future<void> _signInWithCredential(
    PhoneAuthCredential credential, {
    required String phone,
  }) async {
    try {
      final userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCred.user!.getIdToken();
      await _verifyWithBackend(idToken);
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.data(AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: _mapFirebaseError(e.code),
      ));
    }
  }

  Future<void> _verifyWithBackend(String idToken, {bool? isNewUser}) async {
    try {
      await ApiService().setToken(idToken);

      final result = await ApiService().post('/auth/verify-firebase', {
        'idToken': idToken,
        'role': 'DRIVER', // Default; user can change in profile setup
      });

      final serverIsNewUser = result['isNewUser'] as bool? ?? isNewUser ?? false;
      final role = result['role'] as String?;
      final redirectTo = result['redirectTo'] as String?;
      final userModel = UserModel.fromJson(result['user']);

      state = AsyncValue.data(AuthState(
        status: serverIsNewUser
            ? AuthStatus.newUser
            : AuthStatus.authenticated,
        user: userModel,
        role: role,
        redirectTo: redirectTo,
      ));
    } on ApiException catch (e) {
      state = AsyncValue.data(AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message ?? 'Server error. Please try again.',
      ));
    }
  }

  Future<void> _signOut() async {
    await Future.wait([
      FirebaseAuth.instance.signOut(),
      ApiService().clearToken(),
    ]);
  }

  String _redirectForRole(String? role) {
    switch (role) {
      case 'MECHANIC':
        return '/mechanic-dashboard';
      case 'HELPER':
        return '/job-offers';
      default:
        return '/home';
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'invalid-verification-code':
        return 'Wrong OTP. Please check and try again.';
      case 'session-expired':
        return 'OTP session expired. Please request a new OTP.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait before trying again.';
      case 'invalid-phone-number':
        return 'Invalid phone number format.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Authentication failed ($code). Please try again.';
    }
  }
}

// ── Providers ─────────────────────────────────────────────────

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

// Convenience selectors — avoids re-rendering widgets unnecessarily

final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authProvider).maybeWhen(
    data: (s) => s.status,
    loading: () => AuthStatus.initial,
    error: (_, __) => AuthStatus.unauthenticated,
  );
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).maybeWhen(
    data: (s) => s.user,
    orElse: () => null,
  );
});

final currentRoleProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).maybeWhen(
    data: (s) => s.role,
    orElse: () => null,
  );
});
