import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/design_system/app_colors.dart';
import '../../../core/localization/arabic_strings.dart';
import '../domain/reminder_planner.dart';

class NotificationScheduler {
  NotificationScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin() {
    _ready.future.ignore();
  }
  final FlutterLocalNotificationsPlugin _plugin;
  Completer<void> _ready = Completer<void>();
  Future<void>? _initializing;
  Future<void> _scheduling = Future<void>.value();
  void Function(String? payload)? _onTap;
  static const int _firstReminderId = 6000;
  static const int _lastReminderId = 8999;

  Future<void> initialize({void Function(String? payload)? onTap}) {
    _onTap = onTap ?? _onTap;
    if (_initializing != null) return _initializing!;
    if (_ready.isCompleted) {
      _ready = Completer<void>();
      _ready.future.ignore();
    }
    _initializing = _initialize().then(
      (_) {
        _ready.complete();
      },
      onError: (Object error, StackTrace stack) {
        _ready.completeError(error, stack);
        _initializing = null;
        Error.throwWithStackTrace(error, stack);
      },
    );
    return _initializing!;
  }

  Future<void> _initialize() async {
    tzdata.initializeTimeZones();
    await _refreshTimezone();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_halaqa'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) =>
          _onTap?.call(response.payload),
    );
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      _onTap?.call(launchDetails?.notificationResponse?.payload);
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
    await _ready.future;
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

  Future<void> schedule(List<PlannedReminder> reminders) {
    final next = List<PlannedReminder>.unmodifiable(reminders);
    return _scheduling = _scheduling.then(
      (_) => _apply(next),
      onError: (Object _, StackTrace _) => _apply(next),
    );
  }

  Future<void> _apply(List<PlannedReminder> reminders) async {
    await _ready.future;
    await _refreshTimezone();
    final pending = {
      for (final request in await _plugin.pendingNotificationRequests())
        request.id: request,
    };
    final desiredIds = <int>{};
    final ordered = [...reminders]
      ..sort((a, b) => _reminderKey(a).compareTo(_reminderKey(b)));
    for (final reminder in ordered) {
      var id = _notificationId(reminder);
      while (!desiredIds.add(id)) {
        id =
            _firstReminderId +
            (id - _firstReminderId + 1) % (_lastReminderId - _firstReminderId);
      }
      final payload = jsonEncode({
        'destination': 'today',
        'groupIds': reminder.groupIds.toList()..sort(),
        'fireAt': reminder.fireAt.toUtc().toIso8601String(),
        'timezone': tz.local.name,
      });
      final existing = pending[id];
      if (existing?.title == reminder.title &&
          existing?.body == reminder.body &&
          existing?.payload == payload) {
        continue;
      }
      await _plugin.zonedSchedule(
        id: id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: tz.TZDateTime.from(reminder.fireAt, tz.local),
        notificationDetails: NotificationDetails(
          android: _androidDetails(reminder.body),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    }
    for (final id in pending.keys) {
      if (id >= _firstReminderId &&
          id <= _lastReminderId &&
          !desiredIds.contains(id)) {
        await _plugin.cancel(id: id);
      }
    }
  }

  String _reminderKey(PlannedReminder reminder) {
    final date = reminder.fireAt;
    final groups = reminder.groupIds.toList()..sort();
    return '${date.year}-${date.month}-${date.day}:${reminder.slot.name}:${groups.join(',')}';
  }

  Future<void> _refreshTimezone() async {
    final local = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(local.identifier));
  }

  Future<void> cancelScheduledReminders() async {
    await _ready.future;
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
    notificationDetails: NotificationDetails(
      android: _androidDetails(ArabicStrings.reminderTestBody),
      iOS: const DarwinNotificationDetails(),
    ),
    payload: jsonEncode({'destination': 'today'}),
  );

  /// حلقة-branded Android notification: white logo status icon, brand color,
  /// the app icon as the large image, and the full text when expanded.
  AndroidNotificationDetails _androidDetails(String body) =>
      AndroidNotificationDetails(
        'daily_wird_reminders',
        ArabicStrings.reminderChannelName,
        channelDescription: ArabicStrings.reminderChannelDescription,
        icon: 'ic_stat_halaqa',
        color: AppColors.light.primary,
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
        styleInformation: BigTextStyleInformation(body),
        category: AndroidNotificationCategory.reminder,
      );

  int _notificationId(PlannedReminder reminder) {
    var hash = 2166136261;
    for (final code in _reminderKey(reminder).codeUnits) {
      hash = ((hash ^ code) * 16777619) & 0x7fffffff;
    }
    return _firstReminderId + hash % (_lastReminderId - _firstReminderId);
  }
}
