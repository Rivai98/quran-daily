import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/features/quran_groups/cubit/create_group/create_group_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';
import 'package:quran_daily/core/quran/portion_unit.dart';

class _MockRepo extends Mock implements GroupsRepository {}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    registerFallbackValue(
      const CreateGroupInput(
        name: 'x',
        timezone: 'Africa/Cairo',
        visibility: GroupVisibility.private,
        joinMode: JoinMode.approval,
      ),
    );
  });

  CreateGroupCubit build() => CreateGroupCubit(repository: repo);

  group('client-side validation (T058: 3-60 / ≤200)', () {
    blocTest<CreateGroupCubit, CreateGroupState>(
      'name below 3 chars fails without touching the repository',
      build: build,
      act: (cubit) => cubit.submit(
        name: 'ab',
        timezone: 'Africa/Cairo',
        visibility: GroupVisibility.public,
        joinMode: JoinMode.approval,
      ),
      expect: () => [
        isA<CreateGroupState>()
            .having((s) => s.status, 'status', CreateGroupStatus.failure)
            .having((s) => s.failure!.code, 'code', 'validation_failed'),
      ],
      verify: (_) => verifyNever(() => repo.createGroup(any())),
    );

    blocTest<CreateGroupCubit, CreateGroupState>(
      'name above 60 chars fails without touching the repository',
      build: build,
      act: (cubit) => cubit.submit(
        name: 'ط' * 61,
        timezone: 'Africa/Cairo',
        visibility: GroupVisibility.public,
        joinMode: JoinMode.approval,
      ),
      expect: () => [
        isA<CreateGroupState>()
            .having((s) => s.status, 'status', CreateGroupStatus.failure)
            .having((s) => s.failure!.code, 'code', 'validation_failed'),
      ],
      verify: (_) => verifyNever(() => repo.createGroup(any())),
    );

    blocTest<CreateGroupCubit, CreateGroupState>(
      'description above 200 chars fails without touching the repository',
      build: build,
      act: (cubit) => cubit.submit(
        name: 'حلقة صالحة',
        shortDescription: 'و' * 201,
        timezone: 'Africa/Cairo',
        visibility: GroupVisibility.public,
        joinMode: JoinMode.approval,
      ),
      expect: () => [
        isA<CreateGroupState>()
            .having((s) => s.status, 'status', CreateGroupStatus.failure)
            .having((s) => s.failure!.code, 'code', 'validation_failed'),
      ],
      verify: (_) => verifyNever(() => repo.createGroup(any())),
    );
  });

  group('submit guard (T058)', () {
    blocTest<CreateGroupCubit, CreateGroupState>(
      'duplicate submits while submitting are ignored',
      build: build,
      seed: () => const CreateGroupState(status: CreateGroupStatus.submitting),
      act: (cubit) => cubit.submit(
        name: 'حلقة صالحة',
        timezone: 'Africa/Cairo',
        visibility: GroupVisibility.public,
        joinMode: JoinMode.approval,
      ),
      expect: () => <CreateGroupState>[],
      verify: (_) => verifyNever(() => repo.createGroup(any())),
    );
  });

  group('limit error (T058)', () {
    blocTest<CreateGroupCubit, CreateGroupState>(
      'owner_group_limit surfaces as limitReached',
      build: build,
      setUp: () => when(() => repo.createGroup(any())).thenAnswer(
        (_) async => const FailureResult(
          AuthFailure(message: 'owner_group_limit', code: 'owner_group_limit'),
        ),
      ),
      act: (cubit) => cubit.submit(
        name: 'حلقة صالحة',
        timezone: 'Africa/Cairo',
        visibility: GroupVisibility.public,
        joinMode: JoinMode.approval,
      ),
      skip: 1,
      expect: () => [
        isA<CreateGroupState>()
            .having((s) => s.status, 'status', CreateGroupStatus.failure)
            .having((s) => s.failure!.kind, 'kind', FailureKind.limitReached),
      ],
    );

    blocTest<CreateGroupCubit, CreateGroupState>(
      'membership_limit surfaces as limitReached',
      build: build,
      setUp: () => when(() => repo.createGroup(any())).thenAnswer(
        (_) async => const FailureResult(
          AuthFailure(message: 'membership_limit', code: 'membership_limit'),
        ),
      ),
      act: (cubit) => cubit.submit(
        name: 'Ø­Ù„Ù‚Ø© ØµØ§Ù„Ø­Ø©',
        timezone: 'Africa/Cairo',
        visibility: GroupVisibility.public,
        joinMode: JoinMode.approval,
      ),
      skip: 1,
      expect: () => [
        isA<CreateGroupState>()
            .having((s) => s.status, 'status', CreateGroupStatus.failure)
            .having((s) => s.failure!.kind, 'kind', FailureKind.limitReached),
      ],
    );
  });

  group('success navigates (T058)', () {
    blocTest<CreateGroupCubit, CreateGroupState>(
      'selected portion unit is submitted and retained in state',
      build: build,
      setUp: () => when(() => repo.createGroup(any())).thenAnswer(
        (_) async =>
            const Success(CreatedGroup(groupId: 'g9', inviteCode: 'AB23CD45')),
      ),
      act: (cubit) async {
        cubit.selectPortionUnit(PortionUnit.hizb);
        await cubit.submit(
          name: 'حلقة صالحة',
          timezone: 'Africa/Cairo',
          visibility: GroupVisibility.public,
          joinMode: JoinMode.approval,
        );
      },
      expect: () => [
        isA<CreateGroupState>().having(
          (s) => s.portionUnit,
          'unit',
          PortionUnit.hizb,
        ),
        isA<CreateGroupState>().having(
          (s) => s.status,
          'status',
          CreateGroupStatus.submitting,
        ),
        isA<CreateGroupState>()
            .having((s) => s.status, 'status', CreateGroupStatus.success)
            .having((s) => s.portionUnit, 'unit', PortionUnit.hizb),
      ],
      verify: (_) => verify(
        () => repo.createGroup(
          any(
            that: isA<CreateGroupInput>().having(
              (i) => i.portionUnit,
              'unit',
              PortionUnit.hizb,
            ),
          ),
        ),
      ).called(1),
    );

    blocTest<CreateGroupCubit, CreateGroupState>(
      'successful creation ends success with the created group',
      build: build,
      setUp: () => when(() => repo.createGroup(any())).thenAnswer(
        (_) async =>
            const Success(CreatedGroup(groupId: 'g9', inviteCode: 'AB23CD45')),
      ),
      act: (cubit) => cubit.submit(
        name: 'حلقة صالحة',
        timezone: 'Africa/Cairo',
        visibility: GroupVisibility.public,
        joinMode: JoinMode.approval,
      ),
      expect: () => [
        const CreateGroupState(status: CreateGroupStatus.submitting),
        isA<CreateGroupState>()
            .having((s) => s.status, 'status', CreateGroupStatus.success)
            .having((s) => s.created!.groupId, 'groupId', 'g9'),
      ],
    );
  });
}
