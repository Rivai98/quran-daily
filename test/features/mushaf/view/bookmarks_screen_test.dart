import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/localization/arabic_numerals.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/mushaf/data/reader_storage.dart';
import 'package:quran_daily/features/mushaf/view/bookmarks_screen.dart';
import '../../../helpers/widget_test_app.dart';

void main() {
  testWidgets('bookmark list opens its page across accessibility variants', (
    tester,
  ) async {
    for (final variant in testVariants) {
      tester.view.physicalSize = variant.size;
      tester.view.devicePixelRatio = 1;
      var openedPage = 0;
      await tester.pumpWidget(
        buildArabicTestApp(
          BookmarksScreen(
            storage: _Storage(),
            onOpenPage: (page) => openedPage = page,
          ),
          dark: variant.dark,
          textScale: variant.textScale,
          size: variant.size,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          '${ArabicStrings.pageNumberLabel} ${ArabicNumerals.format(8)}',
        ),
        findsOneWidget,
        reason: variant.name,
      );
      await tester.tap(
        find.text(
          '${ArabicStrings.pageNumberLabel} ${ArabicNumerals.format(8)}',
        ),
      );
      expect(openedPage, 8, reason: variant.name);
      await tester.pumpWidget(const SizedBox.shrink());
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('license page credits both data sources', (tester) async {
    await tester.pumpWidget(buildArabicTestApp(const MushafLicensesScreen()));
    expect(find.text(ArabicStrings.kfgqpcAttribution), findsOneWidget);
    expect(find.text(ArabicStrings.tanzilAttribution), findsOneWidget);
  });
}

class _Storage implements ReaderStorage {
  @override
  Future<int?> lastPage() async => 1;

  @override
  Future<void> savePage(int page) async {}

  @override
  Future<List<ReaderBookmark>> bookmarks() async => const [
    ReaderBookmark(id: 'saved', page: 8, note: 'note'),
  ];

  @override
  Future<void> addBookmark(ReaderBookmark bookmark) async {}

  @override
  Future<void> removeBookmark(String id) async {}

  @override
  Future<List<ReaderSyncOperation>> pendingSyncOperations() async => [];

  @override
  Future<void> markSyncOperationComplete(String id) async {}
}
