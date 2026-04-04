// ============================================================
// lib/router/app_router.dart
// Fix: Auth Guard — blocks unauthenticated routes on restart
// Fix: Role-based redirect (DRIVER/MECHANIC/HELPER)
// Fix: Session state properly maintained across app restarts
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

// ── Route Names (constants prevent typos) ────────────────────

class Routes {
  static const splash           = '/';
  static const onboarding       = '/onboarding';
  static const phoneLogin       = '/phone-login';
  static const otp              = '/otp';
  static const profileSetup     = '/profile-setup';
  static const home             = '/home';
  static const mechanics        = '/mechanics';
  static const mechanicDetail   = '/mechanics/:id';
  static const mechanicDashboard = '/mechanic-dashboard';
  static const requestHelp      = '/request-help';
  static const activeJob        = '/active-job/:jobId';
  static const jobOffers        = '/job-offers';
  static const aiMechanic       = '/ai-mechanic';
  static const sos              = '/sos';
  static const profile          = '/profile';
  static const subscription     = '/subscription';
  static const emergencyContacts = '/emergency-contacts';
  static const highwayAlerts    = '/alerts';
  static const nearbyPlaces     = '/nearby-places';
  static const streak           = '/streak';
  static const shop             = '/shop';
}

// ── Auth Guard Helper ─────────────────────────────────────────

// Routes accessible without authentication
const _publicRoutes = {
  Routes.splash,
  Routes.onboarding,
  Routes.phoneLogin,
  Routes.otp,
};

// Routes for authenticated-but-incomplete profile
const _setupRoutes = {
  Routes.profileSetup,
};

// Routes only for Mechanics
const _mechanicRoutes = {
  Routes.mechanicDashboard,
};

// Routes only for Helpers
const _helperRoutes = {
  Routes.jobOffers,
};

String? _authGuard(GoRouterState state, AuthState authState) {
  final location = state.matchedLocation;
  final status = authState.status;

  // ── 1. App still loading session ────────────────────────────
  if (status == AuthStatus.initial) {
    // Let splash handle the loading UI
    return location == Routes.splash ? null : Routes.splash;
  }

  // ── 2. Not authenticated ─────────────────────────────────────
  if (status == AuthStatus.unauthenticated) {
    if (_publicRoutes.contains(location)) return null; // Allow
    return Routes.phoneLogin; // Redirect everything else to login
  }

  // ── 3. Authenticated but new user (incomplete profile) ────────
  if (status == AuthStatus.newUser) {
    if (_setupRoutes.contains(location) || _publicRoutes.contains(location)) {
      return null;
    }
    return Routes.profileSetup;
  }

  // ── 4. Fully authenticated ────────────────────────────────────
  if (status == AuthStatus.authenticated) {
    // Redirect away from auth screens
    if (_publicRoutes.contains(location)) {
      return authState.redirectTo ?? Routes.home;
    }

    // Role-based route protection
    final role = authState.role;
    if (_mechanicRoutes.contains(location) && role != 'MECHANIC') {
      return Routes.home;
    }
    if (_helperRoutes.contains(location) &&
        role != 'HELPER' &&
        role != 'MECHANIC') {
      return Routes.home;
    }

    return null; // Allow
  }

  return null;
}

// ── Router Provider ───────────────────────────────────────────

