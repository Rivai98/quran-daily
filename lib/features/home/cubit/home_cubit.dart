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
  }) : _khatma = khatmaRepository,
       super(const HomeState());
  final TodayRepository _repository;
  final KhatmaRepository _khatma;
  final ProfileRepository? profileRepository;
  DateTime? _lastLoadedAt;
  bool _loading = false;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _loadProfileQuietly();
    // Only show the loading state on the very first load; later refreshes keep the
    // current content on screen so the cards don't jump.
    if (state.snapshot == null) {
      emit(HomeState(status: HomeStatus.loading, snapshot: state.snapshot));
    }
    final result = await _repository.getToday();
    _loading = false;
    result.when(
      success: (snapshot) {
        // A cached (stale) snapshot must not replace fresh content already shown.
        if (snapshot.isStale && state.status == HomeStatus.content) return;
        _lastLoadedAt = DateTime.now();
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
          ),
        );
      },
      failure: (failure) => emit(
        HomeState(
          status: HomeStatus.failure,
          snapshot: state.snapshot,
          failure: failure,
        ),
      ),
    );
  }

  Future<void> _loadProfileQuietly() async {
    final repository = profileRepository;
    if (repository == null) return;
    final result = await repository.getProfile();
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
          tomorrowSeatPortion(
                unit: group.portionUnit,
                currentPortion: seatItem.portionIndex,
                seatNumber: seatItem.seatNumber,
                cycleNumber: day.cycleNumber,
                cycleDay: day.cycleDay,
                cycleLength: day.cycleLength,
              ) ==
              null) {
        result.add(group.groupId);
      }
    }
    return result;
  }

  Future<void> refresh() => load();

  /// Called when the Home tab is re-selected: refresh quietly, at most every 30 s.
  Future<void> refreshIfStale() {
    final last = _lastLoadedAt;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(seconds: 30)) {
      return Future.value();
    }
    return load();
  }

  Future<void> pinMainGroup(String groupId) async {
    final result = await _repository.setMainGroup(groupId);
    if (result.isSuccess) await load();
  }

  Future<void> complete(TodayItem item) async {
    if (state.updatingId != null) return;
    emit(
      HomeState(
        status: state.status,
        snapshot: state.snapshot,
        updatingId: item.assignmentId,
      ),
    );
    await _khatma.markComplete(item.assignmentId, DateTime.now());
    await load();
  }

  Future<void> undo(TodayItem item) async {
    if (state.updatingId != null || !item.canUndo) return;
    emit(
      HomeState(
        status: state.status,
        snapshot: state.snapshot,
        updatingId: item.assignmentId,
      ),
    );
    await _khatma.undoCompletion(item.assignmentId);
    await load();
  }
}
