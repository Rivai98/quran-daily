import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/features/home/cubit/home_cubit.dart';
import 'package:quran_daily/features/home/data/today_repository.dart';
import 'package:quran_daily/features/home/data/today_snapshot.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/khatma_repository.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  test('load exposes an empty successful snapshot', () async {
    final cubit = HomeCubit(repository: _Repo(), khatmaRepository: _Khatma());
    await cubit.load();
    expect(cubit.state.status, HomeStatus.empty);
    await cubit.close();
  });

  test(
    'returning to Home soon after a change refreshes quietly (new group shows)',
    () async {
      final repo = _Repo();
      final cubit = HomeCubit(repository: repo, khatmaRepository: _Khatma());
      await cubit.load();
      expect(repo.calls, 1);
      // The user creates and starts a group within seconds, then taps Home.
      await Future<void>.delayed(const Duration(seconds: 4));
      await cubit.refreshIfStale();
      expect(repo.calls, 2);
      // A double tap on the tab does not hammer the server.
      await cubit.refreshIfStale();
      expect(repo.calls, 2);
      await cubit.close();
    },
  );
}

class _Repo implements TodayRepository {
  int calls = 0;

  @override
  Future<Result<TodaySnapshot>> getToday() async {
    calls++;
    return Success(
    TodaySnapshot(
      serverGeneratedAt: DateTime.utc(2026),
      mainGroupId: null,
      groups: const [],
    ),
  );
  }

  @override
  Future<Result<void>> setMainGroup(String? groupId) async =>
      const Success(null);
  @override
  Future<void> markGroupOpened(String groupId) async {}
}

class _Khatma extends Mock implements KhatmaRepository {}
