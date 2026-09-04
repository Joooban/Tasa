import 'package:flutter/material.dart';

/// Palette lifted 1:1 from the prototype's CSS custom properties.
class AppColors extends ThemeExtension<AppColors> {
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color ink;
  final Color inkSoft;
  final Color inkFaint;
  final Color line;
  final Color amber;
  final Color amberInk;
  final Color sage;
  final Color sageInk;
  final Color clay;
  final Color clayInk;
  final Color danger;
  final Color espressoGradientStart;
  final Color espressoGradientMid;
  final Color espressoGradientEnd;
  final Color espressoShadow;
  final Color onEspresso;

  const AppColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.line,
    required this.amber,
    required this.amberInk,
    required this.sage,
    required this.sageInk,
    required this.clay,
    required this.clayInk,
    required this.danger,
    required this.espressoGradientStart,
    required this.espressoGradientMid,
    required this.espressoGradientEnd,
    required this.espressoShadow,
    required this.onEspresso,
  });

  static const light = AppColors(
    bg: Color(0xFFEDE6D8),
    surface: Color(0xFFFBF7EF),
    surface2: Color(0xFFF3EBDC),
    ink: Color(0xFF2B1D14),
    inkSoft: Color(0xFF7A6A5B),
    inkFaint: Color(0xFFA79683),
    line: Color(0xFFDDD1BA),
    amber: Color(0xFFC98A3A),
    amberInk: Color(0xFF7A4E1D),
    sage: Color(0xFF6E7F5C),
    sageInk: Color(0xFF3F4A32),
    clay: Color(0xFF9C5A42),
    clayInk: Color(0xFF5C3325),
    danger: Color(0xFFA6402F),
    // The Wrapped card gets its own light-roast look in light mode — a warm
    // cream-to-caramel pour instead of the dark-mode espresso, so it doesn't
    // read as a jarring dark rectangle dropped into an otherwise light page.
    espressoGradientStart: Color(0xFFFBF3E4),
    espressoGradientMid: Color(0xFFEFDCB8),
    espressoGradientEnd: Color(0xFFDFC091),
    espressoShadow: Color(0x33241609),
    onEspresso: Color(0xFF2B1D14),
  );

  static const dark = AppColors(
    bg: Color(0xFF1D1712),
    surface: Color(0xFF271F18),
    surface2: Color(0xFF2E251C),
    ink: Color(0xFFF1E8DC),
    inkSoft: Color(0xFFB8A996),
    inkFaint: Color(0xFF82725F),
    line: Color(0xFF3B2F24),
    amber: Color(0xFFE0A24E),
    amberInk: Color(0xFFF6D9A6),
    sage: Color(0xFF93A87B),
    sageInk: Color(0xFFC7D6B4),
    clay: Color(0xFFC9805F),
    clayInk: Color(0xFFEAC0AC),
    danger: Color(0xFFD9705C),
    espressoGradientStart: Color(0xFF54331F),
    espressoGradientMid: Color(0xFF321C10),
    espressoGradientEnd: Color(0xFF190D08),
    espressoShadow: Color(0x40000000),
    onEspresso: Color(0xFFF3E7D6),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return this;
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
