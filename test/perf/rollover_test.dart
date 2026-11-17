import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/features/home/cubit/home_cubit.dart';
import 'package:quran_daily/features/home/data/today_repository.dart';
import 'package:quran_daily/features/home/data/today_snapshot.dart';
import 'package:quran_daily/features/quran_groups/cubit/dashboard/dashboard_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/models/models.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/khatma_repository.dart';

import 'cache_first_test.dart' show todayJson, dashboardJson, testNow;

class _Today extends Mock implements TodayRepository {}

class _Khatma extends Mock implements KhatmaRepository {}

void main() {
  testWidgets(
    'retained Home removes expired assignment while refresh still waits (#2)',
    (tester) async {
      var now = testNow;
      final end = now.add(const Duration(seconds: 1));
      final json = todayJson();
      final group = (json['groups'] as List).single as Map;
      (group['day'] as Map)['ends_at'] = end.toIso8601String();
      final response = Completer<Result<TodaySnapshot>>();
      final repo = _Today();
      when(() => repo.getToday(onCached: any(named: 'onCached')))
          .thenAnswer((call) {
            (call.namedArguments[#onCached] as void Function(TodaySnapshot))(
              TodaySnapshot.fromJson(json, isStale: true),
            );
            return response.future;
          });
      final cubit = HomeCubit(
        repository: repo,
        khatmaRepository: _Khatma(),
        clock: () => now,
      );
      final loading = cubit.load();
      expect(cubit.state.snapshot!.groups.single.items, isNotEmpty);
      now = end;
      await tester.pump(const Duration(seconds: 1));
      expect(cubit.state.snapshot!.groups.single.items, isEmpty);
      expect(cubit.state.snapshot!.groups.single.day, isNull);
      group.remove('day');
      group['items'] = [];
      response.complete(Success(TodaySnapshot.fromJson(json, isStale: true)));
      await loading;
      await cubit.close();
    },
  );

  testWidgets(
    'retained dashboard removes expired assignment during a slow read (#2 #8)',
    (tester) async {
      var now = testNow;
      final end = now.add(const Duration(seconds: 1));
      final json = dashboardJson();
      (json['today'] as Map)['ends_at'] = end.toIso8601String();
      final snapshots = StreamController<DashboardSnapshot?>();
      final response = Completer<Result<DashboardSnapshot>>();
      final repo = _Khatma();
      when(() => repo.watchCachedDashboard('g'))
          .thenAnswer((_) => snapshots.stream);
      when(() => repo.getDashboard('g')).thenAnswer((_) => response.future);
      final cubit = DashboardCubit(
        repository: repo,
        groupId: 'g',
        clock: () => now,
      );
      final loading = cubit.refresh();
      snapshots.add(dashboardSnapshotFromJson(json, isStale: true));
      await tester.pump();
      expect(cubit.state.snapshot!.myAssignments, isNotEmpty);
      now = end;
      await tester.pump(const Duration(seconds: 1));
      expect(cubit.state.snapshot!.today, isNull);
      expect(cubit.state.snapshot!.myAssignments, isEmpty);
      json['today'] = null;
      json['assignments'] = [];
      json['my_assignments'] = [];
      response.complete(
        Success(dashboardSnapshotFromJson(json, isStale: true)),
      );
      await loading;
      addTearDown(() async {
        await cubit.close();
        await snapshots.close();
      });
    },
  );
}
