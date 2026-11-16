// T035 - Today home and profile journey against hosted DEV Supabase.
//
// Compile with the other integration tests; run only on a connected device:
//   flutter test integration_test/home_flow_test.dart -d <device-id> --dart-define-from-file=.env

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quran_daily/app/bootstrap.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/core/quran/portion_unit.dart';
import 'package:quran_daily/features/profile/view/profile_screen.dart';
import 'package:quran_daily/features/quran_groups/view/screens/group_dashboard_screen.dart';
import 'package:quran_daily/features/quran_groups/view/screens/create_group_screen.dart';
import 'package:quran_daily/features/quran_groups/view/widgets/forming_group_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/onboarding.dart';

Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 35),
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
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> enterField(WidgetTester tester, String key, String value) async {
  final field = find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(EditableText),
  );
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pump();
}

Future<void> createGroup(WidgetTester tester, String name) async {
  await pumpUntil(tester, find.text(ArabicStrings.groupsTab));
  await tapAndSettle(tester, find.text(ArabicStrings.groupsTab).last);
  while (find.byType(GroupDashboardScreen).evaluate().isNotEmpty) {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }
  await pumpUntil(tester, find.text(ArabicStrings.createGroup));
  await tapAndSettle(tester, find.text(ArabicStrings.createGroup).last);
  await pumpUntil(tester, find.text(ArabicStrings.groupNameLabel));
  final field = find.descendant(
    of: find
        .ancestor(
          of: find.text(ArabicStrings.groupNameLabel),
          matching: find.byType(Column),
        )
        .first,
    matching: find.byType(EditableText),
  );
  await tester.enterText(field, name);
  await tester.pump();
  await tapAndSettle(tester, find.text(ArabicStrings.createTheGroup));
  final end = DateTime.now().add(const Duration(seconds: 30));
  while (find.byType(CreateGroupScreen).evaluate().isNotEmpty &&
      DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(find.byType(CreateGroupScreen), findsNothing);
}

Future<void> attemptCreateGroup(WidgetTester tester, String name) async {
  await pumpUntil(tester, find.text(ArabicStrings.groupsTab));
  await tapAndSettle(tester, find.text(ArabicStrings.groupsTab).last);
  while (find.byType(GroupDashboardScreen).evaluate().isNotEmpty) {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }
  await pumpUntil(tester, find.text(ArabicStrings.createGroup));
  await tapAndSettle(tester, find.text(ArabicStrings.createGroup).last);
  await pumpUntil(tester, find.text(ArabicStrings.groupNameLabel));
  final field = find.descendant(
    of: find
        .ancestor(
          of: find.text(ArabicStrings.groupNameLabel),
          matching: find.byType(Column),
        )
        .first,
    matching: find.byType(EditableText),
  );
  await tester.enterText(field, name);
  await tester.pump();
  await tapAndSettle(tester, find.text(ArabicStrings.createTheGroup));
  await pumpUntil(tester, find.text(ArabicStrings.membershipLimitMessage));
  expect(find.byType(CreateGroupScreen), findsOneWidget);
}

Future<void> openGroup(WidgetTester tester, String name) async {
  for (var attempt = 0; attempt < 5; attempt++) {
    await pumpUntil(tester, find.text(name));
    await tapAndSettle(tester, find.text(name).first);
    final end = DateTime.now().add(const Duration(seconds: 6));
    while (DateTime.now().isBefore(end) &&
        find.byType(GroupDashboardScreen).evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    if (find.byType(GroupDashboardScreen).evaluate().isNotEmpty) break;
  }
  await pumpUntil(tester, find.byType(FormingGroupView));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Home refreshes today after a group khatma starts', (
    tester,
  ) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    const password = 'it-pass-12345';
    final groupName = 'Home test $stamp';

    await tester.pumpWidget(await bootstrapApp());
    await Supabase.instance.client.auth.signOut();
    await tester.pump(const Duration(seconds: 1));

    await pumpUntil(tester, find.text(ArabicStrings.createAccountTitle));
    await tapAndSettle(
      tester,
      find.text(ArabicStrings.createAccountTitle).first,
    );
    await enterField(tester, 'auth-displayName', 'Home test user');
    await enterField(tester, 'auth-email', 'it-home-$stamp@test.local');
    await enterField(tester, 'auth-password', password);
    await enterField(tester, 'auth-confirmation', password);
    await tapAndSettle(
      tester,
      find.text(ArabicStrings.createAccountTitle).last,
    );
    await pumpUntil(tester, find.byType(NavigationBar));
    await dismissReminderOnboarding(tester);

    await createGroup(tester, groupName);
    await openGroup(tester, groupName);
    await tapAndSettle(tester, find.text(ArabicStrings.startKhatmaAction));
    await pumpUntil(tester, find.text(ArabicStrings.startKhatmaAction));
    await tapAndSettle(tester, find.text(ArabicStrings.startKhatmaAction).last);
    await pumpUntil(tester, find.text(ArabicStrings.readNowAction));

    // Return to the default Home tab and verify the assigned portion appears.
    await pumpUntil(tester, find.text(ArabicStrings.homeTab));
    await tapAndSettle(tester, find.text(ArabicStrings.homeTab).last);
    final portionName = ArabicStrings.portionName(PortionUnit.juz, 1);
    await pumpUntil(tester, find.text(portionName));
    expect(find.text(groupName), findsWidgets);
    expect(find.text(portionName), findsWidgets);

    // First time Home is in front: the reminders sheet asks once.
    await dismissReminderOnboarding(tester);
    await tapAndSettle(tester, find.text(ArabicStrings.portionCompleteAction));
    await pumpUntil(tester, find.text(ArabicStrings.portionUndoAction));

    await pumpUntil(tester, find.text(ArabicStrings.profileTab));
    await tapAndSettle(tester, find.text(ArabicStrings.profileTab).last);
    await pumpUntil(tester, find.byType(ProfileScreen));
    await pumpUntil(tester, find.text(ArabicStrings.profileTitle));

    // Spec 005 FR-004c: two active memberships are allowed; the third is not.
    final secondGroupName = 'Home second group $stamp';
    await createGroup(tester, secondGroupName);
    await attemptCreateGroup(tester, 'Home third group $stamp');
    expect(find.text(ArabicStrings.membershipLimitMessage), findsOneWidget);
  });
}
