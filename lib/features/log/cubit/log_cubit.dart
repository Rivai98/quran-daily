import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/entities/log_entities.dart';
import '../data/repositories/log_repository.dart';
import 'log_state.dart';

class LogCubit extends Cubit<LogState> {
  LogCubit({required this._repository}) : super(const LogState());
  final LogRepository _repository;

  Future<void>? _loading;
  Future<void> load() => _loading ??= _load().whenComplete(() {
    _loading = null;
  });

  Future<void> _load() async {
    emit(
      state.copyWith(
        status: state.log == null ? LogStatus.loading : state.status,
        clearFailure: true,
      ),
    );
    final result = await _repository.getLog(onCached: _applyLog);
    if (isClosed) return;
    result.when(
      success: _applyLog,
      failure: (failure) =>
          emit(state.copyWith(status: LogStatus.failure, failure: failure)),
    );
  }

  void _applyLog(PersonalLog log) {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: log.isStale
            ? LogStatus.offline
            : log.days.isEmpty
            ? LogStatus.empty
            : LogStatus.success,
        log: log,
      ),
    );
  }

  Future<void> refresh() => load();

  Future<void> loadMore() async {
    final before = state.log?.nextBefore;
    if (state.isLoadingMore || before == null || state.log == null) return;
    emit(state.copyWith(isLoadingMore: true));
    final result = await _repository.getLog(before: before);
    result.when(
      success: (next) {
        final current = state.log!;
        final combined = PersonalLog(
          streak: current.streak,
          bestStreak: current.bestStreak,
          month: current.month,
          days: [...current.days, ...next.days],
          nextBefore: next.nextBefore,
          isStale: current.isStale || next.isStale,
        );
        emit(state.copyWith(log: combined, isLoadingMore: false));
      },
      failure: (failure) =>
          emit(state.copyWith(isLoadingMore: false, failure: failure)),
    );
  }
}
