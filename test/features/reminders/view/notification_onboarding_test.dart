import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/design_system/app_button.dart';
import 'package:quran_daily/core/di/service_locator.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/reminders/data/notification_scheduler.dart';
import 'package:quran_daily/features/reminders/data/reminders_repository.dart';
import 'package:quran_daily/features/reminders/domain/reminder_planner.dart';
import 'package:quran_daily/features/reminders/view/notification_onboarding.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../helpers/widget_test_app.dart';

class _FakeScheduler implements NotificationScheduler {
  _FakeScheduler(this.grant);
  final bool grant;
  int permissionRequests = 0;

  @override
  Future<bool?> requestPermissions() async {
    permissionRequests++;
    return grant;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRepository implements RemindersRepository {
  PersonalReminderSettings settings = const PersonalReminderSettings();

  @override
  Future<PersonalReminderSettings> loadPersonalSettings() async => settings;

  @override
  Future<void> savePersonalSettings(PersonalReminderSettings value) async {
    settings = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(loadDesignSystemFonts);

  late _FakeRepository repository;

  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      buildArabicTestApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => NotificationOnboarding.maybeAsk(context),
            child: const Text('ابدأ'),
          ),
        ),
      ),
    );
  }

  void register(_FakeScheduler scheduler) {
    serviceLocator
      ..registerSingleton<NotificationScheduler>(scheduler)
      ..registerSingleton<RemindersRepository>(repository);
  }

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    repository = _FakeRepository();
  });

  tearDown(() async {
    await serviceLocator.reset();
  });

  testWidgets('allowing asks the system permission and enables reminders', (
    tester,
  ) async {
    final scheduler = _FakeScheduler(true);
    register(scheduler);
    await pumpHost(tester);

    await tester.tap(find.text('ابدأ'));
    await tester.pumpAndSettle();
    expect(find.text(ArabicStrings.reminderOnboardingTitle), findsOneWidget);
    expect(find.text(ArabicStrings.reminderOnboardingExplain), findsOneWidget);
    expect(find.text(ArabicStrings.reminderOnboardingAllow), findsOneWidget);
    expect(find.text(ArabicStrings.reminderPermissionLater), findsOneWidget);
    expect(find.byType(AppButton), findsNWidgets(2));

    await tester.tap(find.text(ArabicStrings.reminderOnboardingAllow));
    await tester.pumpAndSettle();

    expect(scheduler.permissionRequests, 1);
    expect(repository.settings.enabled, isTrue);
  });

  testWidgets('"not now" skips the permission and never asks again', (
    tester,
  ) async {
    final scheduler = _FakeScheduler(true);
    register(scheduler);
    await pumpHost(tester);

    await tester.tap(find.text('ابدأ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ArabicStrings.reminderPermissionLater));
    await tester.pumpAndSettle();

    expect(scheduler.permissionRequests, 0);
    expect(repository.settings.enabled, isFalse);

    await tester.tap(find.text('ابدأ'));
    await tester.pumpAndSettle();
    expect(find.text(ArabicStrings.reminderOnboardingTitle), findsNothing);
  });

  testWidgets('denied permission leaves reminders off', (tester) async {
    final scheduler = _FakeScheduler(false);
    register(scheduler);
    await pumpHost(tester);

    await tester.tap(find.text('ابدأ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ArabicStrings.reminderOnboardingAllow));
    await tester.pumpAndSettle();

    expect(scheduler.permissionRequests, 1);
    expect(repository.settings.enabled, isFalse);
  });
}
