// ============================================================
// lib/screens/auth/phone_login_screen.dart  — Refactored v2
// Fix: ZERO setState / bool _isLoading — pure Riverpod
// Fix: Errors surfaced from provider, never swallowed
// Fix: Network error shown explicitly (no silent spinners)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/language_service.dart';
import '../../../theme/app_theme.dart';
import '../../../services/google_auth_service.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _lang = LanguageService();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── Send OTP ───────────────────────────────────────────────
  // Business logic is entirely in AuthNotifier.sendOtp()
  // This method only validates format and delegates.

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length != 10 || !RegExp(r'^\d{10}$').hasMatch(phone)) {
      _snack(_lang.t('invalid_phone'));
      return;
    }
    await ref.read(authProvider.notifier).sendOtp(phone);
  }

  Future<void> _signInWithGoogle() async {
    await ref.read(authProvider.notifier).signInWithGoogle();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.cardBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.r12),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    // ── Listen to auth state for navigation & errors ──────────
    ref.listen<AsyncValue<AuthState>>(authProvider, (prev, next) {
      next.whenData((state) {
        // Show errors from the provider — replaces try/catch in UI
        if (state.errorMessage != null) {
          _snack(state.errorMessage!);
        }

        // Navigate when OTP was sent
        if (state.status == AuthStatus.phoneEntered &&
            state.verificationId != null) {
          context.push('/otp', extra: {
            'verificationId': state.verificationId!,
            'phone': state.phone!,
          });
        }

        // Navigate on success — GoRouter redirect handles this,
        // but we can also push imperatively if needed
        // GoRouter's redirect in app_router.dart handles the actual routing
      });
    });

    // ── Read loading state from provider (no local bool) ──────
    final authAsync = ref.watch(authProvider);
    final isLoading = authAsync.isLoading ||
        authAsync.maybeWhen(
          data: (s) => s.status == AuthStatus.initial,
          orElse: () => false,
        );

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
                _LanguageSelector(lang: _lang),
                const SizedBox(height: 36),

                // ── Hero logo ──────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(AppTheme.r20),
                          boxShadow: AppTheme.primaryShadow,
                        ),
                        child: const Icon(
                          Icons.directions_car_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Raahi',
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _lang.t('highway_par_hamesha_saath'),
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // ── Phone input ────────────────────────────────
                Text(
                  _lang.t('enter_mobile_number'),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                _PhoneInputField(
                  controller: _phoneCtrl,
                  onSubmitted: (_) => _sendOtp(),
                ),
                const SizedBox(height: 20),

                // ── OTP Button ─────────────────────────────────
                _OtpButton(
                  isLoading: isLoading,
                  label: _lang.t('send_otp'),
                  onTap: _sendOtp,
                ),
                const SizedBox(height: 20),

                // ── Divider ────────────────────────────────────
                Row(children: [
                  const Expanded(child: Divider(color: AppTheme.cardBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      _lang.t('or'),
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppTheme.cardBorder)),
                ]),
                const SizedBox(height: 20),

                // ── Google Sign-In ─────────────────────────────
                _GoogleButton(
                  isLoading: isLoading,
                  label: _lang.t('continue_with_google'),
                  onTap: _signInWithGoogle,
                ),
                const SizedBox(height: 32),

                // ── Terms ──────────────────────────────────────
                Center(
                  child: Text(
                    _lang.t('by_continuing_you_agree'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Extracted Widgets (pure, no business logic) ───────────────

class _PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;

  const _PhoneInputField({required this.controller, this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.r14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: AppTheme.cardBorder),
              ),
            ),
            child: const Text(
              '+91',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
              decoration: const InputDecoration(
                hintText: '98765 43210',
                hintStyle: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                counterText: '',
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: onSubmitted,
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpButton extends StatelessWidget {
  final bool isLoading;
  final String label;
  final VoidCallback onTap;

  const _OtpButton({
    required this.isLoading,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          disabledBackgroundColor: AppTheme.primary.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.r14),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  final String label;
  final VoidCallback onTap;

  const _GoogleButton({
    required this.isLoading,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onTap,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.g_mobiledata, size: 28),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textPrimary,
          side: const BorderSide(color: AppTheme.cardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.r14),
          ),
        ),
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  final LanguageService lang;
  const _LanguageSelector({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: LanguageService.supported.map((l) {
        final isSelected = lang.currentLanguage == l;
        return GestureDetector(
          onTap: () => lang.setLanguage(l),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : AppTheme.cardBg,
              borderRadius: BorderRadius.circular(AppTheme.r8),
              border: Border.all(
                color: isSelected ? AppTheme.primary : AppTheme.cardBorder,
              ),
            ),
            child: Text(
              '${l.flag} ${l.displayName}',
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
