import '../../../core/localization/arabic_strings.dart';
import '../../../core/quran/quran_metadata_repository.dart';
import '../../../core/storage/daos/daos.dart';
import '../../quran_groups/data/entities/entities.dart';
import '../../quran_groups/data/models/models.dart';
import '../domain/reminder_planner.dart';
import 'notification_scheduler.dart';
import 'prayer_times_service.dart';
import 'reminders_repository.dart';

/// Rebuilds the next three local days from cached assignments and preferences.
class ReminderPlanningService {
  ReminderPlanningService({
    required this._snapshots,
    required this._metadata,
    required this._preferences,
    required this._notifications,
  });

  final CachedSnapshotsDao _snapshots;
  final QuranMetadataRepository _metadata;
  final RemindersRepository _preferences;
  final NotificationScheduler _notifications;

  Future<void> refresh() async {
    final settings = await _preferences.loadPersonalSettings();
    await _metadata.load();
    final snapshots = await _snapshots.readAll();
    final groupSchedules = <GroupReminderSchedule>[];
    final pending = <PendingPortion>[];
    for (final cached in snapshots) {
      final snapshot = dashboardSnapshotFromJson(
        cached.json,
        isStale: true,
        cachedAt: cached.cachedAt,
      );
      final schedule = await _preferences.loadGroupSchedule(snapshot.groupId);
      if (schedule != null) {
        groupSchedules.add(
          GroupReminderSchedule(
            groupId: schedule.groupId,
            groupName: snapshot.groupName,
            fajrOn: schedule.fajrOn,
            fajrOffsetMinutes: schedule.fajrOffsetMinutes,
            asrOn: schedule.asrOn,
            asrOffsetMinutes: schedule.asrOffsetMinutes,
            nightOn: schedule.nightOn,
            nightTime: schedule.nightTime,
            message: schedule.message,
          ),
        );
      }
      for (final assignment in snapshot.myAssignments.where(
        (item) => item.status == AssignmentStatusEnum.pending,
      )) {
        final portion = _metadata.portion(
          snapshot.portionUnit,
          assignment.portionIndex,
        );
        pending.add(
          PendingPortion(
            groupId: snapshot.groupId,
            groupName: snapshot.groupName,
            portionName: ArabicStrings.portionName(portion.unit, portion.index),
          ),
        );
      }
    }

    final now = DateTime.now();
    final calculationMethod = switch (settings.calculationMethod) {
      'umm_al_qura' => PrayerCalculationMethod.ummAlQura,
      'muslim_world_league' => PrayerCalculationMethod.muslimWorldLeague,
      'karachi' => PrayerCalculationMethod.karachi,
      'north_america' => PrayerCalculationMethod.isna,
      _ => PrayerCalculationMethod.egyptian,
    };
    final prayerService = PrayerTimesService(method: calculationMethod);
    final location = PrayerLocation(
      name: settings.cityName,
      latitude: settings.latitude,
      longitude: settings.longitude,
    );
    final reminders = <PlannedReminder>[];
    final mutedGroups = <String>{};
    for (var day = 0; day < 3; day++) {
      final date = DateTime(now.year, now.month, now.day + day);
      final times = prayerService.calculate(date, location);
      final mutes = <String>{};
      for (final group in groupSchedules) {
        if (await _preferences.isGroupMuted(group.groupId)) {
          mutedGroups.add(group.groupId);
        }
        for (final slot in ReminderSlot.values) {
          if (await _preferences.isMuted(group.groupId, slot)) {
            mutes.add('${group.groupId}:${slot.name}');
          }
        }
      }
      reminders.addAll(
        planReminders(
          date: date,
          now: now,
          prayerTimes: times,
          personal: settings,
          pending: pending,
          groupSchedules: groupSchedules,
          mutedGroupIds: mutedGroups,
          mutedSlots: mutes,
        ),
      );
    }
    await _notifications.schedule(reminders);
  }
}
