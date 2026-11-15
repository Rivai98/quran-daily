import 'arabic_numerals.dart';

/// Arabic-first templates for copy that mixes text, numbers, and separators.
class ArabicFormatting {
  const ArabicFormatting._();

  static String isolate(Object value) => '\u2068$value\u2069';

  static String membersProgress(int members, {int total = 30}) =>
      '${isolate(ArabicNumerals.format(members))} من ${isolate(ArabicNumerals.format(total))} عضوًا';

  static String completedProgress(int completed, int total) =>
      'أُنجز ${isolate(ArabicNumerals.format(completed))} من ${isolate(ArabicNumerals.format(total))}';

  static String pageAyahMeta(int page, int ayahs) =>
      'صفحة ${isolate(ArabicNumerals.format(page))}، ${isolate(ArabicNumerals.format(ayahs))} آيات';

  static String timezoneCity(String timezone) => switch (timezone) {
    'Africa/Cairo' => 'القاهرة',
    'Asia/Riyadh' => 'الرياض',
    'Asia/Makkah' => 'مكة',
    'Asia/Madinah' => 'المدينة',
    'UTC' => 'التوقيت العالمي',
    _ => 'التوقيت المحلي',
  };
}
