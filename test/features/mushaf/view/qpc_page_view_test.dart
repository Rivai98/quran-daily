import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/quran/mushaf/mushaf_models.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/core/quran/mushaf/qpc_v2_repository.dart';
import 'package:quran_daily/core/quran/quran_metadata_repository.dart';
import 'package:quran_daily/features/mushaf/view/widgets/qpc_page_view.dart';
import 'package:quran_daily/features/mushaf/view/widgets/qpc_page_painter.dart';
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
    for (final page in [1, 100, 106, 604]) {
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
