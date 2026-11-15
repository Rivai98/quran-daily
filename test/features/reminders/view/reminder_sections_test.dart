import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/design_system/app_theme.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/reminders/cubit/reminders_cubit.dart';
import 'package:quran_daily/features/reminders/data/reminders_repository.dart';
import 'package:quran_daily/features/reminders/domain/reminder_planner.dart';
import 'package:quran_daily/features/reminders/view/group_reminder_section.dart';
import 'package:quran_daily/features/reminders/view/reminder_settings_section.dart';

void main() {
  testWidgets(
    'personal section works in RTL, dark theme, 320dp and 200% text',
    (tester) async {
      expect(
        ArabicStrings.cityCairo,
        '\u{627}\u{644}\u{642}\u{627}\u{647}\u{631}\u{629}',
      );
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cubit = RemindersCubit(repository: _FakeRepository());
      await tester.pumpWidget(
        _host(
          cubit,
          const ReminderSettingsSection(),
          direction: TextDirection.rtl,
          theme: AppTheme.dark,
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('التذكيرات'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await cubit.close();
    },
  );

  testWidgets('owner group schedule displays editable schedule controls', (
    tester,
  ) async {
    final cubit = RemindersCubit(repository: _FakeRepository());
    await tester.pumpWidget(
      _host(
        cubit,
        const GroupReminderSection(
          groupId: 'group-1',
          groupName: 'مجموعة',
          isOwner: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('حفظ التذكيرات'), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await cubit.close();
  });

  testWidgets('group schedule remains usable at 320dp and 200% in dark RTL', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cubit = RemindersCubit(repository: _FakeRepository());
    await tester.pumpWidget(
      _host(
        cubit,
        const GroupReminderSection(
          groupId: 'group-1',
          groupName: 'مجموعة',
          isOwner: true,
        ),
        theme: AppTheme.dark,
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('حفظ التذكيرات'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await cubit.close();
  });

  testWidgets('member group view exposes device mute controls', (tester) async {
    final cubit = RemindersCubit(repository: _FakeRepository());
    await tester.pumpWidget(
      _host(
        cubit,
        const GroupReminderSection(
          groupId: 'group-1',
          groupName: 'مجموعة',
          isOwner: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SwitchListTile), findsNWidgets(4));
    expect(find.text('كتم هذا التذكير على هذا الجهاز'), findsNWidgets(3));
    expect(find.text('كتم تذكيرات المجموعة على هذا الجهاز'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await cubit.close();
  });

  testWidgets(
    'permission explainer precedes request and denial shows guidance',
    (tester) async {
      var permissionRequests = 0;
      var testNotifications = 0;
      final repository = _FakeRepository()
        ..personal = const PersonalReminderSettings(enabled: true);
      final cubit = RemindersCubit(
        repository: repository,
        requestPermissions: () async {
          permissionRequests++;
          return false;
        },
        showTestNotification: () async => testNotifications++,
      );
      await cubit.loadPersonalSettings();
      await tester.pumpWidget(_host(cubit, const ReminderSettingsSection()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(ArabicStrings.reminderTest));
      await tester.tap(find.text(ArabicStrings.reminderTest));
      await tester.pumpAndSettle();
      expect(
        find.text(ArabicStrings.reminderPermissionExplain),
        findsOneWidget,
      );
      expect(permissionRequests, 0);
      await tester.tap(find.text(ArabicStrings.reminderPermissionContinue));
      await tester.pumpAndSettle();
      expect(permissionRequests, 1);
      expect(find.text(ArabicStrings.reminderPermissionDenied), findsOneWidget);
      expect(testNotifications, 0);
      await cubit.close();
    },
  );

  testWidgets('activating reminders requires permission approval', (
    tester,
  ) async {
    var permissionRequests = 0;
    final repository = _FakeRepository()
      ..personal = const PersonalReminderSettings(enabled: false);
    final cubit = RemindersCubit(
      repository: repository,
      requestPermissions: () async {
        permissionRequests++;
        return true;
      },
    );
    await tester.pumpWidget(_host(cubit, const ReminderSettingsSection()));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();
    expect(find.text(ArabicStrings.reminderPermissionExplain), findsOneWidget);
    expect(permissionRequests, 0);
    expect(cubit.state.personalSettings.enabled, isFalse);
    await tester.tap(find.text(ArabicStrings.reminderPermissionContinue));
    await tester.pumpAndSettle();
    expect(permissionRequests, 1);
    expect(cubit.state.personalSettings.enabled, isTrue);
    await cubit.close();
  });
}

Widget _host(
  RemindersCubit cubit,
  Widget child, {
  TextDirection direction = TextDirection.rtl,
  ThemeData? theme,
  TextScaler textScaler = TextScaler.noScaling,
}) => MaterialApp(
  theme: theme ?? AppTheme.light,
  home: Directionality(
    textDirection: direction,
    child: MediaQuery(
      data: MediaQueryData(textScaler: textScaler),
      child: Scaffold(
        body: SingleChildScrollView(
          child: BlocProvider.value(value: cubit, child: child),
        ),
      ),
    ),
  ),
);

class _FakeRepository implements RemindersRepository {
  PersonalReminderSettings personal = const PersonalReminderSettings();

  @override
  Future<PersonalReminderSettings> loadPersonalSettings() async => personal;
  @override
  Future<void> savePersonalSettings(PersonalReminderSettings settings) async {
    personal = settings;
  }

  @override
  Future<GroupReminderSchedule?> loadGroupSchedule(String groupId) async =>
      null;
  @override
  Future<void> saveGroupSchedule(GroupReminderSchedule schedule) async {}
  @override
  Future<bool> isMuted(String groupId, ReminderSlot slot) async => false;
  @override
  Future<void> setMuted(String groupId, ReminderSlot slot, bool muted) async {}
  @override
  Future<bool> isGroupMuted(String groupId) async => false;
  @override
  Future<void> setGroupMuted(String groupId, bool muted) async {}
}
