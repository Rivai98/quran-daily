import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/features/quran_groups/cubit/dashboard/dashboard_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/khatma_repository.dart';

class _Khatma extends Mock implements KhatmaRepository {}

class _Groups extends Mock implements GroupsRepository {}

DashboardSnapshot _forming() => DashboardSnapshot(
  groupId: 'g1',
  groupName: 'group',
  myRole: GroupRole.owner,
  status: GroupStatus.forming,
  serverGeneratedAt: DateTime.parse('2026-11-15T10:00:00Z'),
  activeMemberCount: 1,
  seats: const SeatMap(groupId: 'g1', activeMemberCount: 1, members: []),
);

DashboardSnapshot _active() => DashboardSnapshot(
  groupId: 'g1',
  groupName: 'group',
  myRole: GroupRole.owner,
  status: GroupStatus.active,
  serverGeneratedAt: DateTime.parse('2026-11-15T10:00:00Z'),
);

void main() {
  late _Khatma khatma;
  late _Groups groups;

  setUp(() {
    khatma = _Khatma();
    groups = _Groups();
  });

  DashboardCubit build() => DashboardCubit(
    repository: khatma,
    groupsRepository: groups,
    groupId: 'g1',
    initialState: DashboardState(
      status: DashboardStatus.empty,
      snapshot: _forming(),
    ),
  );

  blocTest<DashboardCubit, DashboardState>(
    'startKhatma reloads the dashboard through the caching repository',
    setUp: () {
      when(
        () => groups.startKhatma('g1', 7),
      ).thenAnswer((_) async => Success(_active()));
      when(
        () => khatma.getDashboard('g1'),
      ).thenAnswer((_) async => Success(_active()));
    },
    build: build,
    act: (cubit) => cubit.startKhatma(7),
    verify: (cubit) {
      // KhatmaRepository.getDashboard caches the snapshot, so completion can
      // find today's assignments afterwards (T111 regression).
      verify(() => khatma.getDashboard('g1')).called(1);
      expect(cubit.state.startingKhatma, false);
      expect(cubit.state.status, DashboardStatus.success);
      expect(cubit.state.snapshot?.status, GroupStatus.active);
    },
  );

  blocTest<DashboardCubit, DashboardState>(
    'startKhatma failure keeps the forming snapshot and reports the failure',
    setUp: () => when(() => groups.startKhatma('g1', 1)).thenAnswer(
      (_) async => const FailureResult(
        NetworkFailure(message: 'offline', code: 'network'),
      ),
    ),
    build: build,
    act: (cubit) => cubit.startKhatma(1),
    expect: () => [
      isA<DashboardState>().having((s) => s.startingKhatma, 'starting', true),
      isA<DashboardState>()
          .having((s) => s.startingKhatma, 'starting', false)
          .having((s) => s.failure?.code, 'failure', 'network')
          .having((s) => s.snapshot?.status, 'group', GroupStatus.forming),
    ],
  );

  blocTest<DashboardCubit, DashboardState>(
    'duplicate startKhatma while starting is ignored',
    setUp: () {
      when(
        () => groups.startKhatma('g1', 1),
      ).thenAnswer((_) async => Success(_active()));
      when(
        () => khatma.getDashboard('g1'),
      ).thenAnswer((_) async => Success(_active()));
    },
    build: build,
    act: (cubit) async {
      final first = cubit.startKhatma(1);
      await cubit.startKhatma(1);
      await first;
    },
    verify: (_) => verify(() => groups.startKhatma('g1', 1)).called(1),
  );
}
