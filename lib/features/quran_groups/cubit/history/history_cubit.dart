import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../data/repositories/khatma_repository.dart';
import 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit({required String groupId, required this._repository})
    : super(HistoryState(groupId: groupId));

  final KhatmaRepository _repository;

  Future<void> loadHistory() async {
    emit(state.copyWith(status: HistoryStatus.loading, clearFailure: true));

    final result = await _repository.getHistory(state.groupId, limit: 30);

    result.when(
      success: (days) {
        if (days.isEmpty) {
          emit(
            state.copyWith(
              status: HistoryStatus.empty,
              days: const [],
              hasMore: false,
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: HistoryStatus.success,
              days: days,
              hasMore: days.length >= 30,
            ),
          );
        }
      },
      failure: (failure) {
        if (failure is NetworkFailure) {
          emit(state.copyWith(status: HistoryStatus.offline, failure: failure));
        } else {
          emit(state.copyWith(status: HistoryStatus.failure, failure: failure));
        }
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.days.isEmpty) return;

    emit(state.copyWith(isLoadingMore: true));

    final lastDate = state.days.last.groupDate;
    final result = await _repository.getHistory(
      state.groupId,
      beforeDate: lastDate,
      limit: 30,
    );

    result.when(
      success: (newDays) {
        emit(
          state.copyWith(
            isLoadingMore: false,
            days: [...state.days, ...newDays],
            hasMore: newDays.length >= 30,
          ),
        );
      },
      failure: (_) {
        emit(state.copyWith(isLoadingMore: false));
      },
    );
  }

  Future<void> loadDayDetail(String groupDate) async {
    emit(
      state.copyWith(
        isLoadingDetail: true,
        selectedDayDate: groupDate,
        clearFailure: true,
      ),
    );

    final result = await _repository.getHistoryDay(state.groupId, groupDate);

    result.when(
      success: (detail) {
        final updatedDays = state.days.map((d) {
          if (d.groupDate == groupDate) {
            return detail;
          }
          return d;
        }).toList();

        emit(
          state.copyWith(
            isLoadingDetail: false,
            selectedDay: detail,
            days: updatedDays,
          ),
        );
      },
      failure: (failure) {
        emit(state.copyWith(isLoadingDetail: false, failure: failure));
      },
    );
  }

  void clearSelectedDay() {
    emit(state.copyWith(clearSelectedDay: true, clearSelectedDayDate: true));
  }
}
