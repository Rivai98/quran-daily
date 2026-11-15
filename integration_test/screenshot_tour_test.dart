// Screenshot tour for design review, against the hosted DEV project.
//
// Run on an Android phone/emulator with the screenshot driver:
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshot_tour_test.dart \
//     -d <device-id> --dart-define-from-file=.env
//
// Screenshots land in build/screenshots/<name>.png. Each screen is captured
// in light mode and again in dark mode (platform brightness; the app follows
// ThemeMode.system). Signs up a fresh it-tour-<timestamp>@test.local account
// through the UI; the dev DB keeps it.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quran_daily/app/bootstrap.dart';
import 'package:quran_daily/app/router.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/mushaf/view/reader_screen.dart';
import 'package:quran_daily/features/quran_groups/view/screens/group_dashboard_screen.dart';
import 'package:quran_daily/features/quran_groups/view/screens/history_screen.dart';
import 'package:quran_daily/features/quran_groups/view/screens/personal_assignment_screen.dart';
import 'package:quran_daily/features/quran_groups/view/widgets/forming_group_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

late IntegrationTestWidgetsFlutterBinding binding;
final List<String> taken = [];
final List<String> skipped = [];

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

/// Captures [name] in light mode and, unless [darkToo] is false, in dark mode.
Future<void> shot(
  WidgetTester tester,
  String name, {
  bool darkToo = true,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  binding.platformDispatcher.platformBrightnessTestValue = Brightness.light;
  await settle(tester);
  await binding.takeScreenshot('${name}_light');
  taken.add('${name}_light');
  if (!darkToo) return;
  binding.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
  await settle(tester);
  await binding.takeScreenshot('${name}_dark');
  taken.add('${name}_dark');
  binding.platformDispatcher.platformBrightnessTestValue = Brightness.light;
  await settle(tester, 400);
}

/// Scrolls the top-most visible list until [finder] is on screen.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  final scrollable = find.byType(Scrollable).hitTestable();
  await tester.scrollUntilVisible(
    finder,
    250,
    scrollable: scrollable.first,
    maxScrolls: 40,
  );
  await settle(tester, 400);
}

Future<void> popRoute(WidgetTester tester) async {
  navigatorKey.currentState!.pop();
  await settle(tester);
}

