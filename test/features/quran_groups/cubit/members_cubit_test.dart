import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/features/quran_groups/cubit/members/members_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';

class _Groups extends Mock implements GroupsRepository {}

void main() {
  late _Groups repository;
  const members = SeatMap(groupId: 'g', members: [], activeMemberCount: 0);
  setUp(() {
    repository = _Groups();
    when(() => repository.getGroupInfo('g')).thenAnswer(
      (_) async =>
          const FailureResult(NetworkFailure(message: '', code: 'network')),
    );
  });

  test(
    'overlapping loads share independent reads and await enrichment (#7 #9)',
    () async {
      final seats = Completer<Result<SeatMap>>();
      final info = Completer<Result<GroupInfo>>();
      when(() => repository.getMembers('g')).thenAnswer((_) => seats.future);
      when(() => repository.getGroupInfo('g')).thenAnswer((_) => info.future);
      final cubit = MembersCubit(repository);
      final first = cubit.load('g');
      final second = cubit.load('g');
      verify(() => repository.getMembers('g')).called(1);
      verify(() => repository.getGroupInfo('g')).called(1);
      seats.complete(const Success(members));
      info.complete(
        const FailureResult(NetworkFailure(message: '', code: 'network')),
      );
      await Future.wait([first, second]);
      expect(cubit.state.status, MembersStatus.empty);
      await cubit.close();
    },
  );

  blocTest<MembersCubit, MembersState>(
    'loads to empty state',
    build: () {
      when(() => repository.getMembers('g'))
          .thenAnswer((_) async => const Success(members));
      return MembersCubit(repository);
    },
    act: (cubit) => cubit.load('g'),
    expect: () => [
      const MembersState(status: MembersStatus.loading),
      const MembersState(status: MembersStatus.empty, members: members),
    ],
  );

  blocTest<MembersCubit, MembersState>(
    'retains the loaded seat map when refresh fails',
    build: () {
      var calls = 0;
      when(() => repository.getMembers('g')).thenAnswer((_) async {
        calls++;
        if (calls == 1) return const Success(members);
        return const FailureResult(
          NetworkFailure(message: 'offline', code: 'network'),
        );
      });
      return MembersCubit(repository);
    },
    act: (cubit) async {
      await cubit.load('g');
      await cubit.load('g');
    },
    expect: () => [
      const MembersState(status: MembersStatus.loading),
      const MembersState(status: MembersStatus.empty, members: members),
      const MembersState(status: MembersStatus.loading, members: members),
      const MembersState(
        status: MembersStatus.offline,
        members: members,
        failure: NetworkFailure(message: 'offline', code: 'network'),
      ),
    ],
  );

  blocTest<MembersCubit, MembersState>(
    'refreshes after moving a seat',
    build: () {
      when(() => repository.getMembers('g'))
          .thenAnswer((_) async => const Success(members));
      when(() => repository.moveMemberSeat('g', 'm', 4))
          .thenAnswer((_) async => const Success(null));
      return MembersCubit(repository);
    },
    act: (cubit) async {
      await cubit.load('g');
      await cubit.moveSeat('m', 4);
    },
    verify: (_) =>
        verify(() => repository.moveMemberSeat('g', 'm', 4)).called(1),
  );

  blocTest<MembersCubit, MembersState>(
    'keeps a failure visible after a rejected mutation',
    build: () {
      when(() => repository.getMembers('g'))
          .thenAnswer((_) async => const Success(members));
      when(() => repository.leaveGroup('g')).thenAnswer(
        (_) async => const FailureResult(
          UnknownFailure(message: 'blocked', code: 'owner_must_transfer'),
        ),
      );
      return MembersCubit(repository);
    },
    act: (cubit) async {
      await cubit.load('g');
      await cubit.leave();
    },
    verify: (cubit) => expect(cubit.state.failure?.code, 'owner_must_transfer'),
  );
}
