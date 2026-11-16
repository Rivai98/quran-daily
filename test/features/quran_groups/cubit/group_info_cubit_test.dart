import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/quran/portion_unit.dart';
import 'package:quran_daily/features/quran_groups/cubit/group_info/group_info_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';

class _MockGroupsRepository extends Mock implements GroupsRepository {}

void main() {
  late _MockGroupsRepository repository;
  late GroupInfoCubit cubit;

  final sampleGroupInfo = GroupInfo(
    groupId: 'g1',
    name: 'حفظة الفجر',
    description: 'مجموعة مباركة للتلاوة اليومية',
    photoPath: 'g1/photo.jpg',
    status: GroupStatus.active,
    visibility: GroupVisibility.public,
    joinMode: JoinMode.autoAccept,
    portionUnit: PortionUnit.juz,
    timezone: 'Africa/Cairo',
    createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
    myRole: GroupRole.owner,
    memberCount: 25,
    seatCapacity: 30,
    khatmaCount: 3,
    inviteCode: 'ABCDEFGH',
    members: [
      GroupInfoMember(
        userId: 'u1',
        membershipId: 'm1',
        displayName: 'مالك المجموعة',
        role: GroupRole.owner,
        seatNumber: 1,
        joinedAt: DateTime.parse('2026-01-01T00:00:00Z'),
      ),
    ],
  );

  setUp(() {
    repository = _MockGroupsRepository();
    cubit = GroupInfoCubit(repository);
  });

  tearDown(() {
    cubit.close();
  });

  group('GroupInfoCubit (T015)', () {
    test('initial state has initial status and null groupInfo', () {
      expect(cubit.state.status, GroupInfoStatus.initial);
      expect(cubit.state.groupInfo, isNull);
    });

    test(
      'load emits [loading, success] on successful repository call',
      () async {
        when(() => repository.getGroupInfo('g1'))
            .thenAnswer((_) async => Success(sampleGroupInfo));

        final expectedStates = [
          const GroupInfoState(status: GroupInfoStatus.loading),
          GroupInfoState(
            status: GroupInfoStatus.success,
            groupInfo: sampleGroupInfo,
          ),
        ];

        expectLater(cubit.stream, emitsInOrder(expectedStates));

        await cubit.load('g1');
      },
    );

    test('load emits [loading, offline] on NetworkFailure', () async {
      const failure = NetworkFailure(message: 'offline', code: 'network');
      when(() => repository.getGroupInfo('g1'))
          .thenAnswer((_) async => const FailureResult(failure));

      final expectedStates = [
        const GroupInfoState(status: GroupInfoStatus.loading),
        const GroupInfoState(status: GroupInfoStatus.offline, failure: failure),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.load('g1');
    });

    test('updateDetails updates group name and description', () async {
      when(() => repository.getGroupInfo('g1'))
          .thenAnswer((_) async => Success(sampleGroupInfo));
      when(
        () => repository.updateGroupDetails(
          'g1',
          'اسم جديد',
          description: 'وصف جديد',
        ),
      ).thenAnswer((_) async => const Success(null));

      await cubit.load('g1');

      final success = await cubit.updateDetails(
        name: 'اسم جديد',
        description: 'وصف جديد',
      );
      expect(success, isTrue);
      expect(cubit.state.groupInfo?.name, 'اسم جديد');
      expect(cubit.state.groupInfo?.description, 'وصف جديد');
    });

    test('uploadPhotoBytes uploads and sets group photo', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      when(() => repository.getGroupInfo('g1'))
          .thenAnswer((_) async => Success(sampleGroupInfo));
      when(() => repository.uploadGroupPhoto('g1', bytes, 'jpg'))
          .thenAnswer((_) async => const Success('g1/new_photo.jpg'));
      when(() => repository.setGroupPhoto('g1', 'g1/new_photo.jpg'))
          .thenAnswer((_) async => const Success(null));

      await cubit.load('g1');

      final success = await cubit.uploadPhotoBytes(bytes);
      expect(success, isTrue);
      expect(cubit.state.groupInfo?.photoPath, 'g1/new_photo.jpg');
    });

    test('removePhoto sets group photo to null', () async {
      when(() => repository.getGroupInfo('g1'))
          .thenAnswer((_) async => Success(sampleGroupInfo));
      when(() => repository.setGroupPhoto('g1', null))
          .thenAnswer((_) async => const Success(null));

      await cubit.load('g1');

      final success = await cubit.removePhoto();
      expect(success, isTrue);
      expect(cubit.state.groupInfo?.photoPath, isNull);
    });
  });
}
