import 'dart:async';

import '../../../core/sync/current_group_day.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../quran_groups/data/repositories/khatma_repository.dart';
import '../../profile/data/entities/profile_entities.dart';
import '../../profile/data/repositories/profile_repository.dart';
import '../data/today_repository.dart';
import '../data/today_snapshot.dart';
import '../data/tomorrow_rotation.dart';

enum HomeStatus { initial, loading, content, empty, offline, failure }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.snapshot,
    this.failure,
    this.updatingId,
    this.tomorrowPortions = const {},
    this.khatmasEndingToday = const {},
    this.profile,
  });
  final HomeStatus status;
  final TodaySnapshot? snapshot;
  final AppFailure? failure;
  final String? updatingId;
  final Map<String, int> tomorrowPortions;
  final Set<String> khatmasEndingToday;
  final UserProfile? profile;
  bool get allDone =>
      snapshot != null &&
      snapshot!.groups
          .where((g) => g.day != null)
          .expand((g) => g.items)
          .isNotEmpty &&
      snapshot!.groups
          .where((g) => g.day != null)
          .expand((g) => g.items)
          .every((i) => i.status == 'completed' || i.status == 'late');
  @override
  List<Object?> get props => [
    status,
    snapshot,
    failure,
    updatingId,
    tomorrowPortions,
    khatmasEndingToday,
    profile,
  ];
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required this._repository,
    required KhatmaRepository khatmaRepository,
    this.profileRepository,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now,
       _khatma = khatmaRepository,
       super(const HomeState());
  final TodayRepository _repository;
  final DateTime Function() _now;
  final KhatmaRepository _khatma;
  final ProfileRepository? profileRepository;
  DateTime? _lastLoadedAt;
  static const _reselectDebounce = Duration(seconds: 3);
  Future<void>? _loading;
  Timer? _rollover;
  String? _updatingId;

  Future<void> load() => _loading ??= _load().whenComplete(() {
    _loading = null;
  });

  Future<void> _load() async {
    _loadProfileQuietly();
    // Only show the loading state on the very first load; later refreshes keep the
    // current content on screen so the cards don't jump.
    if (state.snapshot == null) {
      emit(HomeState(status: HomeStatus.loading, snapshot: state.snapshot));
    }
    final result = await _repository.getToday(onCached: _applyToday);
    if (isClosed) return;
    result.when(
      success: (snapshot) {
        _lastLoadedAt = _now();
        _applyToday(snapshot);
      },
      failure: (failure) => emit(
        HomeState(
          status: state.snapshot == null
              ? HomeStatus.failure
              : HomeStatus.offline,
          snapshot: state.snapshot,
          failure: failure,
          profile: state.profile,
        ),
      ),
    );
  }

  void _applyToday(TodaySnapshot snapshot) {
    if (isClosed) return;
    emit(
      HomeState(
        snapshot: snapshot,
        status: snapshot.isStale
            ? HomeStatus.offline
            : snapshot.groups.isEmpty
            ? HomeStatus.empty
            : HomeStatus.content,
        tomorrowPortions: _tomorrowFor(snapshot),
        khatmasEndingToday: _endingTodayFor(snapshot),
        profile: state.profile,
        updatingId: _updatingId,
      ),
    );
    _rollover?.cancel();
    final ends =
        snapshot.groups
            .map((g) => g.day?.endsAt)
            .nonNulls
            .where((end) => end.isAfter(_now()))
            .toList()
          ..sort();
    if (ends.isEmpty) return;
    _rollover = Timer(ends.first.difference(_now()), () {
      if (isClosed) return;
      profileRepository?.invalidate();
      _applyToday(
        TodaySnapshot.fromJson(
          currentTodayJson(snapshot.toJson(), _now()),
          isStale: true,
        ),
      );
      unawaited(load());
    });
  }

  @override
  Future<void> close() {
    _rollover?.cancel();
    return super.close();
  }

  Future<void> _loadProfileQuietly({bool forceRefresh = false}) async {
    final repository = profileRepository;
    if (repository == null) return;
    final result = await repository.getProfile(forceRefresh: forceRefresh);
    if (isClosed) return;
    result.when(
      success: (profile) => emit(
        HomeState(
          status: state.status,
          snapshot: state.snapshot,
          failure: state.failure,
          updatingId: state.updatingId,
          tomorrowPortions: state.tomorrowPortions,
          khatmasEndingToday: state.khatmasEndingToday,
          profile: profile,
        ),
      ),
      failure: (_) {},
    );
  }

  Map<String, int> _tomorrowFor(TodaySnapshot snapshot) {
    final result = <String, int>{};
    for (final group in snapshot.groups) {
      final day = group.day;
      final seatItems = group.items.where((item) => item.kind == 'seat');
      final seatItem = seatItems.isEmpty ? null : seatItems.first;
      if (day == null || day.restDay || seatItem == null) continue;
      if (day.cycleDay == day.cycleLength - 1) continue;
      final next = tomorrowSeatPortion(
        unit: group.portionUnit,
        currentPortion: seatItem.portionIndex,
        seatNumber: seatItem.seatNumber,
        cycleNumber: day.cycleNumber,
        cycleDay: day.cycleDay,
        cycleLength: day.cycleLength,
      );
      if (next != null) result[group.groupId] = next;
    }
    return result;
  }

  Set<String> _endingTodayFor(TodaySnapshot snapshot) {
    final result = <String>{};
    for (final group in snapshot.groups) {
      final day = group.day;
      final seatItems = group.items.where((item) => item.kind == 'seat');
      final seatItem = seatItems.isEmpty ? null : seatItems.first;
      if (day == null || day.restDay || seatItem == null) continue;
      if (day.cycleDay == day.cycleLength - 1 &&
          day.cycleLength == portionCycleLength(group.portionUnit)) {
        result.add(group.groupId);
      }
    }
    return result;
  }

  Future<void> refresh() async {
    unawaited(_loadProfileQuietly(forceRefresh: true));
    await load();
  }

  /// Called when the Home tab is re-selected: refresh quietly (content stays
  /// on screen). Groups created, joined or started on other tabs must show at
  /// once, so only a near-duplicate tap within [_reselectDebounce] is skipped.
  Future<void> refreshIfStale() {
    final last = _lastLoadedAt;
    if (last != null && _now().difference(last) < _reselectDebounce) {
      return Future.value();
    }
    return load();
  }

  Future<void> pinMainGroup(String groupId) async {
    final result = await _repository.setMainGroup(groupId);
    if (result.isSuccess) await load();
  }

  Future<void> complete(TodayItem item) => _mutatePersonal(
    item,
    () => _khatma.markComplete(item.assignmentId, _now()),
  );

  Future<void> undo(TodayItem item) async {
    if (!item.canUndo) return;
    await _mutatePersonal(
      item,
      () => _khatma.undoCompletion(item.assignmentId),
    );
  }

  Future<void> _mutatePersonal(
    TodayItem item,
    Future<Object?> Function() action,
  ) async {
    if (_updatingId != null) return;
    _updatingId = item.assignmentId;
    emit(
      HomeState(
        status: state.status,
        snapshot: state.snapshot,
        updatingId: _updatingId,
        profile: state.profile,
        tomorrowPortions: state.tomorrowPortions,
        khatmasEndingToday: state.khatmasEndingToday,
      ),
    );
    try {
      await action();
      profileRepository?.invalidate();
      await _loading;
    } finally {
      _updatingId = null;
    }
    if (!isClosed) await load();
  }
}
