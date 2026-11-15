import '../../../core/localization/arabic_strings.dart';

/// Pure reminder planning types and function. No Flutter or platform APIs.
enum ReminderSlot { fajr, asr, night }

class PrayerTimesForDay {
  const PrayerTimesForDay({required this.fajr, required this.asr});
  final DateTime fajr;
  final DateTime asr;
}

class PersonalReminderSettings {
  const PersonalReminderSettings({
    this.fajrEnabled = true,
    this.asrEnabled = true,
    this.nightEnabled = true,
    this.fajrOffsetMinutes = 20,
    this.asrOffsetMinutes = 20,
    this.nightTime = '22:30',
    this.calculationMethod = 'egyptian',
    this.cityName = ArabicStrings.cityCairo,
    this.latitude = 30.0444,
    this.longitude = 31.2357,
    this.enabled = false,
  });
  final bool enabled;
  final bool fajrEnabled;
  final bool asrEnabled;
  final bool nightEnabled;
  final int fajrOffsetMinutes;
  final int asrOffsetMinutes;
  final String nightTime;
  final String calculationMethod;
  final String cityName;
  final double latitude;
  final double longitude;
}

class GroupReminderSchedule {
  const GroupReminderSchedule({
    required this.groupId,
    required this.groupName,
    this.fajrOn = true,
    this.fajrOffsetMinutes = 20,
    this.asrOn = true,
    this.asrOffsetMinutes = 20,
    this.nightOn = true,
    this.nightTime = '22:30',
    this.message,
  });
  final String groupId;
  final String groupName;
  final bool fajrOn;
  final int fajrOffsetMinutes;
  final bool asrOn;
  final int asrOffsetMinutes;
  final bool nightOn;
  final String nightTime;
  final String? message;
}

class PendingPortion {
  const PendingPortion({
    required this.groupId,
    required this.groupName,
    required this.portionName,
  });
  final String groupId;
  final String groupName;
  final String portionName;
}

class PlannedReminder {
  const PlannedReminder({
    required this.fireAt,
    required this.slot,
    required this.title,
    required this.body,
    required this.groupIds,
  });
  final DateTime fireAt;
  final ReminderSlot slot;
  final String title;
  final String body;
  final Set<String> groupIds;
}

List<PlannedReminder> planReminders({
  required DateTime date,
  required DateTime now,
  required PrayerTimesForDay prayerTimes,
  required PersonalReminderSettings personal,
  required List<PendingPortion> pending,
  List<GroupReminderSchedule> groupSchedules = const [],
  Set<String> mutedGroupIds = const {},
  Set<String> mutedSlots = const {},
}) {
  if (pending.isEmpty || !personal.enabled) return const [];
  final effectiveGroups = groupSchedules
      .where((g) => !mutedGroupIds.contains(g.groupId))
      .toList();
  final usePersonal = groupSchedules.isEmpty;
  final candidates =
      <({DateTime at, ReminderSlot slot, GroupReminderSchedule? group})>[];
  final localDate = DateTime(date.year, date.month, date.day);
  DateTime atClock(String value) {
    final parts = value.split(':');
    final hour = int.tryParse(parts.first) ?? 22;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 30 : 30;
    return localDate.add(Duration(hours: hour, minutes: minute));
  }

  void add(ReminderSlot slot, DateTime at, GroupReminderSchedule? group) {
    if (at.isAfter(now) &&
        !mutedSlots.contains('${group?.groupId ?? 'personal'}:${slot.name}')) {
      candidates.add((at: at, slot: slot, group: group));
    }
  }

  if (usePersonal) {
    if (personal.fajrEnabled) {
      add(
        ReminderSlot.fajr,
        prayerTimes.fajr.add(Duration(minutes: personal.fajrOffsetMinutes)),
        null,
      );
    }
    if (personal.asrEnabled) {
      add(
        ReminderSlot.asr,
        prayerTimes.asr.add(Duration(minutes: personal.asrOffsetMinutes)),
        null,
      );
    }
    if (personal.nightEnabled) {
      add(ReminderSlot.night, atClock(personal.nightTime), null);
    }
  } else {
    for (final group in effectiveGroups) {
      if (group.fajrOn) {
        add(
          ReminderSlot.fajr,
          prayerTimes.fajr.add(Duration(minutes: group.fajrOffsetMinutes)),
          group,
        );
      }
      if (group.asrOn) {
        add(
          ReminderSlot.asr,
          prayerTimes.asr.add(Duration(minutes: group.asrOffsetMinutes)),
          group,
        );
      }
      if (group.nightOn) {
        add(ReminderSlot.night, atClock(group.nightTime), group);
      }
    }
  }
  final grouped =
      <
        String,
        List<({DateTime at, ReminderSlot slot, GroupReminderSchedule? group})>
      >{};
  for (final item in candidates) {
    final minute = DateTime(
      item.at.year,
      item.at.month,
      item.at.day,
      item.at.hour,
      item.at.minute,
    );
    grouped.putIfAbsent(minute.toIso8601String(), () => []).add(item);
  }
  return grouped.entries
      .map((entry) {
        final items = entry.value;
        final at = items.first.at;
        final slot = items.first.slot;
        final groupIds = items
            .map((e) => e.group?.groupId)
            .whereType<String>()
            .toSet();
        final included = pending
            .where((p) => groupIds.isEmpty || groupIds.contains(p.groupId))
            .toList();
        if (included.isEmpty) return null;
        final body = included
            .map(
              (p) => ArabicStrings.reminderPortionInGroup(
                p.portionName,
                p.groupName,
              ),
            )
            .join(ArabicStrings.reminderListSeparator);
        final includedGroupIds = included
            .map((portion) => portion.groupId)
            .toSet();
        final messages = items
            .map((item) => item.group)
            .whereType<GroupReminderSchedule>()
            .where(
              (group) =>
                  includedGroupIds.contains(group.groupId) &&
                  group.message?.isNotEmpty == true,
            )
            .map((group) => group.message!)
            .toSet();
        final fullBody = messages.isEmpty
            ? body
            : '$body${ArabicStrings.reminderMessageSeparator}${messages.join(ArabicStrings.reminderListSeparator)}';
        return PlannedReminder(
          fireAt: at,
          slot: slot,
          title: ArabicStrings.reminderNotificationTitle,
          body: fullBody,
          groupIds: groupIds,
        );
      })
      .whereType<PlannedReminder>()
      .toList()
    ..sort((a, b) => a.fireAt.compareTo(b.fireAt));
}
