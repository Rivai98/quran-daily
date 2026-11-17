import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:quran_daily/features/reminders/data/notification_scheduler.dart';
import 'package:quran_daily/features/reminders/domain/reminder_planner.dart';

class _Plugin extends Mock implements FlutterLocalNotificationsPlugin {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFallbackValue(const InitializationSettings());
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(tz.TZDateTime.utc(2026));
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
  });
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_timezone'),
          (_) async => 'Africa/Cairo',
        );
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_timezone'),
          null,
        ),
  );

  test('schedules only changes, keeps distinct same-slot groups, and survives restart (#3 #21)', () async {
    final plugin = _Plugin();
    final pending = <int, PendingNotificationRequest>{};
    var writes = 0;
    var cancels = 0;
    var launchTaps = 0;
    when(
      () => plugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(
          named: 'onDidReceiveNotificationResponse',
        ),
      ),
    ).thenAnswer((_) async => true);
    when(plugin.getNotificationAppLaunchDetails).thenAnswer(
      (_) async => NotificationAppLaunchDetails(
        true,
        notificationResponse: const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: 'today',
        ),
      ),
    );
    when(plugin.pendingNotificationRequests)
        .thenAnswer((_) async => pending.values.toList());
    when(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((call) async {
      writes++;
      final id = call.namedArguments[#id] as int;
      pending[id] = PendingNotificationRequest(
        id,
        call.namedArguments[#title] as String?,
        call.namedArguments[#body] as String?,
        call.namedArguments[#payload] as String?,
      );
    });
    when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((call) async {
      cancels++;
      pending.remove(call.namedArguments[#id]);
    });
    final scheduler = NotificationScheduler(plugin: plugin);
    await scheduler.initialize(onTap: (_) => launchTaps++);
    expect(launchTaps, 1);
    PlannedReminder reminder(String group, int hour, [String body = 'body']) =>
        PlannedReminder(
          fireAt: DateTime(2026, 11, 18, hour),
          slot: ReminderSlot.night,
          title: 'title',
          body: body,
          groupIds: {group},
        );
    final first = reminder('g', 21);
    final second = reminder('h', 22);
    await scheduler.schedule([first, second]);
    expect(pending.length, 2);
    expect(writes, 2);
    await scheduler.schedule([first, second]);
    expect(writes, 2);
    expect(cancels, 0);
    await scheduler.schedule([reminder('g', 21, 'changed'), second]);
    expect(writes, 3);
    expect(cancels, 0);
    await scheduler.schedule([second]);
    expect(writes, 3);
    expect(cancels, 1);
    final restarted = NotificationScheduler(plugin: plugin);
    await restarted.initialize();
    await restarted.schedule([second]);
    expect(writes, 3);
    expect(cancels, 1);
  });
}
