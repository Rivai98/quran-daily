import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/core/quran/mushaf/mushaf_models.dart';
import 'package:quran_daily/core/quran/mushaf/mushaf_repository.dart';
import 'package:quran_daily/core/quran/mushaf/qpc_v2_repository.dart';
import 'package:quran_daily/core/quran/portion_unit.dart';
import 'package:quran_daily/core/quran/quran_metadata_repository.dart';
import 'package:quran_daily/features/mushaf/cubit/reader_cubit.dart';
import 'package:quran_daily/features/mushaf/data/reader_storage.dart';
import 'package:quran_daily/features/mushaf/view/reader_screen.dart';

import '../../../helpers/widget_test_app.dart';

void main() {
  testWidgets('page prefetch waits until the scroll animation has settled', (
    tester,
  ) async {
    final repository = _RichRepository();
    final storage = _Storage();
    final fonts = _Fonts();
    final prepared = <int>[];
    when(() => fonts.prefetch(any())).thenAnswer((call) async {
      prepared.add(call.positionalArguments.single as int);
    });
    final cubit = ReaderCubit(
      repository: repository,
      storage: storage,
      qpcFonts: fonts,
    );
    await cubit.openPage(5);
    await tester.pumpWidget(
      buildArabicTestApp(
        BlocProvider.value(
          value: cubit,
          child: ReaderScreen(
            repository: repository,
            storage: storage,
            metadata: QuranMetadataRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(Duration.zero);
    expect(prepared, [6]);
    final pages = tester.widget<PageView>(
      find.byKey(const ValueKey('mushaf-page-view')),
    );
    final turn = pages.controller!.animateToPage(
      5,
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(prepared, [
      6,
    ], reason: 'page change during animation must not prefetch');
    await tester.pumpAndSettle();
    await turn;
    await tester.pump(Duration.zero);
    expect(prepared, [6, 7]);
    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
  });
  testWidgets(
    'renders RTL reader (next page on the left) in RTL, dark, 200%, and 320dp variants',
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
          isFalse,
          reason: 'RTL directionality already places the next page on the left',
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
    'renders continuous surah paragraphs, calm chrome, portion progress, and page footer',
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

      // Actions are grouped in the compact chrome menu.
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.bookmark_add_rounded), findsOneWidget);
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();

      // 2. Surah title band at ayah 1
      expect(
        find.text('${ArabicStrings.surahWord} ${ArabicStrings.mushafTitle}'),
        findsWidgets,
      );

      // 3. Page number footer
      expect(find.text('١'), findsWidgets);

      // Portion card is replaced by a thin progress line.
      expect(
        find.byKey(const ValueKey('reader-portion-progress')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('reader-portion-card')), findsNothing);

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
    tester
        .widget<PageView>(find.byKey(const ValueKey('mushaf-page-view')))
        .controller!
        .jumpToPage(2);
    await tester.pumpAndSettle();

    // The completion page offers the primary action after the portion pages.
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

  testWidgets('shows correct thin portion progress on each page', (
    tester,
  ) async {
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

    var progress = tester.widget<LinearProgressIndicator>(
      find.byKey(const ValueKey('reader-portion-progress')),
    );
    expect(progress.value, 0.5);

    await cubit.turnTo(2);
    await tester.pumpAndSettle();
    progress = tester.widget<LinearProgressIndicator>(
      find.byKey(const ValueKey('reader-portion-progress')),
    );
    expect(progress.value, 1.0);

    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
  });

  testWidgets('portion pager is bounded and advances to its completion page', (
    tester,
  ) async {
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

    var pager = tester.widget<PageView>(
      find.byKey(const ValueKey('mushaf-page-view')),
    );
    expect(pager.childrenDelegate.estimatedChildCount, 3);

    pager.controller!.jumpToPage(2);
    await tester.pumpAndSettle();
    expect(cubit.state.isCompletionPage, isTrue);
    expect(
      find.byKey(const ValueKey('reader-completion-page')),
      findsOneWidget,
    );
    expect(find.text(ArabicStrings.readerCompletionTitle), findsOneWidget);
    expect(find.text(ArabicStrings.readerCompletionMessage), findsOneWidget);
    expect(find.text(ArabicStrings.completeReadingAction), findsOneWidget);
    expect(find.text(ArabicStrings.readerBackAction), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
  });

  testWidgets('bounds portion pager for juz, hizb, and page units', (
    tester,
  ) async {
    final repo = _RichRepository();
    final storage = _Storage();
    for (final (unit, expectedCount) in [
      (PortionUnit.juz, 3),
      (PortionUnit.hizb, 4),
      (PortionUnit.page, 2),
    ]) {
      final cubit = ReaderCubit(repository: repo, storage: storage);
      await cubit.openPortion(unit, 1, assignmentId: 'assign-1');
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
      final pager = tester.widget<PageView>(
        find.byKey(const ValueKey('mushaf-page-view')),
      );
      expect(pager.childrenDelegate.estimatedChildCount, expectedCount);
      await tester.pumpWidget(const SizedBox.shrink());
      await cubit.close();
    }
  });

  testWidgets('completion marks the portion and pops the reader route', (
    tester,
  ) async {
    final repo = _RichRepository();
    final storage = _Storage();
    var completions = 0;
    final cubit = ReaderCubit(
      repository: repo,
      storage: storage,
      onComplete: () async {
        completions++;
        return false;
      },
    );
    await cubit.openPortion(PortionUnit.juz, 1, assignmentId: 'assign-1');
    await tester.pumpWidget(
      buildArabicTestApp(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: ReaderScreen(
                      repository: repo,
                      storage: storage,
                      metadata: QuranMetadataRepository(),
                    ),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    tester
        .widget<PageView>(find.byKey(const ValueKey('mushaf-page-view')))
        .controller!
        .jumpToPage(2);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('complete-reading-button')));
    await tester.pumpAndSettle();

    expect(completions, 1);
    expect(find.text('open'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
  });

  testWidgets('already-completed portion shows its recorded state and back', (
    tester,
  ) async {
    final repo = _RichRepository();
    final storage = _Storage();
    final cubit = ReaderCubit(repository: repo, storage: storage);
    await cubit.openPortion(
      PortionUnit.juz,
      1,
      assignmentId: 'assign-1',
      alreadyCompleted: true,
    );
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
    tester
        .widget<PageView>(find.byKey(const ValueKey('mushaf-page-view')))
        .controller!
        .jumpToPage(2);
    await tester.pumpAndSettle();

    expect(find.text(ArabicStrings.readerCompletionRecorded), findsOneWidget);
    expect(find.byKey(const ValueKey('complete-reading-button')), findsNothing);
    expect(
      find.byKey(const ValueKey('reader-completion-back')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
  });
}

class _Fonts extends Mock implements QpcFontManager {}

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
    startPage: switch (unit) {
      PortionUnit.hizb => 3,
      PortionUnit.page => 6,
      _ => 1,
    },
    endPage: switch (unit) {
      PortionUnit.hizb => 5,
      PortionUnit.page => 6,
      _ => 2,
    },
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
    startPage: switch (unit) {
      PortionUnit.hizb => 3,
      PortionUnit.page => 6,
      _ => 1,
    },
    endPage: switch (unit) {
      PortionUnit.hizb => 5,
      PortionUnit.page => 6,
      _ => 2,
    },
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
