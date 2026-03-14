import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/google_auth_service.dart';
import '../../services/language_service.dart';
import '../../models/models.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});
  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneCtrl    = TextEditingController();
  final _lang         = LanguageService();
  bool _otpLoading    = false;
  bool _googleLoading = false;

  // ── Phone OTP via Firebase ────────────────────────────────
  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length != 10) {
      _snack(_lang.t('invalid_phone'));
      return;
    }
    setState(() => _otpLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91$phone',
      timeout: const Duration(seconds: 60),

      // Android pe auto-detect hota hai — seedha login
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
          final idToken  = await userCred.user!.getIdToken();
          final res = await ApiService().verifyOtp('+91$phone', idToken!);
          await ApiService().setToken(res['token'] as String);
          final isNewUser = res['is_new_user'] as bool? ?? false;
          if (mounted) isNewUser ? context.go('/profile-setup') : context.go('/home');
        } catch (_) {}
      },

      verificationFailed: (FirebaseAuthException e) {
        if (mounted) {
          setState(() => _otpLoading = false);
          _snack(e.code == 'invalid-phone-number'
              ? 'Sahi phone number daalo'
              : 'OTP bhejne mein error. Dobara try karo.');
        }
      },

      // OTP SMS gaya — OTP screen pe navigate karo verificationId ke saath
      codeSent: (String verificationId, int? resendToken) {
        if (mounted) {
          setState(() => _otpLoading = false);
          context.push('/otp', extra: {
            'phone': '+91$phone',
            'verificationId': verificationId,
          });
        }
      },

      codeAutoRetrievalTimeout: (_) {},
    );
  }

  // ── Google Sign-In ────────────────────────────────────────
  Future<void> _signInWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      final result = await GoogleAuthService().signIn();
      if (!mounted) return;
      if (result.isNewUser) {
        context.pushReplacement('/profile-setup', extra: {
          'name': result.name,
          'email': result.email,
          'photo': result.photoUrl,
          'via': 'google',
        });
      } else {
        context.go('/home');
      }
    } on GoogleSignInCancelledException {
      // Silent — user ne cancel kiya
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.cardBg,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  void dispose() { _phoneCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _lang,
      builder: (context, _) => Scaffold(
        backgroundColor: AppTheme.navy,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLanguageSelector(),
                const SizedBox(height: 36),

                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: [AppTheme.saffron, AppTheme.saffronDark]),
                    boxShadow: [BoxShadow(
                      color: AppTheme.saffron.withOpacity(0.3),
                      blurRadius: 20, spreadRadius: 2)],
                  ),
                  child: const Icon(Icons.directions_car_rounded,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(height: 28),

                Text(_lang.t('welcome_title'),
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary, height: 1.2)),
                const SizedBox(height: 8),
                Text(_lang.t('welcome_sub'),
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                const SizedBox(height: 36),

                Text(_lang.t('mobile_number'),
                    style: const TextStyle(color: AppTheme.textSecondary,
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: const Text('+91',
                        style: TextStyle(color: AppTheme.textPrimary,
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: AppTheme.textPrimary,
                          fontSize: 18, letterSpacing: 2),
                      decoration: InputDecoration(
                          hintText: _lang.t('phone_hint'), counterText: ''),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton(
                    onPressed: _otpLoading ? null : _sendOtp,
                    child: _otpLoading
                        ? const SizedBox(width: 24, height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_lang.t('btn_send_otp'),
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                ),

                const SizedBox(height: 28),
                Row(children: [
                  const Expanded(child: Divider(color: AppTheme.cardBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(_lang.t('or_divider'),
                        style: const TextStyle(color: AppTheme.textMuted,
                            fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w600)),
                  ),
                  const Expanded(child: Divider(color: AppTheme.cardBorder)),
                ]),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity, height: 54,
                  child: OutlinedButton(
                    onPressed: _googleLoading ? null : _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.cardBorder, width: 1.5),
                      backgroundColor: AppTheme.cardBg,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _googleLoading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: AppTheme.saffron, strokeWidth: 2.5))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _GoogleLogo(),
                              const SizedBox(width: 12),
                              Text(_lang.t('btn_google_login'),
                                  style: const TextStyle(color: AppTheme.textPrimary,
                                      fontSize: 16, fontWeight: FontWeight.w600)),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 32),
                Center(
                  child: TextButton(
                    onPressed: () => context.push('/mechanic-register'),
                    child: Text(_lang.t('mechanic_register_link'),
                        style: const TextStyle(color: AppTheme.cyan, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(_lang.t('terms_note'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_lang.t('choose_language'),
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11,
                letterSpacing: 0.8, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: LanguageService.supported.map((lang) {
              final isSelected = _lang.currentLanguage == lang;
              return GestureDetector(
                onTap: () => _lang.setLanguage(lang),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.saffron : AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppTheme.saffron : AppTheme.cardBorder,
                      width: 1.5),
                    boxShadow: isSelected ? [BoxShadow(
                        color: AppTheme.saffron.withOpacity(0.3), blurRadius: 8)] : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(lang.flag, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(lang.displayName, style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 22, height: 22, child: CustomPaint(painter: _GooglePainter()));
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2; final r = size.width / 2;
    final colors = [const Color(0xFF4285F4), const Color(0xFF34A853),
                    const Color(0xFFFBBC05), const Color(0xFFEA4335)];
    for (int i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.75),
        ([-90.0, 0.0, 90.0, 180.0][i]) * 3.14159 / 180,
        90 * 3.14159 / 180, false,
        Paint()..color = colors[i]..style = PaintingStyle.stroke..strokeWidth = size.width * 0.2,
      );
    }
    canvas.drawCircle(Offset(cx, cy), r * 0.55, Paint()..color = AppTheme.cardBg);
    canvas.drawLine(Offset(cx, cy), Offset(cx + r * 0.72, cy),
      Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.stroke
              ..strokeWidth = size.width * 0.18..strokeCap = StrokeCap.round);
  }
  @override
  bool shouldRepaint(_) => false;
}