final appRouterProvider = Provider<GoRouter>((ref) {
  // Listen to auth state — GoRouter re-evaluates redirect on change
  final authStateListenable = ValueNotifier<AuthState>(
    const AuthState(status: AuthStatus.initial),
  );

  ref.listen<AsyncValue<AuthState>>(authProvider, (_, next) {
    next.whenData((authState) {
      authStateListenable.value = authState;
    });
  });

  return GoRouter(
    refreshListenable: authStateListenable,
    initialLocation: Routes.splash,
    debugLogDiagnostics: false,

    redirect: (context, state) {
      final authState = authStateListenable.value;
      return _authGuard(state, authState);
    },

    errorBuilder: (context, state) => _ErrorPage(error: state.error),

    routes: [
      // ── Public ──────────────────────────────────────────────

      GoRoute(
        path: Routes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.phoneLogin,
        builder: (_, __) => const PhoneLoginScreen(),
      ),
      GoRoute(
        path: Routes.otp,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return OtpScreen(
            verificationId: extra['verificationId'] as String,
            phone: extra['phone'] as String,
          );
        },
      ),
      GoRoute(
        path: Routes.profileSetup,
        builder: (_, state) => ProfileSetupScreen(
          extra: state.extra as Map<String, dynamic>?,
        ),
      ),

      // ── Authenticated Shell (Bottom Nav) ─────────────────────

      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: Routes.home,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: Routes.mechanics,
            builder: (_, __) => const MechanicsMapScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => MechanicDetailScreen(
                  mechanicId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: Routes.aiMechanic,
            builder: (_, __) => const AiMechanicScreen(),
          ),
          GoRoute(
            path: Routes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Authenticated Full-screen ────────────────────────────

      GoRoute(
        path: Routes.requestHelp,
        builder: (_, __) => const RequestHelpScreen(),
      ),
      GoRoute(
        path: Routes.activeJob,
        builder: (_, state) => ActiveJobScreen(
          jobId: state.pathParameters['jobId']!,
        ),
      ),
      GoRoute(
        path: Routes.jobOffers,
        builder: (_, __) => const JobOffersScreen(),
      ),
      GoRoute(
        path: Routes.sos,
        builder: (_, __) => const SosScreen(),
      ),
      GoRoute(
        path: Routes.subscription,
        builder: (_, __) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: Routes.emergencyContacts,
        builder: (_, __) => const EmergencyContactsScreen(),
      ),
      GoRoute(
        path: Routes.highwayAlerts,
        builder: (_, __) => const HighwayAlertsScreen(),
      ),
      GoRoute(
        path: Routes.nearbyPlaces,
        builder: (_, __) => const NearbyPlacesScreen(),
      ),
      GoRoute(
        path: Routes.streak,
        builder: (_, __) => const StreakScreen(),
      ),
      GoRoute(
        path: Routes.shop,
        builder: (_, __) => const ShopScreen(),
      ),
      GoRoute(
        path: Routes.mechanicDashboard,
        builder: (_, __) => const MechanicDashboardScreen(),
      ),
    ],
  );
});

// ── Error Page ────────────────────────────────────────────────

class _ErrorPage extends StatelessWidget {
  final Exception? error;
  const _ErrorPage({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF6B00), size: 48),
            const SizedBox(height: 16),
            const Text(
              'Page not found',
              style: TextStyle(
                color: Color(0xFFEAF2FF),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => context.go(Routes.home),
              child: const Text(
                'Go Home',
                style: TextStyle(color: Color(0xFFFF6B00)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// USAGE IN main.dart:
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   runApp(const ProviderScope(child: RaahiApp()));
// }
//
// class RaahiApp extends ConsumerWidget {
//   const RaahiApp({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final router = ref.watch(appRouterProvider);
//     return MaterialApp.router(
//       routerConfig: router,
//       theme: AppTheme.darkTheme,
//       localizationsDelegates: GlobalMaterialLocalizations.delegates,
//     );
//   }
// }
// ─────────────────────────────────────────────────────────────

// These imports are needed — add them to your barrel exports:
// ignore: unused_import
export 'package:raahi/screens/splash_screen.dart';
// ignore: unused_import
export 'package:raahi/screens/onboarding_screen.dart';
// ignore: unused_import
export 'package:raahi/screens/auth/phone_login_screen.dart';
// ignore: unused_import
export 'package:raahi/screens/auth/otp_screen.dart';
// ignore: unused_import
export 'package:raahi/screens/auth/profile_setup_screen.dart';
// ignore: unused_import
export 'package:raahi/screens/home/home_screen.dart';
