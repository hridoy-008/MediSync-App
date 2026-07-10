import 'package:flutter/material.dart';

/// Type tokens (Design doc §3.2). Bangla uses NotoSansBengali with a slightly
/// taller line-height to avoid conjunct clipping; English uses Inter.
class AppTypography {
  static const String englishFamily = 'Inter';
  static const String banglaFamily = 'NotoSansBengali';

  /// Build a TextTheme for the given locale so Bangla gets correct font + height.
  static TextTheme textTheme(Color onSurface, Color muted, {required bool bangla}) {
    final family = bangla ? banglaFamily : englishFamily;
    final fallback = bangla ? [englishFamily] : [banglaFamily];
    final lh = bangla ? 1.45 : 1.30;

    TextStyle s(double size, FontWeight weight, {Color? color}) => TextStyle(
          fontFamily: family,
          fontFamilyFallback: fallback,
          fontSize: size,
          fontWeight: weight,
          height: lh,
          color: color ?? onSurface,
        );

    return TextTheme(
      displayLarge: s(28, FontWeight.w700), // screen titles
      headlineMedium: s(22, FontWeight.w600), // section headers
      titleMedium: s(18, FontWeight.w600), // card titles, med names
      bodyLarge: s(16, FontWeight.w400), // default body (reminder-critical ≥16)
      bodyMedium: s(14, FontWeight.w400, color: muted), // secondary info
      labelSmall: s(12, FontWeight.w500, color: muted), // timestamps, labels
      labelLarge: s(16, FontWeight.w600), // buttons
    );
  }
}
