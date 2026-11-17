import 'dart:convert';
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/sync/current_group_day.dart';
import '../../data/models/models.dart';
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
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now,
       super(initialState) {
    if (connectivityService != null) observeConnectivity(connectivityService);
    _followCache();
  }

  final KhatmaRepository _repository;
  final DateTime Function() _now;
  final SyncPendingCompletions? _syncPending;
  final String groupId;
  final GroupsRepository? groupsRepository;
  final Future<void> Function()? onOpened;
  final Future<void> Function()? setAsMain;
  bool _markedOpened = false;
  Future<void>? _refreshing;
  Timer? _rollover;
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<DashboardSnapshot?>? _cacheSubscription;

  /// Completions made outside this screen (the Mushaf reader, Home, the
  /// personal assignment) refresh the shared cache; show them here at once.
  void _followCache() {
    try {
      _cacheSubscription = _repository
          .watchCachedDashboard(groupId)
          .listen(_applyCached, onError: (_) {});
    } on Object {
      // Repositories without a cache stream simply refresh on demand.
    }
  }

  void _applyCached(DashboardSnapshot? snapshot) {
    if (isClosed || snapshot == null) return;
    if (snapshot == state.snapshot) return;
    final current = state.snapshot;
    if (snapshot.isStale &&
        current != null &&
        !current.isStale &&
        jsonEncode(dashboardSnapshotToJson(snapshot)) ==
            jsonEncode(dashboardSnapshotToJson(current))) {
      return;
    }
    emit(
      DashboardState(
        status: snapshot.isStale
            ? DashboardStatus.offline
            : snapshot.status == GroupStatus.forming
            ? DashboardStatus.empty
            : DashboardStatus.success,
        snapshot: snapshot,
        volunteeringAssignmentId: state.volunteeringAssignmentId,
        startingKhatma: state.startingKhatma,
      ),
    );
    _armRollover(snapshot);
  }

  void _armRollover(DashboardSnapshot snapshot) {
    _rollover?.cancel();
    final end = snapshot.today?.endsAt;
    if (end == null || !end.isAfter(_now())) return;
    _rollover = Timer(end.difference(_now()), () {
      if (isClosed) return;
      _applyCached(
        dashboardSnapshotFromJson(
          currentDashboardJson(dashboardSnapshotToJson(snapshot), _now()),
          isStale: true,
        ),
      );
      unawaited(refresh());
    });
  }

  void observeConnectivity(ConnectivityService connectivityService) {
    _connectivitySubscription ??= connectivityService.online.listen((online) {
      final sync = _syncPending;
      if (online && sync != null) unawaited(sync());
    });
  }

  Future<void> refresh() => _refreshing ??= _refresh().whenComplete(() {
    _refreshing = null;
  });

  Future<void> _markOpened() async {
    try {
      await onOpened?.call();
    } catch (_) {
      // Bookkeeping is best effort; cached reading remains available offline.
    }
  }

  Future<void> _refresh() async {
    if (!_markedOpened && onOpened != null) {
      _markedOpened = true;
      unawaited(_markOpened());
    }
    try {
      final report = await _syncPending?.call();
      if (report?.refreshedGroupIds.contains(groupId) ?? false) return;
    } catch (_) {
      // A failed background replay must not prevent dashboard reads.
    }
    final previousDate = state.snapshot?.today?.groupDate;
    emit(
      DashboardState(status: DashboardStatus.loading, snapshot: state.snapshot),
    );
    final result = await _repository.getDashboard(groupId);
    if (isClosed) return;
    result.when(
      success: (snapshot) {
        _armRollover(snapshot);
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
      success: (snapshot) async {
        if (isClosed) return;
        emit(
          DashboardState(
            status: snapshot.isStale
                ? DashboardStatus.offline
                : DashboardStatus.success,
            snapshot: snapshot,
          ),
        );
        _armRollover(snapshot);
      },
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
    _rollover?.cancel();
    await _connectivitySubscription?.cancel();
    await _cacheSubscription?.cancel();
    await super.close();
  }
}
