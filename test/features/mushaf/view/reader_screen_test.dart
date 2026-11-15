import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/core/quran/mushaf/mushaf_models.dart';
import 'package:quran_daily/core/quran/mushaf/mushaf_repository.dart';
import 'package:quran_daily/core/quran/portion_unit.dart';
import 'package:quran_daily/core/quran/quran_metadata_repository.dart';
import 'package:quran_daily/features/mushaf/cubit/reader_cubit.dart';
import 'package:quran_daily/features/mushaf/data/reader_storage.dart';
import 'package:quran_daily/features/mushaf/view/reader_screen.dart';
import '../../../helpers/widget_test_app.dart';

void main() {
  testWidgets(
    'renders reversed reader in RTL, dark, 200%, and 320dp variants',
    (tester) async {
      for (final variant in testVariants) {
        tester.view.physicalSize = variant.size;
        tester.view.devicePixelRatio = 1;
        final repo = _Repository();
        final storage = _Storage();
        final cubit = ReaderCubit(repository: repo, storage: storage);
        await cubit.openPage(1);
        await tester.pumpWidget(
          buildArabicTestApp(
            BlocProvider.value(
              value: cubit,
              child: ReaderScreen(
                repository: repo,
                storage: storage,
                metadata: QuranMetadataRepository(),
              ),
            ),
            dark: variant.dark,
            textScale: variant.textScale,
            size: variant.size,
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          find.byKey(const ValueKey('mushaf-page-view')),
          findsOneWidget,
          reason: variant.name,
        );
        expect(
          (tester.widget<PageView>(
            find.byKey(const ValueKey('mushaf-page-view')),
          )).reverse,
          isTrue,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await cubit.close();
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets('does not offer khatm dua until the owner asset exists', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    final repo = _Repository();
    final storage = _Storage();
    final cubit = ReaderCubit(repository: repo, storage: storage);
    await cubit.openPage(repo.pageCount);
    await tester.pumpWidget(
      buildArabicTestApp(
        BlocProvider.value(
          value: cubit,
          child: ReaderScreen(
            repository: repo,
            storage: storage,
            metadata: QuranMetadataRepository(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(ArabicStrings.khatmDuaTitle), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('tap toggles reader chrome and restores system UI on exit', (
    tester,
  ) async {
    final systemUiCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method.startsWith('SystemChrome.')) systemUiCalls.add(call);
        return null;
      },
    );
    final repo = _Repository();
    final storage = _Storage();
    final cubit = ReaderCubit(repository: repo, storage: storage);
    await cubit.openPage(1);
    await tester.pumpWidget(
      buildArabicTestApp(
        BlocProvider.value(
          value: cubit,
          child: ReaderScreen(
            repository: repo,
            storage: storage,
            metadata: QuranMetadataRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reader-page-tap-area')));
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsNothing);
    expect(systemUiCalls.last.method, 'SystemChrome.setEnabledSystemUIMode');
    expect(systemUiCalls.last.arguments, 'SystemUiMode.immersiveSticky');

    await tester.tap(find.byKey(const ValueKey('reader-page-tap-area')));
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsOneWidget);
    expect(systemUiCalls.last.arguments, 'SystemUiMode.edgeToEdge');

    await tester.pumpWidget(const SizedBox.shrink());
    expect(systemUiCalls.last.arguments, 'SystemUiMode.edgeToEdge');
    await cubit.close();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  testWidgets('shows the page the cubit opened, not the first page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    final repo = _Repository();
    final storage = _Storage();
    final cubit = ReaderCubit(repository: repo, storage: storage);
    await tester.pumpWidget(
      buildArabicTestApp(
        BlocProvider.value(
          value: cubit,
          child: ReaderScreen(
            repository: repo,
            storage: storage,
            metadata: QuranMetadataRepository(),
          ),
        ),
      ),
    );
    await cubit.openPage(2);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    final view = tester.widget<PageView>(
      find.byKey(const ValueKey('mushaf-page-view')),
    );
    expect(view.controller!.page, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets(
    'renders Mushaf slim header, page footer, surah title band, and bookmark in app bar',
    (tester) async {
      final repo = _RichRepository();
      final storage = _Storage();
      final cubit = ReaderCubit(repository: repo, storage: storage);
      await cubit.openPortion(PortionUnit.juz, 1, assignmentId: 'assign-1');
      await tester.pumpWidget(
        buildArabicTestApp(
          BlocProvider.value(
            value: cubit,
            child: ReaderScreen(
              repository: repo,
              storage: storage,
              metadata: QuranMetadataRepository(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Bookmark action in AppBar
      expect(find.byIcon(Icons.bookmark_add_rounded), findsOneWidget);

      // 2. Surah title band at ayah 1
      expect(
        find.text('${ArabicStrings.surahWord} ${ArabicStrings.mushafTitle}'),
        findsWidgets,
      );

      // 3. Page number footer
      expect(find.text('١'), findsWidgets);

      // 4. Portion banner with portion name + "صفحة ١ من ٢"
      expect(find.text('صفحة ١ من ٢'), findsOneWidget);

      // 5. Start and end highlights live on the flowing ayah spans.
      final paragraph = tester.widget<RichText>(
        find.byKey(const ValueKey('mushaf-surah-segment-1')).first,
      );
      final spans = (paragraph.text as TextSpan).children!.cast<TextSpan>();
      expect(spans.first.style?.backgroundColor, isNotNull);
      expect(spans.last.style?.backgroundColor, isNotNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await cubit.close();
    },
  );

  testWidgets('renders completion action and end highlight on end page', (
    tester,
  ) async {
    final repo = _RichRepository();
    final storage = _Storage();
    final cubit = ReaderCubit(repository: repo, storage: storage);
    await cubit.openPortion(PortionUnit.juz, 1, assignmentId: 'assign-1');
    await cubit.turnTo(2);
    await tester.pumpWidget(
      buildArabicTestApp(
        BlocProvider.value(
          value: cubit,
          child: ReaderScreen(
            repository: repo,
            storage: storage,
            metadata: QuranMetadataRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // End page offers complete reading
    expect(find.text(ArabicStrings.completeReadingAction), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
  });

  testWidgets(
    'flows ayahs in one paragraph per surah with source numbers and highlights',
    (tester) async {
      final repo = _FlowRepository();
      final storage = _Storage();
      final cubit = ReaderCubit(repository: repo, storage: storage);
      await cubit.openPortion(PortionUnit.juz, 1, assignmentId: 'assign-1');
      await tester.pumpWidget(
        buildArabicTestApp(
          BlocProvider.value(
            value: cubit,
            child: ReaderScreen(
              repository: repo,
              storage: storage,
              metadata: QuranMetadataRepository(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final firstSegment = tester.widget<RichText>(
        find.byKey(const ValueKey('mushaf-surah-segment-1')),
      );
      final secondSegment = tester.widget<RichText>(
        find.byKey(const ValueKey('mushaf-surah-segment-2')),
      );
      expect(firstSegment, isA<RichText>());
      expect(secondSegment, isA<RichText>());
      expect(firstSegment.text.toPlainText(), 'مقطع تجريبي ١ مقطع ثانٍ ٢ ');
      expect(secondSegment.text.toPlainText(), 'مقطع ثالث ١ ');
      final spans = (firstSegment.text as TextSpan).children!.cast<TextSpan>();
      expect(
        spans
            .expand((span) => span.children ?? const <InlineSpan>[])
            .whereType<WidgetSpan>(),
        isEmpty,
        reason: 'source ayah numbers must not get a second marker widget',
      );
      expect(spans.first.style?.backgroundColor, isNotNull);
      expect(spans.last.style?.backgroundColor, isNotNull);

      await tester.longPressAt(
        tester.getCenter(find.byKey(const ValueKey('mushaf-surah-segment-1'))),
      );
      await tester.pumpAndSettle();
      expect(find.text(ArabicStrings.addBookmarkAction), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await cubit.close();
    },
  );
}

class _FlowRepository implements MushafRepository {
  @override
  Future<void> load() async {}

  @override
  int get pageCount => 2;

  @override
  MushafPage page(int number) => MushafPage(
    number: number,
    juz: 1,
    firstSurah: 1,
    ayahs: number == 1
        ? [
            MushafAyah(
              ref: const AyahRef(surah: 1, ayah: 1),
              text: 'مقطع تجريبي ١',
            ),
            MushafAyah(
              ref: const AyahRef(surah: 1, ayah: 2),
              text: 'مقطع ثانٍ ٢',
            ),
            MushafAyah(
              ref: const AyahRef(surah: 2, ayah: 1),
              text: 'مقطع ثالث ١',
            ),
          ]
        : const [],
  );

  @override
  int pageOf(AyahRef ref) => 1;

  @override
  ({AyahRef start, AyahRef end, int startPage, int endPage}) portionRange(
    PortionUnit unit,
    int index,
  ) => (
    start: const AyahRef(surah: 1, ayah: 1),
    end: const AyahRef(surah: 1, ayah: 2),
    startPage: 1,
    endPage: 2,
  );

  @override
  List<({int surah, String name, int ayahs, int startPage})> surahIndex() => [];

  @override
  List<({int juz, int startPage})> juzIndex() => [];

  @override
  List<({int hizb, int startPage})> hizbIndex() => [];
}

class _RichRepository implements MushafRepository {
  @override
  Future<void> load() async {}

  @override
  int get pageCount => 10;

  @override
  MushafPage page(int number) => MushafPage(
    number: number,
    juz: 1,
    firstSurah: 1,
    ayahs: [
      MushafAyah(ref: const AyahRef(surah: 1, ayah: 1), text: 'ayah 1 text'),
      MushafAyah(ref: const AyahRef(surah: 1, ayah: 2), text: 'ayah 2 text'),
    ],
  );

  @override
  int pageOf(AyahRef ref) => ref.ayah == 1 ? 1 : 2;

  @override
  ({AyahRef start, AyahRef end, int startPage, int endPage}) portionRange(
    PortionUnit unit,
    int index,
  ) => (
    start: const AyahRef(surah: 1, ayah: 1),
    end: const AyahRef(surah: 1, ayah: 2),
    startPage: 1,
    endPage: 2,
  );

  @override
  List<({int surah, String name, int ayahs, int startPage})> surahIndex() => [
    (surah: 1, name: 'الفاتحة', ayahs: 7, startPage: 1),
  ];

  @override
  List<({int juz, int startPage})> juzIndex() => [(juz: 1, startPage: 1)];

  @override
  List<({int hizb, int startPage})> hizbIndex() => [(hizb: 1, startPage: 1)];
}

class _Repository implements MushafRepository {
  @override
  Future<void> load() async {}

  @override
  int get pageCount => 2;

  @override
  MushafPage page(int number) =>
      MushafPage(number: number, ayahs: const [], juz: 0, firstSurah: 0);

  @override
  int pageOf(AyahRef ref) => 1;

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

class _Storage implements ReaderStorage {
  @override
  Future<int?> lastPage() async => 1;

  @override
  Future<void> savePage(int page) async {}

  @override
  Future<List<ReaderBookmark>> bookmarks() async => [];

  @override
  Future<void> addBookmark(ReaderBookmark bookmark) async {}

  @override
  Future<void> removeBookmark(String id) async {}

  @override
  Future<List<ReaderSyncOperation>> pendingSyncOperations() async => [];

  @override
  Future<void> markSyncOperationComplete(String id) async {}
}
