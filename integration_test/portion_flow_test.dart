// T016 (spec 004) - hizb group end-to-end against the hosted DEV project.
//
// Run on an Android phone/emulator:
//   flutter test integration_test/portion_flow_test.dart \
//     -d <device-id> --dart-define-from-file=.env
//
// Flow: sign up (UI) -> create a group choosing the hizb unit -> open it ->
// start the khatma at portion 1 -> the dashboard shows hizb portions, and the
// server's day-1 assignments are hizb 1..30 for seats 1..30 in a 2-day cycle.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quran_daily/app/bootstrap.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/core/quran/portion_unit.dart';
import 'package:quran_daily/features/quran_groups/view/screens/group_dashboard_screen.dart';
import 'package:quran_daily/features/quran_groups/view/screens/create_group_screen.dart';
import 'package:quran_daily/features/quran_groups/view/widgets/forming_group_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hizb group: day 1 assigns hizb 1..30 in a 2-day cycle', (
    tester,
  ) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final groupName = 'حزب $stamp';

    await tester.pumpWidget(await bootstrapApp());
    await Supabase.instance.client.auth.signOut();
    await tester.pump(const Duration(seconds: 1));

    // Sign up.
    await pumpUntil(tester, find.text(ArabicStrings.createAccountTitle));
    await tapAndSettle(
      tester,
      find.text(ArabicStrings.createAccountTitle).first,
    );
    await enterField(tester, 'auth-displayName', 'اختبار الأحزاب');
    await enterField(tester, 'auth-email', 'it-hizb-$stamp@test.local');
    await enterField(tester, 'auth-password', 'it-pass-12345');
    await enterField(tester, 'auth-confirmation', 'it-pass-12345');
    await tapAndSettle(
      tester,
      find.text(ArabicStrings.createAccountTitle).last,
    );

    // Create a group with the hizb unit.
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

    // The name finder also matches the editable field until the async create
    // call pops the form, so wait for that route to leave before finding the row.
    final createRouteEnd = DateTime.now().add(const Duration(seconds: 30));
    while (find.byType(CreateGroupScreen).evaluate().isNotEmpty &&
        DateTime.now().isBefore(createRouteEnd)) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.byType(CreateGroupScreen), findsNothing);

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
    await pumpUntil(tester, find.text(ArabicStrings.openTodayWird));

    // The owner (seat 1) reads hizb 1 today.
    expect(
      find.textContaining(ArabicStrings.portionName(PortionUnit.hizb, 1)),
      findsWidgets,
    );

    // Server check: day 1 assigns hizb s to seat s, cycle length 2.
    final client = Supabase.instance.client;
    final myGroups = await client.rpc('get_my_groups') as Map<String, dynamic>;
    final group = (myGroups['groups'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .firstWhere((g) => g['name'] == groupName);
    expect(group['portion_unit'], 'hizb');
    final dashboard =
        await client.rpc(
              'get_dashboard',
              params: {'p_group_id': group['group_id']},
            )
            as Map<String, dynamic>;
    final assignments = (dashboard['assignments'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(assignments, hasLength(30));
    for (final a in assignments) {
      expect(a['portion_index'], a['seat_number'], reason: 'day 1 seat = hizb');
    }
    // The RPC nests cycle fields in `today` (cycle_number/day/length).
    final cycle =
        (dashboard['cycle'] ?? dashboard['today']) as Map<String, dynamic>;
    expect(cycle['length'] ?? cycle['cycle_length'], 2);
  });
}
