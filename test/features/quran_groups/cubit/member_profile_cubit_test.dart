import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/features/quran_groups/cubit/member_profile/member_profile_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';

class _MockGroupsRepository extends Mock implements GroupsRepository {}

void main() {
  late _MockGroupsRepository repository;
  late MemberProfileCubit cubit;

  final sampleProfile = MemberGroupProfile(
    userId: 'u1',
    groupId: 'g1',
    displayName: 'طارق بن زياد',
    initials: 'ط ز',
    bio: 'قارئ مجتهد',
    role: 'member',
    seatNumber: 12,
    memberSince: DateTime.parse('2026-01-01T00:00:00Z'),
    currentStreak: 5,
    portionsRead: 25,
    completionRate: 90,
    recentDays: const [
      MemberRecentDay(
        groupDate: '2026-11-15',
        portionIndex: 12,
        juz: 12,
        kind: AssignmentKind.seat,
        status: AssignmentStatusEnum.completed,
      ),
    ],
  );

  setUp(() {
    repository = _MockGroupsRepository();
    cubit = MemberProfileCubit(repository);
  });

  tearDown(() {
    cubit.close();
  });

  group('MemberProfileCubit (T012)', () {
    test('initial state has initial status and null profile', () {
      expect(cubit.state.status, MemberProfileStatus.initial);
      expect(cubit.state.profile, isNull);
    });

    test('load emits [loading, success] on successful repository call', () async {
      when(() => repository.getMemberProfile('u1', 'g1'))
          .thenAnswer((_) async => Success(sampleProfile));

      final expectedStates = [
        const MemberProfileState(status: MemberProfileStatus.loading),
        MemberProfileState(
          status: MemberProfileStatus.success,
          profile: sampleProfile,
        ),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.load('u1', 'g1');
    });

    test('load emits [loading, notAccessible] when permission failure occurs', () async {
      const failure = PermissionFailure(
        message: 'not_member',
        code: 'not_member',
      );
      when(() => repository.getMemberProfile('u1', 'g1'))
          .thenAnswer((_) async => const FailureResult(failure));

      final expectedStates = [
        const MemberProfileState(status: MemberProfileStatus.loading),
        const MemberProfileState(
          status: MemberProfileStatus.notAccessible,
          failure: failure,
        ),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.load('u1', 'g1');
    });

    test('load emits [loading, offline] on NetworkFailure', () async {
      const failure = NetworkFailure(
        message: 'offline',
        code: 'network',
      );
      when(() => repository.getMemberProfile('u1', 'g1'))
          .thenAnswer((_) async => const FailureResult(failure));

      final expectedStates = [
        const MemberProfileState(status: MemberProfileStatus.loading),
        const MemberProfileState(
          status: MemberProfileStatus.offline,
          failure: failure,
        ),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.load('u1', 'g1');
    });

    test('load emits [loading, failure] on generic failure', () async {
      const failure = UnknownFailure(message: 'error', code: 'server_error');
      when(() => repository.getMemberProfile('u1', 'g1'))
          .thenAnswer((_) async => const FailureResult(failure));

      final expectedStates = [
        const MemberProfileState(status: MemberProfileStatus.loading),
        const MemberProfileState(
          status: MemberProfileStatus.failure,
          failure: failure,
        ),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.load('u1', 'g1');
    });

    test('refresh re-loads current profile', () async {
      when(() => repository.getMemberProfile('u1', 'g1'))
          .thenAnswer((_) async => Success(sampleProfile));

      await cubit.load('u1', 'g1');
      await cubit.refresh();

      verify(() => repository.getMemberProfile('u1', 'g1')).called(2);
    });
  });
}
