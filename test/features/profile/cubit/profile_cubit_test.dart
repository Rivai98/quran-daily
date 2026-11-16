import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/features/profile/cubit/profile_cubit.dart';
import 'package:quran_daily/features/profile/cubit/profile_state.dart';
import 'package:quran_daily/features/profile/data/entities/profile_entities.dart';
import 'package:quran_daily/features/profile/data/repositories/profile_repository.dart';

class MockProfileRepository implements ProfileRepository {
  Result<UserProfile>? result;
  bool lastForceRefresh = false;

  @override
  Future<Result<UserProfile>> getProfile({bool forceRefresh = false}) async {
    lastForceRefresh = forceRefresh;
    return result ??
        const FailureResult(
          NetworkFailure(message: 'no mock result', code: 'network'),
        );
  }
}

void main() {
  late MockProfileRepository repository;
  late ProfileCubit cubit;

  final testProfile = UserProfile(
    displayName: 'سارة',
    memberSince: DateTime(2026, 11, 1),
    streak: 3,
    bestStreak: 5,
    portionsRead: 20,
    portionsLate: 1,
    khatmas: const [
      ProfileKhatma(groupId: 'g-1', groupName: 'ختمة النور', completed: 1),
    ],
    badges: [
      ProfileBadge(
        code: ProfileBadgeCode.firstKhatma,
        earnedAt: DateTime(2026, 11, 5),
      ),
      const ProfileBadge(code: ProfileBadgeCode.streak7),
      const ProfileBadge(code: ProfileBadgeCode.streak30),
      const ProfileBadge(code: ProfileBadgeCode.streak100),
      const ProfileBadge(code: ProfileBadgeCode.portions100),
    ],
  );

  setUp(() {
    repository = MockProfileRepository();
    cubit = ProfileCubit(repository: repository);
  });

  tearDown(() {
    cubit.close();
  });

  group('ProfileCubit', () {
    test('initial state is correct', () {
      expect(cubit.state.status, ProfileStatus.initial);
      expect(cubit.state.profile, isNull);
      expect(cubit.state.failure, isNull);
    });

    test('load emits [loading, success] on successful fetch', () async {
      repository.result = Success(testProfile);

      final expectedStates = [
        const ProfileState(status: ProfileStatus.loading),
        ProfileState(status: ProfileStatus.success, profile: testProfile),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.load();

      expect(cubit.state.status, ProfileStatus.success);
      expect(cubit.state.profile, testProfile);
      expect(cubit.state.isStale, false);
    });

    test(
      'load emits [loading, offline] when profile is stale from cache',
      () async {
        final staleProfile = testProfile.copyWith(isStale: true);
        repository.result = Success(staleProfile);

        final expectedStates = [
          const ProfileState(status: ProfileStatus.loading),
          ProfileState(status: ProfileStatus.offline, profile: staleProfile),
        ];

        expectLater(cubit.stream, emitsInOrder(expectedStates));

        await cubit.load();

        expect(cubit.state.status, ProfileStatus.offline);
        expect(cubit.state.isStale, true);
      },
    );

    test(
      'load emits [loading, failure] when repository returns failure',
      () async {
        const failure = NetworkFailure(
          message: 'Connection failed',
          code: 'network',
        );
        repository.result = const FailureResult(failure);

        final expectedStates = [
          const ProfileState(status: ProfileStatus.loading),
          const ProfileState(status: ProfileStatus.failure, failure: failure),
        ];

        expectLater(cubit.stream, emitsInOrder(expectedStates));

        await cubit.load();

        expect(cubit.state.status, ProfileStatus.failure);
        expect(cubit.state.failure, failure);
      },
    );

    test('refresh calls repository with forceRefresh: true', () async {
      repository.result = Success(testProfile);

      await cubit.refresh();

      expect(repository.lastForceRefresh, true);
      expect(cubit.state.status, ProfileStatus.success);
      expect(cubit.state.profile, testProfile);
    });
  });
}
