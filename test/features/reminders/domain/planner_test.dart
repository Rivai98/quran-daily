import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/features/reminders/domain/reminder_planner.dart';

void main() {
  final date = DateTime(2026, 11, 15);
  final prayers = PrayerTimesForDay(
    fajr: DateTime(2026, 11, 15, 5),
    asr: DateTime(2026, 11, 15, 15),
  );
  final pending = <PendingPortion>[
    const PendingPortion(
      groupId: 'g1',
      groupName: 'الفجر',
      portionName: 'الحزب ١',
    ),
    const PendingPortion(
      groupId: 'g2',
      groupName: 'العائلة',
      portionName: 'الجزء ٢',
    ),
  ];

  test('uses prayer time plus configured offsets and fixed night time', () {
    final plans = planReminders(
      date: date,
      now: DateTime(2026, 11, 14),
      prayerTimes: prayers,
      personal: const PersonalReminderSettings(
        enabled: true,
        fajrOffsetMinutes: 10,
        asrOffsetMinutes: 15,
        nightTime: '22:30',
      ),
      pending: pending,
    );
    expect(
      plans.map((e) => e.fireAt),
      containsAll(<DateTime>[
        DateTime(2026, 11, 15, 5, 10),
        DateTime(2026, 11, 15, 15, 15),
        DateTime(2026, 11, 15, 22, 30),
      ]),
    );
  });

  test(
    'merges same-minute group slots and includes only pending group portions',
    () {
      final plans = planReminders(
        date: date,
        now: DateTime(2026, 11, 14),
        prayerTimes: prayers,
        personal: const PersonalReminderSettings(enabled: true),
        pending: pending,
        groupSchedules: const [
          GroupReminderSchedule(
            groupId: 'g1',
            groupName: 'الفجر',
            fajrOffsetMinutes: 0,
            asrOn: false,
            nightOn: false,
          ),
          GroupReminderSchedule(
            groupId: 'g2',
            groupName: 'العائلة',
            fajrOffsetMinutes: 0,
            asrOn: false,
            nightOn: false,
          ),
        ],
      );
      expect(plans, hasLength(1));
      expect(plans.single.body, contains('الحزب ١ في الفجر'));
      expect(plans.single.body, contains('الجزء ٢ في العائلة'));
    },
  );

  test(
    'returns none when nothing is pending, skips past slots, respects mutes, and falls back to personal',
    () {
      final noPending = planReminders(
        date: date,
        now: DateTime(2026, 11, 14),
        prayerTimes: prayers,
        personal: const PersonalReminderSettings(),
        pending: const [],
      );
      expect(noPending, isEmpty);
      final past = planReminders(
        date: date,
        now: DateTime(2026, 11, 15, 6),
        prayerTimes: prayers,
        personal: const PersonalReminderSettings(enabled: true),
        pending: pending,
      );
      expect(past.map((e) => e.slot), isNot(contains(ReminderSlot.fajr)));
      final muted = planReminders(
        date: date,
        now: DateTime(2026, 11, 14),
        prayerTimes: prayers,
        personal: const PersonalReminderSettings(enabled: true),
        pending: pending,
        groupSchedules: const [
          GroupReminderSchedule(groupId: 'g1', groupName: 'الفجر'),
        ],
        mutedGroupIds: const {'g1'},
      );
      expect(muted, isEmpty);
      final fallback = planReminders(
        date: date,
        now: DateTime(2026, 11, 14),
        prayerTimes: prayers,
        personal: const PersonalReminderSettings(enabled: true),
        pending: pending,
      );
      expect(fallback, isNotEmpty);
    },
  );
}
