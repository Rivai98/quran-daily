import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/features/home/cubit/home_cubit.dart';
import 'package:quran_daily/features/home/data/today_repository.dart';
import 'package:quran_daily/features/home/data/today_snapshot.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/khatma_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/quran/portion_unit.dart';

void main() {
  test('load exposes an empty successful snapshot', () async {
    final cubit = HomeCubit(repository: _Repo(), khatmaRepository: _Khatma());
    await cubit.load();
    expect(cubit.state.status, HomeStatus.empty);
    await cubit.close();
  });

  test('load quietly exposes the next rotation assignment', () async {
    final snapshot = TodaySnapshot(
      serverGeneratedAt: DateTime.utc(2026),
      mainGroupId: 'g',
      groups: [
        TodayGroup(
          groupId: 'g',
          name: 'ح',
          role: 'member',
          status: 'active',
          portionUnit: PortionUnit.juz,
          isMain: true,
          day: TodayDay(
            groupDate: '2026-01-01',
            state: 'open',
            endsAt: DateTime.utc(2026),
            closesAt: DateTime.utc(2026),
            cycleNumber: 0,
            cycleDay: 0,
            cycleLength: 1,
            completedCount: 0,
            totalCount: 30,
            restDay: false,
          ),
          items: const [
            TodayItem(
              assignmentId: 'a',
              kind: 'seat',
              seatNumber: 1,
              portionIndex: 1,
              status: 'pending',
              canUndo: false,
            ),
          ],
        ),
      ],
    );
    final cubit = HomeCubit(
      repository: _Repo(snapshot),
      khatmaRepository: _Khatma(),
    );
    await cubit.load();
    expect(cubit.state.tomorrowPortions['g'], 2);
    await cubit.close();
  });
}

class _Repo implements TodayRepository {
  _Repo([this.snapshot]);
  final TodaySnapshot? snapshot;
  @override
  Future<Result<TodaySnapshot>> getToday() async => Success(
    snapshot ??
        TodaySnapshot(
          serverGeneratedAt: DateTime.utc(2026),
          mainGroupId: null,
          groups: const [],
        ),
  );
  @override
  Future<Result<void>> setMainGroup(String? groupId) async =>
      const Success(null);
  @override
  Future<void> markGroupOpened(String groupId) async {}
}

class _Khatma extends Mock implements KhatmaRepository {}
