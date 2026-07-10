import 'package:flutter/material.dart';

import 'tokens.dart';
import 'typography.dart';

/// Builds Material 3 [ThemeData] from tokens (Design doc §10). Light/dark differ
/// only in token values + Bangla swaps only the font — proving the system is
/// fully tokenized and white-label-ready.
class AppTheme {
  static ThemeData build({required bool dark, required bool bangla}) {
    final c = dark ? AppColors.dark : AppColors.light;
    final scheme = ColorScheme(
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.primaryContainer,
      onPrimaryContainer: c.onSurface,
      secondary: c.secondary,
      onSecondary: Colors.white,
      error: c.danger,
      onError: Colors.white,
      surface: c.surface,
      onSurface: c.onSurface,
      surfaceContainerHighest: c.surfaceVariant,
      onSurfaceVariant: c.onSurfaceMuted,
      outline: c.outline,
    );

    final textTheme = AppTypography.textTheme(c.onSurface, c.onSurfaceMuted,
        bangla: bangla);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[AppColorsExtension(c)],
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          minimumSize: const Size.fromHeight(AppSizing.minTapTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primary,
          side: BorderSide(color: c.primary),
          minimumSize: const Size.fromHeight(AppSizing.minTapTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.primary, width: 2),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.surface,
        selectedItemColor: c.primary,
        unselectedItemColor: c.onSurfaceMuted,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: DividerThemeData(color: c.outline, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}

/// Exposes the full token palette through `Theme.of(context)` so components can
/// read semantic colors (water/sleep/etc.) not present in [ColorScheme].
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension(this.colors);
  final AppColors colors;

  @override
  ThemeExtension<AppColorsExtension> copyWith({AppColors? colors}) =>
      AppColorsExtension(colors ?? this.colors);

  @override
  ThemeExtension<AppColorsExtension> lerp(
      covariant ThemeExtension<AppColorsExtension>? other, double t) =>
      this;
}

/// Convenience accessor.
extension AppColorsContext on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColorsExtension>()!.colors;
}
