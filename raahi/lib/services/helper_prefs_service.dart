// ============================================================
// lib/services/helper_prefs_service.dart
// Helper opt-in preferences + FOMO onboarding logic
// ============================================================

import 'package:shared_preferences/shared_preferences.dart';

class HelperPrefsService {
  static final HelperPrefsService _i = HelperPrefsService._();
  factory HelperPrefsService() => _i;
  HelperPrefsService._();

  static const _keyHelperMode   = 'helper_mode_enabled';
  static const _keyFomoDone     = 'fomo_shown';
  static const _keyFirstOptIn   = 'first_opt_in_time';

  // ── Helper Mode ON/OFF ────────────────────────────────────
  Future<bool> isHelperMode() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_keyHelperMode) ?? false;
  }

  Future<void> setHelperMode(bool val) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyHelperMode, val);
    // First time opt-in — FOMO timer shuru karo
    if (val && !(p.containsKey(_keyFirstOptIn))) {
      await p.setString(_keyFirstOptIn, DateTime.now().toIso8601String());
    }
  }

  // ── FOMO Logic ────────────────────────────────────────────
  Future<bool> shouldShowFomo() async {
    final p = await SharedPreferences.getInstance();
    // Pehle se dikhaya hai toh nahi
    if (p.getBool(_keyFomoDone) ?? false) return false;
    // Opt-in time check
    final firstStr = p.getString(_keyFirstOptIn);
    if (firstStr == null) return false;
    final firstTime = DateTime.parse(firstStr);
    // 10 min baad dikhao
    return DateTime.now().difference(firstTime).inMinutes >= 10;
  }

  Future<void> markFomoDone() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyFomoDone, true);
  }
}
