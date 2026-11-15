import '../domain/reminder_planner.dart';

/// Persistence boundary for personal reminder preferences and group schedules.
/// Implementations may use local storage for personal settings/mutes and the
/// authenticated schedule RPC for group-owned settings.
abstract interface class RemindersRepository {
  Future<PersonalReminderSettings> loadPersonalSettings();

  Future<void> savePersonalSettings(PersonalReminderSettings settings);

  Future<GroupReminderSchedule?> loadGroupSchedule(String groupId);

  Future<void> saveGroupSchedule(GroupReminderSchedule schedule);

  Future<bool> isMuted(String groupId, ReminderSlot slot);

  Future<void> setMuted(String groupId, ReminderSlot slot, bool muted);

  Future<bool> isGroupMuted(String groupId);

  Future<void> setGroupMuted(String groupId, bool muted);
}
