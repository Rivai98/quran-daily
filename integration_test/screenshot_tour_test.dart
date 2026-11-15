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
// through the UI, then walks the HomeShell tabs (الرئيسية / مجموعاتي /
// المصحف / حسابي). The dev DB keeps the account.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quran_daily/app/bootstrap.dart';
import 'package:quran_daily/app/router.dart';
import 'package:quran_daily/core/design_system/widgets/part_tile.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/home/view/home_screen.dart';
import 'package:quran_daily/features/log/view/log_screen.dart';
import 'package:quran_daily/features/mushaf/view/bookmarks_screen.dart';
import 'package:quran_daily/features/mushaf/view/mushaf_index_screen.dart';
import 'package:quran_daily/features/mushaf/view/reader_screen.dart';
import 'package:quran_daily/features/profile/view/profile_screen.dart';
import 'package:quran_daily/features/quran_groups/view/screens/group_dashboard_screen.dart';
import 'package:quran_daily/features/quran_groups/view/screens/group_info_screen.dart';
import 'package:quran_daily/features/quran_groups/view/screens/group_settings_screen.dart';
import 'package:quran_daily/features/quran_groups/view/screens/history_screen.dart';
import 'package:quran_daily/features/quran_groups/view/screens/join_requests_screen.dart';
import 'package:quran_daily/features/quran_groups/view/screens/member_profile_screen.dart';
import 'package:quran_daily/features/quran_groups/view/screens/members_screen.dart';
import 'package:quran_daily/features/quran_groups/view/screens/personal_assignment_screen.dart';
import 'package:quran_daily/features/quran_groups/view/widgets/forming_group_view.dart';
import 'package:quran_daily/features/quran_groups/view/widgets/override_assignment_sheet.dart';
import 'package:quran_daily/features/quran_groups/view/widgets/portion_detail_sheet.dart';
import 'package:quran_daily/features/settings/view/edit_profile_screen.dart';
import 'package:quran_daily/features/settings/view/settings_screen.dart';
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
  await tester.scrollUntilVisible(
    finder,
    250,
    scrollable: find.byType(Scrollable).hitTestable().first,
    maxScrolls: 40,
  );
  await settle(tester, 400);
}

/// Pops the route that contains [onScreen] (works for routes pushed on the
/// root navigator and inside a HomeShell tab navigator alike).
Future<void> popFrom(WidgetTester tester, Finder onScreen) async {
  Navigator.of(tester.element(onScreen.first)).pop();
  await settle(tester);
}

