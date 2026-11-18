import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/features/quran_groups/cubit/group_list/group_list_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';

import '../../../helpers/test_fixtures.dart';

class _MockRepo extends Mock implements GroupsRepository {}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  GroupListCubit build() => GroupListCubit(repository: repo);

  blocTest<GroupListCubit, GroupListState>(
    'loading my groups with data ends success',
    build: build,
    setUp: () => when(() => repo.getMyGroups()).thenAnswer(
      (_) async =>
          Success(TestFixtures.overview(groups: [TestFixtures.myGroup()])),
    ),
    act: (cubit) => cubit.refresh(),
    expect: () => [
      const GroupListState(status: GroupListStatus.loading),
      isA<GroupListState>()
          .having((s) => s.status, 'status', GroupListStatus.success)
          .having((s) => s.overview!.groups.length, 'groups', 1),
    ],
  );

  blocTest<GroupListCubit, GroupListState>(
    'no groups ends empty with entry points',
    build: build,
    setUp: () =>
        when(() => repo.getMyGroups())
            .thenAnswer((_) async => Success(TestFixtures.overview())),
    act: (cubit) => cubit.refresh(),
    expect: () => [
      const GroupListState(status: GroupListStatus.loading),
      isA<GroupListState>().having(
        (s) => s.status,
        'status',
        GroupListStatus.empty,
      ),
    ],
  );

  blocTest<GroupListCubit, GroupListState>(
    'stale cache maps to offline status with data',
    build: build,
    setUp: () => when(() => repo.getMyGroups()).thenAnswer(
      (_) async => Success(
        TestFixtures.overview(groups: [TestFixtures.myGroup()], stale: true),
      ),
    ),
    act: (cubit) => cubit.refresh(),
    expect: () => [
      const GroupListState(status: GroupListStatus.loading),
      isA<GroupListState>()
          .having((s) => s.status, 'status', GroupListStatus.offline)
          .having((s) => s.overview!.isStale, 'stale', isTrue),
    ],
  );

  blocTest<GroupListCubit, GroupListState>(
    'failure maps to failure status with the failure',
    build: build,
    setUp: () => when(() => repo.getMyGroups()).thenAnswer(
      (_) async =>
          const FailureResult(NetworkFailure(message: 'n', code: 'network')),
    ),
    act: (cubit) => cubit.refresh(),
    expect: () => [
      const GroupListState(status: GroupListStatus.loading),
      isA<GroupListState>()
          .having((s) => s.status, 'status', GroupListStatus.failure)
          .having((s) => s.failure, 'failure', isNotNull),
    ],
  );

  blocTest<GroupListCubit, GroupListState>(
    'cancelJoinRequest removes the pending row on success',
    build: build,
    seed: () => GroupListState(
      status: GroupListStatus.success,
      overview: TestFixtures.overview(
        pending: [
          PendingJoinRequest(
            joinRequestId: 'jr1',
            groupId: 'g9',
            groupName: 'مجموعة',
            requestedAt: DateTime.parse('2026-11-14T10:00:00Z'),
            source: JoinSource.invite,
          ),
        ],
      ),
    ),
    setUp: () =>
        when(() => repo.cancelJoinRequest('jr1'))
            .thenAnswer((_) async => const Success<void>(null)),
    act: (cubit) => cubit.cancelJoinRequest('jr1'),
    expect: () => [
      isA<GroupListState>().having(
        (s) => s.overview!.pendingRequests,
        'pending',
        isEmpty,
      ),
    ],
    verify: (_) => verify(() => repo.cancelJoinRequest('jr1')).called(1),
  );

  blocTest<GroupListCubit, GroupListState>(
    'cancelJoinRequest failure keeps the group list and exposes the failure',
    build: build,
    seed: () => GroupListState(
      status: GroupListStatus.success,
      overview: TestFixtures.overview(
        groups: [TestFixtures.myGroup()],
        pending: [
          PendingJoinRequest(
            joinRequestId: 'jr1',
            groupId: 'g9',
            groupName: 'مجموعة',
            requestedAt: DateTime.parse('2026-11-14T10:00:00Z'),
            source: JoinSource.invite,
          ),
        ],
      ),
    ),
    setUp: () => when(() => repo.cancelJoinRequest('jr1')).thenAnswer(
      (_) async => const FailureResult(
        NetworkFailure(message: 'offline', code: 'network'),
      ),
    ),
    act: (cubit) => cubit.cancelJoinRequest('jr1'),
    expect: () => [
      isA<GroupListState>()
          .having((s) => s.status, 'status', GroupListStatus.success)
          .having((s) => s.overview!.groups.length, 'groups', 1)
          .having((s) => s.overview!.pendingRequests.length, 'pending', 1)
          .having((s) => s.failure?.code, 'failure code', 'network'),
    ],
  );
}
