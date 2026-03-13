// ============================================================
// lib/screens/onboarding_screen.dart  (UPDATED — Illustrations)
// 3 screens with custom SVG-style Flutter illustrations
// ============================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  final _pages = const [
    _OBPage(
      illustration: _P2PIllustration(),
      title: 'Highway pe Akele Nahi Ho',
      subtitle: 'Puncture? Fuel khatam? Koi bhi problem — nearby driver ko call karo. 2 minute mein help milegi.',
      color: AppTheme.saffron,
    ),
    _OBPage(
      illustration: _MechanicIllustration(),
      title: 'Mechanic Dhundhna Aasaan',
      subtitle: 'GPS se aas-paas ki workshops dikhengi — rating, distance, speciality sab ek jagah.',
      color: AppTheme.cyan,
    ),
    _OBPage(
      illustration: _AIIllustration(),
      title: 'Raahi Bhaiya — AI Sahayak',
      subtitle: 'Gaadi ki koi bhi problem — voice mein poochho. Hindi, Punjabi, Tamil — apni zubaan mein jawab milega.',
      color: AppTheme.green,
    ),
  ];

  @override
  void dispose() { _pageCtrl.dispose(); super.dispose(); }

  void _next() {
    if (_page < _pages.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut);
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: Column(children: [
          // Skip button
          Align(
            alignment: Alignment.topRight,
            child: TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Skip →',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            ),
          ),

          // Pages
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _page = i),
              itemCount: _pages.length,
              itemBuilder: (_, i) => _pages[i],
            ),
          ),

          // Dots + Button
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
            child: Column(children: [
              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? _pages[_page].color
                          : AppTheme.cardBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Next / Get Started button
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pages[_page].color,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    shadowColor: _pages[_page].color.withOpacity(0.4),
                  ),
                  child: Text(
                    _page == _pages.length - 1
                        ? 'Shuru Karo  🚀'
                        : 'Aage →',
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Page Widget ───────────────────────────────────────────────
class _OBPage extends StatelessWidget {
  final Widget illustration;
  final String title;
  final String subtitle;
  final Color color;

  const _OBPage({
    required this.illustration,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          SizedBox(height: 280, child: illustration),
          const SizedBox(height: 40),

          // Title
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.2,
              )),
          const SizedBox(height: 14),

          // Subtitle
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.6,
              )),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// ILLUSTRATION 1 — P2P Help (two cars on highway)
// ════════════════════════════════════════════════════════════
class _P2PIllustration extends StatefulWidget {
  const _P2PIllustration();
  @override
  State<_P2PIllustration> createState() => _P2PIllustrationState();
}

class _P2PIllustrationState extends State<_P2PIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _float = Tween(begin: -8.0, end: 8.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (_, __) => CustomPaint(
        size: const Size(double.infinity, 280),
        painter: _P2PPainter(_float.value),
      ),
    );
  }
}

class _P2PPainter extends CustomPainter {
  final double floatY;
  _P2PPainter(this.floatY);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Background glow
    final glowPaint = Paint()
      ..color = AppTheme.saffron.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(Offset(cx, cy), 120, glowPaint);

    // Road
    _drawRoad(canvas, size);

    // Car 1 — stuck (left, with SOS triangle)
    _drawCar(canvas, Offset(cx - 70, cy - 10 + floatY * 0.3),
        const Color(0xFF1E3A5F), false);
    // SOS triangle above car 1
    _drawSOSBadge(canvas, Offset(cx - 70, cy - 55 + floatY * 0.3));

    // Car 2 — helper (right, moving toward)
    _drawCar(canvas, Offset(cx + 60, cy - 10 - floatY * 0.5),
        AppTheme.saffron, true);

    // Connection line / signal
    _drawSignal(canvas, Offset(cx - 70, cy - 30), Offset(cx + 60, cy - 30));

