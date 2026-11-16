import 'package:material_ui/material_ui.dart';
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

  testWidgets('renders surah and ayah metadata when present on bookmark', (
    tester,
  ) async {
    final storage = _DetailedStorage();
    await tester.pumpWidget(
      buildArabicTestApp(BookmarksScreen(storage: storage, onOpenPage: (_) {})),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        '${ArabicStrings.pageNumberLabel} ${ArabicNumerals.format(12)}',
      ),
      findsOneWidget,
    );
    expect(find.byType(PopupMenuButton<String>), findsOneWidget);
  });

  testWidgets('renders StatePanel when bookmarks are empty', (tester) async {
    final storage = _EmptyStorage();
    await tester.pumpWidget(
      buildArabicTestApp(BookmarksScreen(storage: storage, onOpenPage: (_) {})),
    );
    await tester.pumpAndSettle();

    expect(find.text(ArabicStrings.bookmarksEmpty), findsOneWidget);
    expect(find.text(ArabicStrings.bookmarksEmptyHint), findsOneWidget);
  });

  testWidgets(
    'license page credits both data sources with cards, versions and links',
    (tester) async {
      await tester.pumpWidget(buildArabicTestApp(const MushafLicensesScreen()));
      expect(find.text(ArabicStrings.kfgqpcAttribution), findsOneWidget);
      expect(find.text(ArabicStrings.tanzilAttribution), findsOneWidget);
      expect(find.text(ArabicStrings.kfgqpcSourceName), findsOneWidget);
      expect(find.text(ArabicStrings.tanzilSourceName), findsOneWidget);
      expect(find.text(ArabicStrings.kfgqpcVersion), findsOneWidget);
      expect(find.text(ArabicStrings.tanzilVersion), findsOneWidget);
      expect(find.text(ArabicStrings.kfgqpcLink), findsOneWidget);
      expect(find.text(ArabicStrings.tanzilLink), findsOneWidget);
    },
  );
}

class _EmptyStorage implements ReaderStorage {
  @override
  Future<int?> lastPage() async => 1;

  @override
  Future<void> savePage(int page) async {}

  @override
  Future<List<ReaderBookmark>> bookmarks() async => const [];

  @override
  Future<void> addBookmark(ReaderBookmark bookmark) async {}

  @override
  Future<void> removeBookmark(String id) async {}

  @override
  Future<List<ReaderSyncOperation>> pendingSyncOperations() async => [];

  @override
  Future<void> markSyncOperationComplete(String id) async {}
}

class _DetailedStorage implements ReaderStorage {
  @override
  Future<int?> lastPage() async => 1;

  @override
  Future<void> savePage(int page) async {}

  @override
  Future<List<ReaderBookmark>> bookmarks() async => [
    ReaderBookmark(
      id: 'bm-1',
      page: 12,
      surah: 2,
      ayah: 75,
      note: 'ملاحظة تدبر',
      createdAt: DateTime(2026, 11, 15),
    ),
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
