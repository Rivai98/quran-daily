import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../data/entities/entities.dart';
import '../../data/repositories/groups_repository.dart';

enum GroupSettingsStatus { initial, loading, submitting, success, started, archived, failure }

class GroupSettingsState extends Equatable {
  const GroupSettingsState({
    this.groupId,
    this.status = GroupSettingsStatus.initial,
    this.inviteCode,
    this.startedSnapshot,
    this.failure,
  });

  final String? groupId;
  final GroupSettingsStatus status;
  final String? inviteCode;
  final DashboardSnapshot? startedSnapshot;
  final AppFailure? failure;

  GroupSettingsState copyWith({
    String? groupId,
    GroupSettingsStatus? status,
    String? inviteCode,
    DashboardSnapshot? startedSnapshot,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return GroupSettingsState(
      groupId: groupId ?? this.groupId,
      status: status ?? this.status,
      inviteCode: inviteCode ?? this.inviteCode,
      startedSnapshot: startedSnapshot ?? this.startedSnapshot,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props =>
      [groupId, status, inviteCode, startedSnapshot, failure];
}

/// S9 group settings: settings form, start khatma, invite regenerate,
/// archive. Owner-only actions are enforced server-side; the cubit maps
/// the failure kinds.
class GroupSettingsCubit extends Cubit<GroupSettingsState> {
  GroupSettingsCubit({required GroupsRepository repository})
      : _repository = repository,
        super(const GroupSettingsState());

  final GroupsRepository _repository;

  void load({
    required String groupId,
    String? inviteCode,
  }) {
    emit(state.copyWith(
      groupId: groupId,
      inviteCode: inviteCode,
      status: GroupSettingsStatus.initial,
    ));
  }

  Future<void> startKhatma({required int startJuz}) async {
    final groupId = state.groupId;
    if (groupId == null) return;
    if (state.status == GroupSettingsStatus.submitting) return;
    if (startJuz < 1 || startJuz > 30) {
      emit(state.copyWith(
        status: GroupSettingsStatus.failure,
        failure: const ValidationFailure(
            message: 'invalid start juz', code: 'validation_failed'),
      ));
      return;
    }

    emit(state.copyWith(status: GroupSettingsStatus.submitting, clearFailure: true));
    final result = await _repository.startKhatma(groupId, startJuz);
    result.when(
      success: (DashboardSnapshot snapshot) => emit(state.copyWith(
        status: GroupSettingsStatus.started,
        startedSnapshot: snapshot,
      )),
      failure: (AppFailure failure) => emit(
        state.copyWith(status: GroupSettingsStatus.failure, failure: failure),
      ),
    );
  }

  Future<void> saveSettings({
    String? name,
    String? shortDescription,
    String? timezone,
    String? dayStartTime,
    GroupVisibility? visibility,
    JoinMode? joinMode,
  }) async {
    final groupId = state.groupId;
    if (groupId == null) return;
    if (state.status == GroupSettingsStatus.submitting) return;

    final patch = GroupSettingsPatch(
      name: name,
      shortDescription: shortDescription,
      timezone: timezone,
      dayStartTime: dayStartTime,
      visibility: visibility,
      joinMode: joinMode,
    );
    if (patch.isEmpty) {
      emit(state.copyWith(
        status: GroupSettingsStatus.failure,
        failure: const ValidationFailure(
            message: 'empty patch', code: 'validation_failed'),
      ));
      return;
    }

    emit(state.copyWith(status: GroupSettingsStatus.submitting, clearFailure: true));
    final result = await _repository.updateGroupSettings(groupId, patch);
    result.when(
      success: (_) => emit(state.copyWith(status: GroupSettingsStatus.success)),
      failure: (AppFailure failure) => emit(
        state.copyWith(status: GroupSettingsStatus.failure, failure: failure),
      ),
    );
  }

  Future<void> regenerateInvite() async {
    final groupId = state.groupId;
    if (groupId == null) return;
    if (state.status == GroupSettingsStatus.submitting) return;

    emit(state.copyWith(status: GroupSettingsStatus.submitting, clearFailure: true));
    final result = await _repository.regenerateInvite(groupId);
    result.when(
      success: (String code) => emit(state.copyWith(
        status: GroupSettingsStatus.success,
        inviteCode: code,
      )),
      failure: (AppFailure failure) => emit(
        state.copyWith(status: GroupSettingsStatus.failure, failure: failure),
      ),
    );
  }

  Future<void> archiveGroup() async {
    final groupId = state.groupId;
    if (groupId == null) return;
    if (state.status == GroupSettingsStatus.submitting) return;

    emit(state.copyWith(status: GroupSettingsStatus.submitting, clearFailure: true));
    final result = await _repository.archiveGroup(groupId);
    result.when(
      success: (_) => emit(state.copyWith(status: GroupSettingsStatus.archived)),
      failure: (AppFailure failure) => emit(
        state.copyWith(status: GroupSettingsStatus.failure, failure: failure),
      ),
    );
  }
}
