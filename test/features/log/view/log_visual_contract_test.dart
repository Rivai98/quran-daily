import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/design_system/app_colors.dart';

double _contrast(Color foreground, Color background) {
  final first = foreground.computeLuminance();
  final second = background.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test(
    'log text and status labels meet normal-text contrast in both themes',
    () {
      for (final colors in [AppColors.light, AppColors.dark]) {
        expect(
          _contrast(colors.ink, colors.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(colors.inkMuted, colors.surface),
          greaterThanOrEqualTo(4.5),
        );
        for (final pair in [
          (colors.completedFg, colors.completedBg),
          (colors.pendingFg, colors.pendingBg),
          (colors.infoFg, colors.infoBg),
          (colors.missedFg, colors.missedBg),
          (colors.lateFg, colors.lateBg),
        ]) {
          expect(_contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
        }
      }
    },
  );
}
