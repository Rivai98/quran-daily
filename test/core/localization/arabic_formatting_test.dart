import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/localization/arabic_formatting.dart';

void main() {
  test(
    'formats mixed Arabic and numeral templates with directional isolates',
    () {
      expect(
        ArabicFormatting.membersProgress(1),
        '\u2068١\u2069 من \u2068٣٠\u2069 عضوًا',
      );
      expect(
        ArabicFormatting.completedProgress(1, 30),
        'أُنجز \u2068١\u2069 من \u2068٣٠\u2069',
      );
      expect(
        ArabicFormatting.pageAyahMeta(1, 7),
        'صفحة \u2068١\u2069 · \u2068٧\u2069 آيات',
      );
    },
  );
}
