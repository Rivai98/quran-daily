import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../data/entities/entities.dart';
import '../../data/repositories/khatma_repository.dart';
import '../../data/use_cases/completion_use_cases.dart';

enum DashboardStatus { initial, loading, success, empty, offline, failure }

class DashboardState extends Equatable {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.snapshot,
    this.failure,
    this.dayRolledOver = false,
  });

  final DashboardStatus status;
  final DashboardSnapshot? snapshot;
  final AppFailure? failure;
  final bool dayRolledOver;

  @override
  List<Object?> get props => [status, snapshot, failure, dayRolledOver];
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({
    required KhatmaRepository repository,
    required this.groupId,
    SyncPendingCompletions? syncPending,
    ConnectivityService? connectivityService,
    DashboardState initialState = const DashboardState(),
  }) : _repository = repository,
       _syncPending = syncPending,
       super(initialState) {
    if (connectivityService != null) observeConnectivity(connectivityService);
  }

  final KhatmaRepository _repository;
  final SyncPendingCompletions? _syncPending;
  final String groupId;
  StreamSubscription<bool>? _connectivitySubscription;

  void observeConnectivity(ConnectivityService connectivityService) {
    _connectivitySubscription ??= connectivityService.online.listen((online) {
      final sync = _syncPending;
      if (online && sync != null) unawaited(sync());
    });
  }

  Future<void> refresh() async {
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

  Future<void> onResumed() => refresh();

  @override
  Future<void> close() async {
    await _connectivitySubscription?.cancel();
    await super.close();
  }
}
