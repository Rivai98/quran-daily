import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../data/entities/entities.dart';

enum AssignmentActionStatus { initial, loading, success, queued, failure }

class AssignmentState extends Equatable {
  const AssignmentState({
    required this.assignment,
    this.dayState = DayState.open,
    this.status = AssignmentActionStatus.initial,
    this.failure,
  });

  final Assignment assignment;
  final DayState dayState;
  final AssignmentActionStatus status;
  final AppFailure? failure;

  AssignmentState copyWith({
    Assignment? assignment,
    DayState? dayState,
    AssignmentActionStatus? status,
    AppFailure? failure,
    bool clearFailure = false,
  }) => AssignmentState(
    assignment: assignment ?? this.assignment,
    dayState: dayState ?? this.dayState,
    status: status ?? this.status,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [assignment, dayState, status, failure];
}
