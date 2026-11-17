import 'dart:async';

import 'package:quran_daily/core/quran/quran_metadata_repository.dart';
import 'package:quran_daily/features/reminders/data/reminder_planning_service.dart';
import 'package:quran_daily/features/reminders/data/reminders_repository.dart';
import 'package:quran_daily/features/reminders/data/notification_scheduler.dart';
import 'package:quran_daily/features/reminders/domain/reminder_planner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_daily/core/network/rpc_client.dart';
import 'package:quran_daily/core/storage/daos/daos.dart';
import 'package:quran_daily/features/reminders/data/reminders_repository_impl.dart';

class _Rpc extends Mock implements RpcClient {}

class _Snapshots extends Mock implements CachedSnapshotsDao {}

class _Preferences extends Mock implements RemindersRepository {}

class _Notifications extends Mock implements NotificationScheduler {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('planning shares overlapping passes and performs one trailing latest pass (#3)', () async {
    final snapshots = _Snapshots();
    final preferences = _Preferences();
    final notifications = _Notifications();
    when(snapshots.readAll).thenAnswer((_) async => []);
    when(preferences.loadPersonalSettings)
        .thenAnswer((_) async => const PersonalReminderSettings());
    final started = Completer<void>();
    final release = Completer<void>();
    var active = 0;
    var mostActive = 0;
    var calls = 0;
    when(() => notifications.schedule(any())).thenAnswer((_) async {
      calls++;
      active++;
      if (active > mostActive) mostActive = active;
      if (calls == 1) {
        started.complete();
        await release.future;
      }
      active--;
    });
    final planner = ReminderPlanningService(
      snapshots: snapshots,
      metadata: QuranMetadataRepository(),
      preferences: preferences,
      notifications: notifications,
    );
    final first = planner.refresh();
    await started.future;
    final others = List.generate(10, (_) => planner.refresh());
    expect(others.every((future) => identical(future, first)), isTrue);
    release.complete();
    await Future.wait([first, ...others]);
    expect(calls, 2);
    expect(mostActive, 1);
  });

  test(
    'reminder schedule uses cached dashboard with zero dashboard RPCs (#3)',
    () async {
      SharedPreferences.setMockInitialValues({});
      final rpc = _Rpc();
      final snapshots = _Snapshots();
      when(() => snapshots.read('g')).thenAnswer(
        (_) async => (
          json: <String, Object?>{
            'group_name': 'group',
            'reminder_schedule': {
              'group_id': 'g',
              'fajr_on': false,
              'night_time': '21:00',
            },
          },
          cachedAt: DateTime.utc(2026),
        ),
      );
      final repository = RemindersRepositoryImpl(
        rpc: rpc,
        snapshots: snapshots,
      );
      final schedule = await repository.loadGroupSchedule('g');
      expect(schedule!.fajrOn, isFalse);
      expect(schedule.nightTime, '21:00');
      verifyZeroInteractions(rpc);
    },
  );
}
