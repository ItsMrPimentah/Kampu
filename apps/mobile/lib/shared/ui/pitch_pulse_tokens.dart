import 'package:flutter/material.dart';

/// Project-level Pitch Pulse tokens transcribed from Google Stitch project
/// 10729709610488881069. See apps/mobile/DESIGN.md for component guidance and
/// the distinction between these tokens and the legacy Midnight screen theme.
abstract final class PitchPulseColors {
  // Stitch theme overrides/seed colors, distinct from generated color roles.
  static const seedPrimary = Color(0xFF10E575);
  static const seedSecondary = Color(0xFF10B981);
  static const seedTertiary = Color(0xFF059669);
  static const seedNeutral = Color(0xFF0B0F12);

  static const surface = Color(0xFF101417);
  static const surfaceDim = Color(0xFF101417);
  static const surfaceBright = Color(0xFF363A3D);
  static const surfaceContainerLowest = Color(0xFF0B0F12);
  static const surfaceContainerLow = Color(0xFF181C1F);
  static const surfaceContainer = Color(0xFF1C2023);
  static const surfaceContainerHigh = Color(0xFF262A2E);
  static const surfaceContainerHighest = Color(0xFF313539);
  static const onSurface = Color(0xFFE0E3E7);
  static const onSurfaceVariant = Color(0xFFBACBB9);
  static const inverseSurface = Color(0xFFE0E3E7);
  static const inverseOnSurface = Color(0xFF2D3134);
  static const outline = Color(0xFF859585);
  static const outlineVariant = Color(0xFF3C4A3D);
  static const surfaceTint = Color(0xFF0AE474);
  static const primary = Color(0xFF6FFF9A);
  static const onPrimary = Color(0xFF003918);
  static const primaryContainer = Color(0xFF10E575);
  static const onPrimaryContainer = Color(0xFF00612D);
  static const inversePrimary = Color(0xFF006D34);
  static const secondary = Color(0xFF4EDEA3);
  static const onSecondary = Color(0xFF003824);
  static const secondaryContainer = Color(0xFF00A572);
  static const onSecondaryContainer = Color(0xFF00311F);
  static const tertiary = Color(0xFF86FAC5);
  static const onTertiary = Color(0xFF003825);
  static const tertiaryContainer = Color(0xFF69DDAA);
  static const onTertiaryContainer = Color(0xFF006041);
  static const error = Color(0xFFFFB4AB);
  static const onError = Color(0xFF690005);
  static const errorContainer = Color(0xFF93000A);
  static const onErrorContainer = Color(0xFFFFDAD6);
  static const primaryFixed = Color(0xFF62FF95);
  static const primaryFixedDim = Color(0xFF0AE474);
  static const onPrimaryFixed = Color(0xFF00210B);
  static const onPrimaryFixedVariant = Color(0xFF005225);
  static const secondaryFixed = Color(0xFF6FFBBE);
  static const secondaryFixedDim = Color(0xFF4EDEA3);
  static const onSecondaryFixed = Color(0xFF002113);
  static const onSecondaryFixedVariant = Color(0xFF005236);
  static const tertiaryFixed = Color(0xFF85F8C4);
  static const tertiaryFixedDim = Color(0xFF68DBA9);
  static const onTertiaryFixed = Color(0xFF002114);
  static const onTertiaryFixedVariant = Color(0xFF005137);
  static const background = Color(0xFF101417);
  static const onBackground = Color(0xFFE0E3E7);
  static const surfaceVariant = Color(0xFF313539);

