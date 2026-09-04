import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final bodyFont = GoogleFonts.karlaTextTheme(base.textTheme);
    final headingFont = GoogleFonts.frauncesTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: c.bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.amber,
        onPrimary: brightness == Brightness.light ? const Color(0xFF241505) : const Color(0xFF241505),
        secondary: c.sage,
        onSecondary: c.sageInk,
        error: c.danger,
        onError: c.surface,
        surface: c.surface,
        onSurface: c.ink,
      ),
      extensions: [c],
      textTheme: bodyFont.copyWith(
        displayLarge: headingFont.displayLarge?.copyWith(color: c.ink, fontWeight: FontWeight.w600),
        displayMedium: headingFont.displayMedium?.copyWith(color: c.ink, fontWeight: FontWeight.w600),
        headlineLarge: headingFont.headlineLarge?.copyWith(color: c.ink, fontWeight: FontWeight.w700),
        headlineMedium: headingFont.headlineMedium?.copyWith(color: c.ink, fontWeight: FontWeight.w700),
        headlineSmall: headingFont.headlineSmall?.copyWith(color: c.ink, fontWeight: FontWeight.w700),
        titleLarge: headingFont.titleLarge?.copyWith(color: c.ink, fontWeight: FontWeight.w700),
        titleMedium: bodyFont.titleMedium?.copyWith(color: c.ink, fontWeight: FontWeight.w700),
        bodyLarge: bodyFont.bodyLarge?.copyWith(color: c.ink),
        bodyMedium: bodyFont.bodyMedium?.copyWith(color: c.ink),
        bodySmall: bodyFont.bodySmall?.copyWith(color: c.inkSoft),
        labelLarge: bodyFont.labelLarge?.copyWith(color: c.ink, fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.ink,
        elevation: 0,
        titleTextStyle: headingFont.titleLarge?.copyWith(color: c.ink, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: c.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: c.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: c.amber, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.amber,
          foregroundColor: const Color(0xFF241505),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          side: BorderSide(color: c.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.inkSoft,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.line, space: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.surface : c.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.sage : c.line,
        ),
      ),
    );
  }
}
