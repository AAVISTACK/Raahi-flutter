import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ── Controllers ─────────────────────────────────────────────
  late AnimationController _mainCtrl;   // 0-1400 ms, one-shot
  late AnimationController _pulseCtrl;  // loops after icon appears
  late AnimationController _dotsCtrl;   // loops after sequence ends

  // ── Main-sequence animations ─────────────────────────────────
  late Animation<double> _bgOpacity;
  late Animation<double> _iconOpacity;
  late Animation<double> _iconScale;
  late Animation<double> _textOpacity;
  late Animation<Offset>  _textSlide;
  late Animation<double> _taglineOpacity;

  // ── Continuous animations ────────────────────────────────────
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // ── Main sequence: 1 400 ms total ──────────────────────────
    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // 0 – 300 ms : background fade-in
    _bgOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.000, 0.214, curve: Curves.easeIn),
      ),
    );

    // 300 – 800 ms : icon opacity
    _iconOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.214, 0.400, curve: Curves.easeIn),
      ),
    );

    // 300 – 800 ms : icon scale with bounce
    _iconScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.214, 0.571),
      ),
    );

    // 800 – 1 100 ms : text slide-up + fade-in
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.571, 0.786, curve: Curves.easeIn),
      ),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.571, 0.786, curve: Curves.easeOutCubic),
      ),
    );

    // 1 100 – 1 400 ms : tagline fade-in
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.786, 1.000, curve: Curves.easeIn),
      ),
    );

    _mainCtrl.forward();

    // ── Pulse: starts when icon finishes appearing (800 ms) ────
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _pulseCtrl.repeat(reverse: true);
    });

    // ── Dots: start after main sequence (1 400 ms) ─────────────
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) _dotsCtrl.repeat();
    });

    // ── Navigate after 3 500 ms — check auth first ─────────────
    Future.delayed(const Duration(milliseconds: 3500), () async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (!mounted) return;
      if (token != null && token.isNotEmpty) {
        context.go('/home');
      } else {
        context.go('/phone-login');
      }
    });
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _pulseCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  // Smooth sin-wave phase for each dot (0..1 per cycle)
  double _dotOpacity(int index) {
    final phase = (_dotsCtrl.value - index / 3.0 + 1.0) % 1.0;
    return 0.25 + 0.75 * sin(phase * pi).clamp(0.0, 1.0);
  }

  double _dotScale(int index) {
    final phase = (_dotsCtrl.value - index / 3.0 + 1.0) % 1.0;
    return 1.0 + 0.55 * sin(phase * pi).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: AnimatedBuilder(
        animation: Listenable.merge([_mainCtrl, _pulseCtrl, _dotsCtrl]),
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0A0E21).withOpacity(_bgOpacity.value),
                  const Color(0xFF16213E).withOpacity(_bgOpacity.value),
                ],
              ),
              color: const Color(0xFF0A0E21),
            ),
            child: SizedBox.expand(
              child: Stack(
                children: [
                  // Centered main content
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon
                        Opacity(
                          opacity: _iconOpacity.value,
                          child: Transform.scale(
                            scale: _iconScale.value * _pulseScale.value,
                            child: SizedBox(
                              width: 120,
                              height: 120,
                              child: CustomPaint(painter: _RaahiIconPainter()),
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // App name
                        FadeTransition(
                          opacity: _textOpacity,
                          child: SlideTransition(
                            position: _textSlide,
                            child: const Text(
                              'Raahi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 4.0,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Tagline
                        FadeTransition(
                          opacity: _taglineOpacity,
                          child: const Text(
                            'Your Roadside Companion',
                            style: TextStyle(
                              color: Color(0xFF00D4AA),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Animated dots at bottom
                  Positioned(
                    bottom: 48,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: FadeTransition(
                        opacity: _taglineOpacity,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: List.generate(3, (i) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              child: Transform.scale(
                                scale: _dotScale(i),
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00D4AA)
                                        .withOpacity(_dotOpacity(i)),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Custom Icon Painter ────────────────────────────────────────
class _RaahiIconPainter extends CustomPainter {
  const _RaahiIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx  = size.width  / 2;
    final cy  = size.height / 2;
    final r   = size.width  / 2;

    // ── Background circle ────────────────────────────────────
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 1.1,
        colors: const [Color(0xFF1E3A6E), Color(0xFF090F20)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    // Subtle outer ring
    canvas.drawCircle(
      Offset(cx, cy), r - 1,
      Paint()
        ..color = const Color(0xFF2A4070)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // ── Road (clip to circle first) ──────────────────────────
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r - 1)),
    );

    final horizonY     = cy + 6.0;
    final roadBottomY  = size.height - 4.0;

    // Road surface
    final roadPath = Path()
      ..moveTo(cx - 6,               horizonY)
      ..lineTo(cx + 6,               horizonY)
      ..lineTo(cx + size.width * 0.44, roadBottomY)
      ..lineTo(cx - size.width * 0.44, roadBottomY)
      ..close();

    canvas.drawPath(
      roadPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF1B2A42), Color(0xFF253B58)],
        ).createShader(Rect.fromLTRB(0, horizonY, size.width, roadBottomY)),
    );

    // Road edge lines (perspective)
    final edgePaint = Paint()
      ..color = const Color(0xFF3D5580)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(roadPath, edgePaint);

    // White shoulder lines
    final shoulderPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx - 6,                horizonY),
      Offset(cx - size.width * 0.44, roadBottomY),
      shoulderPaint,
    );
    canvas.drawLine(
      Offset(cx + 6,                horizonY),
      Offset(cx + size.width * 0.44, roadBottomY),
      shoulderPaint,
    );

    // Center dashes (perspective-scaled)
    final dashPaint = Paint()
      ..color = const Color(0xFFFFC107).withOpacity(0.9)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // [topY, bottomY] pairs — smaller near horizon, bigger near bottom
    final dashSegs = [
      [horizonY + 3,  horizonY + 9],
      [horizonY + 14, horizonY + 24],
      [horizonY + 32, horizonY + 47],
    ];
    for (final d in dashSegs) {
      canvas.drawLine(Offset(cx, d[0]), Offset(cx, d[1]), dashPaint);
    }

    canvas.restore(); // end road clip

    // ── Location pin ────────────────────────────────────────
    final pinCx  = cx;
    final pinCy  = cy - 16.0;
    final pinR   = 20.0;

    // Soft glow
    canvas.drawCircle(
      Offset(pinCx, pinCy), pinR + 8,
      Paint()
        ..color = const Color(0xFF00D4AA).withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Pin tail (smooth teardrop)
    final tailTop    = pinCy + pinR * 0.68;
    final tailBottom = pinCy + pinR * 1.70;
    final tailPath = Path()
      ..moveTo(pinCx - pinR * 0.44, tailTop)
      ..quadraticBezierTo(pinCx - pinR * 0.12, tailTop + (tailBottom - tailTop) * 0.6,
                          pinCx, tailBottom)
      ..quadraticBezierTo(pinCx + pinR * 0.12, tailTop + (tailBottom - tailTop) * 0.6,
                          pinCx + pinR * 0.44, tailTop)
      ..close();
    canvas.drawPath(
      tailPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF00B896), Color(0xFF006655)],
        ).createShader(Rect.fromLTRB(
          pinCx - pinR, tailTop, pinCx + pinR, tailBottom,
        )),
    );

    // Pin circle
    canvas.drawCircle(
      Offset(pinCx, pinCy), pinR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.0,
          colors: const [Color(0xFF00E5BB), Color(0xFF009980)],
        ).createShader(
          Rect.fromCircle(center: Offset(pinCx, pinCy), radius: pinR),
        ),
    );

    // White ring
    canvas.drawCircle(
      Offset(pinCx, pinCy), pinR * 0.67,
      Paint()..color = Colors.white.withOpacity(0.95),
    );

    // Teal inner fill
    canvas.drawCircle(
      Offset(pinCx, pinCy), pinR * 0.53,
      Paint()..color = const Color(0xFF00B896),
    );

    // ── Wrench inside pin ─────────────────────────────────────
    _drawWrench(canvas, pinCx, pinCy, pinR * 0.38);
  }

  void _drawWrench(Canvas canvas, double cx, double cy, double size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = size * 0.30
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Handle: diagonal from lower-right to upper-left
    canvas.drawLine(
      Offset(cx + size * 0.28, cy + size * 0.28),
      Offset(cx - size * 0.12, cy - size * 0.12),
      paint,
    );

    // Head: open arc (wrench jaw) at upper-left
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(cx - size * 0.20, cy - size * 0.20),
        radius: size * 0.34,
      ),
      0.65,
      4.60,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RaahiIconPainter old) => false;
}
