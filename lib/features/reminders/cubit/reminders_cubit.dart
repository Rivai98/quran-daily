import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/reminders_repository.dart';
import '../domain/reminder_planner.dart';

enum RemindersStatus { initial, loading, success, saving, failure }

class RemindersState extends Equatable {
  const RemindersState({
    this.status = RemindersStatus.initial,
    this.personalSettings = const PersonalReminderSettings(),
    this.groupSchedule,
    this.muted = false,
    this.groupMuted = false,
    this.mutes = const {},
    this.failureMessage,
  });

  final RemindersStatus status;
  final PersonalReminderSettings personalSettings;
  final GroupReminderSchedule? groupSchedule;
  final bool muted;
  final bool groupMuted;
  final Map<String, bool> mutes;
  final String? failureMessage;

  RemindersState copyWith({
    RemindersStatus? status,
    PersonalReminderSettings? personalSettings,
    GroupReminderSchedule? groupSchedule,
    bool clearGroupSchedule = false,
    bool? muted,
    bool? groupMuted,
    Map<String, bool>? mutes,
    String? failureMessage,
  }) => RemindersState(
    status: status ?? this.status,
    personalSettings: personalSettings ?? this.personalSettings,
    groupSchedule: clearGroupSchedule
        ? null
        : groupSchedule ?? this.groupSchedule,
    muted: muted ?? this.muted,
    groupMuted: groupMuted ?? this.groupMuted,
    mutes: mutes ?? this.mutes,
    failureMessage: failureMessage,
  );

  @override
  List<Object?> get props => [
    status,
    personalSettings,
    groupSchedule,
    muted,
    groupMuted,
    mutes,
    failureMessage,
  ];
}

/// Settings view model for personal schedules, owner group schedules, and
/// device-local mutes. It contains no widget or copy dependencies.
class RemindersCubit extends Cubit<RemindersState> {
  RemindersCubit({
    required RemindersRepository repository,
    this.showTestNotification,
    this.requestPermissions,
  }) : _repository = repository,
       super(const RemindersState());

  final RemindersRepository _repository;
  final Future<void> Function()? showTestNotification;
  final Future<bool?> Function()? requestPermissions;

  Future<bool> requestNotificationPermission() async =>
      await requestPermissions?.call() ?? false;

  Future<void> loadPersonalSettings() async {
    emit(state.copyWith(status: RemindersStatus.loading));
    try {
      final settings = await _repository.loadPersonalSettings();
      emit(
        state.copyWith(
          status: RemindersStatus.success,
          personalSettings: settings,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(status: RemindersStatus.failure, failureMessage: 'load'),
      );
    }
  }

  Future<void> savePersonalSettings(PersonalReminderSettings settings) async {
    emit(state.copyWith(status: RemindersStatus.saving));
    try {
      await _repository.savePersonalSettings(settings);
      emit(
        state.copyWith(
          status: RemindersStatus.success,
          personalSettings: settings,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(status: RemindersStatus.failure, failureMessage: 'save'),
      );
    }
  }

  Future<void> loadGroupSchedule(String groupId) async {
    emit(state.copyWith(status: RemindersStatus.loading));
    try {
      final schedule = await _repository.loadGroupSchedule(groupId);
      emit(
        state.copyWith(
          status: RemindersStatus.success,
          groupSchedule: schedule,
          clearGroupSchedule: schedule == null,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(status: RemindersStatus.failure, failureMessage: 'load'),
      );
    }
  }

  Future<void> saveGroupSchedule(GroupReminderSchedule schedule) async {
    emit(state.copyWith(status: RemindersStatus.saving));
    try {
      await _repository.saveGroupSchedule(schedule);
      emit(
        state.copyWith(
          status: RemindersStatus.success,
          groupSchedule: schedule,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(status: RemindersStatus.failure, failureMessage: 'save'),
      );
    }
  }

  Future<void> loadMute(String groupId, ReminderSlot slot) async {
    try {
      final value = await _repository.isMuted(groupId, slot);
      emit(
        state.copyWith(
          status: RemindersStatus.success,
          muted: value,
          mutes: {...state.mutes, _muteKey(groupId, slot): value},
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(status: RemindersStatus.failure, failureMessage: 'load'),
      );
    }
  }

  Future<void> setMuted(String groupId, ReminderSlot slot, bool muted) async {
    emit(state.copyWith(status: RemindersStatus.saving));
    try {
      await _repository.setMuted(groupId, slot, muted);
      emit(
        state.copyWith(
          status: RemindersStatus.success,
          muted: muted,
          mutes: {...state.mutes, _muteKey(groupId, slot): muted},
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(status: RemindersStatus.failure, failureMessage: 'save'),
      );
    }
  }

  Future<void> loadGroupMute(String groupId) async {
    try {
      final value = await _repository.isGroupMuted(groupId);
      emit(state.copyWith(status: RemindersStatus.success, groupMuted: value));
    } catch (_) {
      emit(
        state.copyWith(status: RemindersStatus.failure, failureMessage: 'load'),
      );
    }
  }

  Future<void> setGroupMuted(String groupId, bool muted) async {
    emit(state.copyWith(status: RemindersStatus.saving));
    try {
      await _repository.setGroupMuted(groupId, muted);
      emit(state.copyWith(status: RemindersStatus.success, groupMuted: muted));
    } catch (_) {
      emit(
        state.copyWith(status: RemindersStatus.failure, failureMessage: 'save'),
      );
    }
  }

  Future<void> sendTestNotification() async => showTestNotification?.call();

  static String _muteKey(String groupId, ReminderSlot slot) =>
      '$groupId:${slot.name}';
}
