import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/features/quran_groups/cubit/join_requests/join_requests_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';

class _Groups extends Mock implements GroupsRepository {}

void main() {
  late _Groups repository;
  setUp(() => repository = _Groups());
  blocTest<JoinRequestsCubit, JoinRequestsState>(
    'lists requests then reports full group on approval',
    build: () {
      when(
        () => repository.listJoinRequests('g'),
      ).thenAnswer((_) async => const Success([]));
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
}
