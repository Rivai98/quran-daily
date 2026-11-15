import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../data/entities/entities.dart';
import '../../data/repositories/khatma_repository.dart';
import 'assignment_state.dart';

class AssignmentCubit extends Cubit<AssignmentState> {
  AssignmentCubit({
    required KhatmaRepository repository,
    required Assignment assignment,
    this.groupId,
    this.dayState = DayState.open,
  }) : _repository = repository,
       super(AssignmentState(assignment: assignment, dayState: dayState));

  final KhatmaRepository _repository;
  final String? groupId;
  final DayState dayState;
  bool _busy = false;

  Future<void> complete(DateTime clientRecordedAt) async {
    if (_busy ||
        state.assignment.status == AssignmentStatusEnum.completed ||
        state.assignment.status == AssignmentStatusEnum.late) {
      return;
    }
    _busy = true;
    emit(
      state.copyWith(
        status: AssignmentActionStatus.loading,
        clearFailure: true,
      ),
    );
    final result = await _repository.markComplete(
      state.assignment.assignmentId,
      clientRecordedAt,
    );
    _busy = false;
    result.when(
      success: (snapshot) => _finish(snapshot, AssignmentActionStatus.success),
      failure: (failure) {
        if (failure.kind == FailureKind.offlineQueued) {
          emit(
            state.copyWith(
              assignment: _withStatus(
                state.assignment,
                dayState == DayState.grace
                    ? AssignmentStatusEnum.late
                    : AssignmentStatusEnum.completed,
              ),
              status: AssignmentActionStatus.queued,
              failure: failure,
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: AssignmentActionStatus.failure,
              failure: failure,
            ),
          );
        }
      },
    );
  }

  Future<void> undo() async {
    if (_busy ||
        (state.assignment.status != AssignmentStatusEnum.completed &&
            state.assignment.status != AssignmentStatusEnum.late)) {
      return;
    }
    _busy = true;
    emit(
      state.copyWith(
        status: AssignmentActionStatus.loading,
        clearFailure: true,
      ),
    );
    final result = await _repository.undoCompletion(
      state.assignment.assignmentId,
    );
    _busy = false;
    result.when(
      success: (snapshot) => _finish(snapshot, AssignmentActionStatus.success),
      failure: (failure) {
        if (failure.kind == FailureKind.offlineQueued) {
          emit(
            state.copyWith(
              assignment: _withStatus(
                state.assignment,
                state.assignment.status == AssignmentStatusEnum.late
                    ? AssignmentStatusEnum.missed
                    : AssignmentStatusEnum.pending,
              ),
              status: AssignmentActionStatus.queued,
              failure: failure,
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: AssignmentActionStatus.failure,
              failure: failure,
            ),
          );
        }
      },
    );
  }

  Future<void> retrySync() async {
    if (_busy) return;
    _busy = true;
    emit(state.copyWith(status: AssignmentActionStatus.loading));
    final report = await _repository.syncPending();
    if (report.remaining > 0 || groupId == null) {
      _busy = false;
      emit(
        state.copyWith(
          status: report.remaining == 0
              ? AssignmentActionStatus.success
              : AssignmentActionStatus.failure,
        ),
      );
      return;
    }
    final dashboard = await _repository.getDashboard(groupId!);
    _busy = false;
    dashboard.when(
      success: (snapshot) => _finish(snapshot, AssignmentActionStatus.success),
      failure: (failure) => emit(
        state.copyWith(
          status: AssignmentActionStatus.failure,
          failure: failure,
        ),
      ),
    );
  }

  void _finish(DashboardSnapshot snapshot, AssignmentActionStatus status) {
    final updated = [...snapshot.myAssignments, ...snapshot.assignments]
        .where((item) => item.assignmentId == state.assignment.assignmentId)
        .firstOrNull;
    emit(
      state.copyWith(assignment: updated ?? state.assignment, status: status),
    );
  }

  Assignment _withStatus(Assignment assignment, AssignmentStatusEnum status) =>
      Assignment(
        assignmentId: assignment.assignmentId,
        juz: assignment.juz,
        seatNumber: assignment.seatNumber,
        kind: assignment.kind,
        status: status,
        readerDisplayName: assignment.readerDisplayName,
        isMe: assignment.isMe,
        completedAt: assignment.completedAt,
      );
}
