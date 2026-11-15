import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/design_system/widgets/offline_banner.dart';
import 'package:quran_daily/core/design_system/widgets/progress_header.dart';
import 'package:quran_daily/core/design_system/widgets/skeleton.dart';
import 'package:quran_daily/core/design_system/widgets/state_panel.dart';
import 'package:quran_daily/core/design_system/widgets/halaqa_logo.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/core/localization/arabic_numerals.dart';
import 'package:quran_daily/core/quran/portion_unit.dart';
import 'package:quran_daily/features/quran_groups/cubit/history/history_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/khatma_repository.dart';
import 'package:quran_daily/features/quran_groups/view/screens/history_screen.dart';
import 'package:quran_daily/features/quran_groups/view/widgets/history_day_card.dart';

import '../../../helpers/test_fixtures.dart';
import '../../../helpers/widget_test_app.dart';

class _MockKhatmaRepo extends Mock implements KhatmaRepository {}

void main() {
  late _MockKhatmaRepo repo;
  const groupId = TestFixtures.groupId;

  setUp(() {
    repo = _MockKhatmaRepo();
  });

  Widget pump(Widget child, {HistoryCubit? cubit}) {
    final historyCubit =
        cubit ?? HistoryCubit(groupId: groupId, repository: repo);
    return BlocProvider<HistoryCubit>.value(value: historyCubit, child: child);
  }

  testWidgets('loading state shows skeletons', (tester) async {
    final completer = Completer<Result<List<HistoryDaySummary>>>();
    when(
      () => repo.getHistory(groupId, limit: any(named: 'limit')),
    ).thenAnswer((_) => completer.future);

    await tester.pumpWidget(
      buildArabicTestApp(pump(const HistoryScreen(groupId: groupId))),
    );
    await tester.pump();

    expect(find.byType(SkeletonBox), findsWidgets);
    completer.complete(const Success([]));
    await tester.pumpAndSettle();
  });

  testWidgets('empty state shows StatePanel with empty copy', (tester) async {
    when(
      () => repo.getHistory(groupId, limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Success([]));

    await tester.pumpWidget(
      buildArabicTestApp(pump(const HistoryScreen(groupId: groupId))),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StatePanel), findsOneWidget);
    expect(find.text(ArabicStrings.emptyHistoryTitle), findsOneWidget);
    expect(find.text(ArabicStrings.emptyHistoryDesc), findsOneWidget);
    expect(find.byType(HalaqaLogo), findsOneWidget);
    expect(find.text(ArabicStrings.groupSelectionTitle), findsOneWidget);
  });

  testWidgets('failure state shows StatePanel with retry action', (
    tester,
  ) async {
    when(() => repo.getHistory(groupId, limit: any(named: 'limit'))).thenAnswer(
      (_) async => const FailureResult(
        UnknownFailure(message: 'error', code: 'unknown'),
      ),
    );

    await tester.pumpWidget(
      buildArabicTestApp(pump(const HistoryScreen(groupId: groupId))),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StatePanel), findsOneWidget);
    expect(find.text(ArabicStrings.historyErrorTitle), findsOneWidget);
    expect(find.text(ArabicStrings.retryAction), findsOneWidget);
  });

  testWidgets('offline state shows OfflineBanner', (tester) async {
    when(() => repo.getHistory(groupId, limit: any(named: 'limit'))).thenAnswer(
      (_) async => const FailureResult(
        NetworkFailure(message: 'offline', code: 'network'),
      ),
    );

    await tester.pumpWidget(
      buildArabicTestApp(pump(const HistoryScreen(groupId: groupId))),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OfflineBanner), findsOneWidget);
  });

  testWidgets(
    'content: lists day cards with ProgressHeader and full khatma badge',
    (tester) async {
      final days = [
        const HistoryDaySummary(
          groupDate: '2026-11-14',
          completedCount: 28,
          lateCount: 2,
          missedCount: 0,
          unreadCount: 0,
          fullKhatma: true,
          portionUnit: PortionUnit.hizb,
          cycleNumber: 4,
          cycleDay: 2,
        ),
        const HistoryDaySummary(
          groupDate: '2026-11-13',
          completedCount: 20,
          lateCount: 0,
          missedCount: 10,
          unreadCount: 0,
          fullKhatma: false,
          portionUnit: PortionUnit.hizb,
          cycleNumber: 4,
          cycleDay: 1,
        ),
      ];

      when(
        () => repo.getHistory(groupId, limit: any(named: 'limit')),
      ).thenAnswer((_) async => Success(days));

      await tester.pumpWidget(
        buildArabicTestApp(pump(const HistoryScreen(groupId: groupId))),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProgressHeader), findsNWidgets(2));
      expect(
        find.text(ArabicStrings.historyWeekOf(DateTime(2026, 11, 9))),
        findsOneWidget,
      );
      expect(find.text(ArabicStrings.fullKhatmaBadge), findsOneWidget);
      expect(
        find.textContaining(
          '${ArabicStrings.cycleLabel} ${ArabicNumerals.format(4)}',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('day detail: regular member sees summary and own result only', (
    tester,
  ) async {
    const memberDay = HistoryDaySummary(
      groupDate: '2026-11-14',
      completedCount: 28,
      lateCount: 2,
      missedCount: 0,
      unreadCount: 0,
      fullKhatma: true,
      myResult: Assignment(
        assignmentId: 'a-1',
        juz: 3,
        seatNumber: 3,
        kind: AssignmentKind.seat,
        status: AssignmentStatusEnum.completed,
      ),
      perJuz: null,
    );

    when(
      () => repo.getHistory(groupId, limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Success([memberDay]));
    when(
      () => repo.getHistoryDay(groupId, '2026-11-14'),
    ).thenAnswer((_) async => const Success(memberDay));

    await tester.pumpWidget(
      buildArabicTestApp(pump(const HistoryScreen(groupId: groupId))),
    );
    await tester.pumpAndSettle();

    // Tap the day card to load detail
    await tester.tap(find.byType(HistoryDayCard).first);
    await tester.pumpAndSettle();

    expect(find.text(ArabicStrings.myResultSectionTitle), findsOneWidget);
    expect(find.text(ArabicStrings.allMembersDetailTitle), findsNothing);
  });

  testWidgets('day detail: supervisor/owner sees per-juz rows', (tester) async {
    final perJuz = List.generate(
      30,
      (i) => Assignment(
        assignmentId: 'a-$i',
        juz: i + 1,
        seatNumber: i + 1,
        kind: AssignmentKind.seat,
        status: AssignmentStatusEnum.completed,
        readerDisplayName: 'قارئ ${i + 1}',
      ),
    );

    final ownerDay = HistoryDaySummary(
      groupDate: '2026-11-14',
      completedCount: 30,
      lateCount: 0,
      missedCount: 0,
      unreadCount: 0,
      fullKhatma: true,
      perJuz: perJuz,
    );

    when(
      () => repo.getHistory(groupId, limit: any(named: 'limit')),
    ).thenAnswer((_) async => Success([ownerDay]));
    when(
      () => repo.getHistoryDay(groupId, '2026-11-14'),
    ).thenAnswer((_) async => Success(ownerDay));

    await tester.pumpWidget(
      buildArabicTestApp(pump(const HistoryScreen(groupId: groupId))),
    );
    await tester.pumpAndSettle();

    // Tap to open detail
    await tester.tap(find.byType(HistoryDayCard).first);
    await tester.pumpAndSettle();

    expect(find.text(ArabicStrings.allMembersDetailTitle), findsOneWidget);
    expect(find.textContaining('قارئ 1 ·'), findsOneWidget);
  });

  testWidgets('all variants render without overflow', (tester) async {
    final days = TestFixtures.historyPage(days: 4);

    when(
      () => repo.getHistory(groupId, limit: any(named: 'limit')),
    ).thenAnswer((_) async => Success(days));

    await pumpAllVariants(tester, pump(const HistoryScreen(groupId: groupId)), (
      tester,
      variant,
    ) async {
      await tester.pumpAndSettle();
      expect(find.byType(HistoryScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
