import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/quran/mushaf/mushaf_models.dart';
import 'package:quran_daily/core/quran/mushaf/mushaf_repository.dart';
import 'package:quran_daily/core/quran/mushaf/qpc_v2_repository.dart';
import 'package:quran_daily/core/quran/portion_unit.dart';
import 'package:quran_daily/features/mushaf/cubit/reader_cubit.dart';
import 'package:quran_daily/features/mushaf/data/mushaf_sync_repository.dart';
import 'package:quran_daily/features/mushaf/data/reader_storage.dart';

import '../mushaf_test_fixtures.dart';

void main() {
  late _Repository repository;
  late _Storage storage;
  late ReaderCubit cubit;
  var completed = 0;
  late List<MushafAyah> fixtureAyahs;

  setUp(() async {
    fixtureAyahs = await readMushafFixtureAyahs();
    repository = _Repository(fixtureAyahs);
    storage = _Storage();
    completed = 0;
    cubit = ReaderCubit(
      repository: repository,
      storage: storage,
      onComplete: () async {
        completed++;
        return false;
      },
    );
  });

  tearDown(() => cubit.close());

  test('turning does not prefetch until the current page settles', () async {
    final fonts = _Fonts();
    final requested = <int>[];
    when(() => fonts.prefetch(any())).thenAnswer((call) async {
      requested.add(call.positionalArguments.single as int);
    });
    final reader = ReaderCubit(
      repository: repository,
      storage: storage,
      qpcFonts: fonts,
    );
    addTearDown(reader.close);
    await reader.openPage(5);
    await reader.turnTo(6);
    expect(requested, isEmpty);
    await reader.prefetchSettledPage(5);
    expect(requested, isEmpty, reason: 'obsolete settle signal is ignored');
    await reader.prefetchSettledPage(6);
    expect(requested, [7]);
  });

  test(
    'rapid reversal waits for stale work and prepares only the new direction',
    () async {
      final fonts = _Fonts();
      final requested = <int>[];
      final prepared = <int>[];
      final pending = Completer<void>();
      when(() => fonts.isLoaded(any())).thenReturn(true);
      when(() => fonts.prefetch(any())).thenAnswer((call) {
        requested.add(call.positionalArguments.single as int);
        return requested.length == 1 ? pending.future : Future.value();
      });
      final reader = ReaderCubit(
        repository: repository,
        storage: storage,
        qpcFonts: fonts,
      );
      addTearDown(reader.close);
      await reader.openPage(5);
      await reader.turnTo(6);
      final first = reader.prefetchSettledPage(6, onPrepared: prepared.add);
      expect(requested, [7]);
      reader.pageTurnStarted();
      await reader.turnTo(5);
      await reader.prefetchSettledPage(5, onPrepared: prepared.add);
      await reader.prefetchSettledPage(6);
      expect(requested, [7], reason: 'only one background operation may run');
      pending.complete();
      await first;
      expect(requested, [7, 4]);
      expect(reader.state.page?.number, 5);
      expect(prepared, [
        4,
      ], reason: 'stale completion cannot warm the old direction');
    },
  );

  test('settled prefetch respects both portion boundaries', () async {
    final fonts = _Fonts();
    final requested = <int>[];
    when(() => fonts.prefetch(any())).thenAnswer((call) async {
      requested.add(call.positionalArguments.single as int);
    });
    final reader = ReaderCubit(
      repository: repository,
      storage: storage,
      qpcFonts: fonts,
    );
    addTearDown(reader.close);
    await reader.openPortion(PortionUnit.hizb, 1, assignmentId: 'portion');
    expect(
      requested,
      isEmpty,
      reason: 'opening does not eagerly warm the portion',
    );
    await reader.turnTo(5);
    await reader.prefetchSettledPage(5);
    expect(requested, isEmpty);
    await reader.turnTo(4);
    await reader.prefetchSettledPage(4);
    await reader.turnTo(3);
    await reader.prefetchSettledPage(3);
    expect(requested, [3]);
  });

  test('closing clears a queued direction while an uncancelable operation finishes', () async {
    final fonts = _Fonts();
    final requested = <int>[];
    final prepared = <int>[];
    final pending = Completer<void>();
    when(() => fonts.isLoaded(any())).thenReturn(true);
    when(() => fonts.prefetch(any())).thenAnswer((call) {
      requested.add(call.positionalArguments.single as int);
      return pending.future;
    });
    final reader = ReaderCubit(
      repository: repository,
      storage: storage,
      qpcFonts: fonts,
    );
    await reader.openPage(5);
    final active = reader.prefetchSettledPage(5, onPrepared: prepared.add);
    await reader.turnTo(4);
    await reader.prefetchSettledPage(4);
    await reader.close();
    pending.complete();
    await active;
    expect(requested, [6]);
    expect(
      prepared,
      isEmpty,
      reason: 'closed readers cannot publish layout work',
    );
  });

  test('opens a requested page and saves the last position', () async {
    await cubit.openPage(2);
    expect(cubit.state.page?.number, 2);
    expect(storage.savedPage, 2);
  });

  test('opens portion start and exposes start/end highlights', () async {
    await cubit.openPortion(PortionUnit.juz, 1, assignmentId: 'assignment');
    expect(cubit.state.page?.number, 2);
    expect(cubit.state.startAyah, fixtureAyahs.first.ref);
    expect(cubit.state.endAyah, fixtureAyahs[1].ref);
    expect(cubit.state.isEndPage, isTrue);
  });

  test('portion page turns stay inside the selected portion range', () async {
    await cubit.openPortion(PortionUnit.hizb, 1, assignmentId: 'assignment');
    expect(cubit.state.page?.number, 3);

    await cubit.turnTo(2);
    expect(cubit.state.page?.number, 3);
    await cubit.turnTo(4);
    expect(cubit.state.page?.number, 4);
    await cubit.turnTo(6);
    expect(cubit.state.page?.number, 4);
  });

  test(
    'completion on the end page calls completion once and updates state',
    () async {
      await cubit.openPortion(PortionUnit.juz, 1, assignmentId: 'assignment');
      cubit.showCompletionPage();
      await cubit.completePortion();
      expect(completed, 1);
      expect(cubit.state.isCompleted, isTrue);
    },
  );

  test('completed portions do not offer a second completion action', () async {
    await cubit.openPortion(
      PortionUnit.juz,
      1,
      assignmentId: 'assignment',
      alreadyCompleted: true,
    );
    expect(cubit.state.isCompleted, isTrue);
    expect(cubit.state.canComplete, isFalse);
  });

  test(
    'records offline-queued completion as complete and pending sync',
    () async {
      await cubit.close();
      cubit = ReaderCubit(
        repository: repository,
        storage: storage,
        onComplete: () async => true,
      );
      await cubit.openPortion(PortionUnit.juz, 1, assignmentId: 'assignment');
      cubit.showCompletionPage();
      await cubit.completePortion();
      expect(cubit.state.isCompleted, isTrue);
      expect(cubit.state.isOffline, isTrue);
    },
  );

  group('with a syncing storage', () {
    late int scheduled;
    late ReaderCubit syncingCubit;

    setUp(() {
      scheduled = 0;
      syncingCubit = ReaderCubit(
        repository: repository,
        storage: SyncingReaderStorage(
          storage,
          onLocalChange: () => scheduled++,
        ),
      );
    });

    tearDown(() => syncingCubit.close());

    testWidgets('rapid turns save and sync only after 600 ms of idle', (
      tester,
    ) async {
      await syncingCubit.openPage(1);
      await syncingCubit.turnTo(2);
      await tester.pump(const Duration(milliseconds: 400));
      syncingCubit.pageScrollStarted();
      await syncingCubit.turnTo(3);
      await tester.pump(const Duration(seconds: 1));
      expect(storage.savedPage, 1, reason: 'a held drag is not idle');
      syncingCubit.pageScrollEnded();
      await tester.pump(const Duration(milliseconds: 599));
      expect(storage.savedPage, 1);
      expect(scheduled, 1);
      await tester.pump(const Duration(milliseconds: 1));
      expect(storage.savedPage, 3);
      expect(scheduled, 2);
    });

    test('closing flushes the latest page before the idle delay', () async {
      await syncingCubit.openPage(1);
      await syncingCubit.turnTo(2);
      expect(storage.savedPage, 1);
      await syncingCubit.close();
      expect(storage.savedPage, 2);
      expect(scheduled, 2);
    });

    testWidgets(
      'slow position writes finish in order and closing awaits the latest',
      (tester) async {
        final delayed = _PositionStorage();
        final pending = Completer<void>();
        final written = <int>[];
        when(() => delayed.savePage(any())).thenAnswer((call) async {
          final page = call.positionalArguments.single as int;
          if (page == 2) await pending.future;
          written.add(page);
        });
        final reader = ReaderCubit(repository: repository, storage: delayed);
        await reader.openPage(1);
        await reader.turnTo(2);
        await tester.pump(const Duration(milliseconds: 600));
        await reader.turnTo(3);
        await tester.pump(const Duration(milliseconds: 600));
        expect(written, [1]);
        final closing = reader.close();
        pending.complete();
        await closing;
        expect(written, [1, 2, 3]);
      },
    );

    test('opens the last position pulled into local storage', () async {
      storage.savedPage = 2;
      await syncingCubit.openLastPosition();
      expect(syncingCubit.state.page?.number, 2);
    });

    test(
      'portion reading does not overwrite the free-reading position',
      () async {
        storage.savedPage = 1;
        await syncingCubit.openPortion(
          PortionUnit.juz,
          1,
          assignmentId: 'assignment',
        );
        await syncingCubit.turnTo(1);
        expect(storage.savedPage, 1);
        expect(scheduled, 0);
      },
    );
  });
}

