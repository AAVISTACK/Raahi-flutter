// ============================================================
// lib/theme/app_theme.dart  — Production v3
// Tesla / Material 3 / Automotive dark theme
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  AppTheme._();

  // ── Brand ─────────────────────────────────────────────────
  static const Color primary      = Color(0xFFFF6B00);
  static const Color primaryDark  = Color(0xFFCC4D00);
  static const Color primaryLight = Color(0xFFFF8C3A);

  // Legacy aliases
  static const Color saffron      = primary;
  static const Color saffronDark  = primaryDark;
  static const Color saffronLight = primaryLight;

  // ── Backgrounds (layered depth) ───────────────────────────
  static const Color bg           = Color(0xFF0B1220);
  static const Color navy         = Color(0xFF0B1220);
  static const Color navyLight    = Color(0xFF0E1829);
  static const Color cardBg       = Color(0xFF111C2E);
  static const Color cardBorder   = Color(0xFF1A2B42);
  static const Color surfaceHigh  = Color(0xFF162238);

  // ── Text ──────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFEAF2FF);
  static const Color textSecondary = Color(0xFF9FB3C8);
  static const Color textMuted     = Color(0xFF4A6480);

  // ── Accents ───────────────────────────────────────────────
  static const Color green  = Color(0xFF00E676);
  static const Color cyan   = Color(0xFF00CFFF);
  static const Color red    = Color(0xFFFF3D5A);
  static const Color yellow = Color(0xFFFFBF00);
  static const Color purple = Color(0xFF8B5CF6);

  // ── Gradients ─────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF162238), Color(0xFF111C2E)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // ── Shadows ───────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 4)),
  ];
  static List<BoxShadow> get primaryShadow => [
    BoxShadow(color: primary.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 8)),
  ];

  // ── Radius ────────────────────────────────────────────────
  static const double r8  = 8;
  static const double r12 = 12;
  static const double r14 = 14;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double r24 = 24;

  static void configureSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0B1220),
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  // ── Full Theme ────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary, secondary: cyan,
        surface: cardBg, error: red,
        onPrimary: Colors.white, onSecondary: bg,
        onSurface: textPrimary, outline: cardBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: navyLight, foregroundColor: textPrimary,
        elevation: 0, scrolledUnderElevation: 0, centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Rajdhani', fontSize: 20, fontWeight: FontWeight.w700,
          color: textPrimary, letterSpacing: 0.4,
        ),
        iconTheme: IconThemeData(color: textSecondary, size: 22),
      ),
      cardTheme: CardTheme(
        color: cardBg, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(r14),
          side: const BorderSide(color: cardBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary, foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r14)),
          textStyle: const TextStyle(
            fontFamily: 'Rajdhani', fontSize: 17,
            fontWeight: FontWeight.w700, letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: cardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(r12), borderSide: const BorderSide(color: cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r12), borderSide: const BorderSide(color: cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r12), borderSide: const BorderSide(color: primary, width: 1.5)),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected) ? Colors.white : textMuted),
        trackColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected) ? primary : surfaceHigh),
        trackOutlineColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected) ? primary : cardBorder),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: navyLight, selectedItemColor: primary,
        unselectedItemColor: textMuted, type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        unselectedLabelStyle: TextStyle(fontSize: 10),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceHigh,
        contentTextStyle: const TextStyle(color: textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r12)),
        behavior: SnackBarBehavior.floating, elevation: 0,
      ),
      dividerTheme: const DividerThemeData(color: cardBorder, thickness: 1, space: 0),
      textTheme: const TextTheme(
        displayLarge:  TextStyle(fontFamily: 'Rajdhani', color: textPrimary, fontWeight: FontWeight.w700, fontSize: 34),
        displayMedium: TextStyle(fontFamily: 'Rajdhani', color: textPrimary, fontWeight: FontWeight.w700, fontSize: 28),
        displaySmall:  TextStyle(fontFamily: 'Rajdhani', color: textPrimary, fontWeight: FontWeight.w700, fontSize: 22),
        headlineLarge: TextStyle(fontFamily: 'Rajdhani', color: textPrimary, fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: 0.3),
        headlineMedium:TextStyle(fontFamily: 'Rajdhani', color: textPrimary, fontWeight: FontWeight.w700, fontSize: 18),
        headlineSmall: TextStyle(fontFamily: 'Rajdhani', color: textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
        titleLarge:  TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
        titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
        titleSmall:  TextStyle(color: textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
        bodyLarge:   TextStyle(color: textPrimary, fontSize: 15, height: 1.55),
        bodyMedium:  TextStyle(color: textSecondary, fontSize: 13, height: 1.5),
        bodySmall:   TextStyle(color: textMuted, fontSize: 11, height: 1.4),
        labelLarge:  TextStyle(fontFamily: 'Rajdhani', color: primary, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
      ),
    );
  }
}
