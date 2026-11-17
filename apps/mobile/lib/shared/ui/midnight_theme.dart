import 'package:flutter/material.dart';

/// Shared visual tokens for the Google Stitch Midnight mobile experience.
@immutable
class MidnightTheme extends ThemeExtension<MidnightTheme> {
  const MidnightTheme({
    required this.voidColor,
    required this.carbon,
    required this.gunmetal,
    required this.steel,
    required this.steelLight,
    required this.frost,
    required this.iris,
    required this.periwinkle,
    required this.emerald,
    required this.amber,
    required this.danger,
    required this.surfaceCard,
    required this.surfaceElevated,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardRadius,
    required this.controlHeight,
    required this.pageMargin,
  });

  static const defaults = MidnightTheme(
    voidColor: Color(0xFF0F101A),
    carbon: Color(0xFF151621),
    gunmetal: Color(0xFF1F2433),
    steel: Color(0xFF646E87),
    steelLight: Color(0xFF939DB8),
    frost: Color(0xFFC9D3EE),
    iris: Color(0xFF5B63D3),
    periwinkle: Color(0xFF7C87F7),
    emerald: Color(0xFF10E575),
    amber: Color(0xFFF59E0B),
    danger: Color(0xFFFF7D8A),
    surfaceCard: Color(0xFF12181D),
    surfaceElevated: Color(0xFF1A232A),
    borderSubtle: Color(0xFF222E37),
    textPrimary: Color(0xFFF9FAFB),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF646E87),
    cardRadius: 16,
    controlHeight: 48,
    pageMargin: 16,
  );

  final Color voidColor;
  final Color carbon;
  final Color gunmetal;
  final Color steel;
  final Color steelLight;
  final Color frost;
  final Color iris;
  final Color periwinkle;
  final Color emerald;
  final Color amber;
  final Color danger;
  final Color surfaceCard;
  final Color surfaceElevated;
  final Color borderSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final double cardRadius;
  final double controlHeight;
  final double pageMargin;

  LinearGradient get ctaGradient => LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [iris, periwinkle],
  );

  BorderRadius get cardBorderRadius => BorderRadius.circular(cardRadius);

  BoxDecoration cardDecoration({Color? color}) => BoxDecoration(
    color: color ?? surfaceCard,
    borderRadius: cardBorderRadius,
    border: Border.all(color: borderSubtle),
  );

  ButtonStyle get primaryButtonStyle => FilledButton.styleFrom(
    minimumSize: Size.fromHeight(controlHeight),
    backgroundColor: periwinkle,
    foregroundColor: voidColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(fontWeight: FontWeight.w700),
  );

  ButtonStyle get secondaryButtonStyle => OutlinedButton.styleFrom(
    minimumSize: Size.fromHeight(controlHeight),
    foregroundColor: frost,
    side: BorderSide(color: steel),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  TextStyle get displayStyle => TextStyle(
    fontFamily: 'Space Grotesk',
    fontFamilyFallback: const ['Inter', 'sans-serif'],
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.56,
    color: textPrimary,
  );

  TextStyle get labelStyle => TextStyle(
    fontFamily: 'Space Grotesk',
    fontFamilyFallback: const ['Inter', 'sans-serif'],
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.66,
    color: textSecondary,
  );

  TextStyle get bodyStyle => TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: const ['sans-serif'],
    fontSize: 14,
    height: 20 / 14,
    color: textSecondary,
  );

  TextStyle get monoStyle => const TextStyle(
    fontFamily: 'JetBrains Mono',
    fontFamilyFallback: ['monospace'],
    letterSpacing: 0.2,
  );

  @override
  MidnightTheme copyWith({
    Color? voidColor,
    Color? carbon,
    Color? gunmetal,
    Color? steel,
    Color? steelLight,
    Color? frost,
    Color? iris,
    Color? periwinkle,
    Color? emerald,
    Color? amber,
    Color? danger,
    Color? surfaceCard,
    Color? surfaceElevated,
    Color? borderSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    double? cardRadius,
    double? controlHeight,
    double? pageMargin,
  }) {
    return MidnightTheme(
      voidColor: voidColor ?? this.voidColor,
      carbon: carbon ?? this.carbon,
      gunmetal: gunmetal ?? this.gunmetal,
      steel: steel ?? this.steel,
      steelLight: steelLight ?? this.steelLight,
      frost: frost ?? this.frost,
      iris: iris ?? this.iris,
      periwinkle: periwinkle ?? this.periwinkle,
      emerald: emerald ?? this.emerald,
      amber: amber ?? this.amber,
      danger: danger ?? this.danger,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      cardRadius: cardRadius ?? this.cardRadius,
      controlHeight: controlHeight ?? this.controlHeight,
      pageMargin: pageMargin ?? this.pageMargin,
    );
  }

  @override
  MidnightTheme lerp(ThemeExtension<MidnightTheme>? other, double t) {
    if (other is! MidnightTheme) return this;
    Color blend(Color a, Color b) => Color.lerp(a, b, t)!;
    return MidnightTheme(
      voidColor: blend(voidColor, other.voidColor),
      carbon: blend(carbon, other.carbon),
      gunmetal: blend(gunmetal, other.gunmetal),
      steel: blend(steel, other.steel),
      steelLight: blend(steelLight, other.steelLight),
      frost: blend(frost, other.frost),
      iris: blend(iris, other.iris),
      periwinkle: blend(periwinkle, other.periwinkle),
      emerald: blend(emerald, other.emerald),
      amber: blend(amber, other.amber),
      danger: blend(danger, other.danger),
      surfaceCard: blend(surfaceCard, other.surfaceCard),
      surfaceElevated: blend(surfaceElevated, other.surfaceElevated),
      borderSubtle: blend(borderSubtle, other.borderSubtle),
      textPrimary: blend(textPrimary, other.textPrimary),
      textSecondary: blend(textSecondary, other.textSecondary),
      textMuted: blend(textMuted, other.textMuted),
      cardRadius: cardRadius + (other.cardRadius - cardRadius) * t,
      controlHeight: controlHeight + (other.controlHeight - controlHeight) * t,
      pageMargin: pageMargin + (other.pageMargin - pageMargin) * t,
    );
  }
}

