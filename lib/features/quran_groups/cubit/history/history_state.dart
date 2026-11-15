import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../data/entities/entities.dart';

enum HistoryStatus { initial, loading, success, empty, failure, offline }

class HistoryState extends Equatable {
  const HistoryState({
    required this.groupId,
    this.status = HistoryStatus.initial,
    this.days = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.selectedDay,
    this.selectedDayDate,
    this.isLoadingDetail = false,
    this.failure,
  });

  final String groupId;
  final HistoryStatus status;
  final List<HistoryDaySummary> days;
  final bool hasMore;
  final bool isLoadingMore;
  final HistoryDaySummary? selectedDay;
  final String? selectedDayDate;
  final bool isLoadingDetail;
  final AppFailure? failure;

  HistoryState copyWith({
    HistoryStatus? status,
    List<HistoryDaySummary>? days,
    bool? hasMore,
    bool? isLoadingMore,
    HistoryDaySummary? selectedDay,
    bool clearSelectedDay = false,
    String? selectedDayDate,
    bool clearSelectedDayDate = false,
    bool? isLoadingDetail,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return HistoryState(
      groupId: groupId,
      status: status ?? this.status,
      days: days ?? this.days,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      selectedDay: clearSelectedDay ? null : (selectedDay ?? this.selectedDay),
      selectedDayDate: clearSelectedDayDate
          ? null
          : (selectedDayDate ?? this.selectedDayDate),
      isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
        groupId,
        status,
        days,
        hasMore,
        isLoadingMore,
        selectedDay,
        selectedDayDate,
        isLoadingDetail,
        failure,
      ];
}
