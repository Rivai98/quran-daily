import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/features/log/cubit/log_cubit.dart';
import 'package:quran_daily/features/log/cubit/log_state.dart';
import 'package:quran_daily/features/log/data/entities/log_entities.dart';
import 'package:quran_daily/features/log/data/repositories/log_repository.dart';

class _Repository extends Mock implements LogRepository {}

PersonalLog _log({String? next = '2026-10-31', List<LogDay> days = const []}) =>
    PersonalLog(
      streak: 3,
      bestStreak: 8,
      month: const LogMonthSummary(
        year: 2026,
        month: 11,
        fullDays: 4,
        daysWithItems: 6,
      ),
      days: days,
      nextBefore: next,
    );

void main() {
  late _Repository repository;
  setUp(() => repository = _Repository());

  blocTest<LogCubit, LogState>(
    'loads log and exposes empty state',
    build: () {
      when(() => repository.getLog()).thenAnswer((_) async => Success(_log()));
      return LogCubit(repository: repository);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<LogState>().having((s) => s.status, 'status', LogStatus.loading),
      isA<LogState>().having((s) => s.status, 'status', LogStatus.empty),
    ],
  );

  blocTest<LogCubit, LogState>(
    'uses cached data as offline state',
    build: () {
      when(() => repository.getLog())
          .thenAnswer((_) async => Success(_log().copyWith(isStale: true)));
      return LogCubit(repository: repository);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<LogState>().having((s) => s.status, 'status', LogStatus.loading),
      isA<LogState>().having((s) => s.status, 'status', LogStatus.offline),
    ],
  );

  blocTest<LogCubit, LogState>(
    'refresh reloads the first page',
    build: () {
      when(() => repository.getLog()).thenAnswer((_) async => Success(_log()));
      return LogCubit(repository: repository);
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.refresh();
    },
    verify: (_) => verify(() => repository.getLog()).called(2),
    expect: () => [
      isA<LogState>().having((s) => s.status, 'status', LogStatus.loading),
      isA<LogState>().having((s) => s.status, 'status', LogStatus.empty),
      isA<LogState>().having((s) => s.status, 'status', LogStatus.loading),
      isA<LogState>().having((s) => s.status, 'status', LogStatus.empty),
    ],
  );

  blocTest<LogCubit, LogState>(
    'loads more days using cursor and appends results',
    build: () {
      final first = _log(
        next: '2026-10-31',
        days: [
          LogDay(date: DateTime(2026, 11, 1), complete: true, items: const []),
        ],
      );
      final more = _log(
        next: null,
        days: [
          LogDay(
            date: DateTime(2026, 10, 30),
            complete: false,
            items: const [],
          ),
        ],
      );
      when(() => repository.getLog()).thenAnswer((_) async => Success(first));
      when(() => repository.getLog(before: '2026-10-31'))
          .thenAnswer((_) async => Success(more));
      return LogCubit(repository: repository);
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.loadMore();
    },
    verify: (_) =>
        verify(() => repository.getLog(before: '2026-10-31')).called(1),
    expect: () => [
      isA<LogState>().having((s) => s.status, 'status', LogStatus.loading),
      isA<LogState>().having((s) => s.status, 'status', LogStatus.success),
      isA<LogState>().having((s) => s.isLoadingMore, 'loading more', true),
      isA<LogState>()
          .having((s) => s.log!.days.length, 'days', 2)
          .having((s) => s.hasMore, 'more', false),
    ],
  );

  blocTest<LogCubit, LogState>(
    'reports errors',
    build: () {
      when(() => repository.getLog()).thenAnswer(
        (_) async => const FailureResult(
          NetworkFailure(message: 'offline', code: 'network'),
        ),
      );
      return LogCubit(repository: repository);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<LogState>().having((s) => s.status, 'status', LogStatus.loading),
      isA<LogState>().having((s) => s.status, 'status', LogStatus.failure),
    ],
  );
}
