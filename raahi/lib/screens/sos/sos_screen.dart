// ============================================================
// lib/screens/sos/sos_screen.dart — SAFETY UPDATED
// + "I Feel Unsafe" button
// + Emergency contacts ko auto SMS
// + Police direct call
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/safety_service.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});
  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  bool _triggered = false;
  bool _loading   = false;
  int  _countdown = 5;
  Timer? _countdownTimer;
  bool _unsafeSent = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  Future<void> _triggerSos() async {
    setState(() => _loading = true);
    Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);
    final pos = await LocationService().getCurrentPosition();
    if (pos != null) {
      await ApiService().triggerSos(lat: pos.latitude, lng: pos.longitude);
      // Emergency contacts ko SMS bhejo
      await SafetyService().sendUnsafeAlert(lat: pos.latitude, lng: pos.longitude);
    }
    if (mounted) setState(() { _triggered = true; _loading = false; });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdown = 5);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown == 0) { t.cancel(); _triggerSos(); }
      else setState(() => _countdown--);
    });
  }

  // "Main Safe Nahi Hoon" — turant alert
  Future<void> _sendUnsafeAlert() async {
    setState(() => _loading = true);
    Vibration.vibrate(pattern: [0, 300, 100, 300]);
    final pos = await LocationService().getCurrentPosition();
    if (pos != null) {
      await SafetyService().sendUnsafeAlert(
        lat: pos.latitude, lng: pos.longitude,
      );
    }
    if (mounted) setState(() { _unsafeSent = true; _loading = false; });
  }

  Future<void> _callPolice() async {
    final uri = Uri.parse('tel:112');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () { _countdownTimer?.cancel(); context.pop(); },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: _triggered ? _buildTriggered() : _buildPre(),
        ),
      ),
    );
  }

  Widget _buildPre() => Column(
    children: [
      const Text('Emergency SOS',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary)),
      const SizedBox(height: 8),
      const Text('Nearby drivers aur emergency contacts ko turant alert karo',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
      const SizedBox(height: 48),

      // ── Pulsing SOS button ────────────────────────────────
      AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 200 + (_pulseCtrl.value * 30),
              height: 200 + (_pulseCtrl.value * 30),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.red.withOpacity(0.08 * (1 - _pulseCtrl.value)),
              ),
            ),
            Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.red.withOpacity(0.12),
              ),
            ),
            GestureDetector(
              onTap: _loading ? null : _startCountdown,
              child: Container(
                width: 150, height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                      colors: [Color(0xFFFF4444), AppTheme.red]),
                  boxShadow: [BoxShadow(
                      color: AppTheme.red.withOpacity(0.5),
                      blurRadius: 30, spreadRadius: 5)],
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : _countdownTimer != null && _countdown > 0
                    ? Column(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$_countdown', style: const TextStyle(
                          color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
                      const Text('Roko', style: TextStyle(
                          color: Colors.white70, fontSize: 12)),
                    ])
                    : const Column(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emergency_rounded, color: Colors.white, size: 40),
                      SizedBox(height: 4),
                      Text('SOS', style: TextStyle(color: Colors.white,
                          fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 4)),
                    ]),
              ),
            ),
          ],
        ),
      ),

      if (_countdownTimer != null && _countdown > 0) ...[
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () {
            _countdownTimer?.cancel();
            setState(() { _countdown = 5; _countdownTimer = null; });
          },
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.red),
              foregroundColor: AppTheme.red),
          child: const Text('Cancel Karo'),
        ),
      ],

      const SizedBox(height: 40),

      // ── "I Feel Unsafe" button ────────────────────────────
      GestureDetector(
        onTap: _loading ? null : () => _showUnsafeDialog(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF7C3AED).withOpacity(0.2),
                AppTheme.red.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.5), width: 1.5),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_rounded,
                  color: Color(0xFF7C3AED), size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Main Safe Nahi Hoon 🆘',
                    style: TextStyle(color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800, fontSize: 15)),
                SizedBox(height: 3),
                Text('Trusted contacts ko location + alert turant bhejega',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            )),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Color(0xFF7C3AED), size: 16),
          ]),
        ),
      ),

      const SizedBox(height: 16),

      // ── Police direct call ────────────────────────────────
      GestureDetector(
        onTap: _callPolice,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: const Row(children: [
            Icon(Icons.local_police_rounded, color: AppTheme.cyan, size: 24),
            SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Police — 112', style: TextStyle(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w700,
                  fontSize: 15)),
              Text('Seedha call karo', style: TextStyle(
                  color: AppTheme.textMuted, fontSize: 12)),
            ]),
            Spacer(),
            Icon(Icons.phone_rounded, color: AppTheme.cyan),
          ]),
        ),
      ),

      const SizedBox(height: 24),
      const Text('Nearby drivers + emergency contacts ko alert jaayega',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
    ],
  );

  void _showUnsafeDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.navyLight,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.cardBorder,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Icon(Icons.shield_rounded,
              color: Color(0xFF7C3AED), size: 48),
          const SizedBox(height: 16),
          const Text('Safety Alert Bhejein?',
              style: TextStyle(color: AppTheme.textPrimary,
                  fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
            'Tumhare emergency contacts ko tumhari current location aur helper ki details SMS ho jaayengi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.cardBorder),
                  foregroundColor: AppTheme.textMuted),
              child: const Text('Cancel'),
            )),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _sendUnsafeAlert();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED)),
              child: const Text('Haan, Alert Bhejo 🆘',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            )),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _buildTriggered() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const SizedBox(height: 40),
      const Icon(Icons.check_circle_rounded, color: AppTheme.green, size: 80),
      const SizedBox(height: 24),
      const Text('Alert Send Ho Gaya! 🚨',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      const Text(
        'Nearby drivers aur tumhare emergency contacts ko turant alert bheja ja raha hai.\n\nSafe jagah raho. Help aa rahi hai!',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.6),
      ),
      const SizedBox(height: 40),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: () => context.go('/home'),
        child: const Text('Home Jao'),
      )),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(
        onPressed: _callPolice,
        icon: const Icon(Icons.phone_rounded),
        label: const Text('112 — Police Call Karo'),
        style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.red),
            foregroundColor: AppTheme.red),
      )),
    ],
  );
}
