import 'package:flutter/material.dart';

/// Type scale from constitution Principle VI (v2.4.0).
///
/// Exactly eight tokens; no other sizes are permitted anywhere in the app.
/// Cairo is a variable font, so every Cairo TextStyle sets BOTH `fontWeight`
/// and a matching `FontVariation('wght', w)` so the weight axis renders
/// correctly. Amiri is used ONLY for Quran part names, surah names, and
/// reading-range labels.
@immutable
class AppTypography {
  const AppTypography._();

  /// 28/40 · 700 · Progress number, hero figures.
  static const TextStyle display = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 28,
    height: 40 / 28,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
  );

  /// 24/36 · 700 · Screen titles.
  static const TextStyle headline = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 24,
    height: 36 / 24,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
  );

  /// 18/28 · 600 · Card and section titles.
  static const TextStyle title = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 18,
    height: 28 / 18,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
  );

  /// 16/26 · 400 · Primary reading text.
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 16,
    height: 26 / 16,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
  );

  /// 15/24 · 400 · Default body text.
  static const TextStyle body = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 15,
    height: 24 / 15,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
  );

  /// 14/20 · 600 · Buttons, chips, tabs.
  static const TextStyle label = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
  );

  /// 13/20 · 500 · Metadata, timestamps.
  static const TextStyle caption = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 13,
    height: 20 / 13,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
  );

  /// 20/34 · 700 · Amiri; part and surah labels ONLY (scales with the
  /// user's Quran text-size setting, not with the type scale).
  static const TextStyle quranLabel = TextStyle(
    fontFamily: 'Amiri',
    fontSize: 20,
    height: 34 / 20,
    fontWeight: FontWeight.w700,
  );

  /// Printed-Mushaf (KFGQPC QPC V2) page glyphs. Each page has its own font and the
  /// size is computed so the page's 15 lines fill the available width.
  static TextStyle mushafPage({
    required String fontFamily,
    required double size,
    Color? color,
  }) => TextStyle(
    fontFamily: fontFamily,
    fontSize: size,
    height: 1.0,
    color: color,
  );

  /// Material [TextTheme] composed strictly from the eight tokens above.
  ///
  /// Colors are intentionally left unset so ThemeData fills them from the
  /// colorScheme (onSurface / onSurfaceVariant).
  static TextTheme get textTheme => const TextTheme(
        displayLarge: display,
        displayMedium: display,
        displaySmall: display,
        headlineLarge: headline,
        headlineMedium: headline,
        headlineSmall: headline,
        titleLarge: title,
        titleMedium: bodyLarge,
        titleSmall: label,
        bodyLarge: bodyLarge,
        bodyMedium: body,
        bodySmall: caption,
        labelLarge: label,
        labelMedium: label,
        labelSmall: caption,
      );
}
