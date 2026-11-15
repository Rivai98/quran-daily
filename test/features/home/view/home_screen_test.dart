import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/design_system/app_theme.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/core/quran/quran_metadata_repository.dart';
import 'package:quran_daily/core/quran/portion_unit.dart';
import 'package:quran_daily/features/home/cubit/home_cubit.dart';
import 'package:quran_daily/features/home/data/today_repository.dart';
import 'package:quran_daily/features/home/data/today_snapshot.dart';
import 'package:quran_daily/features/home/view/home_screen.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/khatma_repository.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ar'));
  testWidgets(
    'shows empty entry points in RTL at narrow width and large text',
    (tester) async {
      await _setSmallScreen(tester);
      await _show(tester, Success(_emptySnapshot), largeText: true);
      expect(find.text(ArabicStrings.homeEmptyTitle), findsOneWidget);
      expect(find.text(ArabicStrings.joinAnyGroupAction), findsOneWidget);
      expect(_rtl(tester), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows an online group card and all-done message in dark mode', (
    tester,
  ) async {
    await _setSmallScreen(tester);
    await _show(tester, Success(_completedSnapshot), dark: true);
    expect(find.text('مجموعة الاختبار'), findsNWidgets(2));
    await tester.scrollUntilVisible(
      find.text(ArabicStrings.todayCompleteTitle),
      400,
    );
    expect(find.text(ArabicStrings.todayCompleteTitle), findsOneWidget);
    expect(find.text(ArabicStrings.portionUndoAction), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows cached group card with offline banner', (tester) async {
    await _setSmallScreen(tester);
    await _show(tester, Success(_offlineSnapshot));
    expect(find.text(ArabicStrings.offlineStale), findsOneWidget);
    expect(find.text('مجموعة الاختبار'), findsOneWidget);
  });

  testWidgets('shows an error panel when no cached Home snapshot exists', (
    tester,
  ) async {
    await _setSmallScreen(tester);
    await _show(
      tester,
      const FailureResult(NetworkFailure(message: 'offline', code: 'network')),
    );
    expect(find.text(ArabicStrings.todayLoadError), findsOneWidget);
    expect(find.text(ArabicStrings.retry), findsOneWidget);
  });
}

bool _rtl(WidgetTester tester) =>
    Directionality.of(tester.element(find.text(ArabicStrings.homeGreeting))) ==
    TextDirection.rtl;

Future<void> _setSmallScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(320, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _show(
  WidgetTester tester,
  Result<TodaySnapshot> result, {
  bool dark = false,
  bool largeText = false,
}) async {
  final cubit = HomeCubit(
    repository: _TodayRepository(result),
    khatmaRepository: _KhatmaRepository(),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(largeText ? 2 : 1),
          ),
          child: BlocProvider.value(
            value: cubit,
            child: HomeScreen(metadataRepository: QuranMetadataRepository()),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(cubit.close);
}

final _emptySnapshot = TodaySnapshot(
  serverGeneratedAt: DateTime.utc(2026),
  mainGroupId: null,
  groups: const [],
);
final _group = TodayGroup(
  groupId: 'group-1',
  name: 'مجموعة الاختبار',
  role: 'member',
  status: 'active',
  portionUnit: PortionUnit.juz,
  isMain: true,
  day: TodayDay(
    groupDate: '2026-11-15',
    state: 'open',
    endsAt: DateTime.utc(2026, 11, 15, 20),
    closesAt: DateTime.utc(2026, 11, 16),
    cycleNumber: 1,
    cycleDay: 1,
    cycleLength: 30,
    completedCount: 1,
    totalCount: 30,
    restDay: false,
  ),
  items: const [
    TodayItem(
      assignmentId: 'assignment-1',
      kind: 'seat',
      seatNumber: 1,
      portionIndex: 1,
      status: 'completed',
      canUndo: true,
    ),
    TodayItem(
      assignmentId: 'assignment-2',
      kind: 'volunteer',
      seatNumber: 2,
      portionIndex: 2,
      status: 'completed',
      canUndo: true,
    ),
  ],
);
final _completedSnapshot = TodaySnapshot(
  serverGeneratedAt: DateTime.utc(2026),
  mainGroupId: 'group-1',
  groups: [_group],
);
final _offlineSnapshot = TodaySnapshot(
  serverGeneratedAt: DateTime.utc(2026),
  mainGroupId: 'group-1',
  groups: [_group],
  isStale: true,
);

class _TodayRepository implements TodayRepository {
  const _TodayRepository(this.result);
  final Result<TodaySnapshot> result;
  @override
  Future<Result<TodaySnapshot>> getToday() async => result;
  @override
  Future<Result<void>> setMainGroup(String? groupId) async =>
      const Success(null);
  @override
  Future<void> markGroupOpened(String groupId) async {}
}

class _KhatmaRepository extends Mock implements KhatmaRepository {}
