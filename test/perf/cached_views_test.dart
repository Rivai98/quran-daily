import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/design_system/widgets/offline_banner.dart';
import 'package:quran_daily/core/design_system/widgets/skeleton.dart';
import 'package:quran_daily/core/quran/quran_metadata_repository.dart';
import 'package:quran_daily/features/home/cubit/home_cubit.dart';
import 'package:quran_daily/features/home/data/today_repository.dart';
import 'package:quran_daily/features/home/data/today_snapshot.dart';
import 'package:quran_daily/features/home/view/home_screen.dart';
import 'package:quran_daily/features/log/cubit/log_cubit.dart';
import 'package:quran_daily/features/log/data/entities/log_entities.dart';
import 'package:quran_daily/features/log/data/repositories/log_repository.dart';
import 'package:quran_daily/features/log/view/log_screen.dart';
import 'package:quran_daily/features/quran_groups/cubit/dashboard/dashboard_cubit.dart';
import 'package:quran_daily/features/quran_groups/cubit/group_list/group_list_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/khatma_repository.dart';
import 'package:quran_daily/features/quran_groups/view/screens/group_dashboard_screen.dart';
import 'package:quran_daily/features/quran_groups/view/screens/group_selection_screen.dart';

import '../helpers/widget_test_app.dart';
import '../helpers/fake_mushaf_repository.dart';
import '../helpers/test_fixtures.dart';
import 'cache_first_test.dart' show todayJson, logJson;

class _Today extends Mock implements TodayRepository {}

class _Khatma extends Mock implements KhatmaRepository {}

class _Groups extends Mock implements GroupsRepository {}

class _Log extends Mock implements LogRepository {}

class _CountingMushaf extends FakeMushafRepository {
  int loads = 0;
  @override
  Future<void> load() {
    loads++;
    return super.load();
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  testWidgets(
    'Home renders cached assignment in RTL dark large text while revalidating (#2)',
    (tester) async {
      final repo = _Today();
      final response = Completer<Result<TodaySnapshot>>();
      final snapshot = TodaySnapshot.fromJson(todayJson(), isStale: true);
      when(() => repo.getToday(onCached: any(named: 'onCached')))
          .thenAnswer((call) {
            (call.namedArguments[#onCached] as void Function(TodaySnapshot))(
              snapshot,
            );
            return response.future;
          });
      final mushaf = _CountingMushaf();
      await tester.runAsync(mushaf.load);
      mushaf.loads = 0;
      final cubit = HomeCubit(repository: repo, khatmaRepository: _Khatma());
      await tester.pumpWidget(
        buildArabicTestApp(
          BlocProvider.value(
            value: cubit,
            child: HomeScreen(
              metadataRepository: QuranMetadataRepository(),
              mushafRepository: mushaf,
            ),
          ),
          dark: true,
          textScale: 2,
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('group'), findsOneWidget);
      expect(find.byType(OfflineBanner), findsOneWidget);
      expect(find.byType(SkeletonBox), findsNothing);
      response.complete(Success(snapshot));
      await tester.pumpAndSettle();
      expect(
        mushaf.loads,
        1,
        reason:
            'Home rebuilds share one retained initialization Future (#5 #18)',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await cubit.close();
    },
  );

  testWidgets(
    'Groups keeps cached content marked stale during a slow refresh (#2)',
    (tester) async {
      final repo = _Groups();
      final response = Completer<Result<MyGroupsOverview>>();
      final overview = TestFixtures.overview(
        groups: [TestFixtures.myGroup()],
        stale: true,
      );
      when(() => repo.getMyGroups(onCached: any(named: 'onCached')))
          .thenAnswer((call) {
            (call.namedArguments[#onCached] as void Function(MyGroupsOverview))(
              overview,
            );
            return response.future;
          });
      final cubit = GroupListCubit(repository: repo);
      await tester.pumpWidget(
        buildArabicTestApp(
          BlocProvider.value(value: cubit, child: const GroupSelectionScreen()),
          dark: true,
          textScale: 2,
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text(TestFixtures.groupName), findsOneWidget);
      expect(find.byType(OfflineBanner), findsOneWidget);
      expect(find.byType(SkeletonBox), findsNothing);
      response.complete(Success(overview));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await cubit.close();
    },
  );

  testWidgets('Log shows cached entries before remote response (#2)', (
    tester,
  ) async {
    final repo = _Log();
    final response = Completer<Result<PersonalLog>>();
    final log = PersonalLog.fromJson(logJson()).copyWith(isStale: true);
    when(() => repo.getLog(onCached: any(named: 'onCached')))
        .thenAnswer((call) {
          (call.namedArguments[#onCached] as void Function(PersonalLog))(log);
          return response.future;
        });
    final cubit = LogCubit(repository: repo);
    await tester.pumpWidget(
      buildArabicTestApp(
        BlocProvider.value(
          value: cubit,
          child: LogScreen(repository: repo),
        ),
        dark: true,
        textScale: 2,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(OfflineBanner), findsOneWidget);
    expect(find.byType(SkeletonBox), findsNothing);
    response.complete(Success(log));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
  });

  testWidgets(
    'Dashboard consumes stale cache while its fresh read waits (#2 #8)',
    (tester) async {
      final repo = _Khatma();
      final response = Completer<Result<DashboardSnapshot>>();
      final snapshots = StreamController<DashboardSnapshot?>();
      when(() => repo.watchCachedDashboard('g'))
          .thenAnswer((_) => snapshots.stream);
      when(() => repo.getDashboard('g')).thenAnswer((_) => response.future);
      final cubit = DashboardCubit(repository: repo, groupId: 'g');
      final refreshing = cubit.refresh();
      snapshots.add(TestFixtures.activeDashboard(offline: true));
      await tester.pumpWidget(
        buildArabicTestApp(
          BlocProvider.value(
            value: cubit,
            child: GroupDashboardScreen(
              metadataRepository: QuranMetadataRepository(),
            ),
          ),
          dark: true,
          textScale: 2,
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(OfflineBanner), findsOneWidget);
      expect(find.byType(SkeletonBox), findsNothing);
      response.complete(Success(TestFixtures.activeDashboard()));
      await refreshing;
      await tester.pumpAndSettle();
      expect(find.byType(OfflineBanner), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      addTearDown(() async {
        await cubit.close();
        await snapshots.close();
      });
    },
  );
}