// The font manager is the platform/network boundary; no font work runs in Cubit tests.
class _Fonts extends Mock implements QpcFontManager {}

class _PositionStorage extends Mock implements ReaderStorage {}

class _Repository implements MushafRepository {
  _Repository(this.ayahs);

  final List<MushafAyah> ayahs;

  @override
  Future<void> load() async {}

  @override
  int get pageCount => 10;

  @override
  MushafPage page(int number) => MushafPage(
    number: number,
    ayahs: ayahs,
    juz: 0,
    firstSurah: ayahs.first.ref.surah,
  );

  @override
  int pageOf(AyahRef ref) => 2;

  @override
  ({AyahRef start, AyahRef end, int startPage, int endPage}) portionRange(
    PortionUnit unit,
    int index,
  ) => (
    start: ayahs.first.ref,
    end: ayahs[1].ref,
    startPage: unit == PortionUnit.hizb ? 3 : 2,
    endPage: unit == PortionUnit.hizb ? 5 : 2,
  );

  @override
  List<({int surah, String name, int ayahs, int startPage})> surahIndex() => [];

  @override
  List<({int juz, int startPage})> juzIndex() => [];

  @override
  List<({int hizb, int startPage})> hizbIndex() => [];
}

class _Storage implements ReaderStorage {
  int? savedPage;

  @override
  Future<int?> lastPage() async => savedPage;

  @override
  Future<void> savePage(int page) async => savedPage = page;

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