    // Stars / sparkles
    _drawSparkles(canvas, size, floatY);
  }

  void _drawRoad(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final roadY = size.height * 0.65;

    final paint = Paint()..color = const Color(0xFF1A2744);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(20, roadY, size.width - 40, 50),
            const Radius.circular(8)),
        paint);

    // Dashes
    final dash = Paint()
      ..color = AppTheme.saffron.withOpacity(0.5)
      ..strokeWidth = 3;
    for (int i = 0; i < 6; i++) {
      final x = 40.0 + i * ((size.width - 80) / 6);
      canvas.drawLine(Offset(x, roadY + 25), Offset(x + 20, roadY + 25), dash);
    }
  }

  void _drawCar(Canvas canvas, Offset pos, Color color, bool flip) {
    final w = 80.0, h = 44.0;
    final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: pos.translate(0, h * 0.2),
            width: w, height: h * 0.55),
        const Radius.circular(6));
    canvas.drawRRect(rect, Paint()..color = color);

    // Cabin
    final cabinW = w * 0.55, cabinH = h * 0.45;
    final cabinX = pos.dx - cabinW / 2;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cabinX, pos.dy - h * 0.3, cabinW, cabinH),
            const Radius.circular(5)),
        Paint()..color = color);

    // Window
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cabinX + 6, pos.dy - h * 0.26,
                cabinW - 12, cabinH * 0.65),
            const Radius.circular(3)),
        Paint()..color = AppTheme.navy.withOpacity(0.7));

    // Wheels
    for (final wx in [pos.dx - 22.0, pos.dx + 22.0]) {
      final wy = pos.dy + h * 0.35;
      canvas.drawCircle(Offset(wx, wy), 12,
          Paint()..color = const Color(0xFF0D1B2A));
      canvas.drawCircle(Offset(wx, wy), 6,
          Paint()..color = Colors.grey.shade500);
    }

    // Headlights
    if (!flip) {
      canvas.drawCircle(Offset(pos.dx - w/2 + 8, pos.dy + h * 0.05),
          5, Paint()..color = const Color(0xFFFFF9C4).withOpacity(0.8));
    } else {
      canvas.drawCircle(Offset(pos.dx + w/2 - 8, pos.dy + h * 0.05),
          5, Paint()..color = const Color(0xFFFFF9C4).withOpacity(0.8));
    }
  }

  void _drawSOSBadge(Canvas canvas, Offset pos) {
    final paint = Paint()..color = AppTheme.red;
    // Triangle
    final path = Path()
      ..moveTo(pos.dx, pos.dy - 18)
      ..lineTo(pos.dx - 14, pos.dy + 2)
      ..lineTo(pos.dx + 14, pos.dy + 2)
      ..close();
    canvas.drawPath(path, paint);

    // ! mark
    final textPainter = TextPainter(
      text: const TextSpan(text: '!',
          style: TextStyle(color: Colors.white, fontSize: 11,
              fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(pos.dx - 4, pos.dy - 14));
  }

  void _drawSignal(Canvas canvas, Offset from, Offset to) {
    final paint = Paint()
      ..color = AppTheme.green.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // Dashed line
    final dx = to.dx - from.dx;
    for (int i = 0; i < 5; i++) {
      final t1 = i / 5.0;
      final t2 = (i + 0.6) / 5.0;
      canvas.drawLine(
        Offset(from.dx + dx * t1, from.dy),
        Offset(from.dx + dx * t2, from.dy),
        paint,
      );
    }
    // Signal dots
    canvas.drawCircle(Offset(from.dx + dx * 0.5, from.dy - 12), 4,
        Paint()..color = AppTheme.green.withOpacity(0.8));
    canvas.drawCircle(Offset(from.dx + dx * 0.5, from.dy - 12), 8,
        Paint()
          ..color = AppTheme.green.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  void _drawSparkles(Canvas canvas, Size size, double floatY) {
    final positions = [
      Offset(size.width * 0.15, size.height * 0.2 + floatY * 0.2),
      Offset(size.width * 0.82, size.height * 0.18 - floatY * 0.3),
      Offset(size.width * 0.72, size.height * 0.55 + floatY * 0.15),
    ];
    for (final p in positions) {
      canvas.drawCircle(p, 3,
          Paint()..color = AppTheme.yellow.withOpacity(0.6));
      canvas.drawCircle(p, 6,
          Paint()
            ..color = AppTheme.yellow.withOpacity(0.2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
    }
  }

  @override
  bool shouldRepaint(_P2PPainter old) => old.floatY != floatY;
}

// ════════════════════════════════════════════════════════════
// ILLUSTRATION 2 — Mechanic Map
// ════════════════════════════════════════════════════════════
class _MechanicIllustration extends StatefulWidget {
  const _MechanicIllustration();
  @override
  State<_MechanicIllustration> createState() => _MechanicIllustrationState();
}

class _MechanicIllustrationState extends State<_MechanicIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500))
      ..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => CustomPaint(
      size: const Size(double.infinity, 280),
      painter: _MapPainter(_ctrl.value),
    ),
  );
}

class _MapPainter extends CustomPainter {
  final double t;
  _MapPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Map background
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: 240, height: 200),
            const Radius.circular(16)),
        Paint()..color = const Color(0xFF0D1B2A));

    // Map grid lines
    final gridP = Paint()
      ..color = const Color(0xFF1A2744)
      ..strokeWidth = 1;
    for (int i = 1; i < 5; i++) {
      canvas.drawLine(Offset(cx - 120 + i * 48, cy - 100),
          Offset(cx - 120 + i * 48, cy + 100), gridP);
    }
    for (int i = 1; i < 4; i++) {
      canvas.drawLine(Offset(cx - 120, cy - 100 + i * 50),
          Offset(cx + 120, cy - 100 + i * 50), gridP);
    }

    // Roads
    final roadP = Paint()
      ..color = const Color(0xFF1E3A5F)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 120, cy), Offset(cx + 120, cy), roadP);
    canvas.drawLine(Offset(cx, cy - 100), Offset(cx, cy + 100), roadP);
    canvas.drawLine(Offset(cx - 80, cy - 60), Offset(cx + 60, cy + 50), roadP);

    // Mechanic pins (with pulse)
    final mechanics = [
      Offset(cx - 50, cy - 30),
      Offset(cx + 55, cy + 20),
      Offset(cx - 20, cy + 55),
    ];

    for (int i = 0; i < mechanics.length; i++) {
      final pulse = ((t + i * 0.33) % 1.0);
      // Pulse ring
      canvas.drawCircle(mechanics[i], 10 + pulse * 20,
          Paint()
            ..color = AppTheme.cyan.withOpacity((1 - pulse) * 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      // Pin
      canvas.drawCircle(mechanics[i], 10,
          Paint()..color = AppTheme.cyan);
      // Wrench icon approximation
      final textP = TextPainter(
        text: const TextSpan(text: '🔧',
            style: TextStyle(fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      textP.paint(canvas, mechanics[i].translate(-6, -6));
    }

    // User location (you)
    final userPos = Offset(cx + 10, cy - 10);
    canvas.drawCircle(userPos, 14,
        Paint()..color = AppTheme.saffron);
    canvas.drawCircle(userPos, 14,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    final youP = TextPainter(
      text: const TextSpan(text: '📍',
          style: TextStyle(fontSize: 12)),
      textDirection: TextDirection.ltr,
    )..layout();
    youP.paint(canvas, userPos.translate(-7, -8));

    // Distance lines
    final distP = Paint()
      ..color = AppTheme.saffron.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (final m in mechanics) {
      canvas.drawLine(userPos, m, distP);
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.t != t;
}

// ════════════════════════════════════════════════════════════
// ILLUSTRATION 3 — AI Chat
// ════════════════════════════════════════════════════════════
class _AIIllustration extends StatefulWidget {
  const _AIIllustration();
  @override
  State<_AIIllustration> createState() => _AIIllustrationState();
}

class _AIIllustrationState extends State<_AIIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => CustomPaint(
      size: const Size(double.infinity, 280),
      painter: _AIPainter(_ctrl.value),
    ),
  );
}

class _AIPainter extends CustomPainter {
  final double t;
  _AIPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // AI Bot head
    final botCenter = Offset(cx, cy - 30);
    // Glow
    canvas.drawCircle(botCenter, 55,
        Paint()
          ..color = AppTheme.green.withOpacity(0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));

    canvas.drawCircle(botCenter, 48,
        Paint()..color = const Color(0xFF0D1B2A));
    canvas.drawCircle(botCenter, 48,
        Paint()
          ..color = AppTheme.green.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);

    // Face
    final textP = TextPainter(
      text: const TextSpan(text: '🤖',
          style: TextStyle(fontSize: 44)),
      textDirection: TextDirection.ltr,
    )..layout();
    textP.paint(canvas, botCenter.translate(-22, -24));

    // Rotating orbit
    final orbitR = 68.0;
    final orbitPaint = Paint()
      ..color = AppTheme.green.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(botCenter, orbitR, orbitPaint);

    final orbitAngle = t * 2 * 3.14159;
    final orbitDot = botCenter.translate(
        orbitR * (0 + 1 * _cos(orbitAngle)),
        orbitR * _sin(orbitAngle));
    canvas.drawCircle(orbitDot, 5,
        Paint()..color = AppTheme.green.withOpacity(0.8));

    // Chat bubbles
    _drawBubble(canvas,
        'Engine ki awaaz aa rahi hai...',
        Offset(cx - 80, cy + 42), false, t);
    _drawBubble(canvas,
        'Oil check karo bhai! 🔧',
        Offset(cx + 10, cy + 82), true, (t + 0.5) % 1.0);

    // Sound waves (voice)
    for (int i = 1; i <= 3; i++) {
      final waveT = (t * 2 + i * 0.2) % 1.0;
      canvas.drawArc(
          Rect.fromCenter(center: Offset(cx - 90, cy - 30),
              width: 20.0 + i * 14, height: 20.0 + i * 14),
          -0.8, 1.6, false,
          Paint()
            ..color = AppTheme.saffron.withOpacity((1 - waveT) * 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
  }

  void _drawBubble(Canvas canvas, String text, Offset pos, bool isAI, double anim) {
    final opacity = 0.7 + 0.3 * ((anim * 2 * 3.14159).abs() % 1.0);
    final bubbleW = 150.0, bubbleH = 32.0;
    final color = isAI ? AppTheme.green : const Color(0xFF1E3A5F);

    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(pos.dx - bubbleW/2, pos.dy, bubbleW, bubbleH),
            const Radius.circular(12)),
        Paint()..color = color.withOpacity(opacity * 0.9));

    final tp = TextPainter(
      text: TextSpan(text: text,
          style: TextStyle(color: Colors.white.withOpacity(opacity),
              fontSize: 9, fontWeight: FontWeight.w500)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: bubbleW - 12);
    tp.paint(canvas, pos.translate(-tp.width/2, 9));
  }

  double _sin(double a) => (a - 1.5708).abs() < 0.001 ? 1.0 :
      (a < 3.14159 ? a / 3.14159 * 2 - 1 : 3 - a / 3.14159 * 2).clamp(-1.0, 1.0);
  double _cos(double a) => _sin(a + 1.5708);

  @override
  bool shouldRepaint(_AIPainter old) => old.t != t;
}
