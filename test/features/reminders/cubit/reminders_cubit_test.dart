import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/features/reminders/cubit/reminders_cubit.dart';
import 'package:quran_daily/features/reminders/data/reminders_repository.dart';
import 'package:quran_daily/features/reminders/domain/reminder_planner.dart';

void main() {
  late _FakeRemindersRepository repository;
  late RemindersCubit cubit;

  setUp(() {
    repository = _FakeRemindersRepository();
    cubit = RemindersCubit(repository: repository);
  });

  tearDown(() => cubit.close());

  test('loads saved personal preferences', () async {
    repository.personal = const PersonalReminderSettings(fajrEnabled: false);
    await cubit.loadPersonalSettings();
    expect(cubit.state.personalSettings.fajrEnabled, isFalse);
    expect(cubit.state.status, RemindersStatus.success);
  });

  test('saves personal preferences and publishes state', () async {
    const settings = PersonalReminderSettings(asrOffsetMinutes: 35);
    await cubit.savePersonalSettings(settings);
    expect(repository.personal.asrOffsetMinutes, 35);
    expect(cubit.state.personalSettings.asrOffsetMinutes, 35);
  });

  test('loads and saves group schedule', () async {
    const schedule = GroupReminderSchedule(
      groupId: 'g1',
      groupName: 'Test',
      fajrOffsetMinutes: 40,
    );
    repository.schedule = schedule;
    await cubit.loadGroupSchedule('g1');
    expect(cubit.state.groupSchedule, schedule);
    await cubit.saveGroupSchedule(schedule);
    expect(repository.schedule, schedule);
  });

  test('loads and updates a per-group slot mute', () async {
    repository.muted.add(('g1', ReminderSlot.asr));
    await cubit.loadMute('g1', ReminderSlot.asr);
    expect(cubit.state.muted, isTrue);
    await cubit.setMuted('g1', ReminderSlot.asr, false);
    expect(repository.muted, isEmpty);
    expect(cubit.state.muted, isFalse);
  });

  test('loads and updates a per-group mute', () async {
    repository.groupMuted = true;
    await cubit.loadGroupMute('g1');
    expect(cubit.state.groupMuted, isTrue);
    await cubit.setGroupMuted('g1', false);
    expect(repository.groupMuted, isFalse);
    expect(cubit.state.groupMuted, isFalse);
  });
}

class _FakeRemindersRepository implements RemindersRepository {
  PersonalReminderSettings personal = const PersonalReminderSettings();
  GroupReminderSchedule? schedule;
  final muted = <(String, ReminderSlot)>{};
  bool groupMuted = false;

  @override
  Future<PersonalReminderSettings> loadPersonalSettings() async => personal;
  @override
  Future<void> savePersonalSettings(PersonalReminderSettings settings) async {
    personal = settings;
  }

  @override
  Future<GroupReminderSchedule?> loadGroupSchedule(String groupId) async =>
      schedule;
  @override
  Future<void> saveGroupSchedule(GroupReminderSchedule value) async {
    schedule = value;
  }

  @override
  Future<bool> isMuted(String groupId, ReminderSlot slot) async =>
      muted.contains((groupId, slot));
  @override
  Future<void> setMuted(String groupId, ReminderSlot slot, bool value) async {
    value ? muted.add((groupId, slot)) : muted.remove((groupId, slot));
  }

  @override
  Future<bool> isGroupMuted(String groupId) async => groupMuted;
  @override
  Future<void> setGroupMuted(String groupId, bool value) async {
    groupMuted = value;
  }
}
