import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Material 3 [ThemeData] built exclusively from the Principle VI tokens.
///
/// Both themes carry an [AppColors] extension so feature code can read
/// status/ink tokens that have no colorScheme slot.
@immutable
class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(AppColors.light, Brightness.light);
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final onSurface = c.ink;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.primaryContainer,
      onPrimaryContainer: c.onPrimaryContainer,
      secondary: c.accent,
      onSecondary: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF241A06),
      tertiary: c.accent,
      onTertiary: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF241A06),
      error: c.danger,
      onError: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF3D1A18),
      surface: c.surface,
      onSurface: onSurface,
      surfaceContainerHighest: c.surfaceMuted,
      onSurfaceVariant: c.inkMuted,
      outline: c.border,
      outlineVariant: c.border,
      surfaceContainer: c.surfaceMuted,
      shadow: isLight ? const Color(0xFF141E19) : const Color(0xFF000000),
    );

    final buttonBase = ButtonStyle(
      shape: const WidgetStatePropertyAll(RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
      )),
      textStyle: const WidgetStatePropertyAll(AppTypography.label),
      minimumSize: const WidgetStatePropertyAll(Size(64, 48)),
      tapTargetSize: MaterialTapTargetSize.padded,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.background,
      textTheme: AppTypography.textTheme,
      extensions: <ThemeExtension<dynamic>>[c],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headline.copyWith(color: onSurface),
        foregroundColor: onSurface,
        iconTheme: IconThemeData(color: onSurface),
      ),
      filledButtonTheme: FilledButtonThemeData(style: buttonBase),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: buttonBase.copyWith(
          side: WidgetStatePropertyAll(BorderSide(color: c.border)),
          foregroundColor: WidgetStatePropertyAll(c.primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: buttonBase.copyWith(
          foregroundColor: WidgetStatePropertyAll(c.primary),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: buttonBase.copyWith(
          minimumSize: const WidgetStatePropertyAll(Size.square(48)),
          maximumSize: const WidgetStatePropertyAll(Size.square(48)),
          fixedSize: const WidgetStatePropertyAll(Size.square(48)),
        ),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: c.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.danger, width: 1.5),
        ),
        hintStyle: AppTypography.body.copyWith(color: c.inkMuted),
        labelStyle: AppTypography.label.copyWith(color: c.ink),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.primaryContainer,
        elevation: 0,
        height: 72,
        labelTextStyle: const WidgetStatePropertyAll(AppTypography.caption),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? c.ink : c.inkMuted,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.ink,
        contentTextStyle: AppTypography.body.copyWith(color: c.background),
        actionTextColor: c.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: c.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
    );
  }
}
