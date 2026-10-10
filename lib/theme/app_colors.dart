import 'package:flutter/material.dart';

/// Semantic colours for the app, with a light and a dark set.
/// Read with `context.colors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color background;

  // Text and icons
  final Color text;
  final Color textSecondary;
  final Color textTertiary;

  // Glass surfaces (cards, nav pill)
  final Color glassTop;
  final Color glassBottom;
  final Color glassBorder;
  final Color glassRim; // bright top-edge highlight
  final Color glassShadow;

  // Sliding lens in the nav bar
  final Color lensTop;
  final Color lensBottom;
  final Color lensBorder;
  final Color lensGlow;

  // Bottom sheet
  final Color sheetBackground;
  final Color sheetBorder;
  final Color sheetHandle;

  // Misc
  final Color outline; // outlined buttons
  final Color divider;
  final Color fieldFill;
  final Color fieldBorder;

  const AppColors({
    required this.background,
    required this.text,
    required this.textSecondary,
    required this.textTertiary,
    required this.glassTop,
    required this.glassBottom,
    required this.glassBorder,
    required this.glassRim,
    required this.glassShadow,
    required this.lensTop,
    required this.lensBottom,
    required this.lensBorder,
    required this.lensGlow,
    required this.sheetBackground,
    required this.sheetBorder,
    required this.sheetHandle,
    required this.outline,
    required this.divider,
    required this.fieldFill,
    required this.fieldBorder,
  });

  static const dark = AppColors(
    background: Color(0xFF0B0B0F),
    text: Colors.white,
    textSecondary: Colors.white70,
    textTertiary: Colors.white54,
    glassTop: Color(0x1AFFFFFF),
    glassBottom: Color(0x08FFFFFF),
    glassBorder: Color(0x2EFFFFFF),
    glassRim: Color(0xB3FFFFFF),
    glassShadow: Color(0x66000000),
    lensTop: Color(0x42FFFFFF),
    lensBottom: Color(0x14FFFFFF),
    lensBorder: Color(0x59FFFFFF),
    lensGlow: Color(0x14FFFFFF),
    sheetBackground: Color(0xCC1C1C1E),
    sheetBorder: Color(0x33FFFFFF),
    sheetHandle: Colors.white24,
    outline: Color(0x40FFFFFF),
    divider: Color(0x1AFFFFFF),
    fieldFill: Color(0x0FFFFFFF),
    fieldBorder: Color(0x26FFFFFF),
  );

  // Light: dark-grey text, brighter and more opaque glass.
  static const light = AppColors(
    background: Color(0xFFF2F2F7),
    text: Color(0xFF2C2C2E),
    textSecondary: Color(0xFF636366),
    textTertiary: Color(0xFF8E8E93),
    glassTop: Color(0xCCFFFFFF),
    glassBottom: Color(0x80FFFFFF),
    glassBorder: Color(0xE6FFFFFF),
    glassRim: Color(0xFFFFFFFF),
    glassShadow: Color(0x1F000000),
    lensTop: Color(0xF2FFFFFF),
    lensBottom: Color(0x99FFFFFF),
    lensBorder: Color(0xFFFFFFFF),
    lensGlow: Color(0x14000000),
    sheetBackground: Color(0xE6FFFFFF),
    sheetBorder: Color(0xCCFFFFFF),
    sheetHandle: Color(0x33000000),
    outline: Color(0x33000000),
    divider: Color(0x1A000000),
    fieldFill: Color(0xB3FFFFFF),
    fieldBorder: Color(0x1F000000),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return t < 0.5 ? this : other;
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
