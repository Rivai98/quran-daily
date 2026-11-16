import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/features/quran_groups/cubit/join/join_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/models/models.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';

class _Repository extends Mock implements GroupsRepository {}

const _profile = PublicGroupProfile(
  groupId: 'g1',
  name: 'حلقة الفجر',
  status: GroupStatus.forming,
  activeMemberCount: 2,
  timezone: 'Africa/Cairo',
  joinMode: JoinMode.approval,
);

void main() {
  late _Repository repository;
  setUp(() => repository = _Repository());

  blocTest<JoinCubit, JoinState>(
    'rejects invalid invite codes without network access',
    build: () => JoinCubit(repository: repository),
    act: (cubit) => cubit.previewInvite('invalid'),
    expect: () => [
      isA<JoinState>()
          .having((s) => s.status, 'failure', JoinStatus.failure)
          .having(
            (s) => s.failure?.code,
            'validation code',
            'validation_failed',
          ),
    ],
    verify: (_) => verifyNever(() => repository.getInvitePreview(any())),
  );

  blocTest<JoinCubit, JoinState>(
    'normalizes invite codes, previews, and records pending outcome',
    build: () {
      when(() => repository.getInvitePreview('AB234567'))
          .thenAnswer((_) async => const Success(_profile));
      when(
        () => repository.joinGroup(
          inviteCode: 'AB234567',
          source: JoinSource.invite,
        ),
      ).thenAnswer(
        (_) async =>
            const Success(JoinOutcome(joined: false, joinRequestId: 'r1')),
      );
      return JoinCubit(repository: repository);
    },
    act: (cubit) async {
      await cubit.previewInvite(' ab234567 ');
      await cubit.joinInvite();
    },
    expect: () => [
      isA<JoinState>().having(
        (s) => s.status,
        'preview loading',
        JoinStatus.loading,
      ),
      isA<JoinState>().having(
        (s) => s.status,
        'preview ready',
        JoinStatus.success,
      ),
      isA<JoinState>().having(
        (s) => s.status,
        'join loading',
        JoinStatus.loading,
      ),
      isA<JoinState>().having((s) => s.status, 'pending', JoinStatus.pending),
    ],
  );

  blocTest<JoinCubit, JoinState>(
    'join-any exposes the no-group failure for the next action',
    build: () {
      when(() => repository.joinAnyGroup('Africa/Cairo')).thenAnswer(
        (_) async => const FailureResult(
          AuthFailure(
            message: 'no_group_available',
            code: 'no_group_available',
          ),
        ),
      );
      return JoinCubit(repository: repository);
    },
    act: (cubit) => cubit.joinAny('Africa/Cairo'),
    expect: () => [
      isA<JoinState>().having((s) => s.status, 'loading', JoinStatus.loading),
      isA<JoinState>().having(
        (s) => s.failure?.code,
        'no groups',
        'no_group_available',
      ),
    ],
  );
}
