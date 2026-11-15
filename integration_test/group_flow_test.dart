// T111 - end-to-end group flow against the hosted DEV Supabase project.
//
// Run on a connected Android phone/emulator (mobile only, constitution P2):
//   flutter test integration_test/group_flow_test.dart \
//     -d <device-id> --dart-define-from-file=.env
//
// Flow: sign up (owner, via UI) -> create group -> second user joins with the
// invite code (separate client) -> owner starts the khatma -> opens today's
// wird -> marks it complete -> undoes it (confirm sheet) -> opens history.
// Uses unique it-<timestamp>@test.local accounts; the dev DB keeps them.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_daily/features/quran_groups/cubit/dashboard/dashboard_cubit.dart';
import 'package:quran_daily/features/quran_groups/view/screens/group_dashboard_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quran_daily/app/bootstrap.dart';
import 'package:quran_daily/core/config/app_config.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/quran_groups/view/screens/history_screen.dart';
import 'package:quran_daily/features/quran_groups/view/screens/personal_assignment_screen.dart';
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

  testWidgets('sign up, create, join, start, complete, undo, history', (
    tester,
  ) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final ownerEmail = 'it-owner-$stamp@test.local';
    final memberEmail = 'it-member-$stamp@test.local';
    const password = 'it-pass-12345';
    final groupName = 'اختبار $stamp';

    await tester.pumpWidget(await bootstrapApp());
    // Start signed out even if the phone has a saved session.
    await Supabase.instance.client.auth.signOut();
    await tester.pump(const Duration(seconds: 1));

    // 1. Sign up the owner through the UI.
    await pumpUntil(tester, find.text(ArabicStrings.createAccountTitle));
    await tapAndSettle(tester, find.text(ArabicStrings.createAccountTitle).first);
    await enterField(tester, 'auth-displayName', 'مالك الاختبار');
    await enterField(tester, 'auth-email', ownerEmail);
    await enterField(tester, 'auth-password', password);
    await enterField(tester, 'auth-confirmation', password);
    await tapAndSettle(tester, find.text(ArabicStrings.createAccountTitle).last);

    // 2. Create a group.
    await pumpUntil(tester, find.text(ArabicStrings.createGroup));
    await tapAndSettle(tester, find.text(ArabicStrings.createGroup).last);
    await pumpUntil(tester, find.text(ArabicStrings.groupNameLabel));
    final nameField = find.descendant(
      of: find.ancestor(
        of: find.text(ArabicStrings.groupNameLabel),
        matching: find.byType(Column),
      ).first,
      matching: find.byType(EditableText),
    );
    await tester.enterText(nameField, groupName);
    await tester.pump();
    await tapAndSettle(tester, find.text(ArabicStrings.createTheGroup));

    // 3. Open the new (forming) group.
    await pumpUntil(tester, find.text(groupName));
    await tapAndSettle(tester, find.text(groupName).first);
    try {
      await pumpUntil(tester, find.byType(FormingGroupView));
    } on TestFailure {
      final screen = find.byType(GroupDashboardScreen);
      if (screen.evaluate().isNotEmpty) {
        final state = tester.element(screen).read<DashboardCubit>().state;
        debugPrint('DASHBOARD STATE: ${state.status} failure=${state.failure} '
            'snapshotStatus=${state.snapshot?.status}');
      } else {
        debugPrint('DASHBOARD SCREEN NOT FOUND');
      }
      rethrow;
    }

    // 4. A second user joins with the invite code (separate client).
    final ownerClient = Supabase.instance.client;
    final groups = await ownerClient.rpc('get_my_groups') as List<dynamic>;
    final group = groups
        .cast<Map<String, dynamic>>()
        .firstWhere((g) => g['name'] == groupName);
    final groupId = group['group_id'] ?? group['id'];
    final dashboard =
        await ownerClient.rpc('get_dashboard', params: {'p_group_id': groupId})
            as Map<String, dynamic>;
    final inviteCode =
        (dashboard['seats'] as Map<String, dynamic>)['invite_code'] as String;

    final config = AppConfig.fromDartEnvironment();
    final memberClient = SupabaseClient(
      config.supabaseUrl.toString(),
      config.supabaseAnonKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    await memberClient.auth.signUp(
      email: memberEmail,
      password: password,
      data: {'display_name': 'عضو الاختبار'},
    );
    if (memberClient.auth.currentSession == null) {
      await memberClient.auth.signInWithPassword(
        email: memberEmail,
        password: password,
      );
    }
    await memberClient.rpc('join_group', params: {'p_invite_code': inviteCode});
    await memberClient.dispose();

    // 5. Owner starts the khatma from the forming dashboard.
    await tapAndSettle(tester, find.text(ArabicStrings.startKhatmaAction));
    await pumpUntil(tester, find.text(ArabicStrings.startKhatmaAction));
    await tapAndSettle(tester, find.text(ArabicStrings.startKhatmaAction).last);
    await pumpUntil(tester, find.text(ArabicStrings.openTodayWird));
    expect(find.byType(FormingGroupView), findsNothing);

    // 6. Open today's wird and mark it complete.
    await tapAndSettle(tester, find.text(ArabicStrings.openTodayWird));
    await pumpUntil(tester, find.byType(PersonalAssignmentScreen));
    await tapAndSettle(tester, find.text(ArabicStrings.completeAction));
    await pumpUntil(tester, find.text(ArabicStrings.undoAction));

    // 7. Undo through the confirmation sheet.
    await tapAndSettle(tester, find.text(ArabicStrings.undoAction));
    await pumpUntil(tester, find.text(ArabicStrings.confirmUndoAction));
    await tapAndSettle(tester, find.text(ArabicStrings.confirmUndoAction));
    await pumpUntil(tester, find.text(ArabicStrings.completeAction));

    // 8. Back to the dashboard, then history.
    await tester.pageBack();
    await pumpUntil(tester, find.byTooltip(ArabicStrings.openHistoryAction));
    await tapAndSettle(tester, find.byTooltip(ArabicStrings.openHistoryAction));
    await pumpUntil(tester, find.byType(HistoryScreen));
  });
}
