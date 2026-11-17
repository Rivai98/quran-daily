import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/quran/mushaf/mushaf_models.dart';
import 'package:quran_daily/core/di/service_locator.dart';
import 'package:quran_daily/core/quran/mushaf/mushaf_repository.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/core/quran/mushaf/qpc_v2_repository.dart';
import 'package:quran_daily/core/quran/quran_metadata_repository.dart';
import 'package:quran_daily/features/mushaf/view/widgets/qpc_page_view.dart';
import 'package:quran_daily/features/mushaf/view/widgets/qpc_page_painter.dart';
import 'package:quran_daily/features/mushaf/view/widgets/qpc_page_layout_cache.dart';
import 'package:quran_daily/features/mushaf/view/widgets/qpc_page_layout.dart';
import 'package:quran_daily/features/mushaf/cubit/reader_cubit.dart';
import 'package:quran_daily/features/mushaf/data/reader_storage.dart';
import 'package:quran_daily/features/mushaf/view/reader_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/widget_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory sources;
  late QpcV2Repository layout;
  late QuranMetadataRepository metadata;
  final fonts = _LoadedFonts();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    sources = await Directory.systemTemp.createTemp('qpc_page_test_');
    layout = QpcV2Repository(storageDirectory: sources);
    metadata = QuranMetadataRepository();
    await layout.load();
    await metadata.load();
    await loadArabicUiFontsForGoldenTests();
    for (final page in [1, 2, 100, 106, 604]) {
      final bytes = await File('test/fixtures/qpc_v2/p$page.ttf').readAsBytes();
      final manifest = layout.fontInfo(page);
      QpcV2Repository.verifyFontBytes(
        page: page,
        bytes: bytes,
        expectedSha256: manifest['sha256']! as String,
        expectedBytes: manifest['bytes']! as int,
      );
      await (FontLoader(
        'qpcv2_p$page',
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    }
    when(() => fonts.isLoaded(any())).thenReturn(true);
  });
  tearDownAll(() async {
    await layout.close();
    await sources.delete(recursive: true);
  });

  Future<void> showPage(
    WidgetTester tester,
    int page, {
    bool dark = false,
    double scale = 1,
    double width = 360,
    ValueChanged<QpcWord>? onLongPress,
    QpcPageLayoutCache? layoutCache,
  }) async {
    tester.view.physicalSize = Size(width, 740);
    tester.view.devicePixelRatio = 1;
    final words = layout.linesForPage(page).expand((line) => line.words);
    final first = words.first;
    final last = words.last;
    await tester.pumpWidget(
      buildArabicTestApp(
        Center(
          child: RepaintBoundary(
            key: const ValueKey('printed-page'),
            child: SizedBox(
              width: width,
              height: 640,
              child: QpcPageView(
                key: ValueKey(page),
                pageNumber: page,
                layout: layout,
                fonts: fonts,
                layoutCache: layoutCache,
                startAyah: AyahRef(surah: first.surah, ayah: first.ayah),
                endAyah: AyahRef(surah: last.surah, ayah: last.ayah),
                onLongPress: onLongPress ?? (_) {},
                surahName: metadata.suraName,
              ),
            ),
          ),
        ),
        dark: dark,
        textScale: scale,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('printed centered, justified and surah pages keep their pixels', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final page in [1, 100, 106]) {
      for (final dark in [false, true]) {
        await showPage(tester, page, dark: dark);
        await expectLater(
          find.byKey(const ValueKey('printed-page')),
          matchesGoldenFile(
            'goldens/qpc_${page}_${dark ? 'dark' : 'light'}.png',
          ),
        );
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('idle prepared layout transfers to the first displayed page', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cache = QpcPageLayoutCache();
    addTearDown(cache.dispose);
    await showPage(tester, 100, layoutCache: cache);
    final next = QpcPageData(
      layout.linesForPage(106),
      'qpcv2_p106',
      'qpcv2_p1',
      layout.basmallahWords,
    );
    final prepared = QpcPageLayout(cache.specFor(next)!);
    cache.store(prepared);
    await showPage(tester, 106, layoutCache: cache);
    final painter =
        tester
                .widget<CustomPaint>(
                  find.byKey(const ValueKey('qpc-page-canvas')),
                )
                .painter!
            as QpcPagePainter;
    expect(painter.layout, same(prepared));
    await expectLater(
      find.byKey(const ValueKey('printed-page')),
      matchesGoldenFile('goldens/qpc_106_light.png'),
    );
    expect(
      cache.specFor(next),
      isNull,
      reason: 'mounted matching layout is already prepared',
    );
    await tester.pumpWidget(const SizedBox.shrink());
    expect(prepared.words.first.painter.debugDisposed, isTrue);
  });

  testWidgets(
    'warm cache keeps one layout and disposes stale viewport and closed work',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cache = QpcPageLayoutCache();
      await showPage(tester, 100, layoutCache: cache);
      final next = QpcPageData.forLoadedPage(layout, fonts, 106)!;
      final oldSpec = cache.specFor(next)!;
      final first = QpcPageLayout(oldSpec);
      cache.store(first);
      final replacement = QpcPageLayout(
        cache.specFor(QpcPageData.forLoadedPage(layout, fonts, 1)!)!,
      );
      cache.store(replacement);
      expect(first.words.first.painter.debugDisposed, isTrue);
      await showPage(
        tester,
        100,
        dark: true,
        scale: 2,
        width: 320,
        layoutCache: cache,
      );
      expect(replacement.words.first.painter.debugDisposed, isTrue);
      final stale = QpcPageLayout(oldSpec);
      cache.store(stale);
      expect(stale.words.first.painter.debugDisposed, isTrue);
      final ready = QpcPageLayout(cache.specFor(next)!);
      cache.store(ready);
      cache.dispose();
      expect(ready.words.first.painter.debugDisposed, isTrue);
      final mounted =
          tester
                  .widget<CustomPaint>(
                    find.byKey(const ValueKey('qpc-page-canvas')),
                  )
                  .painter!
              as QpcPagePainter;
      expect(mounted.layout.words.first.painter.debugDisposed, isFalse);
      final closed = QpcPageLayout(oldSpec);
      cache.store(closed);
      expect(closed.words.first.painter.debugDisposed, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(mounted.layout.words.first.painter.debugDisposed, isTrue);
    },
  );

  testWidgets(
    'font completion prepares the next page after a painted idle frame',
    (tester) async {
      final repository = MushafRepositoryImpl(metadata: metadata);
      // Repository loading spawns an isolate, which cannot finish in fake async.
      await tester.runAsync(repository.load);
      final storage = _ReaderStorage();
      final readerFonts = _LoadedFonts();
      final pending = Completer<void>();
      when(() => storage.savePage(any())).thenAnswer((_) async {});
      when(
        () => readerFonts.isLoaded(any()),
      ).thenAnswer((call) => [1, 2].contains(call.positionalArguments.single));
      when(
        () => readerFonts.ensureLoaded(any()),
      ).thenAnswer((call) async => 'qpcv2_p${call.positionalArguments.single}');
      when(() => readerFonts.prefetch(any())).thenAnswer((_) async {});
      when(() => readerFonts.prefetch(2)).thenAnswer((_) => pending.future);
      serviceLocator.registerSingleton<QpcFontManager>(readerFonts);
      final cubit = ReaderCubit(
        repository: repository,
        storage: storage,
        qpcLayout: layout,
        qpcFonts: readerFonts,
      );
      addTearDown(() async {
        await cubit.close();
        serviceLocator.unregister<QpcFontManager>();
      });
      await cubit.openPage(1);
      await tester.pumpWidget(
        buildArabicTestApp(
          BlocProvider.value(
            value: cubit,
            child: ReaderScreen(
              repository: repository,
              storage: storage,
              metadata: metadata,
              qpcLayout: layout,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(Duration.zero);
      final cache = tester
          .widget<QpcPageView>(find.byType(QpcPageView).first)
          .layoutCache!;
      final next = QpcPageData.forLoadedPage(layout, readerFonts, 2)!;
      expect(cache.specFor(next), isNotNull);
      final animation = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 200),
      )..forward();
      pending.complete();
      expect(
        cache.specFor(next),
        isNotNull,
        reason: 'font readiness alone has not shaped the page',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        cache.specFor(next),
        isNotNull,
        reason: 'shaping waits until animations finish',
      );
      await tester.pumpAndSettle();
      await tester.pump(Duration.zero);
      expect(cache.specFor(next), isNull, reason: 'idle layout is now ready');
      animation.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('words share one canvas with long-press word hit testing', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pressed = <QpcWord>[];
    final semantics = tester.ensureSemantics();
    try {
      for (final page in [1, 100, 106, 604]) {
        await showPage(tester, page, onLongPress: pressed.add);
        final canvas = find.byKey(const ValueKey('qpc-page-canvas'));
        expect(canvas, findsOneWidget);
        final painter =
            tester.widget<CustomPaint>(canvas).painter! as QpcPagePainter;
        for (final word in [
          painter.layout.words.first,
          painter.layout.words.last,
        ]) {
          await tester.longPressAt(
            tester.getTopLeft(canvas) + word.rect.center,
          );
          expect(pressed.last, same(word.word));
        }
        final first = painter.layout.words.first.word;
        final expectedReadingOrder = [
          for (final line in layout.linesForPage(page))
            if (line.lineType == QpcLineType.surahName)
              '${ArabicStrings.surahWord} ${metadata.suraName(line.surahNumber!)}'
            else if (line.lineType == QpcLineType.basmallah)
              ...layout.basmallahWords.map((word) => word.text)
            else
              ...line.words.map((word) => word.text),
        ];
        expect(
          tester.semantics
              .simulatedAccessibilityTraversal()
              .map((node) => node.label)
              .where((label) => label.isNotEmpty),
          expectedReadingOrder,
        );
        if (page == 604) {
          expect(
            find.semantics.byLabel(layout.basmallahWords.first.text).evaluate(),
            hasLength(
              painter.layout.words
                  .where(
                    (word) =>
                        word.word.text == layout.basmallahWords.first.text,
                  )
                  .length,
            ),
          );
        }
        final node = find.semantics.byLabel(first.text).evaluate().first;
        expect(
          node.getSemanticsData().hasAction(SemanticsAction.longPress),
          isTrue,
        );
        tester.semantics.performAction(
          find.semantics.byLabel(first.text).first,
          SemanticsAction.longPress,
        );
        expect(pressed.last, same(first));
        final beforeBlank = pressed.length;
        await tester.longPressAt(
          tester.getTopLeft(canvas) + const Offset(1, 1),
        );
        expect(pressed, hasLength(beforeBlank));
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'scaled narrow pages fit the same source lines and update hit testing',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pressed = <QpcWord>[];
      await showPage(tester, 100, onLongPress: pressed.add);
      for (final page in [100, 106]) {
        await showPage(
          tester,
          page,
          scale: 2,
          width: 320,
          onLongPress: pressed.add,
        );
        final canvas = find.byKey(const ValueKey('qpc-page-canvas'));
        final painter =
            tester.widget<CustomPaint>(canvas).painter! as QpcPagePainter;
        final bounds = Offset.zero & tester.getSize(canvas);
        for (final word in painter.layout.words) {
          expect(bounds.contains(word.rect.center), isTrue);
          expect(word.rect.left, greaterThanOrEqualTo(-0.001));
          expect(word.rect.right, lessThanOrEqualTo(bounds.width + 0.001));
        }
        final middle = painter.layout.words[painter.layout.words.length ~/ 2];
        await tester.longPressAt(
          tester.getTopLeft(canvas) + middle.rect.center,
        );
        expect(pressed.last, same(middle.word));
        await expectLater(
          find.byKey(const ValueKey('printed-page')),
          matchesGoldenFile('goldens/qpc_${page}_320_scaled.png'),
        );
      }
      expect(tester.takeException(), isNull);
    },
  );
}

class _LoadedFonts extends Mock implements QpcFontManager {}

class _ReaderStorage extends Mock implements ReaderStorage {}
