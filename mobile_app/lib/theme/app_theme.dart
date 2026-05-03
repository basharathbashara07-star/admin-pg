import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFFEFF6FF);
  static const Color secondary = Color(0xFF7C3AED);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color orange = Color(0xFFF97316);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMid = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);

  // Dark mode colors
  static const Color bgDark = Color(0xFF0F172A);
  static const Color bgDarkCard = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF334155);
  static const Color textDarkMode = Color(0xFFF1F5F9);
  static const Color textMidDark = Color(0xFF94A3B8);

  // ── Helper methods ──
  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? bgDark : bgLight;

  static Color card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? bgDarkCard : Colors.white;

  static Color text(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textDarkMode : textDark;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textMidDark : textMid;

  static Color borderColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? borderDark : border;

  // ✅ LIGHT THEME
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: bgLight,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: textDark),
          titleTextStyle: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: bgDark,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: bgDarkCard,
          elevation: 0,
          iconTheme: IconThemeData(color: textDarkMode),
          titleTextStyle: TextStyle(
            color: textDarkMode,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardColor: bgDarkCard,
        dividerColor: borderDark,
      );
}