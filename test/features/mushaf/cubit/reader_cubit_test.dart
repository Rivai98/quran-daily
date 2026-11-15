import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/quran/mushaf/mushaf_models.dart';
import 'package:quran_daily/core/quran/mushaf/mushaf_repository.dart';
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

  test(
    'completion on the end page calls completion once and updates state',
    () async {
      await cubit.openPortion(PortionUnit.juz, 1, assignmentId: 'assignment');
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

    test('free reading queues a sync for each saved position', () async {
      await syncingCubit.openPage(1);
      await syncingCubit.turnTo(2);
      expect(storage.savedPage, 2);
      expect(scheduled, 2);
    });

    test('opens the last position pulled into local storage', () async {
      storage.savedPage = 2;
      await syncingCubit.openLastPosition();
      expect(syncingCubit.state.page?.number, 2);
    });

    test('portion reading does not overwrite the free-reading position',
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
    });
  });
}

class _Repository implements MushafRepository {
  _Repository(this.ayahs);

  final List<MushafAyah> ayahs;

  @override
  Future<void> load() async {}

  @override
  int get pageCount => 2;

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
  ) => (start: ayahs.first.ref, end: ayahs[1].ref, startPage: 2, endPage: 2);

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
