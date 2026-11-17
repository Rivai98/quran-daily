import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/design_system/widgets/islamic_ornament.dart';
import 'package:quran_daily/core/design_system/widgets/offline_banner.dart';
import 'package:quran_daily/core/design_system/widgets/skeleton.dart';
import 'package:quran_daily/core/design_system/widgets/state_panel.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/log/data/entities/log_entities.dart';
import 'package:quran_daily/features/log/data/repositories/log_repository.dart';
import 'package:quran_daily/features/log/view/log_screen.dart';
import 'package:quran_daily/features/log/view/log_day_detail_screen.dart';
import 'package:quran_daily/core/quran/quran_metadata_repository.dart';

import '../../../helpers/quran_metadata_test_asset_bundle.dart';
import '../../../helpers/widget_test_app.dart';

class _Repository extends Mock implements LogRepository {}

PersonalLog _log({List<LogDay> days = const [], bool stale = false}) =>
    PersonalLog(
      streak: 3,
      bestStreak: 7,
      month: const LogMonthSummary(
        year: 2026,
        month: 11,
        fullDays: 4,
        daysWithItems: 6,
      ),
      days: days,
      nextBefore: null,
      isStale: stale,
    );

LogDay _day() => LogDay(
  date: DateTime(2026, 11, 14),
  complete: true,
  items: const [
    LogItem(
      groupId: 'g1',
      groupName: 'مجموعة النور',
      portionUnit: 'juz',
      portionIndex: 2,
      kind: LogItemKind.seat,
      status: LogItemStatus.completed,
      completedAt: null,
      groupDayId: 'day1',
    ),
  ],
);

void main() {
  setUpAll(loadDesignSystemFonts);
  late _Repository repository;
  setUp(() => repository = _Repository());

  Future<void> pump(
    WidgetTester tester, {
    required Future<Result<PersonalLog>> Function() response,
  }) async {
    when(() => repository.getLog(onCached: any(named: 'onCached'))).thenAnswer((_) => response());
    await tester.pumpWidget(
      buildArabicTestApp(LogScreen(repository: repository)),
    );
    await tester.pump();
  }

  testWidgets('loading shows shaped skeletons', (tester) async {
    final pending = Completer<Result<PersonalLog>>();
    await pump(tester, response: () => pending.future);
    expect(find.byType(SkeletonBox), findsWidgets);
    pending.complete(Success(_log()));
    await tester.pumpAndSettle();
  });

  testWidgets('empty state uses spiritual ornament and friendly copy', (
    tester,
  ) async {
    await pump(tester, response: () async => Success(_log()));
    await tester.pumpAndSettle();
    expect(find.byType(IslamicOrnamentBand), findsOneWidget);
    expect(find.text(ArabicStrings.logEmptyTitle), findsOneWidget);
  });

  testWidgets('failure state offers retry', (tester) async {
    await pump(
      tester,
      response: () async => const FailureResult(
        UnknownFailure(message: 'failed', code: 'unknown'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(StatePanel), findsOneWidget);
    expect(find.text(ArabicStrings.retryAction), findsOneWidget);
  });

  testWidgets('offline cached state displays banner and days', (tester) async {
    await pump(
      tester,
      response: () async => Success(_log(days: [_day()], stale: true)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(OfflineBanner), findsOneWidget);
    expect(
      find.textContaining('مجموعة النور', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('content displays streak, month summary and day status', (
    tester,
  ) async {
    await pump(tester, response: () async => Success(_log(days: [_day()])));
    await tester.pumpAndSettle();
    expect(find.textContaining(ArabicStrings.logCurrentStreak), findsOneWidget);
    expect(find.text(ArabicStrings.logMonthSummary), findsOneWidget);
    expect(find.textContaining('مجموعة النور'), findsOneWidget);
  });

  testWidgets('empty state goldens remain calm in light and dark themes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    for (final dark in [false, true]) {
      when(() => repository.getLog(onCached: any(named: 'onCached'))).thenAnswer((_) async => Success(_log()));
      await tester.pumpWidget(
        buildArabicTestApp(
          LogScreen(repository: repository),
          dark: dark,
          size: const Size(360, 800),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          dark
              ? '../../../goldens/005_log_empty_dark.png'
              : '../../../goldens/005_log_empty_light.png',
        ),
      );
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('history cards render at 360x800 in both themes', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final dark in [false, true]) {
      when(() => repository.getLog(onCached: any(named: 'onCached')))
          .thenAnswer((_) async => Success(_log(days: [_day()])));
      await tester.pumpWidget(
        buildArabicTestApp(
          LogScreen(repository: repository),
          dark: dark,
          size: const Size(360, 800),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(LogScreen),
        matchesGoldenFile('goldens/log_content_${dark ? 'dark' : 'light'}.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('day details render at 360x800 in both themes', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final dark in [false, true]) {
      final metadata = QuranMetadataRepository(
        bundle: QuranMetadataTestAssetBundle(),
      );
      await tester.runAsync(metadata.load);
      await tester.pumpWidget(
        buildArabicTestApp(
          LogDayDetailScreen(day: _day(), metadataRepository: metadata),
          dark: dark,
          size: const Size(360, 800),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(LogDayDetailScreen),
        matchesGoldenFile('goldens/log_detail_${dark ? 'dark' : 'light'}.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('day details support accessibility variants', (tester) async {
    final metadata = QuranMetadataRepository(
      bundle: QuranMetadataTestAssetBundle(),
    );
    await tester.runAsync(metadata.load);
    await pumpAllVariants(
      tester,
      LogDayDetailScreen(day: _day(), metadataRepository: metadata),
      (tester, variant) async {
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: variant);
      },
    );
  });

  testWidgets('all accessibility variants render without overflow', (
    tester,
  ) async {
    when(() => repository.getLog(onCached: any(named: 'onCached')))
        .thenAnswer((_) async => Success(_log(days: [_day()])));
    await pumpAllVariants(tester, LogScreen(repository: repository), (
      tester,
      variant,
    ) async {
      await tester.pumpAndSettle();
      expect(find.byType(LogScreen), findsOneWidget, reason: variant);
      expect(tester.takeException(), isNull, reason: variant);
    });
  });
}
