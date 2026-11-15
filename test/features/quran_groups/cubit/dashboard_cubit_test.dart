import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/features/quran_groups/cubit/dashboard/dashboard_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/khatma_repository.dart';

class _Repository extends Mock implements KhatmaRepository {}

DashboardSnapshot _snapshot({String date = '2026-11-15', bool stale = false}) =>
    DashboardSnapshot(
      groupId: 'g1',
      groupName: 'group',
      myRole: GroupRole.member,
      status: GroupStatus.active,
      serverGeneratedAt: DateTime.parse('${date}T10:00:00Z'),
      today: GroupDayInfo(
        groupDate: date,
        state: DayState.open,
        completedCount: 1,
        lateCount: 0,
        missedCount: 0,
        unreadCount: 28,
        pendingCount: 1,
        availableCount: 0,
        fullKhatma: false,
        endsAt: DateTime.parse('${date}T23:59:00Z'),
      ),
      isStale: stale,
    );

void main() {
  late _Repository repository;
  setUp(() => repository = _Repository());

  blocTest<DashboardCubit, DashboardState>(
    'refresh emits loading then success',
    build: () {
      when(
        () => repository.getDashboard('g1'),
      ).thenAnswer((_) async => Success(_snapshot()));
      return DashboardCubit(repository: repository, groupId: 'g1');
    },
    act: (cubit) => cubit.refresh(),
    expect: () => [
      isA<DashboardState>().having(
        (s) => s.status,
        'status',
        DashboardStatus.loading,
      ),
      isA<DashboardState>().having(
        (s) => s.status,
        'status',
        DashboardStatus.success,
      ),
    ],
  );

  blocTest<DashboardCubit, DashboardState>(
    'forming snapshot emits empty state',
    build: () {
      when(() => repository.getDashboard('g1')).thenAnswer(
        (_) async => Success(
          DashboardSnapshot(
            groupId: 'g1',
            groupName: 'group',
            myRole: GroupRole.owner,
            status: GroupStatus.forming,
            serverGeneratedAt: DateTime.parse('2026-11-15T10:00:00Z'),
          ),
        ),
      );
      return DashboardCubit(repository: repository, groupId: 'g1');
    },
    act: (cubit) => cubit.refresh(),
    expect: () => [
      isA<DashboardState>().having(
        (s) => s.status,
        'status',
        DashboardStatus.loading,
      ),
      isA<DashboardState>().having(
        (s) => s.status,
        'status',
        DashboardStatus.empty,
      ),
    ],
  );

  blocTest<DashboardCubit, DashboardState>(
    'stale snapshot is explicitly offline',
    build: () {
      when(
        () => repository.getDashboard('g1'),
      ).thenAnswer((_) async => Success(_snapshot(stale: true)));
      return DashboardCubit(repository: repository, groupId: 'g1');
    },
    act: (cubit) => cubit.refresh(),
    expect: () => [
      isA<DashboardState>().having(
        (s) => s.status,
        'status',
        DashboardStatus.loading,
      ),
      isA<DashboardState>().having(
        (s) => s.status,
        'status',
        DashboardStatus.offline,
      ),
    ],
  );

  blocTest<DashboardCubit, DashboardState>(
    'failure is surfaced and resume refresh detects a new group day',
    build: () {
      when(
        () => repository.getDashboard('g1'),
      ).thenAnswer((_) async => Success(_snapshot(date: '2026-11-16')));
      return DashboardCubit(
        repository: repository,
        groupId: 'g1',
        initialState: DashboardState(
          status: DashboardStatus.success,
          snapshot: _snapshot(),
        ),
      );
    },
    act: (cubit) => cubit.onResumed(),
    expect: () => [
      isA<DashboardState>().having(
        (s) => s.status,
        'status',
        DashboardStatus.loading,
      ),
      isA<DashboardState>().having((s) => s.dayRolledOver, 'rollover', isTrue),
    ],
  );

  blocTest<DashboardCubit, DashboardState>(
    'network failure without cache emits failure',
    build: () {
      when(() => repository.getDashboard('g1')).thenAnswer(
        (_) async => const FailureResult<DashboardSnapshot>(
          NetworkFailure(message: 'offline', code: 'network'),
        ),
      );
      return DashboardCubit(repository: repository, groupId: 'g1');
    },
    act: (cubit) => cubit.refresh(),
    expect: () => [
      isA<DashboardState>().having(
        (s) => s.status,
        'status',
        DashboardStatus.loading,
      ),
      isA<DashboardState>().having(
        (s) => s.status,
        'status',
        DashboardStatus.failure,
      ),
    ],
  );
}
