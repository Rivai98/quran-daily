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
}

class _Repo implements TodayRepository {
  @override
  Future<Result<TodaySnapshot>> getToday() async => Success(
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
