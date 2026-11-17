import 'package:flutter/material.dart';

@immutable
class PitchPulseTheme extends ThemeExtension<PitchPulseTheme> {
  const PitchPulseTheme({
    required this.voidColor,
    required this.carbon,
    required this.gunmetal,
    required this.iris,
    required this.periwinkle,
    required this.frost,
    required this.mutedSteel,
    required this.textPrimary,
    required this.fieldRadius,
    required this.cardRadius,
    required this.controlHeight,
    required this.pageMargin,
    required this.sectionGap,
  });

  static const defaults = PitchPulseTheme(
    voidColor: Color(0xFF0F101A),
    carbon: Color(0xFF151621),
    gunmetal: Color(0xFF1F2433),
    iris: Color(0xFF5B63D3),
    periwinkle: Color(0xFF98A4F7),
    frost: Color(0xFFC9D3EE),
    mutedSteel: Color(0xFF646E87),
    textPrimary: Color(0xFFF9FAFB),
    fieldRadius: 10,
    cardRadius: 16,
    controlHeight: 48,
    pageMargin: 16,
    sectionGap: 24,
  );

  final Color voidColor;
  final Color carbon;
  final Color gunmetal;
  final Color iris;
  final Color periwinkle;
  final Color frost;
  final Color mutedSteel;
  final Color textPrimary;
  final double fieldRadius;
  final double cardRadius;
  final double controlHeight;
  final double pageMargin;
  final double sectionGap;

  LinearGradient get ctaGradient => LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [iris, const Color(0xFF7C87F7)],
  );

  @override
  PitchPulseTheme copyWith({
    Color? voidColor,
    Color? carbon,
    Color? gunmetal,
    Color? iris,
    Color? periwinkle,
    Color? frost,
    Color? mutedSteel,
    Color? textPrimary,
    double? fieldRadius,
    double? cardRadius,
    double? controlHeight,
    double? pageMargin,
    double? sectionGap,
  }) {
    return PitchPulseTheme(
      voidColor: voidColor ?? this.voidColor,
      carbon: carbon ?? this.carbon,
      gunmetal: gunmetal ?? this.gunmetal,
      iris: iris ?? this.iris,
      periwinkle: periwinkle ?? this.periwinkle,
      frost: frost ?? this.frost,
      mutedSteel: mutedSteel ?? this.mutedSteel,
      textPrimary: textPrimary ?? this.textPrimary,
      fieldRadius: fieldRadius ?? this.fieldRadius,
      cardRadius: cardRadius ?? this.cardRadius,
      controlHeight: controlHeight ?? this.controlHeight,
      pageMargin: pageMargin ?? this.pageMargin,
      sectionGap: sectionGap ?? this.sectionGap,
    );
  }

  @override
  PitchPulseTheme lerp(ThemeExtension<PitchPulseTheme>? other, double t) {
    if (other is! PitchPulseTheme) return this;
    return PitchPulseTheme(
      voidColor: Color.lerp(voidColor, other.voidColor, t)!,
      carbon: Color.lerp(carbon, other.carbon, t)!,
      gunmetal: Color.lerp(gunmetal, other.gunmetal, t)!,
      iris: Color.lerp(iris, other.iris, t)!,
      periwinkle: Color.lerp(periwinkle, other.periwinkle, t)!,
      frost: Color.lerp(frost, other.frost, t)!,
      mutedSteel: Color.lerp(mutedSteel, other.mutedSteel, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      fieldRadius: fieldRadius + (other.fieldRadius - fieldRadius) * t,
      cardRadius: cardRadius + (other.cardRadius - cardRadius) * t,
      controlHeight: controlHeight + (other.controlHeight - controlHeight) * t,
      pageMargin: pageMargin + (other.pageMargin - pageMargin) * t,
      sectionGap: sectionGap + (other.sectionGap - sectionGap) * t,
    );
  }
}

class PitchPulseThemeData {
  const PitchPulseThemeData._();

  static ThemeData apply(ThemeData base) {
    final tokens = PitchPulseTheme.defaults;
    final scheme = base.colorScheme.copyWith(
      brightness: Brightness.dark,
      primary: tokens.periwinkle,
      onPrimary: tokens.voidColor,
      surface: tokens.carbon,
      onSurface: tokens.textPrimary,
      outline: tokens.gunmetal,
      error: const Color(0xFFFFB4AB),
    );

    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: tokens.voidColor,
      colorScheme: scheme,
      extensions: const <ThemeExtension<dynamic>>[PitchPulseTheme.defaults],
      textTheme: base.textTheme.apply(
        bodyColor: tokens.textPrimary,
        displayColor: tokens.textPrimary,
        fontFamily: 'Inter',
        fontFamilyFallback: const ['Inter', 'sans-serif'],
      ),
    );
  }
}
