import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';

/// Each `flutter test` run is a fresh install, so the first-run reminders
/// sheet («ذكّرني بوردي اليومي») opens over Home once. Answer «ليس الآن» so
/// the flow under test is not blocked by its modal barrier.
Future<void> dismissReminderOnboarding(
  WidgetTester tester, {
  Duration wait = const Duration(seconds: 10),
}) async {
  final later = find.text(ArabicStrings.reminderPermissionLater);
  final end = DateTime.now().add(wait);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (later.evaluate().isNotEmpty) {
      await tester.tap(later.last);
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      return;
    }
  }
}
