// ============================================================
// lib/screens/splash_screen.dart  (UPDATED — Animated)
// ============================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late AnimationController _roadCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _roadAnim;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _roadCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    _logoScale = Tween(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.5)));

    _textFade = Tween(begin: 0.0, end: 1.0).animate(_textCtrl);
    _textSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    _roadAnim = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _roadCtrl, curve: Curves.easeInOut));

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _roadCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1800));
    _navigate();
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _roadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: Stack(
        children: [
          // Animated road lines at bottom
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: AnimatedBuilder(
              animation: _roadAnim,
              builder: (_, __) => CustomPaint(
                size: Size(MediaQuery.of(context).size.width, 200),
                painter: _RoadPainter(_roadAnim.value),
              ),
            ),
          ),

          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                AnimatedBuilder(
                  animation: _logoCtrl,
                  builder: (_, __) => FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: _buildLogo(),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // App name
                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Column(children: [
                      const Text(
                        'RAAHI',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.saffron.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppTheme.saffron.withOpacity(0.3)),
                        ),
                        child: const Text(
                          'Highway Driver Ka Saathi',
                          style: TextStyle(
                            color: AppTheme.saffron,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // Loading dots at bottom
          Positioned(
            bottom: 60, left: 0, right: 0,
            child: FadeTransition(
              opacity: _textFade,
              child: const Center(child: _LoadingDots()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 130, height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: AppTheme.saffron.withOpacity(0.5),
              blurRadius: 35, spreadRadius: 5),
          BoxShadow(color: AppTheme.saffron.withOpacity(0.2),
              blurRadius: 60, spreadRadius: 15),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.asset(
          'assets/icons/splash_logo.png',
          width: 130,
          height: 130,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// ── Road Painter ──────────────────────────────────────────────
class _RoadPainter extends CustomPainter {
  final double progress;
  _RoadPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1A2744);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.3, size.width, size.height), paint);

    // Road lines
    final linePaint = Paint()
      ..color = const Color(0xFF2A3F6B)
      ..strokeWidth = 2;

    for (int i = 0; i < 8; i++) {
      final y = size.height * 0.35 + i * 20.0;
      canvas.drawLine(Offset(0, y), Offset(size.width * progress, y), linePaint);
    }

    // Center dashes
    final dashPaint = Paint()
      ..color = AppTheme.saffron.withOpacity(0.4)
      ..strokeWidth = 3;

    final cx = size.width / 2;
    for (int i = 0; i < 5; i++) {
      final y = size.height * 0.38 + i * 28.0;
      final dashEnd = (progress * (i + 1) / 5).clamp(0.0, 1.0);
      if (dashEnd > 0) {
        canvas.drawLine(Offset(cx, y), Offset(cx, y + 16 * dashEnd), dashPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_RoadPainter old) => old.progress != progress;
}

// ── Loading Dots ──────────────────────────────────────────────
class _LoadingDots extends StatefulWidget {
  const _LoadingDots();
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final delay = i / 3;
          final t = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
          final scale = 0.5 + 0.5 * (t < 0.5 ? t * 2 : (1 - t) * 2);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8 * scale,
            height: 8 * scale,
            decoration: BoxDecoration(
              color: AppTheme.saffron.withOpacity(0.4 + 0.6 * scale),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}
