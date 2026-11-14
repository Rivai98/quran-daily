import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/localization/arabic_numerals.dart';

void main() {
  test('formats integers as Arabic-Indic digits', () {
    expect(ArabicNumerals.format(0), '٠');
    expect(ArabicNumerals.format(5), '٥');
    expect(ArabicNumerals.format(12), '١٢');
    expect(ArabicNumerals.format(30), '٣٠');
    expect(ArabicNumerals.format(2026), '٢٠٢٦');
  });

  test('maps every Western digit to its Arabic-Indic counterpart', () {
    for (var d = 0; d <= 9; d++) {
      final western = '$d';
      final eastern = '٠١٢٣٤٥٦٧٨٩'[d];
      expect(ArabicNumerals.format(western), eastern);
    }
  });

  test('converts digits inside strings and keeps other characters', () {
    expect(ArabicNumerals.format('Juz 5 of 30'), 'Juz ٥ of ٣٠');
    expect(ArabicNumerals.format(12.5), '١٢.٥');
  });

  test('formats percentages with the Arabic percent sign', () {
    expect(ArabicNumerals.percent(40), '٤٠٪');
    expect(ArabicNumerals.percent(100), '١٠٠٪');
  });

  test('formats "completed / total" ratios like ١٢ / ٣٠', () {
    expect(ArabicNumerals.ratio(12, 30), '١٢ / ٣٠');
    expect(ArabicNumerals.ratio(0, 30), '٠ / ٣٠');
  });
}
