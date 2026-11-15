import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/design_system/widgets/app_card.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/mushaf/cubit/mushaf_font_download_cubit.dart';
import 'package:quran_daily/features/mushaf/view/mushaf_font_download_section.dart';

import '../../../helpers/widget_test_app.dart';

class _MockCubit extends MockCubit<MushafFontDownloadState>
    implements MushafFontDownloadCubit {}

const _mb = 1024 * 1024;
const _total = 208 * _mb;

const _nothingSaved = MushafFontDownloadState(totalBytes: _total);
const _partial = MushafFontDownloadState(
  totalBytes: _total,
  cachedBytes: 9 * _mb,
);
const _complete = MushafFontDownloadState(
  status: MushafFontDownloadStatus.complete,
  completedPages: 604,
  totalBytes: _total,
  cachedBytes: _total,
);
const _downloading = MushafFontDownloadState(
  status: MushafFontDownloadStatus.downloading,
  completedPages: 302,
  totalBytes: _total,
  cachedBytes: 100 * _mb,
);

Widget _host(MushafFontDownloadCubit cubit) => Scaffold(
  body: ListView(
    padding: const EdgeInsets.all(16),
    children: [
      // Settings places the section inside its reading card.
      AppCard(
        child: BlocProvider<MushafFontDownloadCubit>.value(
          value: cubit,
          child: const MushafFontDownloadSection(),
        ),
      ),
    ],
  ),
);

Future<_MockCubit> _pump(
  WidgetTester tester,
  MushafFontDownloadState state, {
  bool dark = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(360, 800);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final cubit = _MockCubit();
  when(() => cubit.state).thenReturn(state);
  when(cubit.downloadAll).thenAnswer((_) async {});
  when(cubit.deleteCache).thenAnswer((_) async {});
  await tester.pumpWidget(
    buildArabicTestApp(_host(cubit), dark: dark, size: const Size(360, 800)),
  );
  await tester.pumpAndSettle();
  return cubit;
}

/// Every label inside a button renders on one line.
void _expectSingleLineButtonLabels(WidgetTester tester, String reason) {
  final labels = find.descendant(
    of: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    matching: find.byType(RichText),
  );
  for (final element in labels.evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    final lineHeight = paragraph.getFullHeightForCaret(
      const TextPosition(offset: 0),
    );
    expect(
      (paragraph.size.height / lineHeight).round(),
      1,
      reason: '$reason: "${paragraph.text.toPlainText()}" wraps',
    );
  }
}

void main() {
  setUpAll(loadArabicUiFontsForGoldenTests);

  testWidgets('no nested card and one short primary action at 360dp', (
    tester,
  ) async {
    for (final dark in [false, true]) {
      final mode = dark ? 'dark' : 'light';
      await _pump(tester, _nothingSaved, dark: dark);
      expect(find.byType(AppCard), findsOneWidget, reason: mode);
      expect(find.text(ArabicStrings.mushafOfflineTitle), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget, reason: mode);
      expect(find.text(ArabicStrings.mushafDownloadAction), findsOneWidget);
      // Nothing saved yet: nothing to delete.
      expect(find.text(ArabicStrings.mushafDeleteSaved), findsNothing);
      _expectSingleLineButtonLabels(tester, mode);
      expect(tester.takeException(), isNull, reason: mode);
    }
  });

  testWidgets('partial download offers resume, delete and a size status', (
    tester,
  ) async {
    final cubit = await _pump(tester, _partial);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.text(ArabicStrings.mushafResumeDownload), findsOneWidget);
    expect(find.text(ArabicStrings.mushafDeleteSaved), findsOneWidget);
    expect(find.text(ArabicStrings.mushafSavedOf(9, 208)), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    _expectSingleLineButtonLabels(tester, 'partial');

    await tester.tap(find.text(ArabicStrings.mushafResumeDownload));
    verify(cubit.downloadAll).called(1);
    await tester.tap(find.text(ArabicStrings.mushafDeleteSaved));
    verify(cubit.deleteCache).called(1);
  });

  testWidgets('complete download shows the saved status and no primary', (
    tester,
  ) async {
    await _pump(tester, _complete, dark: true);
    expect(find.text(ArabicStrings.mushafSavedOnDevice), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.text(ArabicStrings.mushafDeleteSaved), findsOneWidget);
    _expectSingleLineButtonLabels(tester, 'complete');
  });

  testWidgets('downloading shows progress, percent and cancel', (
    tester,
  ) async {
    final cubit = await _pump(tester, _downloading);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text(ArabicStrings.mushafDownloadingPercent(50)), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.text(ArabicStrings.mushafDeleteSaved), findsNothing);
    await tester.tap(find.text(ArabicStrings.mushafCancelDownload));
    verify(cubit.cancel).called(1);
    _expectSingleLineButtonLabels(tester, 'downloading');
  });

  testWidgets('golden: offline section at 360dp in light and dark', (
    tester,
  ) async {
    await _pump(tester, _partial);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/mushaf_font_download_light.png'),
    );
    await _pump(tester, _partial, dark: true);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/mushaf_font_download_dark.png'),
    );
  });
}