  static const pitchDark = Color(0xFF070A0C);
  static const surfaceCard = Color(0xFF12181D);
  static const surfaceElevated = Color(0xFF1A232A);
  static const borderSubtle = Color(0xFF222E37);
  static const electricLime = Color(0xFF10E575);
  static const statusOpen = Color(0xFF38BDF8);
  static const statusNegotiating = Color(0xFFFBBF24);
  static const statusAgreed = Color(0xFFA78BFA);
  static const statusConfirmed = Color(0xFF10E575);
  static const badgeFormatBackground = Color(0xFF15241C);
  static const badgeFormatText = Color(0xFF34D399);
  static const badgePaymentBackground = Color(0xFF212015);
  static const badgePaymentText = Color(0xFFFACC15);
  static const textPrimary = Color(0xFFF9FAFB);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF64748B);

  // Component-specific colors, in Flutter's AARRGGBB order.
  static const statusOpenBackground = Color(0x1A0284C7);
  static const statusNegotiatingBackground = Color(0x1AD97706);
  static const statusAgreedBackground = Color(0x1A7C3AED);
  static const statusConfirmedBackground = Color(0x26059669);
  static const floatingPanelBorder = Color(0x2610E575);
}

/// Stitch rem/px values converted to Flutter logical pixels (1rem = 16px).
abstract final class PitchPulseSpacing {
  static const gutter = 16.0;
  static const gutterMobile = 12.0;
  static const margin = 16.0;
  static const marginMobile = 16.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
}

abstract final class PitchPulseRadii {
  static const sm = 4.0;
  static const standard = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const full = 9999.0;
  // The format badge component explicitly specifies 6px, despite calling it
  // rounded-sm in the prose (the rounded.sm token above is 4px).
  static const formatBadge = 6.0;
}

abstract final class PitchPulseTypography {
  static const _heading = 'Space Grotesk';
  static const _body = 'Inter';
  static const _headingFallback = <String>['Inter', 'sans-serif'];
  static const _bodyFallback = <String>['sans-serif'];

  // Flutter letterSpacing is in logical pixels; Stitch specifies em.
  static const displayLg = TextStyle(
    fontFamily: _heading,
    fontFamilyFallback: _headingFallback,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 44 / 36,
    letterSpacing: -1.08,
  );
  static const displayMobile = TextStyle(
    fontFamily: _heading,
    fontFamilyFallback: _headingFallback,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 36 / 28,
    letterSpacing: -0.56,
  );
  static const headlineLg = TextStyle(
    fontFamily: _heading,
    fontFamilyFallback: _headingFallback,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 32 / 24,
    letterSpacing: -0.48,
  );
  static const headlineMd = TextStyle(
    fontFamily: _heading,
    fontFamilyFallback: _headingFallback,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    letterSpacing: -0.2,
  );
  static const headlineSm = TextStyle(
    fontFamily: _heading,
    fontFamilyFallback: _headingFallback,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
  );
  static const titleMd = TextStyle(
    fontFamily: _body,
    fontFamilyFallback: _bodyFallback,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 22 / 16,
  );
  static const bodyLg = TextStyle(
    fontFamily: _body,
    fontFamilyFallback: _bodyFallback,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
  );
  static const bodyMd = TextStyle(
    fontFamily: _body,
    fontFamilyFallback: _bodyFallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
  );
  static const bodySm = TextStyle(
    fontFamily: _body,
    fontFamilyFallback: _bodyFallback,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
  );
  static const labelLg = TextStyle(
    fontFamily: _heading,
    fontFamilyFallback: _headingFallback,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 16 / 13,
    letterSpacing: 0.52,
  );
  static const labelMd = TextStyle(
    fontFamily: _heading,
    fontFamilyFallback: _headingFallback,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 14 / 11,
    letterSpacing: 0.66,
  );
  static const labelSm = TextStyle(
    fontFamily: _heading,
    fontFamilyFallback: _headingFallback,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 12 / 10,
    letterSpacing: 0.8,
  );
  static const numeralBadge = TextStyle(
    fontFamily: _heading,
    fontFamilyFallback: _headingFallback,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 16 / 14,
  );
}

abstract final class PitchPulseComponents {
  static const primaryButtonMinHeight = 48.0;
  static const cardBorderWidth = 1.0;
  static const statusBeaconSize = 6.0;
  static const primaryGlow = BoxShadow(
    color: Color(0x3310E575),
    offset: Offset(0, 4),
    blurRadius: 16,
  );
}
