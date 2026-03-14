import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String verificationId;

  const OtpScreen({
    super.key,
    required this.phone,
    required this.verificationId,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  int _resendSeconds = 60;
  Timer? _timer;
  late String _currentVerificationId;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendSeconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_resendSeconds == 0) {
        t.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  // ── Verify OTP via Firebase ──────────────────────────────
  Future<void> _verify() async {
    if (_otp.length != 6) return;
    setState(() => _loading = true);

    try {
      // Firebase credential banao OTP se
      final credential = PhoneAuthProvider.credential(
        verificationId: _currentVerificationId,
        smsCode: _otp,
      );

      // Firebase se sign in karo
      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken  = await userCred.user!.getIdToken();

      // Backend ko idToken bhejo → apna JWT lo
      final res = await ApiService().verifyOtp(widget.phone, idToken!);
      final token     = res['token'] as String;
      final isNewUser = res['is_new_user'] as bool? ?? false;

      await ApiService().setToken(token);

      if (mounted) {
        isNewUser ? context.go('/profile-setup') : context.go('/home');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final msg = e.code == 'invalid-verification-code'
            ? 'Galat OTP hai. Dobara check karo.'
            : e.code == 'session-expired'
                ? 'OTP expire ho gaya. Resend karo.'
                : 'Error: ${e.message}';
        _showError(msg);
      }
    } catch (e) {
      if (mounted) _showError('Kuch problem aayi. Dobara try karo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Resend OTP ───────────────────────────────────────────
  Future<void> _resendOtp() async {
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
        final idToken  = await userCred.user!.getIdToken();
        final res = await ApiService().verifyOtp(widget.phone, idToken!);
        await ApiService().setToken(res['token'] as String);
        final isNewUser = res['is_new_user'] as bool? ?? false;
        if (mounted) isNewUser ? context.go('/profile-setup') : context.go('/home');
      },
      verificationFailed: (e) {
        if (mounted) _showError('OTP bhejne mein error. Dobara try karo.');
      },
      codeSent: (String newVerificationId, int? _) {
        _currentVerificationId = newVerificationId;
        _startResendTimer();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Naya OTP bheja gaya!')),
          );
        }
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade800),
    );
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
  }

  void _onDigitEntered(int index, String value) {
    if (value.isNotEmpty && index < 5) _focusNodes[index + 1].requestFocus();
    if (value.isEmpty && index > 0)   _focusNodes[index - 1].requestFocus();
    if (_otp.length == 6) _verify();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textSecondary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text('OTP Enter Karo 🔐',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Text('${widget.phone} pe 6-digit OTP bheja gaya hai',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 48),

              // OTP boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _OtpBox(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  onChanged: (v) => _onDigitEntered(i, v),
                )),
              ),
              const SizedBox(height: 40),

              // Verify button
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: (_loading || _otp.length != 6) ? null : _verify,
                  child: _loading
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Verify Karo ✓',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 24),

              // Resend
              Center(
                child: _resendSeconds > 0
                    ? Text('Resend OTP in ${_resendSeconds}s',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 13))
                    : TextButton(
                        onPressed: _resendOtp,
                        child: const Text('OTP Dobara Bhejo',
                            style: TextStyle(color: AppTheme.saffron)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46, height: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
            fontSize: 24, fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppTheme.cardBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.saffron, width: 2),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
