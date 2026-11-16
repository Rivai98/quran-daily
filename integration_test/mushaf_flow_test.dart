// T019 (spec 003) - in-app Mushaf portion reading against the hosted DEV
// project.
//
// Run on an Android phone/emulator:
//   flutter test integration_test/mushaf_flow_test.dart \
//     -d <device-id> --dart-define-from-file=.env
//
// Flow: sign up (UI) -> create a hizb group -> start the khatma -> "اقرأ الآن"
// opens the reader on the start page of hizb 1 -> bookmark it (synced to the
// account) -> swipe to the end page -> "تمت القراءة" -> the server dashboard
// shows the assignment completed.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quran_daily/app/bootstrap.dart';
import 'package:quran_daily/core/design_system/widgets/status_chip.dart';
import 'package:quran_daily/core/di/service_locator.dart';
import 'package:quran_daily/core/localization/arabic_numerals.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/core/quran/mushaf/mushaf_repository.dart';
import 'package:quran_daily/core/quran/portion_unit.dart';
import 'package:quran_daily/features/mushaf/data/mushaf_sync_repository.dart';
import 'package:quran_daily/features/mushaf/view/reader_screen.dart';
import 'package:quran_daily/features/quran_groups/view/screens/group_dashboard_screen.dart';
import 'package:quran_daily/features/quran_groups/view/widgets/forming_group_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/onboarding.dart';

Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  final visible = find
      .byType(Text)
      .evaluate()
      .map((e) => (e.widget as Text).data)
      .whereType<String>()
      .join(' | ');
  throw TestFailure('Timed out waiting for $finder. On screen: $visible');
}

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> enterField(WidgetTester tester, String key, String text) async {
  final field = find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(EditableText),
  );
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump();
}

final _pageView = find.byKey(const ValueKey('mushaf-page-view'));

int _visiblePage(WidgetTester tester) =>
    tester.widget<PageView>(_pageView).controller!.page!.round() + 1;

