import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/features/quran_groups/cubit/dashboard/dashboard_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/khatma_repository.dart';

class _Repository extends Mock implements KhatmaRepository {}

DashboardSnapshot snapshot({int available = 1, String date = '2026-11-15'}) =>
    DashboardSnapshot(
      groupId: 'g1',
      groupName: 'g',
      myRole: GroupRole.member,
      status: GroupStatus.active,
      serverGeneratedAt: DateTime.parse('${date}T10:00:00Z'),
      today: GroupDayInfo(
        groupDate: date,
        state: DayState.open,
        completedCount: 0,
        lateCount: 0,
        missedCount: 0,
        unreadCount: 0,
        pendingCount: 1,
        availableCount: available,
        fullKhatma: false,
        endsAt: DateTime.parse('${date}T23:59:00Z'),
      ),
    );

void main() {
  late _Repository repository;
  setUp(() => repository = _Repository());

  blocTest<DashboardCubit, DashboardState>(
    'volunteer success updates the dashboard snapshot',
    build: () {
      when(() => repository.volunteer('a1'))
          .thenAnswer((_) async => Success(snapshot(available: 0)));
      return DashboardCubit(
        repository: repository,
        groupId: 'g1',
        initialState: DashboardState(
          status: DashboardStatus.success,
          snapshot: snapshot(),
        ),
      );
    },
    act: (cubit) => cubit.volunteer('a1'),
    expect: () => [
      isA<DashboardState>().having(
        (s) => s.volunteeringAssignmentId,
        'in progress',
        'a1',
      ),
      isA<DashboardState>().having(
        (s) => s.snapshot!.today!.availableCount,
        'available count',
        0,
      ),
    ],
  );

  blocTest<DashboardCubit, DashboardState>(
    'taken conflict refreshes the dashboard and preserves the conflict failure',
    build: () {
      when(() => repository.volunteer('a1')).thenAnswer(
        (_) async => const FailureResult(
          SyncConflictFailure(message: 'taken', code: 'juz_already_taken'),
        ),
      );
      when(() => repository.getDashboard('g1'))
          .thenAnswer((_) async => Success(snapshot(available: 0)));
      return DashboardCubit(
        repository: repository,
        groupId: 'g1',
        initialState: DashboardState(
          status: DashboardStatus.success,
          snapshot: snapshot(),
        ),
      );
    },
    act: (cubit) => cubit.volunteer('a1'),
    expect: () => [
      isA<DashboardState>().having(
        (s) => s.volunteeringAssignmentId,
        'in progress',
        'a1',
      ),
      isA<DashboardState>()
          .having(
            (s) => s.snapshot!.today!.availableCount,
            'refreshed count',
            0,
          )
          .having((s) => s.failure?.code, 'conflict', 'juz_already_taken'),
    ],
    verify: (_) => verify(() => repository.getDashboard('g1')).called(1),
  );

  blocTest<DashboardCubit, DashboardState>(
    'network failure is surfaced without an optimistic volunteer',
    build: () {
      when(() => repository.volunteer('a1')).thenAnswer(
        (_) async => const FailureResult(
          NetworkFailure(message: 'offline', code: 'network'),
        ),
      );
      return DashboardCubit(
        repository: repository,
        groupId: 'g1',
        initialState: DashboardState(
          status: DashboardStatus.success,
          snapshot: snapshot(),
        ),
      );
    },
    act: (cubit) => cubit.volunteer('a1'),
    expect: () => [
      isA<DashboardState>().having(
        (s) => s.volunteeringAssignmentId,
        'in progress',
        'a1',
      ),
      isA<DashboardState>()
          .having((s) => s.status, 'failure', DashboardStatus.failure)
          .having((s) => s.failure?.kind, 'network kind', FailureKind.network),
    ],
  );
}
