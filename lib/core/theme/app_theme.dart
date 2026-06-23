import 'package:flutter/material.dart';

import 'app_spacing.dart';

class AppTheme {
  const AppTheme._();

  static const completeColor = Color(0xFF167A4A);
  static const pendingColor = Color(0xFF8A6D1F);
  static const missedColor = Color(0xFFB3261E);
  static const lateColor = Color(0xFF6750A4);
  static const surfaceTint = Color(0xFFF6F8F4);
  static const surfaceRaised = Color(0xFFFFFFFF);
  static const inkMuted = Color(0xFF5D665F);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1D6B4F),
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: surfaceTint,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.w800, height: 1.2),
        titleLarge: TextStyle(fontWeight: FontWeight.w800, height: 1.25),
        titleMedium: TextStyle(fontWeight: FontWeight.w700, height: 1.3),
        bodyLarge: TextStyle(height: 1.45),
        bodyMedium: TextStyle(height: 1.45),
        labelLarge: TextStyle(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surfaceRaised,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minLeadingWidth: 36,
      ),
    );
  }
}
