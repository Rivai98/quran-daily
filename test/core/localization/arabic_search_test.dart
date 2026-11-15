import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/localization/arabic_search.dart';

void main() {
  group('ArabicSearch.normalize', () {
    test('folds taa marbuta into haa', () {
      expect(ArabicSearch.normalize('حلقة'), ArabicSearch.normalize('حلقه'));
    });

    test('folds every alef form into a bare alef', () {
      for (final word in ['أمل', 'إمل', 'آمل', 'ٱمل']) {
        expect(ArabicSearch.normalize(word), 'امل', reason: word);
      }
    });

    test('folds alef maqsura into yaa', () {
      expect(ArabicSearch.normalize('هدى'), ArabicSearch.normalize('هدي'));
    });

    test('strips diacritics, superscript alef and tatweel', () {
      expect(ArabicSearch.normalize('سَلَامٌ'), 'سلام');
      expect(ArabicSearch.normalize('رحمٰن'), 'رحمن');
      expect(ArabicSearch.normalize('كـتـاب'), 'كتاب');
    });

    test('trims and lower-cases', () {
      expect(ArabicSearch.normalize('  Abc '), 'abc');
    });
  });

  group('ArabicSearch.matches', () {
    test('matches a spelling variant inside a longer text', () {
      expect(ArabicSearch.matches('حلقة الفجر', 'حلقه'), isTrue);
      expect(ArabicSearch.matches('سَلَامٌ عليكم', 'سلام'), isTrue);
    });

    test('an empty query matches everything', () {
      expect(ArabicSearch.matches('أي نص', '  '), isTrue);
    });

    test('a different word does not match', () {
      expect(ArabicSearch.matches('حلقة الفجر', 'العصر'), isFalse);
    });
  });
}
