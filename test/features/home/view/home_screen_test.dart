import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import 'dart:async';

import 'package:quran_daily/core/design_system/app_theme.dart';
import 'package:quran_daily/core/design_system/app_colors.dart';
import 'package:quran_daily/core/design_system/app_button.dart';
import 'package:quran_daily/core/design_system/widgets/status_chip.dart';
import 'package:quran_daily/core/design_system/widgets/skeleton.dart';
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

import '../../../helpers/widget_test_app.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
    await loadArabicUiFontsForGoldenTests();
  });
  testWidgets(
    'shows empty entry points in RTL at narrow width and large text',
    (tester) async {
      await _setSmallScreen(tester);
      await _show(tester, Success(_emptySnapshot), largeText: true);
      expect(find.text(ArabicStrings.homeEmptyTitle), findsOneWidget);
      expect(find.text(ArabicStrings.searchGroupAction), findsOneWidget);
      expect(_rtl(tester), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows an online group card and all-done message in dark mode', (
    tester,
  ) async {
    await _setSmallScreen(tester);
    await _show(tester, Success(_completedSnapshot), dark: true);
    expect(find.text('مجموعة الاختبار'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(ArabicStrings.todayCompleteTitle),
      400,
    );
    expect(find.text(ArabicStrings.todayCompleteTitle), findsOneWidget);
    expect(find.text(ArabicStrings.readNowAction), findsNothing);
    expect(find.text(ArabicStrings.portionUndoAction), findsNWidgets(2));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(tester.getSize(find.byType(LinearProgressIndicator)).height, 8);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows cached group card with offline banner', (tester) async {
    await _setSmallScreen(tester);
    await _show(tester, Success(_offlineSnapshot));
    expect(find.text(ArabicStrings.offlineStale), findsOneWidget);
    expect(find.text('مجموعة الاختبار'), findsOneWidget);
  });

  testWidgets('personalizes the greeting and shows member progress', (
    tester,
  ) async {
    await _setSmallScreen(tester);
    await _show(
      tester,
      Success(_pendingSnapshot),
      displayName: 'أحمد محمد عبد الله صالح',
    );

    expect(find.text('السلام عليكم يا أحمد'), findsOneWidget);
    expect(
      find.text(ArabicStrings.homeGroupProgress(1, 1, 12)),
      findsOneWidget,
    );
    expect(find.textContaining('من ٣٠'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('shows reading actions for a pending portion', (tester) async {
    await _setSmallScreen(tester);
    await _show(tester, Success(_pendingSnapshot));

    expect(find.text(ArabicStrings.readNowAction), findsOneWidget);
    expect(find.text(ArabicStrings.portionCompleteAction), findsOneWidget);
    expect(find.byType(StatusChip), findsOneWidget);
    expect(tester.getSize(find.byType(StatusChip)).width, lessThan(220));
  });

  testWidgets('other group cards reuse the badge and action styles', (
    tester,
  ) async {
    await _setSmallScreen(tester);
    await _show(tester, Success(_withOtherGroup));
    await tester.scrollUntilVisible(find.text('حلقة المساء'), 300);

    expect(find.text(ArabicStrings.readNowAction), findsNWidgets(2));
    expect(find.byType(StatusChip), findsNWidgets(2));
    expect(find.byIcon(Icons.auto_stories_rounded), findsNWidgets(2));
    expect(find.text(ArabicStrings.portionCompleteAction), findsNWidgets(2));
    expect(
      find
          .byType(AppButton)
          .evaluate()
          .where(
            (element) =>
                (element.widget as AppButton).variant ==
                AppButtonVariant.primary,
          )
          .length,
      1,
    );
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'action icons follow foreground tokens ${dark ? 'dark' : 'light'}',
      (tester) async {
        await _setSmallScreen(tester);
        await _show(tester, Success(_pendingSnapshot), dark: dark);
        final colors = dark ? AppColors.dark : AppColors.light;
        expect(
          IconTheme.of(tester.element(find.byIcon(Icons.auto_stories_rounded)))
              .color,
          colors.onPrimary,
        );
        expect(
          IconTheme.of(
            tester.element(find.byIcon(Icons.check_circle_outline_rounded)),
          ).color,
          colors.onPrimaryContainer,
        );
      },
    );
  }

  for (final theme in [false, true]) {
    testWidgets('Home ${theme ? 'dark' : 'light'} golden at 360x800', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _show(
        tester,
        Success(_pendingSnapshot),
        dark: theme,
        displayName: 'أحمد محمد عبد الله صالح',
        date: DateTime(2026, 11, 15),
      );
      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile(
          '../../../goldens/home_${theme ? 'dark' : 'light'}_360x800.png',
        ),
      );
    });
  }

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

  testWidgets('shows loading state while Home data is being read', (
    tester,
  ) async {
    await _setSmallScreen(tester);
    final pending = Completer<Result<TodaySnapshot>>();
    final cubit = HomeCubit(
      repository: _TodayRepository.pending(pending.future),
      khatmaRepository: _KhatmaRepository(),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: BlocProvider.value(
            value: cubit,
            child: HomeScreen(metadataRepository: QuranMetadataRepository()),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(SkeletonBox), findsWidgets);
    expect(tester.takeException(), isNull);
    addTearDown(cubit.close);
  });
}

bool _rtl(WidgetTester tester) =>
    Directionality.of(tester.element(find.byType(HomeScreen))) ==
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
  String? displayName,
  DateTime? date,
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
            child: HomeScreen(
              metadataRepository: QuranMetadataRepository(),
              displayName: displayName,
              date: date,
            ),
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
    completedMemberCount: 1,
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
  activeMemberCount: 12,
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
final _pendingSnapshot = TodaySnapshot(
  serverGeneratedAt: DateTime.utc(2026),
  mainGroupId: 'group-1',
  groups: [
    TodayGroup(
      groupId: 'group-1',
      name: 'حلقة الفجر',
      role: 'member',
      status: 'active',
      portionUnit: PortionUnit.juz,
      isMain: true,
      activeMemberCount: 12,
      day: _group.day,
      items: const [
        TodayItem(
          assignmentId: 'assignment-pending',
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
final _withOtherGroup = TodaySnapshot(
  serverGeneratedAt: DateTime.utc(2026),
  mainGroupId: 'group-1',
  groups: [
    ..._pendingSnapshot.groups,
    TodayGroup(
      groupId: 'group-2',
      name: 'حلقة المساء',
      role: 'member',
      status: 'active',
      portionUnit: PortionUnit.juz,
      isMain: false,
      activeMemberCount: 8,
      day: _group.day,
      items: const [
        TodayItem(
          assignmentId: 'assignment-other',
          kind: 'seat',
          seatNumber: 2,
          portionIndex: 2,
          status: 'pending',
          canUndo: false,
        ),
      ],
    ),
  ],
);

class _TodayRepository implements TodayRepository {
  const _TodayRepository(this.result) : pendingResult = null;
  const _TodayRepository.pending(this.pendingResult) : result = null;
  final Result<TodaySnapshot>? result;
  final Future<Result<TodaySnapshot>>? pendingResult;
  @override
  Future<Result<TodaySnapshot>> getToday() =>
      pendingResult ?? Future.value(result!);
  @override
  Future<Result<void>> setMainGroup(String? groupId) async =>
      const Success(null);
  @override
  Future<void> markGroupOpened(String groupId) async {}
}

class _KhatmaRepository extends Mock implements KhatmaRepository {}
