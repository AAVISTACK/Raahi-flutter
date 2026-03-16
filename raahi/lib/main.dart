import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/api_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'services/ad_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import 'services/language_service.dart';
import 'models/models.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth/phone_login_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/auth/profile_setup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/p2p/request_help_screen.dart';
import 'screens/p2p/active_job_screen.dart';
import 'screens/p2p/job_offers_screen.dart';
import 'screens/mechanic/mechanics_map_screen.dart';
import 'screens/mechanic/mechanic_detail_screen.dart';
import 'screens/ai/ai_mechanic_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/sos/sos_screen.dart';
import 'screens/mechanic/mechanic_register_screen.dart';
import 'screens/subscription/subscription_screen.dart';
import 'screens/safety/emergency_contacts_screen.dart';
import 'screens/safety/aadhaar_verify_screen.dart';
import 'screens/alerts/highway_alerts_screen.dart';
import 'screens/tips/daily_tips_screen.dart';
import 'screens/places/nearby_places_screen.dart';
import 'screens/streak/streak_screen.dart';
import 'screens/safety/selfie_verify_screen.dart';
import 'screens/admin/selfie_review_screen.dart';
import 'screens/breakdown/breakdown_location_picker_screen.dart';
import 'models/breakdown_request.dart';
import 'screens/shop/shop_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only Firebase must block before runApp — auth state unavailable without it.
  // Everything else (token, language, ads) loads after first frame.
  await Firebase.initializeApp();
  ApiService().init(); // init Dio immediately — token loaded in background

  // Non-blocking — doesn't delay startup
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // runApp() immediately after Firebase — UI appears in ~1s
  runApp(const ProviderScope(child: RaahiApp()));

  // Everything else loads in background — non-blocking
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await Future.wait([
      ApiService().loadToken(),
      LanguageService().loadSavedLanguage(),
    ]);
    AdService.initialize().then((_) {
      AdService().loadInterstitial();
      AdService().loadRewarded();
    });
  });
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(
      path: '/phone-login',
      builder: (context, state) => const PhoneLoginScreen(),
    ),
    GoRoute(path: '/login', builder: (_, __) => const PhoneLoginScreen()),
    GoRoute(
      path: '/otp',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return OtpScreen(
          verificationId: extra['verificationId'] as String,
          phone: extra['phone'] as String,
        );
      },
    ),
    GoRoute(path: '/profile-setup', builder: (_, __) => const ProfileSetupScreen()),

    // Main shell with bottom nav
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/home',        builder: (_, __) => const HomeScreen()),
        GoRoute(
      path: '/mechanics',
      builder: (_, state) {
        final req = state.extra as BreakdownRequest?;
        return MechanicsMapScreen(breakdownRequest: req);
      },
    ),
        GoRoute(path: '/ai-mechanic', builder: (_, __) => const AiMechanicScreen()),
        GoRoute(path: '/shop',        builder: (_, __) => const ShopScreen()),
        GoRoute(path: '/profile',     builder: (_, __) => const ProfileScreen()),
      ],
    ),

    // Standalone screens
    GoRoute(path: '/request-help',  builder: (_, __) => const RequestHelpScreen()),
    GoRoute(
      path: '/active-job/:id',
      builder: (_, state) => ActiveJobScreen(jobId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/job-offers',    builder: (_, __) => const JobOffersScreen()),
    GoRoute(
      path: '/mechanic/:id',
      builder: (_, state) => MechanicDetailScreen(mechanicId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/sos',               builder: (_, __) => const SosScreen()),
    GoRoute(path: '/mechanic-register', builder: (_, __) => const MechanicRegisterScreen()),
    GoRoute(path: '/subscription',      builder: (_, __) => const SubscriptionScreen()),
    GoRoute(path: '/emergency-contacts', builder: (_, __) => const EmergencyContactsScreen()),
    GoRoute(path: '/aadhaar-verify',     builder: (_, __) => const AadhaarVerifyScreen()),
    GoRoute(path: '/highway-alerts',     builder: (_, __) => const HighwayAlertsScreen()),
    GoRoute(path: '/daily-tips',         builder: (_, __) => const DailyTipsScreen()),
    GoRoute(path: '/nearby-places',      builder: (_, __) => const NearbyPlacesScreen()),
    GoRoute(path: '/streak',             builder: (_, __) => const StreakScreen()),
    GoRoute(path: '/selfie-verify',      builder: (_, __) => const SelfieVerifyScreen()),
    GoRoute(path: '/admin/selfie-review', builder: (_, __) => const SelfieReviewScreen()),
    GoRoute(
      path: '/breakdown-location',
      builder: (_, state) {
        final issue = state.extra as String? ?? '';
        return BreakdownLocationPickerScreen(initialIssue: issue);
      },
    ),

  ],
);

// ── RaahiApp: listens to LanguageService so MaterialApp rebuilds on lang change ──
class RaahiApp extends StatelessWidget {
  const RaahiApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService(),
      builder: (context, _) => MaterialApp.router(
        title: 'Raahi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        locale: Locale(LanguageService().currentCode),
        supportedLocales: LanguageService.supported
            .map((l) => Locale(l.code))
            .toList(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: _router,
      ),
    );
  }
}

// ── Bottom Nav Shell ──────────────────────────────────────────
class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final _routes = ['/home', '/mechanics', '/ai-mechanic', '/shop', '/profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _PremiumBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          context.go(_routes[i]);
        },
      ),
    );
  }
}

// ── Premium Bottom Navigation Bar ─────────────────────────────
class _PremiumBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _PremiumBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(Icons.home_rounded, Icons.home_outlined, 'Home'),
    _NavItem(Icons.build_rounded, Icons.build_outlined, 'Mechanics'),
    _NavItem(Icons.smart_toy_rounded, Icons.smart_toy_outlined, 'AI Help'),
    _NavItem(Icons.shopping_bag_rounded, Icons.shopping_bag_outlined, 'Shop'),
    _NavItem(Icons.person_rounded, Icons.person_outlined, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.navyLight,
        border: Border(top: BorderSide(color: AppTheme.cardBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: _items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final selected = i == currentIndex;

              if (i == 2) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          gradient: selected
                              ? AppTheme.primaryGradient
                              : const LinearGradient(
                                  colors: [AppTheme.surfaceHigh, AppTheme.cardBg]),
                          shape: BoxShape.circle,
                          boxShadow: selected ? AppTheme.primaryShadow : [],
                          border: Border.all(
                            color: selected ? AppTheme.primary : AppTheme.cardBorder,
                            width: selected ? 0 : 1),
                        ),
                        child: Icon(
                          selected ? item.activeIcon : item.icon,
                          color: selected ? Colors.white : AppTheme.textMuted,
                          size: 24),
                      ),
                    ),
                  ),
                );
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            selected ? item.activeIcon : item.icon,
                            key: ValueKey(selected),
                            color: selected ? AppTheme.primary : AppTheme.textMuted,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 3),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                            color: selected ? AppTheme.primary : AppTheme.textMuted,
                            letterSpacing: selected ? 0.3 : 0,
                          ),
                          child: Text(item.label),
                        ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: selected ? 16 : 0,
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData activeIcon, icon;
  final String label;
  const _NavItem(this.activeIcon, this.icon, this.label);
}
