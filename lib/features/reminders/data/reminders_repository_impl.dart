import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/rpc_client.dart';
import '../../../core/localization/arabic_strings.dart';
import '../domain/reminder_planner.dart';
import 'reminders_repository.dart';

class RemindersRepositoryImpl implements RemindersRepository {
  RemindersRepositoryImpl({
    required RpcClient rpc,
    Future<SharedPreferences> Function()? preferences,
    Future<void> Function()? onChanged,
  }) : _rpc = rpc,
       _preferences = preferences ?? SharedPreferences.getInstance,
       _onChanged = onChanged;

  final RpcClient _rpc;
  final Future<SharedPreferences> Function() _preferences;
  final Future<void> Function()? _onChanged;
  static const _personalKey = 'reminders.personal.v1';
  static const _groupPrefix = 'reminders.group.';
  static const _mutePrefix = 'reminders.mute.';

  @override
  Future<PersonalReminderSettings> loadPersonalSettings() async {
    final prefs = await _preferences();
    final raw = prefs.getString(_personalKey);
    if (raw == null) return const PersonalReminderSettings();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return PersonalReminderSettings(
      enabled: json['enabled'] as bool? ?? true,
      fajrEnabled: json['fajrEnabled'] as bool? ?? true,
      asrEnabled: json['asrEnabled'] as bool? ?? true,
      nightEnabled: json['nightEnabled'] as bool? ?? true,
      fajrOffsetMinutes: json['fajrOffsetMinutes'] as int? ?? 20,
      asrOffsetMinutes: json['asrOffsetMinutes'] as int? ?? 20,
      nightTime: json['nightTime'] as String? ?? '22:30',
      calculationMethod: json['calculationMethod'] as String? ?? 'egyptian',
      cityName: json['cityName'] as String? ?? ArabicStrings.cityCairo,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 30.0444,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 31.2357,
    );
  }

  @override
  Future<void> savePersonalSettings(PersonalReminderSettings settings) async {
    final prefs = await _preferences();
    await prefs.setString(
      _personalKey,
      jsonEncode({
        'enabled': settings.enabled,
        'fajrEnabled': settings.fajrEnabled,
        'asrEnabled': settings.asrEnabled,
        'nightEnabled': settings.nightEnabled,
        'fajrOffsetMinutes': settings.fajrOffsetMinutes,
        'asrOffsetMinutes': settings.asrOffsetMinutes,
        'nightTime': settings.nightTime,
        'calculationMethod': settings.calculationMethod,
        'cityName': settings.cityName,
        'latitude': settings.latitude,
        'longitude': settings.longitude,
      }),
    );
    await _notifyChanged();
  }

  @override
  Future<GroupReminderSchedule?> loadGroupSchedule(String groupId) async {
    final prefs = await _preferences();
    final cached = prefs.getString('$_groupPrefix$groupId');
    final result = await _rpc.call<Object?>('get_dashboard', {
      'p_group_id': groupId,
    });
    if (result.isSuccess) {
      final payload = result.valueOrNull;
      final dashboard = payload is Map ? payload : const <Object?, Object?>{};
      final raw = dashboard['reminder_schedule'];
      if (raw is Map) {
        final schedule = _scheduleFromJson(
          raw.cast<String, Object?>(),
          _groupName(dashboard, groupId),
        );
        await prefs.setString(
          '$_groupPrefix$groupId',
          jsonEncode(_scheduleToJson(schedule)),
        );
        return schedule;
      }
      return null;
    }
    if (cached == null) return null;
    final json = (jsonDecode(cached) as Map).cast<String, Object?>();
    return _scheduleFromJson(json, json['groupName'] as String? ?? groupId);
  }

  @override
  Future<void> saveGroupSchedule(GroupReminderSchedule schedule) async {
    final result = await _rpc.call<Object?>('set_group_reminder_schedule', {
      'p_group_id': schedule.groupId,
      'p_fajr_on': schedule.fajrOn,
      'p_fajr_offset_min': schedule.fajrOffsetMinutes,
      'p_asr_on': schedule.asrOn,
      'p_asr_offset_min': schedule.asrOffsetMinutes,
      'p_night_on': schedule.nightOn,
      'p_night_time': schedule.nightTime,
      'p_message': schedule.message,
    });
    if (result.isFailure) {
      throw StateError(result.failureOrNull?.message ?? 'schedule_save_failed');
    }
    final prefs = await _preferences();
    await prefs.setString(
      '$_groupPrefix${schedule.groupId}',
      jsonEncode(_scheduleToJson(schedule)),
    );
    await _notifyChanged();
  }

  @override
  Future<bool> isMuted(String groupId, ReminderSlot slot) async =>
      (await _preferences()).getBool('$_mutePrefix$groupId:${slot.name}') ??
      false;

  @override
  Future<void> setMuted(String groupId, ReminderSlot slot, bool muted) async {
    await (await _preferences()).setBool(
      '$_mutePrefix$groupId:${slot.name}',
      muted,
    );
    await _notifyChanged();
  }

  @override
  Future<bool> isGroupMuted(String groupId) async =>
      (await _preferences()).getBool('$_mutePrefix$groupId:all') ?? false;

  @override
  Future<void> setGroupMuted(String groupId, bool muted) async {
    await (await _preferences()).setBool('$_mutePrefix$groupId:all', muted);
    await _notifyChanged();
  }

  Future<void> _notifyChanged() async {
    try {
      await _onChanged?.call();
    } catch (_) {
      // A local reschedule failure must not lose the saved setting.
    }
  }

  String _groupName(Map dashboard, String fallback) {
    final raw = dashboard['group'];
    if (raw is Map && raw['name'] is String) return raw['name'] as String;
    if (dashboard['group_name'] is String) {
      return dashboard['group_name'] as String;
    }
    return fallback;
  }

  GroupReminderSchedule _scheduleFromJson(
    Map<String, Object?> json,
    String groupName,
  ) => GroupReminderSchedule(
    groupId: json['group_id'] as String? ?? json['groupId'] as String? ?? '',
    groupName: groupName,
    fajrOn: json['fajr_on'] as bool? ?? json['fajrOn'] as bool? ?? true,
    fajrOffsetMinutes:
        (json['fajr_offset_min'] as num? ?? json['fajrOffsetMinutes'] as num?)
            ?.toInt() ??
        20,
    asrOn: json['asr_on'] as bool? ?? json['asrOn'] as bool? ?? true,
    asrOffsetMinutes:
        (json['asr_offset_min'] as num? ?? json['asrOffsetMinutes'] as num?)
            ?.toInt() ??
        20,
    nightOn: json['night_on'] as bool? ?? json['nightOn'] as bool? ?? true,
    nightTime:
        json['night_time'] as String? ??
        json['nightTime'] as String? ??
        '22:30',
    message: json['message'] as String?,
  );

  Map<String, Object?> _scheduleToJson(GroupReminderSchedule value) => {
    'group_id': value.groupId,
    'groupName': value.groupName,
    'fajr_on': value.fajrOn,
    'fajr_offset_min': value.fajrOffsetMinutes,
    'asr_on': value.asrOn,
    'asr_offset_min': value.asrOffsetMinutes,
    'night_on': value.nightOn,
    'night_time': value.nightTime,
    'message': value.message,
  };
}
