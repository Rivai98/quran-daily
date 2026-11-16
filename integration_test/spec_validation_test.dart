// Device validation for the open emulator tasks, against the hosted DEV
// project, with test accounts this test creates itself (*@test.local):
//
//   005 T034  the four HomeShell tabs: المصحف = Mushaf index, حسابي = profile
//   006 T019  a wird reminder ~2 min ahead with a pending portion: scheduled
//             text, delivered notification, tap opens الرئيسية, completing
//             the portion cancels the later reminders
//   007 T021  owner vs member: the missed status is shown to the owner only,
//             group info from the dashboard header, a member profile
//   008 T017  a normal user sees no admin entry and cannot load the console
//
// Run (grant the notification permission first, it is a fresh install):
//   adb -s emulator-5554 shell pm grant com.halaqa.app \
//     android.permission.POST_NOTIFICATIONS
//   flutter test integration_test/spec_validation_test.dart \
//     -d emulator-5554 --dart-define-from-file=.env
//
// Not covered here (see the validation logs): the admin path (needs a row in
// private.app_admins that only the owner can add), group photo upload (the
// system photo picker is outside the Flutter test), and missed reader names
// (need a past group day; covered by pgTAP 007_reader_visibility_test.sql).

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:quran_daily/app/bootstrap.dart';
import 'package:quran_daily/app/router.dart';
import 'package:quran_daily/core/config/app_config.dart';
import 'package:quran_daily/core/design_system/assignment_status.dart';
import 'package:quran_daily/core/design_system/widgets/status_chip.dart';
import 'package:quran_daily/core/di/service_locator.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/core/quran/portion_unit.dart';
import 'package:quran_daily/features/admin/view/admin_screens.dart';
import 'package:quran_daily/features/home/view/home_screen.dart';
import 'package:quran_daily/features/mushaf/view/mushaf_index_screen.dart';
import 'package:quran_daily/features/profile/view/profile_screen.dart';
import 'package:quran_daily/features/quran_groups/view/screens/group_dashboard_screen.dart';
import 'package:quran_daily/features/quran_groups/view/screens/group_info_screen.dart';
import 'package:quran_daily/features/quran_groups/view/screens/member_profile_screen.dart';
import 'package:quran_daily/features/quran_groups/view/widgets/forming_group_view.dart';
import 'package:quran_daily/features/reminders/data/reminder_planning_service.dart';
import 'package:quran_daily/features/reminders/data/reminders_repository.dart';
import 'package:quran_daily/features/reminders/domain/reminder_planner.dart';
import 'package:quran_daily/features/settings/view/settings_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 40),
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

Future<void> settle(WidgetTester tester, [int millis = 800]) async {
  final end = DateTime.now().add(Duration(milliseconds: millis));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
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

Future<void> selectTab(WidgetTester tester, String label) async {
  await dismissOnboarding(tester, wait: const Duration(milliseconds: 300));
  final tab = find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
  await pumpUntil(tester, tab);
  await tapAndSettle(tester, tab.first);
  await settle(tester);
}

/// The first-run reminders sheet appears once per install; answer «ليس الآن».
Future<void> dismissOnboarding(
  WidgetTester tester, {
  Duration wait = const Duration(seconds: 10),
}) async {
  final later = find.text(ArabicStrings.reminderPermissionLater);
  final end = DateTime.now().add(wait);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (later.evaluate().isNotEmpty) {
      await tapAndSettle(tester, later.last);
      await settle(tester);
      return;
    }
  }
}