class MidnightThemeData {
  const MidnightThemeData._();

  static ThemeData apply([ThemeData? base]) {
    final tokens = MidnightTheme.defaults;
    final source = base ?? ThemeData.dark(useMaterial3: true);
    final scheme = source.colorScheme.copyWith(
      brightness: Brightness.dark,
      primary: tokens.periwinkle,
      onPrimary: tokens.voidColor,
      secondary: tokens.iris,
      surface: tokens.surfaceCard,
      onSurface: tokens.textPrimary,
      outline: tokens.borderSubtle,
      error: tokens.danger,
    );
    final textTheme = source.textTheme
        .apply(
          bodyColor: tokens.textSecondary,
          displayColor: tokens.textPrimary,
          fontFamily: 'Inter',
          fontFamilyFallback: const ['Inter', 'sans-serif'],
        )
        .copyWith(
          displayLarge: tokens.displayStyle.copyWith(
            fontSize: 36,
            height: 44 / 36,
          ),
          headlineLarge: tokens.displayStyle.copyWith(
            fontSize: 24,
            height: 32 / 24,
          ),
          headlineSmall: tokens.displayStyle.copyWith(
            fontSize: 18,
            height: 24 / 18,
          ),
          labelLarge: tokens.labelStyle.copyWith(fontSize: 13, height: 16 / 13),
        );
    return source.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: tokens.voidColor,
      colorScheme: scheme,
      dividerColor: tokens.borderSubtle,
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.voidColor,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: tokens.surfaceCard,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: tokens.cardBorderRadius),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.voidColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.periwinkle),
        ),
        labelStyle: TextStyle(color: tokens.steelLight),
      ),
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[tokens],
    );
  }
}

extension MidnightThemeContext on BuildContext {
  MidnightTheme get midnight =>
      Theme.of(this).extension<MidnightTheme>() ?? MidnightTheme.defaults;
}
