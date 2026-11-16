import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/design_system/app_typography.dart';

/// Constitution Principle VI type scale: exactly 8 tokens
/// (size / line height / weight); UI font Cairo, Quran label font Amiri;
/// 13 is the minimum font size; Cairo is a variable font so every Cairo
/// TextStyle must set fontWeight AND a matching FontVariation('wght', w).
void main() {
  TextStyle cairo(TokenSpec s, TextStyle style) {
    expect(style.fontSize, s.size, reason: '${s.name} size');
    expect(
      style.height! * style.fontSize!,
      closeTo(s.lineHeight, 0.001),
      reason: '${s.name} line height',
    );
    expect(style.fontWeight, s.weight, reason: '${s.name} weight');
    expect(style.fontFamily, 'Cairo', reason: '${s.name} family');
    expect(style.fontVariations, [
      FontVariation('wght', s.weight!.value.toDouble()),
    ], reason: '${s.name} variable weight axis');
    return style;
  }

  test('the 8 constitution tokens are exact', () {
    cairo(
      const TokenSpec('display', 28, 40, FontWeight.w700),
      AppTypography.display,
    );
    cairo(
      const TokenSpec('headline', 24, 36, FontWeight.w700),
      AppTypography.headline,
    );
    cairo(
      const TokenSpec('title', 18, 28, FontWeight.w600),
      AppTypography.title,
    );
    cairo(
      const TokenSpec('bodyLarge', 16, 26, FontWeight.w400),
      AppTypography.bodyLarge,
    );
    cairo(const TokenSpec('body', 15, 24, FontWeight.w400), AppTypography.body);
    cairo(
      const TokenSpec('label', 14, 20, FontWeight.w600),
      AppTypography.label,
    );
    cairo(
      const TokenSpec('caption', 13, 20, FontWeight.w500),
      AppTypography.caption,
    );

    final quran = AppTypography.quranLabel;
    expect(quran.fontSize, 20);
    expect(quran.height! * quran.fontSize!, closeTo(34, 0.001));
    expect(quran.fontWeight, FontWeight.w700);
    expect(quran.fontFamily, 'Amiri');
  });

  test('no token is smaller than the 13px minimum', () {
    for (final style in [
      AppTypography.display,
      AppTypography.headline,
      AppTypography.title,
      AppTypography.bodyLarge,
      AppTypography.body,
      AppTypography.label,
      AppTypography.caption,
      AppTypography.quranLabel,
    ]) {
      expect(style.fontSize!, greaterThanOrEqualTo(13));
    }
  });

  test('Material TextTheme is composed only from the 8 tokens', () {
    final sizes = <double>{
      AppTypography.display.fontSize!,
      AppTypography.headline.fontSize!,
      AppTypography.title.fontSize!,
      AppTypography.bodyLarge.fontSize!,
      AppTypography.body.fontSize!,
      AppTypography.label.fontSize!,
      AppTypography.caption.fontSize!,
      AppTypography.quranLabel.fontSize!,
    };
    final textTheme = AppTypography.textTheme;
    final styles = <TextStyle?>[
      textTheme.displayLarge,
      textTheme.displayMedium,
      textTheme.displaySmall,
      textTheme.headlineLarge,
      textTheme.headlineMedium,
      textTheme.headlineSmall,
      textTheme.titleLarge,
      textTheme.titleMedium,
      textTheme.titleSmall,
      textTheme.bodyLarge,
      textTheme.bodyMedium,
      textTheme.bodySmall,
      textTheme.labelLarge,
      textTheme.labelMedium,
      textTheme.labelSmall,
    ];
    for (final style in styles) {
      expect(style, isNotNull);
      expect(sizes, contains(style!.fontSize!), reason: '$style');
    }
  });
}

class TokenSpec {
  const TokenSpec(this.name, this.size, this.lineHeight, this.weight);

  final String name;
  final double size;
  final double lineHeight;
  final FontWeight? weight;
}
