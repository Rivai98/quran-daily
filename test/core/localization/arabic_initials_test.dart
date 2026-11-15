import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/localization/arabic_initials.dart';

void main() {
  group('displayInitials', () {
    test('single word gives one letter', () {
      expect(displayInitials('عمر'), 'ع');
      expect(displayInitials('أحمد'), 'أ');
    });

    test('two regular words gives first of each', () {
      expect(displayInitials('أحمد علي'), 'أ ع');
      expect(displayInitials('سعيد حسن'), 'س ح');
    });

    test(
      'three words with compound last gives first of first and prefix of compound',
      () {
        expect(displayInitials('محمد عبد الله'), 'م ع');
        expect(displayInitials('طارق أبو بكر'), 'ط أ');
      },
    );

    test('two words being compound gives first letter', () {
      expect(displayInitials('عبد الله'), 'ع');
      expect(displayInitials('أبو بكر'), 'أ');
    });

    test('empty or null returns empty string', () {
      expect(displayInitials(null), '');
      expect(displayInitials('   '), '');
    });
  });

  group('groupInitials', () {
    test('uses group words and skips generic group prefixes', () {
      expect(groupInitials('حلقة الفجر'), 'ف');
      expect(groupInitials('مجموعة تحفيظ القرآن'), 'ت ق');
      expect(groupInitials('مجموعة ١٢ الفجر'), 'ف');
      expect(groupInitials('أهل القرآن'), 'أ ق');
    });
  });
}
