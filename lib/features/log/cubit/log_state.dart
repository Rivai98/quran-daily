import 'package:equatable/equatable.dart';

import '../data/entities/log_entities.dart';
import '../../../../core/errors/failures.dart';

enum LogStatus { initial, loading, success, empty, failure, offline }

class LogState extends Equatable {
  const LogState({
    this.status = LogStatus.initial,
    this.log,
    this.failure,
    this.isLoadingMore = false,
  });
  final LogStatus status;
  final PersonalLog? log;
  final AppFailure? failure;
  final bool isLoadingMore;
  bool get hasMore => log?.nextBefore != null;
  LogState copyWith({
    LogStatus? status,
    PersonalLog? log,
    AppFailure? failure,
    bool? isLoadingMore,
    bool clearFailure = false,
  }) => LogState(
    status: status ?? this.status,
    log: log ?? this.log,
    failure: clearFailure ? null : (failure ?? this.failure),
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
  @override
  List<Object?> get props => [status, log, failure, isLoadingMore];
}
