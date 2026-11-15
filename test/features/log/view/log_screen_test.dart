import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/design_system/widgets/islamic_ornament.dart';
import 'package:quran_daily/core/design_system/widgets/offline_banner.dart';
import 'package:quran_daily/core/design_system/widgets/skeleton.dart';
import 'package:quran_daily/core/design_system/widgets/state_panel.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/log/cubit/log_cubit.dart';
import 'package:quran_daily/features/log/data/entities/log_entities.dart';
import 'package:quran_daily/features/log/data/repositories/log_repository.dart';
import 'package:quran_daily/features/log/view/log_screen.dart';
import '../../../helpers/widget_test_app.dart';

class _Repository extends Mock implements LogRepository {}

PersonalLog _log({List<LogDay> days = const [], bool stale = false}) => PersonalLog(
  streak: 3, bestStreak: 7,
  month: const LogMonthSummary(year: 2026, month: 11, fullDays: 4, daysWithItems: 6),
  days: days, nextBefore: null, isStale: stale,
);

LogDay _day() => LogDay(date: DateTime(2026, 11, 14), complete: true, items: const [
  LogItem(groupId: 'g1', groupName: 'مجموعة النور', portionUnit: 'juz', portionIndex: 2, kind: LogItemKind.seat, status: LogItemStatus.completed, completedAt: null, groupDayId: 'day1'),
]);

void main() {
  late _Repository repository;
  setUp(() => repository = _Repository());

  Future<void> pump(WidgetTester tester, {required Future<Result<PersonalLog>> Function() response}) async {
    when(() => repository.getLog()).thenAnswer((_) => response());
    final cubit = LogCubit(repository: repository);
    await tester.pumpWidget(buildArabicTestApp(BlocProvider.value(value: cubit, child: const LogScreen())));
    await tester.pump();
  }

  testWidgets('loading shows shaped skeletons', (tester) async {
    final pending = Completer<Result<PersonalLog>>();
    await pump(tester, response: () => pending.future);
    expect(find.byType(SkeletonBox), findsWidgets);
    pending.complete(Success(_log()));
    await tester.pumpAndSettle();
  });

  testWidgets('empty state uses spiritual ornament and friendly copy', (tester) async {
    await pump(tester, response: () async => Success(_log()));
    await tester.pumpAndSettle();
    expect(find.byType(IslamicOrnamentBand), findsOneWidget);
    expect(find.text(ArabicStrings.logEmptyTitle), findsOneWidget);
  });

  testWidgets('failure state offers retry', (tester) async {
    await pump(tester, response: () async => const FailureResult(UnknownFailure(message: 'failed', code: 'unknown')));
    await tester.pumpAndSettle();
    expect(find.byType(StatePanel), findsOneWidget);
    expect(find.text(ArabicStrings.retryAction), findsOneWidget);
  });

  testWidgets('offline cached state displays banner and days', (tester) async {
    await pump(tester, response: () async => Success(_log(days: [_day()], stale: true)));
    await tester.pumpAndSettle();
    expect(find.byType(OfflineBanner), findsOneWidget);
    expect(find.text('مجموعة النور', skipOffstage: false), findsOneWidget);
  });

  testWidgets('content displays streak, month summary and day status', (tester) async {
    await pump(tester, response: () async => Success(_log(days: [_day()])));
    await tester.pumpAndSettle();
    expect(find.text(ArabicStrings.logCurrentStreak), findsOneWidget);
    expect(find.text(ArabicStrings.logMonthSummary), findsOneWidget);
    expect(find.textContaining('مجموعة النور'), findsOneWidget);
  });

  testWidgets('all accessibility variants render without overflow', (tester) async {
    when(() => repository.getLog()).thenAnswer((_) async => Success(_log(days: [_day()])));
    final cubit = LogCubit(repository: repository);
    await pumpAllVariants(tester, BlocProvider.value(value: cubit, child: const LogScreen()), (tester, variant) async {
      await tester.pumpAndSettle();
      expect(find.byType(LogScreen), findsOneWidget, reason: variant);
      expect(tester.takeException(), isNull, reason: variant);
    });
  });
}