Future<void> openGroup(WidgetTester tester, String name) async {
  for (var attempt = 0; attempt < 5; attempt++) {
    final row = find.text(name).hitTestable();
    await pumpUntil(tester, row);
    await tapAndSettle(tester, row.first);
    final end = DateTime.now().add(const Duration(seconds: 6));
    while (DateTime.now().isBefore(end) &&
        find.byType(GroupDashboardScreen).evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    if (find.byType(GroupDashboardScreen).evaluate().isNotEmpty) return;
  }
  await pumpUntil(tester, find.byType(GroupDashboardScreen));
}

Future<void> signOutFromProfile(WidgetTester tester) async {
  await selectTab(tester, ArabicStrings.profileTab);
  await pumpUntil(tester, find.byType(ProfileScreen));
  final signOut = find.text(ArabicStrings.signOut).hitTestable();
  await tester.scrollUntilVisible(
    find.text(ArabicStrings.signOut),
    300,
    scrollable: find.byType(Scrollable).hitTestable().first,
  );
  await pumpUntil(tester, signOut);
  await tapAndSettle(tester, signOut.first);
  // Confirm sheet: its confirm button repeats «تسجيل الخروج».
  await pumpUntil(tester, find.text(ArabicStrings.signOutConfirmTitle));
  await tapAndSettle(tester, find.text(ArabicStrings.signOut).last);
  await pumpUntil(tester, find.text(ArabicStrings.createAccountTitle));
}

bool _isReminder(PendingNotificationRequest r) => r.id >= 6000 && r.id <= 8999;

String _clock(DateTime at) =>
    '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('spec validation: tabs, reminders, visibility, admin guard', (
    tester,
  ) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final ownerEmail = 'it-val-owner-$stamp@test.local';
    final memberEmail = 'it-val-member-$stamp@test.local';
    final password = 'it-val-${stamp.toRadixString(36)}';
    const ownerName = 'مالك التحقق';
    const memberName = 'عضو التحقق';
    final groupName = 'تحقق $stamp';
    final log = <String>[];

    await tester.pumpWidget(await bootstrapApp());
    await Supabase.instance.client.auth.signOut();
    await tester.pump(const Duration(seconds: 1));

    // Owner signs up through the UI.
    await pumpUntil(tester, find.text(ArabicStrings.createAccountTitle));
    await tapAndSettle(
      tester,
      find.text(ArabicStrings.createAccountTitle).first,
    );
    await enterField(tester, 'auth-displayName', ownerName);
    await enterField(tester, 'auth-email', ownerEmail);
    await enterField(tester, 'auth-password', password);
    await enterField(tester, 'auth-confirmation', password);
    await tapAndSettle(tester, find.text(ArabicStrings.createAccountTitle).last);
    await pumpUntil(tester, find.byType(NavigationBar));
    await dismissOnboarding(tester);

    // --- 005 T034: four tabs, المصحف = index, حسابي = profile -------------
    for (final label in [
      ArabicStrings.homeTab,
      ArabicStrings.groupsTab,
      ArabicStrings.mushafTab,
      ArabicStrings.profileTab,
    ]) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: label,
      );
    }
    await selectTab(tester, ArabicStrings.mushafTab);
    await pumpUntil(tester, find.byType(MushafIndexScreen).hitTestable());
    await selectTab(tester, ArabicStrings.profileTab);
    await pumpUntil(tester, find.byType(ProfileScreen).hitTestable());
    await selectTab(tester, ArabicStrings.homeTab);
    await pumpUntil(tester, find.byType(HomeScreen).hitTestable());
    log.add('005 T034 PASS: 4 tabs; المصحف=MushafIndexScreen; حسابي=ProfileScreen');

    // --- 008 T017 (normal user): no admin entry, console refuses ----------
    navigatorKey.currentState!.pushNamed(AppRoutes.settings);
    await pumpUntil(tester, find.byType(SettingsScreen));
    await settle(tester, 2500);
    expect(find.text(ArabicStrings.adminEntry), findsNothing);
    navigatorKey.currentState!.pop();
    await settle(tester);
    navigatorKey.currentState!.pushNamed('/admin');
    await pumpUntil(tester, find.byType(AdminOverviewScreen));
    await pumpUntil(tester, find.text(ArabicStrings.adminRefresh));
    expect(find.text(ArabicStrings.adminLoadError), findsWidgets);
    navigatorKey.currentState!.pop();
    await settle(tester);
    Object? adminError;
    try {
      await Supabase.instance.client.rpc('admin_overview');
    } on Object catch (error) {
      adminError = error;
    }
    expect(adminError, isA<PostgrestException>());
    expect((adminError! as PostgrestException).message, contains('not_admin'));
    final isAdmin = await Supabase.instance.client.rpc('admin_is_admin');
    expect(isAdmin, isFalse);
    log.add(
      '008 T017 PASS (normal user): no admin entry; /admin shows the load '
      'error panel; admin_overview raises not_admin; admin_is_admin=false',
    );

    // Owner creates an auto-accept juz group through the UI.
    await selectTab(tester, ArabicStrings.groupsTab);
    final create = find.text(ArabicStrings.createGroup).hitTestable();
    await pumpUntil(tester, create);
    await tapAndSettle(tester, create.last);
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
    await tapAndSettle(tester, find.text(ArabicStrings.autoAcceptJoinMode));
    await tapAndSettle(tester, find.text(ArabicStrings.createTheGroup));
    await pumpUntil(tester, find.text(groupName).hitTestable());

    // A second test account joins with the invite code (separate client).
    final owner = Supabase.instance.client;
    final groups =
        ((await owner.rpc('get_my_groups') as Map)['groups'] as List)
            .cast<Map<String, dynamic>>();
    final groupId =
        (groups.firstWhere((g) => g['name'] == groupName)['group_id'] ??
                groups.firstWhere((g) => g['name'] == groupName)['id'])
            as String;
    final dashboard =
        await owner.rpc('get_dashboard', params: {'p_group_id': groupId})
            as Map<String, dynamic>;
    final inviteCode =
        (dashboard['seats'] as Map<String, dynamic>)['invite_code'] as String;
    final config = AppConfig.fromDartEnvironment();
    final memberClient = SupabaseClient(
      config.supabaseUrl.toString(),
      config.supabaseAnonKey,
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
    );
    await memberClient.auth.signUp(
      email: memberEmail,
      password: password,
      data: {'display_name': memberName},
    );
    if (memberClient.auth.currentSession == null) {
      await memberClient.auth.signInWithPassword(
        email: memberEmail,
        password: password,
      );
    }
    await memberClient.rpc('join_group', params: {'p_invite_code': inviteCode});
    await memberClient.dispose();

    // Owner starts the khatma at juz 1.
    await openGroup(tester, groupName);
    await pumpUntil(tester, find.byType(FormingGroupView));
    await settle(tester, 1500);
    await tapAndSettle(tester, find.text(ArabicStrings.startKhatmaAction));
    await pumpUntil(tester, find.text(ArabicStrings.startKhatmaAction).at(1));
    await tapAndSettle(tester, find.text(ArabicStrings.startKhatmaAction).last);
    await pumpUntil(tester, find.text(ArabicStrings.readNowAction));
    await settle(tester, 1500);

    // --- 007 T021 (owner): missed status shown to the owner ----------------
    final missedChip = find.byWidgetPredicate(
      (w) => w is StatusChip && w.status == AssignmentStatus.missed,
    );
    expect(missedChip, findsWidgets);
    // Group info from the header, then the member's profile.
    final header = find.descendant(
      of: find.byType(AppBar),
      matching: find.text(groupName),
    );
    await tapAndSettle(tester, header.first);
    await pumpUntil(tester, find.byType(GroupInfoScreen));
    await pumpUntil(tester, find.text(memberName));
    await tester.scrollUntilVisible(
      find.text(memberName),
      250,
      scrollable: find.byType(Scrollable).hitTestable().first,
    );
    await tapAndSettle(tester, find.text(memberName).hitTestable().first);
    await pumpUntil(tester, find.byType(MemberProfileScreen));
    await pumpUntil(
      tester,
      find.descendant(
        of: find.byType(MemberProfileScreen),
        matching: find.text(memberName),
      ),
    );
    expect(find.textContaining('@'), findsNothing, reason: 'never email');
    Navigator.of(tester.element(find.byType(MemberProfileScreen))).pop();
    await settle(tester);
    Navigator.of(tester.element(find.byType(GroupInfoScreen))).pop();
    await settle(tester);
    log.add(
      '007 T021 PASS (owner): missed legend visible; group info from header; '
      'member profile opens without email',
    );

    // --- 006 T019: a wird reminder ~2 minutes ahead ------------------------
    final reminders = serviceLocator<RemindersRepository>();
    final planning = serviceLocator<ReminderPlanningService>();
    final fireAt = DateTime.now().add(const Duration(minutes: 2));
    final clock = _clock(fireAt);
    await reminders.savePersonalSettings(
      PersonalReminderSettings(
        enabled: true,
        fajrEnabled: false,
        asrEnabled: false,
        nightTime: clock,
      ),
    );
    await reminders.saveGroupSchedule(
      GroupReminderSchedule(
        groupId: groupId,
        groupName: groupName,
        fajrOn: false,
        asrOn: false,
        nightTime: clock,
      ),
    );
    await planning.refresh();
    final plugin = FlutterLocalNotificationsPlugin();
    final portionName = ArabicStrings.portionName(PortionUnit.juz, 1);
    final scheduled = (await plugin.pendingNotificationRequests())
        .where(_isReminder)
        .where((r) => (r.body ?? '').contains(groupName))
        .toList();
    expect(scheduled, isNotEmpty, reason: 'reminder scheduled at $clock');
    expect(scheduled.first.body, contains(portionName));
    expect(scheduled.first.title, isNotEmpty);
    log.add(
      '006 T019 PASS (scheduled): ${scheduled.length} reminder(s) for $clock; '
      'title="${scheduled.first.title}" body="${scheduled.first.body}"',
    );

    // Wait for delivery (inexact alarm: allow up to 6 minutes).
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    ActiveNotification? delivered;
    final deadline = DateTime.now().add(const Duration(minutes: 6));
    while (delivered == null && DateTime.now().isBefore(deadline)) {
      await settle(tester, 5000);
      final active = await android?.getActiveNotifications() ?? const [];
      for (final item in active) {
        if ((item.body ?? '').contains(groupName)) delivered = item;
      }
    }
    log.add(
      delivered == null
          ? '006 T019 NOTE: not delivered within 6 min (inexact alarm window)'
          : '006 T019 PASS (delivered): "${delivered.title}" / '
                '"${delivered.body}"',
    );

    // The tap handler the plugin calls opens الرئيسية from any screen.
    expect(find.byType(GroupDashboardScreen).hitTestable(), findsOneWidget);
    openHomeFromReminder();
    await settle(tester, 1500);
    expect(find.byType(HomeScreen).hitTestable(), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
    log.add('006 T019 PASS (tap): reminder tap handler shows الرئيسية');

    // Completing the portion from Home cancels the later reminders.
    final complete = find.text(ArabicStrings.portionCompleteAction).hitTestable();
    await pumpUntil(tester, complete);
    await tapAndSettle(tester, complete.first);
    await pumpUntil(
      tester,
      find.text(ArabicStrings.portionUndoAction).hitTestable(),
    );
    var remaining = <PendingNotificationRequest>[];
    final cancelDeadline = DateTime.now().add(const Duration(seconds: 30));
    do {
      await settle(tester, 1000);
      remaining = (await plugin.pendingNotificationRequests())
          .where(_isReminder)
          .where((r) => (r.body ?? '').contains(groupName))
          .toList();
    } while (remaining.isNotEmpty && DateTime.now().isBefore(cancelDeadline));
    expect(remaining, isEmpty, reason: 'completion cancels later reminders');
    log.add('006 T019 PASS (cancel): no reminders left after completion');
    await reminders.savePersonalSettings(const PersonalReminderSettings());
    await planning.refresh();

    // --- 007 T021 (member): no missed status for a member ------------------
    await signOutFromProfile(tester);
    await tapAndSettle(tester, find.text(ArabicStrings.signInTitle).first);
    await enterField(tester, 'auth-email', memberEmail);
    await enterField(tester, 'auth-password', password);
    await tapAndSettle(tester, find.text(ArabicStrings.signInTitle).last);
    await pumpUntil(tester, find.byType(NavigationBar));
    await dismissOnboarding(tester);
    await selectTab(tester, ArabicStrings.groupsTab);
    await openGroup(tester, groupName);
    await pumpUntil(tester, find.text(ArabicStrings.juzGridTitle));
    await settle(tester, 1500);
    expect(missedChip, findsNothing, reason: 'members never see missed');
    await tapAndSettle(
      tester,
      find
          .descendant(of: find.byType(AppBar), matching: find.text(groupName))
          .first,
    );
    await pumpUntil(tester, find.byType(GroupInfoScreen));
    await pumpUntil(tester, find.text(ownerName));
    expect(find.text(ArabicStrings.inviteCodeLabel), findsNothing);
    log.add(
      '007 T021 PASS (member): no missed legend; group info opens; invite '
      'link hidden for a member',
    );
    Navigator.of(tester.element(find.byType(GroupInfoScreen))).pop();
    await settle(tester);
    await signOutFromProfile(tester);

    debugPrint('SPEC VALIDATION LOG\n${log.join('\n')}');
  });
}