Finder _pageHeader(int page) => find.textContaining(
  '${ArabicStrings.pageNumberLabel} ${ArabicNumerals.format(page)}',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hizb portion: read now -> end page -> completed on server', (
    tester,
  ) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final groupName = 'مصحف $stamp';

    await tester.pumpWidget(await bootstrapApp());
    await Supabase.instance.client.auth.signOut();
    await tester.pump(const Duration(seconds: 1));

    // Sign up.
    await pumpUntil(tester, find.text(ArabicStrings.createAccountTitle));
    await tapAndSettle(
      tester,
      find.text(ArabicStrings.createAccountTitle).first,
    );
    await enterField(tester, 'auth-displayName', 'اختبار المصحف');
    await enterField(tester, 'auth-email', 'it-mushaf-$stamp@test.local');
    await enterField(tester, 'auth-password', 'it-pass-12345');
    await enterField(tester, 'auth-confirmation', 'it-pass-12345');
    await tapAndSettle(
      tester,
      find.text(ArabicStrings.createAccountTitle).last,
    );
    await pumpUntil(tester, find.byType(NavigationBar));
    await dismissReminderOnboarding(tester);

    // Create a group with the hizb unit (from the مجموعاتي tab).
    await pumpUntil(tester, find.text(ArabicStrings.groupsTab));
    await tapAndSettle(tester, find.text(ArabicStrings.groupsTab).last);
    await pumpUntil(tester, find.text(ArabicStrings.createGroup));
    await tapAndSettle(tester, find.text(ArabicStrings.createGroup).last);
    await pumpUntil(tester, find.text(ArabicStrings.groupNameLabel));
    final nameField = find.descendant(
      of: find
          .ancestor(
            of: find.text(ArabicStrings.groupNameLabel),
            matching: find.byType(Column),
          )
          .first,
      matching: find.byType(EditableText),
    );
    await tester.enterText(nameField, groupName);
    await tester.pump();
    await tapAndSettle(
      tester,
      find.text(ArabicStrings.portionUnitName(PortionUnit.hizb)).first,
    );
    await tapAndSettle(tester, find.text(ArabicStrings.createTheGroup));

    // Open it (retry while the list refreshes).
    for (var attempt = 0; attempt < 5; attempt++) {
      await pumpUntil(tester, find.text(groupName));
      await tapAndSettle(tester, find.text(groupName).first);
      final end = DateTime.now().add(const Duration(seconds: 6));
      while (DateTime.now().isBefore(end) &&
          find.byType(GroupDashboardScreen).evaluate().isEmpty) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      if (find.byType(GroupDashboardScreen).evaluate().isNotEmpty) break;
    }
    await pumpUntil(tester, find.byType(FormingGroupView));

    // Start at portion 1 (default in the sheet).
    await tapAndSettle(tester, find.text(ArabicStrings.startKhatmaAction));
    await pumpUntil(tester, find.text(ArabicStrings.startKhatmaAction));
    await tapAndSettle(tester, find.text(ArabicStrings.startKhatmaAction).last);
    await pumpUntil(tester, find.text(ArabicStrings.readNowAction));

    // The owner (seat 1) reads hizb 1 today.
    final mushaf = serviceLocator<MushafRepository>();
    await mushaf.load();
    final range = mushaf.portionRange(PortionUnit.hizb, 1);
    expect(range.endPage, greaterThan(range.startPage));

    // "اقرأ الآن" opens the reader on the portion's start page.
    await tapAndSettle(tester, find.text(ArabicStrings.readNowAction).first);
    await pumpUntil(tester, _pageView, timeout: const Duration(seconds: 60));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ReaderScreen), findsOneWidget);
    expect(_pageHeader(range.startPage), findsOneWidget);
    expect(_visiblePage(tester), range.startPage);
    expect(
      find.widgetWithText(FilledButton, ArabicStrings.completeReadingAction),
      findsNothing,
    );
    expect(
      find.textContaining(ArabicStrings.portionName(PortionUnit.hizb, 1)),
      findsWidgets,
    );

    // Bookmark the start page; it reaches the account's bookmarks table.
    await tapAndSettle(tester, find.byTooltip(ArabicStrings.addBookmarkAction));
    await pumpUntil(tester, find.text(ArabicStrings.save));
    await tapAndSettle(tester, find.text(ArabicStrings.save));
    await pumpUntil(tester, find.text(ArabicStrings.bookmarkSaved));
    await serviceLocator<MushafSyncRepository>().sync();
    final client = Supabase.instance.client;
    final remoteBookmarks = await client
        .from('bookmarks')
        .select('page, surah')
        .eq('user_id', client.auth.currentUser!.id);
    expect(remoteBookmarks, hasLength(1));
    expect(remoteBookmarks.single['page'], range.startPage);

    // Swipe forward (right-to-left, like a printed Mushaf) to the end page.
    for (var i = 0; i < 40 && _visiblePage(tester) < range.endPage; i++) {
      final before = _visiblePage(tester);
      await tester.fling(_pageView, const Offset(-400, 0), 1500);
      await tester.pump(const Duration(milliseconds: 600));
      expect(_visiblePage(tester), before + 1, reason: 'swipe goes forward');
    }
    await pumpUntil(tester, _pageHeader(range.endPage));
    expect(_visiblePage(tester), range.endPage);

    // "تمت القراءة" is offered on the end page and completes the assignment.
    await pumpUntil(tester, find.text(ArabicStrings.completeReadingAction));
    await tapAndSettle(tester, find.text(ArabicStrings.completeReadingAction));
    await pumpUntil(
      tester,
      find.descendant(
        of: find.byType(ReaderScreen),
        matching: find.byType(StatusChip),
      ),
    );
    // The completed chip reuses the same words; the action button is gone.
    expect(
      find.widgetWithText(FilledButton, ArabicStrings.completeReadingAction),
      findsNothing,
    );

    // Server check: the owner's hizb 1 assignment is completed.
    final myGroups = await client.rpc('get_my_groups') as Map<String, dynamic>;
    final group = (myGroups['groups'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .firstWhere((g) => g['name'] == groupName);
    final dashboard = await client.rpc(
      'get_dashboard',
      params: {'p_group_id': group['group_id']},
    ) as Map<String, dynamic>;
    final mine = (dashboard['assignments'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .firstWhere((a) => a['portion_index'] == 1);
    expect(mine['seat_number'], 1);
    expect(mine['status'], 'completed');
  });
}
