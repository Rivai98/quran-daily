import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/quran/mushaf/mushaf_models.dart';
import 'package:quran_daily/core/quran/mushaf/mushaf_repository.dart';
import 'package:quran_daily/core/quran/portion_unit.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import '../../../helpers/widget_test_app.dart';
import 'package:quran_daily/core/di/service_locator.dart';
import 'package:quran_daily/features/mushaf/data/reader_storage.dart';
import 'package:quran_daily/features/mushaf/view/mushaf_index_screen.dart';

void main() {
  testWidgets('index loads the Mushaf once, not on every rebuild', (
    tester,
  ) async {
    final repository = _CountingRepository();
    await tester.pumpWidget(
      buildArabicTestApp(
        MushafIndexScreen(repository: repository, onOpenPage: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'ب');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'با');
    await tester.pumpAndSettle();
    expect(repository.loads, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('surah search matches Arabic spelling variants', (tester) async {
    await tester.pumpWidget(
      buildArabicTestApp(
        MushafIndexScreen(repository: _SearchRepository(), onOpenPage: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'حلقه');
    await tester.pumpAndSettle();
    expect(find.text('حلقة الذكر'), findsOneWidget);
    expect(find.text('باب'), findsNothing);
  });

  testWidgets(
    'continue-reading card follows a position saved while the tab is alive',
    (tester) async {
      final storage = _PositionStorage();
      serviceLocator.registerSingleton<ReaderStorage>(storage);
      addTearDown(() => serviceLocator.unregister<ReaderStorage>());

      await tester.pumpWidget(
        buildArabicTestApp(
          MushafIndexScreen(repository: _PagedRepository(), onOpenPage: (_) {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(ArabicStrings.continueReadingTitle), findsNothing);

      storage.page = 2;
      ReaderStorage.notifyPositionSaved(2);
      await tester.pumpAndSettle();
      expect(find.text(ArabicStrings.continueReadingTitle), findsOneWidget);
      expect(find.text('${ArabicStrings.pageNumberLabel} ٢'), findsOneWidget);
    },
  );

  testWidgets(
    'index exposes the four source-backed browsing categories in all variants',
    (tester) async {
      var openedPage = 0;
      for (final variant in testVariants) {
        tester.view.physicalSize = variant.size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          buildArabicTestApp(
            MushafIndexScreen(
              repository: _Repository(),
              onOpenPage: (page) => openedPage = page,
            ),
            dark: variant.dark,
            textScale: variant.textScale,
            size: variant.size,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(ArabicStrings.surahsTab),
          findsOneWidget,
          reason: variant.name,
        );
        expect(
          find.text(ArabicStrings.ajzaaTab),
          findsOneWidget,
          reason: variant.name,
        );
        expect(
          find.text(ArabicStrings.ahzabTab),
          findsOneWidget,
          reason: variant.name,
        );
        expect(
          find.text(ArabicStrings.pagesTab),
          findsOneWidget,
          reason: variant.name,
        );
        await tester.ensureVisible(find.text(ArabicStrings.pagesTab));
        await tester.tap(find.text(ArabicStrings.pagesTab));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '٢');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        expect(openedPage, 2, reason: variant.name);
        expect(
          find.text('${ArabicStrings.pageNumberLabel} ١'),
          findsOneWidget,
          reason: variant.name,
        );
        await tester.pumpWidget(const SizedBox.shrink());
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets('renders surah rows with number badge, meta template, and chevron', (tester) async {
    final repo = _DetailedRepository();
    await tester.pumpWidget(
      buildArabicTestApp(
        MushafIndexScreen(
          repository: repo,
          onOpenPage: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الفاتحة'), findsOneWidget);
    expect(find.text(ArabicStrings.surahAyahMeta(1, 7)), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsWidgets);
  });

  testWidgets('renders juz and hizb rows with start page and chevron', (tester) async {
    final repo = _DetailedRepository();
    await tester.pumpWidget(
      buildArabicTestApp(
        MushafIndexScreen(
          repository: repo,
          onOpenPage: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(ArabicStrings.ajzaaTab));
    await tester.pumpAndSettle();

    expect(find.text('${ArabicStrings.juzLabel} ١'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsWidgets);

    await tester.tap(find.text(ArabicStrings.ahzabTab));
    await tester.pumpAndSettle();

    expect(find.text('${ArabicStrings.portionUnitHizb} ١'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsWidgets);
  });
}

class _DetailedRepository implements MushafRepository {
  @override
  Future<void> load() async {}

  @override
  int get pageCount => 604;

  @override
  MushafPage page(int number) => throw UnimplementedError();

  @override
  int pageOf(AyahRef ref) => throw UnimplementedError();

  @override
  ({AyahRef start, AyahRef end, int startPage, int endPage}) portionRange(
    PortionUnit unit,
    int index,
  ) => throw UnimplementedError();

  @override
  List<({int surah, String name, int ayahs, int startPage})> surahIndex() => [
    (surah: 1, name: 'الفاتحة', ayahs: 7, startPage: 1),
    (surah: 2, name: 'البقرة', ayahs: 286, startPage: 2),
  ];

  @override
  List<({int juz, int startPage})> juzIndex() => [
    (juz: 1, startPage: 1),
    (juz: 2, startPage: 22),
  ];

  @override
  List<({int hizb, int startPage})> hizbIndex() => [
    (hizb: 1, startPage: 1),
    (hizb: 2, startPage: 11),
  ];
}

class _Repository implements MushafRepository {
  @override
  Future<void> load() async {}

  @override
  int get pageCount => 2;

  @override
  MushafPage page(int number) => throw UnimplementedError();

  @override
  int pageOf(AyahRef ref) => throw UnimplementedError();

  @override
  ({AyahRef start, AyahRef end, int startPage, int endPage}) portionRange(
    PortionUnit unit,
    int index,
  ) => throw UnimplementedError();

  @override
  List<({int surah, String name, int ayahs, int startPage})> surahIndex() => [];

  @override
  List<({int juz, int startPage})> juzIndex() => [];

  @override
  List<({int hizb, int startPage})> hizbIndex() => [];
}

class _PagedRepository extends _Repository {
  @override
  MushafPage page(int number) =>
      MushafPage(number: number, ayahs: const [], juz: 1, firstSurah: 1);
}

class _PositionStorage implements ReaderStorage {
  int? page;

  @override
  Future<int?> lastPage() async => page;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SearchRepository extends _Repository {
  @override
  List<({int surah, String name, int ayahs, int startPage})> surahIndex() => [
    (surah: 1, name: 'حلقة الذكر', ayahs: 3, startPage: 1),
    (surah: 2, name: 'باب', ayahs: 4, startPage: 2),
  ];
}

class _CountingRepository extends _SearchRepository {
  int loads = 0;

  @override
  Future<void> load() async => loads++;
}
