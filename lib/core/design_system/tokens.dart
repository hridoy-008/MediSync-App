import 'package:flutter/material.dart';

/// Design tokens — the single source of visual truth (Design doc §3). Every
/// component reads from here; swapping these values re-skins the whole app.

/// Color tokens, light + dark, mapped from Design doc §3.1.
class AppColors {
  const AppColors({
    required this.primary,
    required this.primaryContainer,
    required this.onPrimary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.outline,
    // reminder-domain accents
    required this.medicine,
    required this.meal,
    required this.water,
    required this.sleep,
  });

  final Color primary;
  final Color primaryContainer;
  final Color onPrimary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color onSurface;
  final Color onSurfaceMuted;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color outline;
  final Color medicine;
  final Color meal;
  final Color water;
  final Color sleep;

  static const AppColors light = AppColors(
    primary: Color(0xFF1C9B8E),
    primaryContainer: Color(0xFFD5F2EE),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFF2A33C),
    background: Color(0xFFF7FAF9),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFEEF3F2),
    onSurface: Color(0xFF1A2422),
    onSurfaceMuted: Color(0xFF5C6B68),
    success: Color(0xFF2E9E5B),
    warning: Color(0xFFE2A100),
    danger: Color(0xFFD9534F),
    info: Color(0xFF3B82C4),
    outline: Color(0xFFD4DEDC),
    medicine: Color(0xFF1C9B8E),
    meal: Color(0xFFF2A33C),
    water: Color(0xFF3B82C4),
    sleep: Color(0xFF6366C7),
  );

  static const AppColors dark = AppColors(
    primary: Color(0xFF3BC2B3),
    primaryContainer: Color(0xFF12433E),
    onPrimary: Color(0xFF06201D),
    secondary: Color(0xFFF2B765),
    background: Color(0xFF0F1715),
    surface: Color(0xFF18211F),
    surfaceVariant: Color(0xFF222D2B),
    onSurface: Color(0xFFE7EEEC),
    onSurfaceMuted: Color(0xFF9AA9A6),
    success: Color(0xFF4FBE7E),
    warning: Color(0xFFF1BE3A),
    danger: Color(0xFFE8736F),
    info: Color(0xFF5C9FDB),
    outline: Color(0xFF31403D),
    medicine: Color(0xFF3BC2B3),
    meal: Color(0xFFF2B765),
    water: Color(0xFF5C9FDB),
    sleep: Color(0xFF8C8FE0),
  );
}

/// 4-pt spacing scale (Design doc §3.3).
class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Corner radii (Design doc §3.3).
class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;
}

/// Soft, low elevation (Design doc §3.3).
class AppElevation {
  static List<BoxShadow> card(Color shadow) => [
        BoxShadow(
          color: shadow.withOpacity(0.12),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
}

/// Minimum interactive size (Design doc §3.3 / §8).
class AppSizing {
  static const double minTapTarget = 48;
}
