import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../../quran_groups/data/repositories/khatma_repository.dart';
import '../data/today_repository.dart';
import '../data/today_snapshot.dart';

enum HomeStatus { initial, loading, content, empty, offline, failure }
class HomeState extends Equatable {
  const HomeState({this.status = HomeStatus.initial, this.snapshot, this.failure, this.updatingId});
  final HomeStatus status;
  final TodaySnapshot? snapshot;
  final AppFailure? failure;
  final String? updatingId;
  bool get allDone => snapshot != null && snapshot!.groups.where((g) => g.day != null).expand((g) => g.items).isNotEmpty && snapshot!.groups.where((g) => g.day != null).expand((g) => g.items).every((i) => i.status == 'completed' || i.status == 'late');
  @override List<Object?> get props => [status,snapshot,failure,updatingId];
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({required TodayRepository repository, required KhatmaRepository khatmaRepository}) : _repository = repository, _khatma = khatmaRepository, super(const HomeState());
  final TodayRepository _repository;
  final KhatmaRepository _khatma;
  Future<void> load() async {
    emit(HomeState(status: HomeStatus.loading, snapshot: state.snapshot));
    final result = await _repository.getToday();
    result.when(success: (snapshot) => emit(HomeState(snapshot: snapshot, status: snapshot.isStale ? HomeStatus.offline : snapshot.groups.isEmpty ? HomeStatus.empty : HomeStatus.content)),
      failure: (failure) => emit(HomeState(status: HomeStatus.failure, snapshot: state.snapshot, failure: failure)));
  }
  Future<void> refresh() => load();
  Future<void> pinMainGroup(String groupId) async { final result = await _repository.setMainGroup(groupId); if (result.isSuccess) await load(); }
  Future<void> complete(TodayItem item) async {
    if (state.updatingId != null) return;
    emit(HomeState(status: state.status, snapshot: state.snapshot, updatingId: item.assignmentId));
    await _khatma.markComplete(item.assignmentId, DateTime.now());
    await load();
  }
  Future<void> undo(TodayItem item) async {
    if (state.updatingId != null || !item.canUndo) return;
    emit(HomeState(status: state.status, snapshot: state.snapshot, updatingId: item.assignmentId));
    await _khatma.undoCompletion(item.assignmentId);
    await load();
  }
}
