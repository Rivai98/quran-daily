import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/features/quran_groups/cubit/assignment/assignment_cubit.dart';
import 'package:quran_daily/features/quran_groups/cubit/assignment/assignment_state.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/khatma_repository.dart';

class _Repository extends Mock implements KhatmaRepository {}

Assignment _assignment(AssignmentStatusEnum status) => Assignment(
  assignmentId: 'a-1',
  juz: 1,
  seatNumber: 1,
  kind: AssignmentKind.seat,
  status: status,
  isMe: true,
);

DashboardSnapshot _snapshot(AssignmentStatusEnum status) {
  final assignment = _assignment(status);
  return DashboardSnapshot(
    groupId: 'g1',
    groupName: 'group',
    myRole: GroupRole.member,
    status: GroupStatus.active,
    serverGeneratedAt: DateTime.parse('2026-11-15T10:00:00Z'),
    today: GroupDayInfo(
      groupDate: '2026-11-15',
      state: DayState.open,
      completedCount: status == AssignmentStatusEnum.completed ? 1 : 0,
      lateCount: 0,
      missedCount: 0,
      unreadCount: 0,
      pendingCount: status == AssignmentStatusEnum.pending ? 1 : 0,
      availableCount: 29,
      fullKhatma: false,
      endsAt: DateTime.parse('2026-11-15T23:59:00Z'),
    ),
    myAssignments: [assignment],
    assignments: [assignment],
  );
}

void main() {
  late _Repository repository;
  late Completer<Result<DashboardSnapshot>> pendingCompletion;

  AssignmentCubit buildCubit({
    AssignmentStatusEnum status = AssignmentStatusEnum.pending,
  }) => AssignmentCubit(
    repository: repository,
    groupId: 'g1',
    assignment: _assignment(status),
  );

  setUp(() {
    repository = _Repository();
    registerFallbackValue(DateTime(2026));
  });

  blocTest<AssignmentCubit, AssignmentState>(
    'completion updates the assignment status',
    build: () {
      when(() => repository.markComplete('a-1', any())).thenAnswer(
        (_) async => Success(_snapshot(AssignmentStatusEnum.completed)),
      );
      return buildCubit();
    },
    act: (bloc) => bloc.complete(DateTime.parse('2026-11-15T12:00:00Z')),
    expect: () => [
      isA<AssignmentState>().having(
        (s) => s.status,
        'status',
        AssignmentActionStatus.loading,
      ),
      isA<AssignmentState>()
          .having((s) => s.status, 'status', AssignmentActionStatus.success)
          .having(
            (s) => s.assignment.status,
            'assignment',
            AssignmentStatusEnum.completed,
          ),
    ],
  );

  blocTest<AssignmentCubit, AssignmentState>(
    'offline queued completion is visible optimistically',
    build: () {
      when(() => repository.markComplete('a-1', any())).thenAnswer(
        (_) async => const FailureResult<DashboardSnapshot>(
          OfflineQueuedFailure(message: 'queued', code: 'offline_queued'),
        ),
      );
      return buildCubit();
    },
    act: (bloc) => bloc.complete(DateTime.parse('2026-11-15T12:00:00Z')),
    expect: () => [
      isA<AssignmentState>().having(
        (s) => s.status,
        'status',
        AssignmentActionStatus.loading,
      ),
      isA<AssignmentState>()
          .having((s) => s.status, 'status', AssignmentActionStatus.queued)
          .having(
            (s) => s.assignment.status,
            'assignment',
            AssignmentStatusEnum.completed,
          ),
    ],
  );

  blocTest<AssignmentCubit, AssignmentState>(
    'undo restores pending status for a completed assignment',
    build: () {
      when(() => repository.undoCompletion('a-1')).thenAnswer(
        (_) async => Success(_snapshot(AssignmentStatusEnum.pending)),
      );
      return buildCubit(status: AssignmentStatusEnum.completed);
    },
    act: (bloc) => bloc.undo(),
    expect: () => [
      isA<AssignmentState>().having(
        (s) => s.status,
        'status',
        AssignmentActionStatus.loading,
      ),
      isA<AssignmentState>()
          .having((s) => s.status, 'status', AssignmentActionStatus.success)
          .having(
            (s) => s.assignment.status,
            'assignment',
            AssignmentStatusEnum.pending,
          ),
    ],
  );

  blocTest<AssignmentCubit, AssignmentState>(
    'failed sync can be retried and refreshes the assignment',
    build: () {
      when(() => repository.syncPending()).thenAnswer(
        (_) async => const SyncReport(succeeded: 0, failed: 1, remaining: 1),
      );
      when(() => repository.getDashboard('g1')).thenAnswer(
        (_) async => Success(_snapshot(AssignmentStatusEnum.completed)),
      );
      return buildCubit();
    },
    act: (bloc) async {
      await bloc.retrySync();
      when(() => repository.syncPending()).thenAnswer(
        (_) async => const SyncReport(succeeded: 1, failed: 0, remaining: 0),
      );
      await bloc.retrySync();
    },
    expect: () => [
      isA<AssignmentState>().having(
        (s) => s.status,
        'status',
        AssignmentActionStatus.loading,
      ),
      isA<AssignmentState>().having(
        (s) => s.status,
        'status',
        AssignmentActionStatus.failure,
      ),
      isA<AssignmentState>().having(
        (s) => s.status,
        'status',
        AssignmentActionStatus.loading,
      ),
      isA<AssignmentState>()
          .having((s) => s.status, 'status', AssignmentActionStatus.success)
          .having(
            (s) => s.assignment.status,
            'assignment',
            AssignmentStatusEnum.completed,
          ),
    ],
  );

  blocTest<AssignmentCubit, AssignmentState>(
    'duplicate completion taps are ignored while a request is pending',
    build: () {
      pendingCompletion = Completer<Result<DashboardSnapshot>>();
      when(() => repository.markComplete('a-1', any()))
          .thenAnswer((_) => pendingCompletion.future);
      return buildCubit();
    },
    act: (bloc) async {
      final first = bloc.complete(DateTime.parse('2026-11-15T12:00:00Z'));
      await bloc.complete(DateTime.parse('2026-11-15T12:00:00Z'));
      pendingCompletion.complete(
        Success(_snapshot(AssignmentStatusEnum.completed)),
      );
      await first;
    },
    expect: () => [
      isA<AssignmentState>().having(
        (s) => s.status,
        'status',
        AssignmentActionStatus.loading,
      ),
      isA<AssignmentState>().having(
        (s) => s.status,
        'status',
        AssignmentActionStatus.success,
      ),
    ],
    verify: (_) =>
        verify(() => repository.markComplete('a-1', any())).called(1),
  );
}