/// Runs one optional stop; a failure is recorded instead of ending the tour.
Future<void> optional(
  WidgetTester tester,
  String name,
  Future<void> Function() body,
) async {
  try {
    await body();
  } catch (error) {
    skipped.add('$name: $error'.split('\n').first);
    debugPrint('TOUR SKIPPED $name: $error');
  }
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot tour of every reachable screen', (tester) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final email = 'it-tour-$stamp@test.local';
    final password = 'it-tour-${stamp.toRadixString(36)}';
    final groupName = 'جولة $stamp';

    await tester.pumpWidget(await bootstrapApp());
    await Supabase.instance.client.auth.signOut();
    await tester.pump(const Duration(seconds: 1));
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
    }

    // Auth: sign in, then create account.
    await pumpUntil(tester, find.text(ArabicStrings.createAccountTitle));
    await tapAndSettle(tester, find.text(ArabicStrings.signInTitle).first);
    await shot(tester, '01_auth_sign_in');
    await tapAndSettle(
      tester,
      find.text(ArabicStrings.createAccountTitle).first,
    );
    await shot(tester, '02_auth_create_account');
    await enterField(tester, 'auth-displayName', 'جولة التصميم');
    await enterField(tester, 'auth-email', email);
    await enterField(tester, 'auth-password', password);
    await enterField(tester, 'auth-confirmation', password);
    await tapAndSettle(tester, find.text(ArabicStrings.createAccountTitle).last);

    // Group list, empty state.
    await pumpUntil(tester, find.text(ArabicStrings.createGroup));
    await pumpUntil(tester, find.text(ArabicStrings.noApprovedGroups));
    await shot(tester, '03_groups_empty');

    // Discovery and invite screens reachable from the empty state.
    await optional(tester, 'discovery', () async {
      navigatorKey.currentState!.pushNamed(AppRoutes.discovery);
      await settle(tester, 2500);
      await shot(tester, '03b_discovery');
      await popRoute(tester);
    });
    await optional(tester, 'invite_join', () async {
      navigatorKey.currentState!.pushNamed('/join');
      await settle(tester, 1500);
      await shot(tester, '03c_invite_join');
      await popRoute(tester);
    });
    await optional(tester, 'join_any', () async {
      navigatorKey.currentState!.pushNamed('/join-any');
      await settle(tester, 1500);
      await shot(tester, '03d_join_any');
      await popRoute(tester);
    });

    // Create group form, then the unit selector.
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
    await shot(tester, '04_create_group_form');
    await optional(tester, 'create_group_unit_selector', () async {
      await scrollTo(tester, find.text(ArabicStrings.createTheGroup));
      await shot(tester, '04b_create_group_unit_selector');
    });
    await tapAndSettle(tester, find.text(ArabicStrings.createTheGroup));

    // Group list with one group.
    await pumpUntil(tester, find.text(groupName));
    await settle(tester, 1500);
    await shot(tester, '05_groups_with_group');

    // Forming dashboard (retry while the list refreshes).
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
    await shot(tester, '06_dashboard_forming');

    // Start sheet.
    await tapAndSettle(tester, find.text(ArabicStrings.startKhatmaAction));
    await pumpUntil(tester, find.text(ArabicStrings.startKhatmaAction).at(1));
    await shot(tester, '07_start_sheet');
    await tapAndSettle(tester, find.text(ArabicStrings.startKhatmaAction).last);

    // Active dashboard.
    await pumpUntil(tester, find.text(ArabicStrings.readNowAction));
    await settle(tester, 1500);
    await shot(tester, '08_dashboard_active');

    // Personal assignment.
    await optional(tester, 'personal_assignment', () async {
      await tapAndSettle(
        tester,
        find.text(ArabicStrings.assignmentDetailsAction).first,
      );
      await pumpUntil(tester, find.byType(PersonalAssignmentScreen));
      await shot(tester, '09_personal_assignment');
      await popRoute(tester);
    });

    // History.
    await optional(tester, 'history', () async {
      await pumpUntil(tester, find.byTooltip(ArabicStrings.openHistoryAction));
      await tapAndSettle(
        tester,
        find.byTooltip(ArabicStrings.openHistoryAction),
      );
      await pumpUntil(tester, find.byType(HistoryScreen));
      await settle(tester, 1500);
      await shot(tester, '10_history');
      await popRoute(tester);
    });

    Future<void> openGroupMenuItem(String label) async {
      await pumpUntil(tester, find.byTooltip(ArabicStrings.groupMenuTooltip));
      await tapAndSettle(tester, find.byTooltip(ArabicStrings.groupMenuTooltip));
      await pumpUntil(tester, find.text(label));
      await tapAndSettle(tester, find.text(label).last);
      await settle(tester, 2000);
    }

    await optional(tester, 'group_menu', () async {
      await pumpUntil(tester, find.byTooltip(ArabicStrings.groupMenuTooltip));
      await tapAndSettle(tester, find.byTooltip(ArabicStrings.groupMenuTooltip));
      await pumpUntil(tester, find.text(ArabicStrings.manageMembersAction));
      await shot(tester, '10b_group_menu');
      navigatorKey.currentState!.pop();
      await settle(tester);
    });
    await optional(tester, 'members', () async {
      await openGroupMenuItem(ArabicStrings.manageMembersAction);
      await shot(tester, '11_members');
      await popRoute(tester);
    });
    await optional(tester, 'join_requests', () async {
      await openGroupMenuItem(ArabicStrings.reviewJoinRequestsAction);
      await shot(tester, '12_join_requests');
      await popRoute(tester);
    });
    await optional(tester, 'group_settings', () async {
      await openGroupMenuItem(ArabicStrings.groupSettingsAction);
      await shot(tester, '13_group_settings');
      await optional(tester, 'group_settings_reminders', () async {
        await scrollTo(tester, find.text(ArabicStrings.reminderGroupTitle));
        await shot(tester, '13b_group_settings_reminders');
      });
      await popRoute(tester);
    });

    // Mushaf reader on the portion's start page.
    await optional(tester, 'mushaf', () async {
      await pumpUntil(tester, find.text(ArabicStrings.readNowAction));
      await tapAndSettle(tester, find.text(ArabicStrings.readNowAction).first);
      await pumpUntil(
        tester,
        find.byKey(const ValueKey('mushaf-page-view')),
        timeout: const Duration(seconds: 60),
      );
      await settle(tester, 1500);
      expect(find.byType(ReaderScreen), findsOneWidget);
      await shot(tester, '14_mushaf_reader_portion_start');

      // Index tabs.
      await optional(tester, 'mushaf_index', () async {
        await tapAndSettle(
          tester,
          find.byTooltip(ArabicStrings.mushafIndexAction),
        );
        await pumpUntil(
          tester,
          find.widgetWithText(Tab, ArabicStrings.surahsTab),
        );
        await settle(tester, 1500);
        const tabs = {
          ArabicStrings.surahsTab: '15a_mushaf_index_surahs',
          ArabicStrings.ajzaaTab: '15b_mushaf_index_ajzaa',
          ArabicStrings.ahzabTab: '15c_mushaf_index_ahzab',
          ArabicStrings.pagesTab: '15d_mushaf_index_pages',
        };
        for (final entry in tabs.entries) {
          await tapAndSettle(tester, find.widgetWithText(Tab, entry.key));
          await settle(tester, 1000);
          await shot(tester, entry.value);
        }
        await popRoute(tester);
      });

      // Bookmark sheet, then the bookmarks list.
      await optional(tester, 'bookmark_sheet', () async {
        await pumpUntil(
          tester,
          find.byTooltip(ArabicStrings.addBookmarkAction),
        );
        await tapAndSettle(
          tester,
          find.byTooltip(ArabicStrings.addBookmarkAction),
        );
        await pumpUntil(tester, find.text(ArabicStrings.save));
        await shot(tester, '16_bookmark_sheet');
        await tapAndSettle(tester, find.text(ArabicStrings.save));
        await settle(tester, 1500);
      });
      await optional(tester, 'bookmarks', () async {
        await tapAndSettle(tester, find.byTooltip(ArabicStrings.bookmarksTitle));
        await settle(tester, 1500);
        await shot(tester, '17_bookmarks');
        await popRoute(tester);
      });
      await optional(tester, 'mushaf_licenses', () async {
        await tapAndSettle(
          tester,
          find.byTooltip(ArabicStrings.mushafLicensesTitle),
        );
        await settle(tester, 1500);
        await shot(tester, '18_mushaf_licenses');
        await popRoute(tester);
      });

      await popRoute(tester);
    });

    // Settings, then its reminders section.
    await optional(tester, 'settings', () async {
      await pumpUntil(tester, find.byTooltip(ArabicStrings.settingsTitle));
      await tapAndSettle(tester, find.byTooltip(ArabicStrings.settingsTitle));
      await settle(tester, 1500);
      await shot(tester, '19_settings');
      await optional(tester, 'settings_reminders', () async {
        await scrollTo(tester, find.text(ArabicStrings.remindersTitle));
        await tester.drag(
          find.byType(Scrollable).hitTestable().first,
          const Offset(0, -200),
        );
        await settle(tester, 600);
        await shot(tester, '19b_settings_reminders');
        await scrollTo(tester, find.text(ArabicStrings.signOut));
        await shot(tester, '19c_settings_bottom');
      });
      expect(find.text(ArabicStrings.adminEntry), findsNothing);
      await popRoute(tester);
    });

    binding.platformDispatcher.clearPlatformBrightnessTestValue();
    debugPrint('TOUR TAKEN (${taken.length}): ${taken.join(', ')}');
    debugPrint('TOUR SKIPPED (${skipped.length}): ${skipped.join(' || ')}');
  });
}
