import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/features/quran_groups/cubit/history/history_cubit.dart';
import 'package:quran_daily/features/quran_groups/cubit/history/history_state.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/khatma_repository.dart';

import '../../../helpers/test_fixtures.dart';

class _MockKhatmaRepo extends Mock implements KhatmaRepository {}

void main() {
  late _MockKhatmaRepo repo;
  const groupId = TestFixtures.groupId;

  setUp(() {
    repo = _MockKhatmaRepo();
  });

  HistoryCubit build() => HistoryCubit(groupId: groupId, repository: repo);

  group('HistoryCubit - loadHistory', () {
    blocTest<HistoryCubit, HistoryState>(
      'loading history with data ends in success',
      build: build,
      setUp: () => when(
        () => repo.getHistory(groupId, limit: any(named: 'limit')),
      ).thenAnswer((_) async => Success(TestFixtures.historyPage(days: 3))),
      act: (cubit) => cubit.loadHistory(),
      expect: () => [
        const HistoryState(groupId: groupId, status: HistoryStatus.loading),
        isA<HistoryState>()
            .having((s) => s.status, 'status', HistoryStatus.success)
            .having((s) => s.days.length, 'days', 3)
            .having((s) => s.hasMore, 'hasMore', false),
      ],
    );

    blocTest<HistoryCubit, HistoryState>(
      'loading empty history ends in empty',
      build: build,
      setUp: () =>
          when(() => repo.getHistory(groupId, limit: any(named: 'limit')))
              .thenAnswer((_) async => const Success([])),
      act: (cubit) => cubit.loadHistory(),
      expect: () => [
        const HistoryState(groupId: groupId, status: HistoryStatus.loading),
        isA<HistoryState>()
            .having((s) => s.status, 'status', HistoryStatus.empty)
            .having((s) => s.days.isEmpty, 'days empty', true),
      ],
    );

    blocTest<HistoryCubit, HistoryState>(
      'network failure with offline data sets offline status',
      build: build,
      setUp: () =>
          when(() => repo.getHistory(groupId, limit: any(named: 'limit')))
              .thenAnswer(
                (_) async => const FailureResult(
                  NetworkFailure(message: 'offline', code: 'network'),
                ),
              ),
      act: (cubit) => cubit.loadHistory(),
      expect: () => [
        const HistoryState(groupId: groupId, status: HistoryStatus.loading),
        isA<HistoryState>().having(
          (s) => s.status,
          'status',
          HistoryStatus.offline,
        ),
      ],
    );

    blocTest<HistoryCubit, HistoryState>(
      'general failure sets failure status',
      build: build,
      setUp: () =>
          when(() => repo.getHistory(groupId, limit: any(named: 'limit')))
              .thenAnswer(
                (_) async => const FailureResult(
                  UnknownFailure(message: 'error', code: 'unknown'),
                ),
              ),
      act: (cubit) => cubit.loadHistory(),
      expect: () => [
        const HistoryState(groupId: groupId, status: HistoryStatus.loading),
        isA<HistoryState>()
            .having((s) => s.status, 'status', HistoryStatus.failure)
            .having((s) => s.failure, 'failure', isNotNull),
      ],
    );
  });

  group('HistoryCubit - loadMore', () {
    final page1 = TestFixtures.historyPage(days: 30);
    final page2 = TestFixtures.historyPage(days: 5);

    blocTest<HistoryCubit, HistoryState>(
      'loads next page and appends to days list',
      build: build,
      seed: () => HistoryState(
        groupId: groupId,
        status: HistoryStatus.success,
        days: page1,
        hasMore: true,
      ),
      setUp: () => when(
        () => repo.getHistory(
          groupId,
          beforeDate: page1.last.groupDate,
          limit: 30,
        ),
      ).thenAnswer((_) async => Success(page2)),
      act: (cubit) => cubit.loadMore(),
      expect: () => [
        isA<HistoryState>().having(
          (s) => s.isLoadingMore,
          'isLoadingMore',
          true,
        ),
        isA<HistoryState>()
            .having((s) => s.isLoadingMore, 'isLoadingMore', false)
            .having((s) => s.days.length, 'days', 35)
            .having((s) => s.hasMore, 'hasMore', false),
      ],
    );
  });

  group('HistoryCubit - loadDayDetail', () {
    const detailDay = HistoryDaySummary(
      groupDate: '2026-11-10',
      completedCount: 28,
      lateCount: 2,
      missedCount: 0,
      unreadCount: 0,
      fullKhatma: true,
      myResult: Assignment(
        assignmentId: 'a-1',
        juz: 3,
        seatNumber: 3,
        kind: AssignmentKind.seat,
        status: AssignmentStatusEnum.completed,
      ),
    );

    blocTest<HistoryCubit, HistoryState>(
      'loads detail for a specific day',
      build: build,
      setUp: () =>
          when(() => repo.getHistoryDay(groupId, '2026-11-10'))
              .thenAnswer((_) async => const Success(detailDay)),
      act: (cubit) => cubit.loadDayDetail('2026-11-10'),
      expect: () => [
        isA<HistoryState>()
            .having((s) => s.isLoadingDetail, 'isLoadingDetail', true)
            .having((s) => s.selectedDayDate, 'selectedDayDate', '2026-11-10'),
        isA<HistoryState>()
            .having((s) => s.isLoadingDetail, 'isLoadingDetail', false)
            .having((s) => s.selectedDay, 'selectedDay', detailDay),
      ],
    );

    blocTest<HistoryCubit, HistoryState>(
      'clearSelectedDay resets selection',
      build: build,
      seed: () => const HistoryState(
        groupId: groupId,
        selectedDay: detailDay,
        selectedDayDate: '2026-11-10',
      ),
      act: (cubit) => cubit.clearSelectedDay(),
      expect: () => [
        const HistoryState(
          groupId: groupId,
          selectedDay: null,
          selectedDayDate: null,
        ),
      ],
    );
  });
}