Future<void> selectTab(WidgetTester tester, String label) async {
  final tab = find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
  await pumpUntil(tester, tab);
  await tapAndSettle(tester, tab.first);
  await settle(tester, 1000);
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

Future<void> openGroup(WidgetTester tester, String groupName) async {
  for (var attempt = 0; attempt < 5; attempt++) {
    final row = find.text(groupName).hitTestable();
    await pumpUntil(tester, row);
    await tapAndSettle(tester, row.first);
    final end = DateTime.now().add(const Duration(seconds: 6));
    while (DateTime.now().isBefore(end) &&
        find.byType(GroupDashboardScreen).evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    if (find.byType(GroupDashboardScreen).evaluate().isNotEmpty) break;
  }
  await pumpUntil(tester, find.byType(GroupDashboardScreen));
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot tour of every reachable screen', (tester) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final email = 'it-tour-$stamp@test.local';
    final password = 'it-tour-${stamp.toRadixString(36)}';
    const displayName = 'جولة التصميم';
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
    await enterField(tester, 'auth-displayName', displayName);
    await enterField(tester, 'auth-email', email);
    await enterField(tester, 'auth-password', password);
    await enterField(tester, 'auth-confirmation', password);
    await tapAndSettle(tester, find.text(ArabicStrings.createAccountTitle).last);

    // HomeShell opens on الرئيسية: empty Today state with the tab bar.
    await pumpUntil(tester, find.byType(NavigationBar));
    await pumpUntil(tester, find.byType(HomeScreen));
    await settle(tester, 2000);
    await shot(tester, '03_home_empty');

    // مجموعاتي, empty state.
    await selectTab(tester, ArabicStrings.groupsTab);
    await pumpUntil(tester, find.text(ArabicStrings.noApprovedGroups));
    await shot(tester, '04_groups_empty');

    // Discovery and invite screens (root routes).
    await optional(tester, 'discovery', () async {
      navigatorKey.currentState!.pushNamed(AppRoutes.discovery);
      await settle(tester, 2500);
      await shot(tester, '04b_discovery');
      navigatorKey.currentState!.pop();
      await settle(tester);
    });
    await optional(tester, 'invite_join', () async {
      navigatorKey.currentState!.pushNamed('/join');
      await settle(tester, 1500);
      await shot(tester, '04c_invite_join');
      navigatorKey.currentState!.pop();
      await settle(tester);
    });
    await optional(tester, 'join_any', () async {
      navigatorKey.currentState!.pushNamed('/join-any');
      await settle(tester, 1500);
      await shot(tester, '04d_join_any');
      navigatorKey.currentState!.pop();
      await settle(tester);
    });

    // Create group form, then the unit selector.
    final createButton = find.text(ArabicStrings.createGroup).hitTestable();
    await pumpUntil(tester, createButton);
    await tapAndSettle(tester, createButton.last);
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
    await shot(tester, '05_create_group_form');
    await optional(tester, 'create_group_unit_selector', () async {
      await scrollTo(tester, find.text(ArabicStrings.createTheGroup));
      await shot(tester, '05b_create_group_unit_selector');
    });
    await tapAndSettle(tester, find.text(ArabicStrings.createTheGroup));

    // Group list with one group.
    await pumpUntil(tester, find.text(groupName).hitTestable());
    await settle(tester, 1500);
    await shot(tester, '06_groups_with_group');

    // Forming dashboard and start sheet.
    await openGroup(tester, groupName);
    await pumpUntil(tester, find.byType(FormingGroupView));
    await settle(tester, 1000);
    await shot(tester, '07_dashboard_forming');
    await tapAndSettle(tester, find.text(ArabicStrings.startKhatmaAction));
    await pumpUntil(tester, find.text(ArabicStrings.startKhatmaAction).at(1));
    await shot(tester, '08_start_sheet');
    await tapAndSettle(tester, find.text(ArabicStrings.startKhatmaAction).last);

    // Active dashboard.
    await pumpUntil(tester, find.text(ArabicStrings.readNowAction));
    await settle(tester, 1500);
    await shot(tester, '09_dashboard_active');

    // Home hero card now that the khatma started.
    await optional(tester, 'home_today', () async {
      await selectTab(tester, ArabicStrings.homeTab);
      await pumpUntil(
        tester,
        find.text(ArabicStrings.portionCompleteAction).hitTestable(),
      );
      await settle(tester, 1500);
      await shot(tester, '10_home_today');
    });
    await selectTab(tester, ArabicStrings.groupsTab);
    await pumpUntil(tester, find.byType(GroupDashboardScreen));

    // Personal assignment.
    await optional(tester, 'personal_assignment', () async {
      await tapAndSettle(
        tester,
        find.text(ArabicStrings.assignmentDetailsAction).first,
      );
      await pumpUntil(tester, find.byType(PersonalAssignmentScreen));
      await shot(tester, '11_personal_assignment');
      await popFrom(tester, find.byType(PersonalAssignmentScreen));
    });

    // Another seat's portion: owner override sheet when the seat is filled,
    // otherwise the portion detail sheet for a vacant seat.
    await optional(tester, 'other_portion_sheet', () async {
      final other = find.byWidgetPredicate(
        (w) => w is PartTile && !w.isMine && w.portionIndex == 2,
      );
      await tapAndSettle(tester, other);
      final sheet = find.byWidgetPredicate(
        (w) => w is OverrideAssignmentSheet || w is PortionDetailSheet,
      );
      await pumpUntil(tester, sheet);
      final isOverride = find
          .byType(OverrideAssignmentSheet)
          .evaluate()
          .isNotEmpty;
      await shot(
        tester,
        isOverride ? '12_override_sheet' : '12_portion_detail_vacant',
      );
      await popFrom(tester, sheet);
    });
    await tester.scrollUntilVisible(
      find.text(ArabicStrings.readNowAction),
      -250,
      scrollable: find.byType(Scrollable).hitTestable().first,
    );

    // History.
    await optional(tester, 'history', () async {
      await tapAndSettle(
        tester,
        find.byTooltip(ArabicStrings.openHistoryAction),
      );
      await pumpUntil(tester, find.byType(HistoryScreen));
      await settle(tester, 1500);
      await shot(tester, '13_history');
      await popFrom(tester, find.byType(HistoryScreen));
    });

    Future<void> openGroupMenuItem(String label) async {
      await pumpUntil(tester, find.byTooltip(ArabicStrings.groupMenuTooltip));
      await tapAndSettle(tester, find.byTooltip(ArabicStrings.groupMenuTooltip));
      await pumpUntil(tester, find.text(label));
      await tapAndSettle(tester, find.text(label).last);
      await settle(tester, 2000);
    }

    await optional(tester, 'group_menu', () async {
      await tapAndSettle(tester, find.byTooltip(ArabicStrings.groupMenuTooltip));
      await pumpUntil(tester, find.text(ArabicStrings.manageMembersAction));
      await shot(tester, '14_group_menu');
      await popFrom(tester, find.text(ArabicStrings.manageMembersAction));
    });
    await optional(tester, 'members', () async {
      await openGroupMenuItem(ArabicStrings.manageMembersAction);
      await pumpUntil(tester, find.byType(MembersScreen));
      await shot(tester, '15_members');
      await popFrom(tester, find.byType(MembersScreen));
    });
    await optional(tester, 'join_requests', () async {
      await openGroupMenuItem(ArabicStrings.reviewJoinRequestsAction);
      await pumpUntil(tester, find.byType(JoinRequestsScreen));
      await shot(tester, '16_join_requests');
      await popFrom(tester, find.byType(JoinRequestsScreen));
    });
    await optional(tester, 'group_settings', () async {
      await openGroupMenuItem(ArabicStrings.groupSettingsAction);
      await pumpUntil(tester, find.byType(GroupSettingsScreen));
      await shot(tester, '17_group_settings');
      await optional(tester, 'group_settings_reminders', () async {
        await scrollTo(tester, find.text(ArabicStrings.reminderGroupTitle));
        await shot(tester, '17b_group_settings_reminders');
      });
      await popFrom(tester, find.byType(GroupSettingsScreen));
    });

    // Group info from the dashboard header, then a member profile.
    await optional(tester, 'group_info', () async {
      final header = find.descendant(
        of: find.byType(AppBar),
        matching: find.text(groupName),
      );
      await tapAndSettle(tester, header.first);
      await pumpUntil(tester, find.byType(GroupInfoScreen));
      await settle(tester, 2500);
      await shot(tester, '18_group_info');
      await optional(tester, 'group_info_members', () async {
        await scrollTo(tester, find.text(displayName));
        await shot(tester, '18b_group_info_members');
        await tapAndSettle(tester, find.text(displayName).hitTestable().first);
        await pumpUntil(tester, find.byType(MemberProfileScreen));
        await settle(tester, 2500);
        await shot(tester, '19_member_profile');
        await popFrom(tester, find.byType(MemberProfileScreen));
      });
      await popFrom(tester, find.byType(GroupInfoScreen));
    });

    // Mushaf reader on the portion's start page, index tabs, bookmarks.
    await optional(tester, 'mushaf', () async {
      await pumpUntil(tester, find.text(ArabicStrings.readNowAction));
      await tapAndSettle(tester, find.text(ArabicStrings.readNowAction).first);
      await pumpUntil(
        tester,
        find.byKey(const ValueKey('mushaf-page-view')),
        timeout: const Duration(seconds: 60),
      );
      await settle(tester, 1500);
      await shot(tester, '20_mushaf_reader_portion_start');
      // Turn two pages forward (RTL: next page is on the left, so drag right).
      for (final name in ['20b_mushaf_portion_page2', '20c_mushaf_portion_page3']) {
        await tester.fling(
          find.byKey(const ValueKey('mushaf-page-view')),
          const Offset(400, 0),
          1500,
        );
        await settle(tester, 2500);
        await shot(tester, name);
      }
      // Tap the page to hide the chrome (immersive) and capture it.
      await tester.tapAt(tester.getCenter(find.byKey(const ValueKey('mushaf-page-view'))));
      await settle(tester, 800);
      await shot(tester, '20d_mushaf_immersive');
      await tester.tapAt(tester.getCenter(find.byKey(const ValueKey('mushaf-page-view'))));
      await settle(tester, 800);

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
          ArabicStrings.surahsTab: '21a_mushaf_index_surahs',
          ArabicStrings.ajzaaTab: '21b_mushaf_index_ajzaa',
          ArabicStrings.ahzabTab: '21c_mushaf_index_ahzab',
          ArabicStrings.pagesTab: '21d_mushaf_index_pages',
        };
        for (final entry in tabs.entries) {
          await tapAndSettle(
            tester,
            find.widgetWithText(Tab, entry.key).hitTestable(),
          );
          await settle(tester, 1000);
          await shot(tester, entry.value);
        }
        await popFrom(tester, find.byType(MushafIndexScreen).hitTestable());
      });

      await optional(tester, 'bookmark_sheet', () async {
        await tapAndSettle(
          tester,
          find.byTooltip(ArabicStrings.addBookmarkAction),
        );
        await pumpUntil(tester, find.text(ArabicStrings.save));
        await shot(tester, '22_bookmark_sheet');
        await tapAndSettle(tester, find.text(ArabicStrings.save));
        await settle(tester, 1500);
      });
      await optional(tester, 'bookmarks', () async {
        await tapAndSettle(tester, find.byTooltip(ArabicStrings.bookmarksTitle));
        await pumpUntil(tester, find.byType(BookmarksScreen));
        await settle(tester, 1500);
        await shot(tester, '23_bookmarks');
        await popFrom(tester, find.byType(BookmarksScreen));
      });
      await optional(tester, 'mushaf_licenses', () async {
        await tapAndSettle(
          tester,
          find.byTooltip(ArabicStrings.mushafLicensesTitle),
        );
        await settle(tester, 1500);
        await shot(tester, '24_mushaf_licenses');
        await popFrom(tester, find.text(ArabicStrings.mushafLicensesTitle));
      });
      await popFrom(tester, find.byType(ReaderScreen));
    });

    // Complete today's portion from Home, then see reader names.
    await optional(tester, 'home_completed', () async {
      await selectTab(tester, ArabicStrings.homeTab);
      final complete = find
          .text(ArabicStrings.portionCompleteAction)
          .hitTestable();
      await pumpUntil(tester, complete);
      await tapAndSettle(tester, complete.first);
      await pumpUntil(
        tester,
        find.text(ArabicStrings.portionUndoAction).hitTestable(),
      );
      await settle(tester, 1500);
      await shot(tester, '25_home_completed');
    });
    await optional(tester, 'dashboard_reader_names', () async {
      await selectTab(tester, ArabicStrings.groupsTab);
      await popFrom(tester, find.byType(GroupDashboardScreen));
      await openGroup(tester, groupName);
      await pumpUntil(tester, find.text(ArabicStrings.readNowAction));
      await settle(tester, 2500);
      await scrollTo(tester, find.text(ArabicStrings.juzGridTitle));
      await shot(tester, '26_dashboard_reader_names');

      await optional(tester, 'portion_detail_sheet', () async {
        final mine = find.byWidgetPredicate(
          (w) => w is PartTile && w.isMine,
        );
        await tapAndSettle(tester, mine);
        await pumpUntil(tester, find.byType(PortionDetailSheet));
        await shot(tester, '27_portion_detail_sheet');
        final openProfile = find.text(ArabicStrings.openProfile);
        if (openProfile.evaluate().isNotEmpty) {
          await tapAndSettle(tester, openProfile);
          await pumpUntil(tester, find.byType(MemberProfileScreen));
          await settle(tester, 2500);
          await shot(tester, '28_member_profile_from_reader');
          await popFrom(tester, find.byType(MemberProfileScreen));
        } else {
          await popFrom(tester, find.byType(PortionDetailSheet));
        }
      });
    });

    // Settings (from the dashboard), reminders section, bottom.
    await optional(tester, 'settings', () async {
      await pumpUntil(tester, find.byTooltip(ArabicStrings.settingsTitle));
      await tapAndSettle(tester, find.byTooltip(ArabicStrings.settingsTitle));
      await pumpUntil(tester, find.byType(SettingsScreen));
      await settle(tester, 1500);
      await shot(tester, '29_settings');
      await optional(tester, 'settings_reminders', () async {
        await scrollTo(tester, find.text(ArabicStrings.remindersTitle));
        await shot(tester, '29b_settings_reminders');
        await scrollTo(tester, find.text(ArabicStrings.signOut));
        await shot(tester, '29c_settings_bottom');
      });
      expect(find.text(ArabicStrings.adminEntry), findsNothing);
      await popFrom(tester, find.byType(SettingsScreen));
    });

    // المصحف tab: the Mushaf index.
    await optional(tester, 'mushaf_tab', () async {
      await selectTab(tester, ArabicStrings.mushafTab);
      await pumpUntil(tester, find.byType(MushafIndexScreen).hitTestable());
      await settle(tester, 1500);
      await shot(tester, '30_mushaf_tab');
      // Open surah rows 2 and 5 from the index (page 2 and a surah-start page).
      for (final entry in const {1: '30b_mushaf_free_row2', 4: '30c_mushaf_free_row5'}.entries) {
        await optional(tester, entry.value, () async {
          await tapAndSettle(tester, find.byType(ListTile).at(entry.key));
          await pumpUntil(
            tester,
            find.byKey(const ValueKey('mushaf-page-view')),
            timeout: const Duration(seconds: 60),
          );
          await settle(tester, 3000);
          await shot(tester, entry.value);
          await tester.pageBack();
          await settle(tester, 1500);
        });
      }
    });

    // حسابي: profile, personal log, edit profile.
    await optional(tester, 'profile', () async {
      await selectTab(tester, ArabicStrings.profileTab);
      await pumpUntil(tester, find.byType(ProfileScreen));
      await settle(tester, 2500);
      await shot(tester, '31_profile');
      await scrollTo(tester, find.text(ArabicStrings.profileSettingsNavigation));
      await shot(tester, '31b_profile_links');

      await optional(tester, 'personal_log', () async {
        await tapAndSettle(
          tester,
          find.text(ArabicStrings.profileLogNavigation).hitTestable(),
        );
        await pumpUntil(tester, find.byType(LogScreen));
        await settle(tester, 2500);
        await shot(tester, '32_personal_log');
        await popFrom(tester, find.byType(LogScreen));
      });
      await optional(tester, 'edit_profile', () async {
        await tapAndSettle(
          tester,
          find.text(ArabicStrings.myProfileTitle).hitTestable(),
        );
        await pumpUntil(tester, find.byType(EditProfileScreen));
        await settle(tester, 2000);
        await shot(tester, '33_edit_profile');
        await popFrom(tester, find.byType(EditProfileScreen));
      });
    });

    binding.platformDispatcher.clearPlatformBrightnessTestValue();
    debugPrint('TOUR TAKEN (${taken.length}): ${taken.join(', ')}');
    debugPrint('TOUR SKIPPED (${skipped.length}): ${skipped.join(' || ')}');
  });
}
