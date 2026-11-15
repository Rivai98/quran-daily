import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/localization/arabic_strings.dart';
import '../domain/reminder_planner.dart';

class NotificationScheduler {
  NotificationScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();
  final FlutterLocalNotificationsPlugin _plugin;
  static const int _firstReminderId = 6000;
  static const int _lastReminderId = 8999;

  Future<void> initialize({void Function(String? payload)? onTap}) async {
    tzdata.initializeTimeZones();
    await _refreshTimezone();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) =>
          onTap?.call(response.payload),
    );
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      onTap?.call(launchDetails?.notificationResponse?.payload);
    }
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'daily_wird_reminders',
            ArabicStrings.reminderChannelName,
            description: ArabicStrings.reminderChannelDescription,
            importance: Importance.defaultImportance,
          ),
        );
  }

  Future<bool?> requestPermissions() async {
    final android = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return android ?? ios;
  }

  Future<void> schedule(List<PlannedReminder> reminders) async {
    await _refreshTimezone();
    await cancelScheduledReminders();
    for (final reminder in reminders) {
      final id = _notificationId(reminder);
      await _plugin.zonedSchedule(
        id: id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: tz.TZDateTime.from(reminder.fireAt, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_wird_reminders',
            ArabicStrings.reminderChannelName,
            channelDescription: ArabicStrings.reminderChannelDescription,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: jsonEncode({
          'destination': 'today',
          'groupIds': reminder.groupIds.toList(),
        }),
      );
    }
  }

  Future<void> _refreshTimezone() async {
    final local = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(local.identifier));
  }

  Future<void> cancelScheduledReminders() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending.where(
      (item) => item.id >= _firstReminderId && item.id <= _lastReminderId,
    )) {
      await _plugin.cancel(id: request.id);
    }
  }

  Future<void> showTestNotification() => _plugin.show(
    id: _lastReminderId,
    title: ArabicStrings.reminderTestTitle,
    body: ArabicStrings.reminderTestBody,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_wird_reminders',
        ArabicStrings.reminderChannelName,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    payload: jsonEncode({'destination': 'today'}),
  );

  int _notificationId(PlannedReminder reminder) {
    final day =
        reminder.fireAt.year * 10000 +
        reminder.fireAt.month * 100 +
        reminder.fireAt.day;
    return _firstReminderId + (day % 1000) * 3 + reminder.slot.index;
  }
}
