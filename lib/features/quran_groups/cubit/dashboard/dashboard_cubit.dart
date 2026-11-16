import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../data/entities/entities.dart';
import '../../data/repositories/khatma_repository.dart';
import '../../data/repositories/groups_repository.dart';
import '../../data/use_cases/completion_use_cases.dart';

enum DashboardStatus { initial, loading, success, empty, offline, failure }

class DashboardState extends Equatable {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.snapshot,
    this.failure,
    this.dayRolledOver = false,
    this.volunteeringAssignmentId,
    this.volunteerFeedbackCode,
    this.startingKhatma = false,
  });

  final DashboardStatus status;
  final DashboardSnapshot? snapshot;
  final AppFailure? failure;
  final bool dayRolledOver;
  final String? volunteeringAssignmentId;
  final String? volunteerFeedbackCode;
  final bool startingKhatma;

  @override
  List<Object?> get props => [
    status,
    snapshot,
    failure,
    dayRolledOver,
    volunteeringAssignmentId,
    volunteerFeedbackCode,
    startingKhatma,
  ];
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({
    required this._repository,
    required this.groupId,
    this.groupsRepository,
    this._syncPending,
    ConnectivityService? connectivityService,
    DashboardState initialState = const DashboardState(),
    this.onOpened,
    this.setAsMain,
  }) : super(initialState) {
    if (connectivityService != null) observeConnectivity(connectivityService);
  }

  final KhatmaRepository _repository;
  final SyncPendingCompletions? _syncPending;
  final String groupId;
  final GroupsRepository? groupsRepository;
  final Future<void> Function()? onOpened;
  final Future<void> Function()? setAsMain;
  bool _markedOpened = false;
  StreamSubscription<bool>? _connectivitySubscription;

  void observeConnectivity(ConnectivityService connectivityService) {
    _connectivitySubscription ??= connectivityService.online.listen((online) {
      final sync = _syncPending;
      if (online && sync != null) unawaited(sync());
    });
  }

  Future<void> refresh() async {
    if (!_markedOpened && onOpened != null) {
      _markedOpened = true;
      try {
        await onOpened!();
      } catch (_) {
        /* opening remains available offline */
      }
    }
    try {
      await _syncPending?.call();
    } catch (_) {
      // Dashboard reads remain available even if background queue replay fails.
    }
    final previousDate = state.snapshot?.today?.groupDate;
    emit(
      DashboardState(status: DashboardStatus.loading, snapshot: state.snapshot),
    );
    final result = await _repository.getDashboard(groupId);
    result.when(
      success: (snapshot) {
        final empty = snapshot.status == GroupStatus.forming;
        emit(
          DashboardState(
            status: snapshot.isStale
                ? DashboardStatus.offline
                : (empty ? DashboardStatus.empty : DashboardStatus.success),
            snapshot: snapshot,
            dayRolledOver:
                previousDate != null &&
                snapshot.today?.groupDate != null &&
                previousDate != snapshot.today!.groupDate,
          ),
        );
      },
      failure: (failure) => emit(
        DashboardState(
          status: DashboardStatus.failure,
          snapshot: state.snapshot,
          failure: failure,
        ),
      ),
    );
  }

  Future<void> volunteer(String assignmentId) async {
    if (state.volunteeringAssignmentId != null) return;
    final before = state;
    emit(
      DashboardState(
        status: before.status,
        snapshot: before.snapshot,
        failure: before.failure,
        dayRolledOver: before.dayRolledOver,
        volunteeringAssignmentId: assignmentId,
        volunteerFeedbackCode: null,
      ),
    );
    final result = await _repository.volunteer(assignmentId);
    if (result.isSuccess) {
      final snapshot = result.valueOrNull!;
      emit(
        DashboardState(
          status: snapshot.isStale
              ? DashboardStatus.offline
              : DashboardStatus.success,
          snapshot: snapshot,
          dayRolledOver: before.dayRolledOver,
          volunteerFeedbackCode: null,
        ),
      );
      return;
    }
    final failure = result.failureOrNull!;
    if (failure.code == 'juz_already_taken') {
      final refreshed = await _repository.getDashboard(groupId);
      final updated = refreshed.valueOrNull;
      emit(
        DashboardState(
          status: updated == null
              ? before.status
              : (updated.isStale
                    ? DashboardStatus.offline
                    : DashboardStatus.success),
          snapshot: updated ?? before.snapshot,
          failure: failure,
          dayRolledOver: before.dayRolledOver,
          volunteerFeedbackCode: failure.code,
        ),
      );
      return;
    }
    emit(
      DashboardState(
        status: DashboardStatus.failure,
        snapshot: before.snapshot,
        failure: failure,
        dayRolledOver: before.dayRolledOver,
        volunteerFeedbackCode: failure.code,
      ),
    );
  }

  Future<void> onResumed() => refresh();

  Future<void> pinAsMain() async => setAsMain?.call();

  /// Starts the khatma of a forming group (owner action on the forming view).
  Future<void> startKhatma(int startJuz) async {
    final groups = groupsRepository;
    if (groups == null || state.startingKhatma) return;
    final before = state;
    emit(
      DashboardState(
        status: before.status,
        snapshot: before.snapshot,
        startingKhatma: true,
      ),
    );
    final result = await groups.startKhatma(groupId, startJuz);
    await result.when(
      // Reload through KhatmaRepository so the active snapshot is cached;
      // completion looks today's assignments up in that cache.
      success: (_) => refresh(),
      failure: (failure) async => emit(
        DashboardState(
          status: before.status,
          snapshot: before.snapshot,
          failure: failure,
        ),
      ),
    );
  }

  Future<SeatMap?> getActiveMembers() async {
    if (state.snapshot?.myRole != GroupRole.owner) return null;
    final groups = groupsRepository;
    if (groups == null) return null;
    final result = await groups.getMembers(groupId);
    return result.valueOrNull;
  }

  Future<Result<DashboardSnapshot>> overrideAssignment(
    String assignmentId,
    String membershipId,
  ) async {
    if (state.snapshot?.myRole != GroupRole.owner) {
      return const FailureResult(
        PermissionFailure(message: 'owner only', code: 'forbidden'),
      );
    }
    final result = await _repository.overrideAssignment(
      assignmentId,
      membershipId,
    );
    result.when(
      success: (snapshot) => emit(
        DashboardState(
          status: snapshot.isStale
              ? DashboardStatus.offline
              : DashboardStatus.success,
          snapshot: snapshot,
        ),
      ),
      failure: (failure) => emit(
        DashboardState(
          status: DashboardStatus.failure,
          snapshot: state.snapshot,
          failure: failure,
        ),
      ),
    );
    return result;
  }

  @override
  Future<void> close() async {
    await _connectivitySubscription?.cancel();
    await super.close();
  }
}
