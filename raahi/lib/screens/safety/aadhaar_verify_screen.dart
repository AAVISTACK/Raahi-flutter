// ============================================================
// lib/screens/safety/aadhaar_verify_screen.dart
// Surepass Aadhaar Verification — Real API
// Flow: Enter Aadhaar → OTP on registered mobile → Verify → VERIFIED tier
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class AadhaarVerifyScreen extends StatefulWidget {
  const AadhaarVerifyScreen({super.key});
  @override
  State<AadhaarVerifyScreen> createState() => _AadhaarVerifyScreenState();
}

class _AadhaarVerifyScreenState extends State<AadhaarVerifyScreen> {
  final _aadhaarCtrl = TextEditingController();
  final _otpCtrl     = TextEditingController();
  final _api         = ApiService();

  // State
  bool   _loading      = false;
  bool   _otpSent      = false;
  bool   _verified     = false;
  String _clientId     = '';       // Surepass client_id — OTP verify ke liye
  String _maskedPhone  = '';
  String _verifiedName = '';
  String _error        = '';

  // ── Send OTP ─────────────────────────────────────────────
  Future<void> _sendOtp() async {
    final aadhaar = _aadhaarCtrl.text.replaceAll(' ', '').trim();
    if (aadhaar.length != 12) {
      _setError('12 digit Aadhaar number daalo');
      return;
    }

    setState(() { _loading = true; _error = ''; });

    try {
      final res = await _api.post('/aadhaar/send-otp', {
        'aadhaarNumber': aadhaar,
      });

      setState(() {
        _loading     = false;
        _otpSent     = true;
        _clientId    = res['clientId'] ?? '';
        _maskedPhone = res['maskedPhone'] ?? 'registered number pe';
      });

      _snack('✅ OTP bheja gaya: $_maskedPhone', isSuccess: true);

    } catch (e) {
      setState(() => _loading = false);
      _setError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ── Verify OTP ───────────────────────────────────────────
  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      _setError('6 digit OTP daalo');
      return;
    }
    if (_clientId.isEmpty) {
      _setError('Session expire ho gayi. Pehle OTP dobara request karo.');
      return;
    }

    setState(() { _loading = true; _error = ''; });

    try {
      final res = await _api.post('/aadhaar/verify-otp', {
        'aadhaarNumber': _aadhaarCtrl.text.replaceAll(' ', '').trim(),
        'clientId':      _clientId,
        'otp':           otp,
      });

      setState(() {
        _loading      = false;
        _verified     = true;
        _verifiedName = res['verifiedName'] ?? '';
      });

    } catch (e) {
      setState(() => _loading = false);
      _setError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _setError(String msg) => setState(() => _error = msg);

  void _snack(String msg, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isSuccess ? AppTheme.green : AppTheme.navyLight,
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  void dispose() {
    _aadhaarCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        backgroundColor: AppTheme.navyLight,
        title: const Text('Aadhaar Verification',
            style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: _verified ? _buildSuccess() : _buildForm(),
    );
  }

  // ── Success Screen ────────────────────────────────────────
  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.green.withOpacity(0.15),
                border: Border.all(color: AppTheme.green.withOpacity(0.4), width: 2),
              ),
              child: const Icon(Icons.verified_user, color: AppTheme.green, size: 44),
            ),
            const SizedBox(height: 24),
            Text('Aadhaar Verified! 🎉',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.green, fontFamily: 'Rajdhani', fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (_verifiedName.isNotEmpty) ...[
              Text(_verifiedName,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
            ],
            const Text('Ab tumhara account VERIFIED tier pe hai.\nHighway jobs bhi apply kar sakte ho.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.6)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.green.withOpacity(0.3)),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.shield, color: AppTheme.green, size: 16),
                SizedBox(width: 6),
                Text('VERIFIED', style: TextStyle(color: AppTheme.green,
                    fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.5)),
              ]),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Profile Pe Wapas Jao',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main Form ─────────────────────────────────────────────
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Info banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.verified_user, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text('Kyun Zaroori Hai?',
                  style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 15)),
            ]),
            const SizedBox(height: 10),
            _infoRow(Icons.lock_open, 'Highway jobs apply kar sakte ho'),
            _infoRow(Icons.shield, 'Trusted Helper badge milega'),
            _infoRow(Icons.star, 'Trust score +20 boost'),
            _infoRow(Icons.security, 'Dono parties ke liye safety'),
          ]),
        ),
        const SizedBox(height: 24),

        // Privacy note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.navyLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          child: const Row(children: [
            Icon(Icons.privacy_tip_outlined, color: AppTheme.textSecondary, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Aadhaar number encrypted store hota hai. Raw number kabhi save nahi hota.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            )),
          ]),
        ),
        const SizedBox(height: 24),

        // ── Step 1: Aadhaar Number ──
        _stepHeader('1', 'Aadhaar Number Daalo', !_otpSent),
        const SizedBox(height: 12),
        TextField(
          controller: _aadhaarCtrl,
          enabled: !_otpSent,
          keyboardType: TextInputType.number,
          maxLength:    14, // 12 digits + 2 spaces
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _AadhaarFormatter(), // Auto space after every 4 digits
          ],
          style: const TextStyle(
            color: AppTheme.textPrimary,
            letterSpacing: 2,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'XXXX XXXX XXXX',
            hintStyle: TextStyle(color: AppTheme.muted, letterSpacing: 2, fontSize: 18),
            prefixIcon: const Icon(Icons.credit_card, color: AppTheme.primary),
            filled: true,
            fillColor: AppTheme.navyLight,
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.6), width: 1.5),
            ),
          ),
        ),

        if (!_otpSent) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _sendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                disabledBackgroundColor: AppTheme.primary.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('OTP Bhejo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],

        // ── Step 2: OTP ──
        if (_otpSent) ...[
          const SizedBox(height: 24),
          _stepHeader('2', 'OTP Daalo', true),
          const SizedBox(height: 6),
          Text('OTP bheja gaya: $_maskedPhone',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength:    6,
            textAlign:    TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              color: AppTheme.textPrimary,
              letterSpacing: 8,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: '------',
              hintStyle: TextStyle(color: AppTheme.muted, letterSpacing: 8, fontSize: 22),
              counterText: '',
              filled: true,
              fillColor: AppTheme.navyLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.6), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.green,
                disabledBackgroundColor: AppTheme.green.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Verify Karo ✓',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
            ),
          ),
          const SizedBox(height: 12),
          // Resend OTP
          Center(
            child: TextButton(
              onPressed: _loading ? null : () {
                setState(() { _otpSent = false; _otpCtrl.clear(); _clientId = ''; });
              },
              child: const Text('Naya OTP Request Karo',
                  style: TextStyle(color: AppTheme.primary, fontSize: 13)),
            ),
          ),
        ],

        // Error message
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.red.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline, color: AppTheme.red, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(_error,
                  style: const TextStyle(color: AppTheme.red, fontSize: 13))),
            ]),
          ),
        ],

        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(icon, color: AppTheme.primary, size: 14),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      ]),
    );
  }

  Widget _stepHeader(String num, String title, bool active) {
    return Row(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? AppTheme.primary : AppTheme.muted.withOpacity(0.3),
        ),
        child: Center(child: Text(num,
            style: TextStyle(
              color: active ? Colors.white : AppTheme.muted,
              fontWeight: FontWeight.w800, fontSize: 14,
            ))),
      ),
      const SizedBox(width: 10),
      Text(title, style: TextStyle(
        color: active ? AppTheme.textPrimary : AppTheme.muted,
        fontWeight: FontWeight.w700, fontSize: 16,
      )),
    ]);
  }
}

// ── Aadhaar Number Formatter (XXXX XXXX XXXX) ──────────────
class _AadhaarFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 12; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
