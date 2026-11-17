import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/quran_groups/cubit/join_requests/join_requests_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';

class _Groups extends Mock implements GroupsRepository {}

void main() {
  test('membership limit uses the canonical Arabic error message', () {
    expect(
      ArabicStrings.authError('membership_limit'),
      ArabicStrings.membershipLimitMessage,
    );
    expect(
      const UnknownFailure(message: 'limit', code: 'membership_limit').kind,
      FailureKind.limitReached,
    );
  });
  late _Groups repository;
  setUp(() => repository = _Groups());
  test('overlapping requests loads share one request (#7)', () async {
    final response = Completer<Result<List<PublicJoinRequestInfo>>>();
    when(() => repository.listJoinRequests('g'))
        .thenAnswer((_) => response.future);
    final cubit = JoinRequestsCubit(repository);
    final first = cubit.load('g');
    final second = cubit.load('g');
    verify(() => repository.listJoinRequests('g')).called(1);
    response.complete(const Success([]));
    await Future.wait([first, second]);
    expect(cubit.state.status, JoinRequestsStatus.empty);
    await cubit.close();
  });

  blocTest<JoinRequestsCubit, JoinRequestsState>(
    'lists requests then reports full group on approval',
    build: () {
      when(() => repository.listJoinRequests('g'))
          .thenAnswer((_) async => const Success([]));
      when(() => repository.reviewJoinRequest('r', true)).thenAnswer(
        (_) async => const FailureResult(
          UnknownFailure(message: 'full', code: 'group_full'),
        ),
      );
      return JoinRequestsCubit(repository);
    },
    act: (cubit) async {
      await cubit.load('g');
      await cubit.review('r', approve: true);
    },
    expect: () => [
      const JoinRequestsState(status: JoinRequestsStatus.loading),
      const JoinRequestsState(status: JoinRequestsStatus.empty),
      const JoinRequestsState(status: JoinRequestsStatus.submitting),
      const JoinRequestsState(
        status: JoinRequestsStatus.groupFull,
        failure: UnknownFailure(message: 'full', code: 'group_full'),
      ),
    ],
  );

  blocTest<JoinRequestsCubit, JoinRequestsState>(
    'retains requests when refresh fails offline',
    build: () {
      var calls = 0;
      final request = PublicJoinRequestInfo(
        joinRequestId: 'r',
        userDisplayName: ArabicStrings.memberRole,
        requestedAt: DateTime.utc(2026),
        source: JoinSource.invite,
      );
      when(() => repository.listJoinRequests('g')).thenAnswer((_) async {
        calls++;
        if (calls == 1) return Success([request]);
        return const FailureResult(
          NetworkFailure(message: 'offline', code: 'network'),
        );
      });
      return JoinRequestsCubit(repository);
    },
    act: (cubit) async {
      await cubit.load('g');
      await cubit.load('g');
    },
    expect: () => [
      const JoinRequestsState(status: JoinRequestsStatus.loading),
      predicate<JoinRequestsState>(
        (state) =>
            state.status == JoinRequestsStatus.success &&
            state.requests.length == 1,
      ),
      predicate<JoinRequestsState>(
        (state) =>
            state.status == JoinRequestsStatus.loading &&
            state.requests.length == 1,
      ),
      predicate<JoinRequestsState>(
        (state) =>
            state.status == JoinRequestsStatus.offline &&
            state.requests.length == 1,
      ),
    ],
  );

  blocTest<JoinRequestsCubit, JoinRequestsState>(
    'surfaces the membership limit distinctly when approving a request',
    build: () {
      when(() => repository.listJoinRequests('g'))
          .thenAnswer((_) async => const Success([]));
      when(() => repository.reviewJoinRequest('r', true)).thenAnswer(
        (_) async => const FailureResult(
          UnknownFailure(message: 'limit', code: 'membership_limit'),
        ),
      );
      return JoinRequestsCubit(repository);
    },
    act: (cubit) async {
      await cubit.load('g');
      await cubit.review('r', approve: true);
    },
    expect: () => [
      const JoinRequestsState(status: JoinRequestsStatus.loading),
      const JoinRequestsState(status: JoinRequestsStatus.empty),
      const JoinRequestsState(status: JoinRequestsStatus.submitting),
      const JoinRequestsState(
        status: JoinRequestsStatus.membershipLimit,
        failure: UnknownFailure(message: 'limit', code: 'membership_limit'),
      ),
    ],
  );
}
