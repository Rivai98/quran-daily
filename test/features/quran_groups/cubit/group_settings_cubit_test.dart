import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/features/quran_groups/cubit/group_settings/group_settings_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';

import '../../../helpers/test_fixtures.dart';

class _MockRepo extends Mock implements GroupsRepository {}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    registerFallbackValue(const GroupSettingsPatch());
  });

  GroupSettingsCubit build() => GroupSettingsCubit(repository: repo);

  group('startKhatma (T059: start juz + owner-only)', () {
    blocTest<GroupSettingsCubit, GroupSettingsState>(
      'owner starts the khatma and the dashboard snapshot arrives',
      build: build,
      seed: () => const GroupSettingsState(groupId: 'g1'),
      setUp: () {
        when(() => repo.startKhatma('g1', 1))
            .thenAnswer((_) async => Success(TestFixtures.activeDashboard()));
      },
      act: (cubit) => cubit.startKhatma(startJuz: 1),
      expect: () => [
        isA<GroupSettingsState>().having(
          (s) => s.status,
          'status',
          GroupSettingsStatus.submitting,
        ),
        isA<GroupSettingsState>()
            .having((s) => s.status, 'status', GroupSettingsStatus.started)
            .having((s) => s.startedSnapshot, 'snapshot', isNotNull),
      ],
    );

    blocTest<GroupSettingsCubit, GroupSettingsState>(
      'invalid start juz fails client-side without a call',
      build: build,
      seed: () => const GroupSettingsState(groupId: 'g1'),
      act: (cubit) => cubit.startKhatma(startJuz: 31),
      expect: () => [
        isA<GroupSettingsState>()
            .having((s) => s.status, 'status', GroupSettingsStatus.failure)
            .having((s) => s.failure!.code, 'code', 'validation_failed'),
      ],
      verify: (_) => verifyNever(() => repo.startKhatma(any(), any())),
    );

    blocTest<GroupSettingsCubit, GroupSettingsState>(
      'forbidden (non-owner) maps to failure with forbidden kind',
      build: build,
      seed: () => const GroupSettingsState(groupId: 'g1'),
      setUp: () => when(() => repo.startKhatma('g1', 1)).thenAnswer(
        (_) async => const FailureResult(
          PermissionFailure(message: 'forbidden', code: 'forbidden'),
        ),
      ),
      act: (cubit) => cubit.startKhatma(startJuz: 1),
      expect: () => [
        isA<GroupSettingsState>().having(
          (s) => s.status,
          'status',
          GroupSettingsStatus.submitting,
        ),
        isA<GroupSettingsState>()
            .having((s) => s.status, 'status', GroupSettingsStatus.failure)
            .having((s) => s.failure!.kind, 'kind', FailureKind.forbidden),
      ],
    );
  });

  group('regenerateInvite (T059)', () {
    blocTest<GroupSettingsCubit, GroupSettingsState>(
      'owner regenerates the invite code',
      build: build,
      seed: () =>
          const GroupSettingsState(groupId: 'g1', inviteCode: 'OLDCODE1'),
      setUp: () =>
          when(() => repo.regenerateInvite('g1'))
              .thenAnswer((_) async => const Success('NEWCODE2')),
      act: (cubit) => cubit.regenerateInvite(),
      expect: () => [
        isA<GroupSettingsState>().having(
          (s) => s.status,
          'status',
          GroupSettingsStatus.submitting,
        ),
        isA<GroupSettingsState>()
            .having((s) => s.status, 'status', GroupSettingsStatus.success)
            .having((s) => s.inviteCode, 'inviteCode', 'NEWCODE2'),
      ],
    );
  });

  group('saveSettings (owner-only settings form)', () {
    blocTest<GroupSettingsCubit, GroupSettingsState>(
      'valid patch saves and ends success',
      build: build,
      seed: () => const GroupSettingsState(groupId: 'g1'),
      setUp: () =>
          when(() => repo.updateGroupSettings('g1', any()))
              .thenAnswer((_) async => Success(TestFixtures.myGroup())),
      act: (cubit) => cubit.saveSettings(name: 'اسم جديد'),
      expect: () => [
        isA<GroupSettingsState>().having(
          (s) => s.status,
          'status',
          GroupSettingsStatus.submitting,
        ),
        isA<GroupSettingsState>().having(
          (s) => s.status,
          'status',
          GroupSettingsStatus.success,
        ),
      ],
    );

    blocTest<GroupSettingsCubit, GroupSettingsState>(
      'empty patch fails validation without a call',
      build: build,
      seed: () => const GroupSettingsState(groupId: 'g1'),
      act: (cubit) => cubit.saveSettings(),
      expect: () => [
        isA<GroupSettingsState>()
            .having((s) => s.status, 'status', GroupSettingsStatus.failure)
            .having((s) => s.failure!.code, 'code', 'validation_failed'),
      ],
      verify: (_) => verifyNever(() => repo.updateGroupSettings(any(), any())),
    );
  });

  group('archiveGroup (owner-only, destructive)', () {
    blocTest<GroupSettingsCubit, GroupSettingsState>(
      'archive succeeds and ends archived',
      build: build,
      seed: () => const GroupSettingsState(groupId: 'g1'),
      setUp: () =>
          when(() => repo.archiveGroup('g1'))
              .thenAnswer((_) async => const Success<void>(null)),
      act: (cubit) => cubit.archiveGroup(),
      expect: () => [
        isA<GroupSettingsState>().having(
          (s) => s.status,
          'status',
          GroupSettingsStatus.submitting,
        ),
        isA<GroupSettingsState>().having(
          (s) => s.status,
          'status',
          GroupSettingsStatus.archived,
        ),
      ],
    );
  });

  group('load (prefills the current details)', () {
    blocTest<GroupSettingsCubit, GroupSettingsState>(
      'fetches the group description for the form',
      build: build,
      setUp: () => when(() => repo.getGroupInfo('g1')).thenAnswer(
        (_) async => Success(
          GroupInfo(
            groupId: 'g1',
            name: 'حلقة الفجر',
            description: 'ورد يومي بعد الفجر',
            status: GroupStatus.active,
            visibility: GroupVisibility.public,
            joinMode: JoinMode.autoAccept,
            timezone: 'Africa/Cairo',
            createdAt: DateTime(2026),
            myRole: GroupRole.owner,
            memberCount: 1,
          ),
        ),
      ),
      act: (cubit) => cubit.load(groupId: 'g1'),
      expect: () => [
        isA<GroupSettingsState>().having((s) => s.groupId, 'groupId', 'g1'),
        isA<GroupSettingsState>().having(
          (s) => s.description,
          'description',
          'ورد يومي بعد الفجر',
        ),
      ],
    );

    blocTest<GroupSettingsCubit, GroupSettingsState>(
      'a failed details fetch keeps the form usable',
      build: build,
      setUp: () => when(() => repo.getGroupInfo('g1')).thenAnswer(
        (_) async => const FailureResult(
          NetworkFailure(message: 'offline', code: 'network'),
        ),
      ),
      act: (cubit) => cubit.load(groupId: 'g1'),
      expect: () => [
        isA<GroupSettingsState>()
            .having((s) => s.groupId, 'groupId', 'g1')
            .having((s) => s.description, 'description', isNull),
      ],
    );
  });
}
