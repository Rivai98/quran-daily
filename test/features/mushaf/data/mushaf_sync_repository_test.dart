import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/storage/local_database.dart';
import 'package:quran_daily/features/mushaf/data/mushaf_remote_data_source.dart';
import 'package:quran_daily/features/mushaf/data/mushaf_sync_repository.dart';
import 'package:quran_daily/features/mushaf/data/reader_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _user = 'user-1';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late LocalDatabase db;
  late _FakeRemote remote;
  late SqfliteReaderStorage storage;
  String? signedIn;
  late MushafSyncRepository sync;

  MushafSyncRepository build(String? Function() user) => MushafSyncRepository(
    remote: remote,
    storeFor: (userId) => SqfliteReaderStorage(database: db, userId: userId),
    currentUserId: user,
    debounce: const Duration(milliseconds: 10),
  );

  setUp(() async {
    db = LocalDatabase();
    await db.open(inMemory: true);
    remote = _FakeRemote();
    storage = SqfliteReaderStorage(database: db, userId: _user);
    signedIn = _user;
    sync = build(() => signedIn);
  });

  tearDown(() async {
    sync.dispose();
    await db.close();
  });

  test('pushes only the newest position, then bookmark writes in order, '
      'and empties the queue', () async {
    final id = ReaderBookmark.newId();
    await storage.savePage(10);
    await storage.savePage(11);
    await storage.addBookmark(ReaderBookmark(id: id, page: 11, surah: 2));
    await storage.removeBookmark(id);

    final report = await sync.sync();

    expect(report.pushed, 3);
    expect(report.pulled, isTrue);
    expect(remote.calls, ['position:11', 'upsert:$id', 'delete:$id']);
    expect(await storage.pendingSyncOperations(), isEmpty);
  });

  test(
    'pull replaces local bookmarks and takes a newer remote position',
    () async {
      final remoteBookmark = ReaderBookmark(
        id: ReaderBookmark.newId(),
        page: 300,
        surah: 18,
        ayah: 1,
        note: 'kahf',
        createdAt: DateTime(2026, 11, 1),
      );
      remote.snapshot = RemoteReaderSnapshot(
        position: RemoteReadingPosition(
          page: 300,
          updatedAt: DateTime.now().add(const Duration(minutes: 1)),
        ),
        bookmarks: [remoteBookmark],
      );

      await sync.sync();

      expect(await storage.lastPage(), 300);
      expect(await storage.bookmarks(), [remoteBookmark]);
      expect(
        await storage.pendingSyncOperations(),
        isEmpty,
        reason: 'merging the server copy must not queue writes back',
      );
    },
  );

  test('an older remote position does not overwrite the local one', () async {
    await storage.savePage(42);
    remote.snapshot = RemoteReaderSnapshot(
      position: RemoteReadingPosition(page: 7, updatedAt: DateTime(2020)),
    );

    await sync.sync();

    expect(await storage.lastPage(), 42);
  });

  test(
    'a network failure stops the pass, keeps the queue, and skips the pull',
    () async {
      await storage.savePage(5);
      await storage.addBookmark(
        ReaderBookmark(id: ReaderBookmark.newId(), page: 5, surah: 2),
      );
      remote.failWith = Exception('SocketException: offline');
      remote.snapshot = const RemoteReaderSnapshot(bookmarks: []);

      final report = await sync.sync();

      expect(report.pushed, 0);
      expect(report.pulled, isFalse);
      expect(await storage.pendingSyncOperations(), hasLength(2));
      expect(await storage.bookmarks(), hasLength(1));
    },
  );

  test(
    'a permanently rejected write is dropped and the pass continues',
    () async {
      final bad = ReaderBookmark(id: 'not-a-uuid', page: 1, surah: 1);
      await storage.addBookmark(bad);
      await storage.savePage(3);
      remote.rejectIds.add(bad.id);

      final report = await sync.sync();

      expect(report.dropped, 1);
      expect(report.pushed, 1);
      expect(report.pulled, isTrue);
      expect(await storage.pendingSyncOperations(), isEmpty);
    },
  );

  test(
    'pull keeps local bookmarks while this user has unsent changes',
    () async {
      final local = ReaderBookmark(
        id: ReaderBookmark.newId(),
        page: 9,
        surah: 2,
      );
      await storage.addBookmark(local);

      await storage.applyRemote(const RemoteReaderSnapshot(bookmarks: []));

      expect((await storage.bookmarks()).single.id, local.id);
    },
  );

  test('leaves queued writes of another account untouched', () async {
    final other = SqfliteReaderStorage(database: db, userId: 'user-2');
    await other.savePage(77);

    final report = await sync.sync();

    expect(report.pushed, 0);
    expect(remote.calls, isEmpty);
    expect(await other.pendingSyncOperations(), hasLength(1));
  });

  test('is skipped without a signed-in user', () async {
    signedIn = null;
    await storage.savePage(2);

    final report = await sync.sync();

    expect(report.skipped, isTrue);
    expect(remote.calls, isEmpty);
  });

  test('concurrent callers share a single pass', () async {
    await storage.savePage(4);
    remote.gate = Completer<void>();

    final first = sync.sync();
    final second = sync.sync();
    remote.gate!.complete();

    expect(identical(await first, await second), isTrue);
    expect(remote.calls, ['position:4']);
  });

  test('schedule() coalesces bursts into one background pass', () async {
    await storage.savePage(1);
    sync.schedule();
    sync.schedule();
    sync.schedule();

    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(remote.fetches, 1);
    expect(remote.calls, ['position:1']);
  });

  test('SyncingReaderStorage schedules after every local write', () async {
    var changes = 0;
    final syncing = SyncingReaderStorage(
      storage,
      onLocalChange: () => changes++,
    );
    final id = ReaderBookmark.newId();

    await syncing.savePage(8);
    await syncing.addBookmark(ReaderBookmark(id: id, page: 8, surah: 2));
    await syncing.removeBookmark(id);
    await syncing.lastPage();
    await syncing.bookmarks();

    expect(changes, 3);
  });

  test('newId produces RFC 4122 v4 uuids', () {
    final ids = List.generate(50, (_) => ReaderBookmark.newId());
    final v4 = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    expect(ids.every(v4.hasMatch), isTrue);
    expect(ids.toSet(), hasLength(50));
  });
}

class _FakeRemote implements MushafRemoteDataSource {
  final calls = <String>[];
  final rejectIds = <String>{};
  RemoteReaderSnapshot snapshot = const RemoteReaderSnapshot();
  Object? failWith;
  Completer<void>? gate;
  int fetches = 0;

  Future<void> _write(String call) async {
    await gate?.future;
    final failure = failWith;
    if (failure != null) throw failure;
    calls.add(call);
  }

  @override
  Future<void> upsertPosition({
    required String userId,
    required int page,
    required DateTime updatedAt,
  }) => _write('position:$page');

  @override
  Future<void> upsertBookmark({
    required String userId,
    required ReaderBookmark bookmark,
  }) {
    if (rejectIds.contains(bookmark.id)) {
      throw const MushafRemoteRejected('22P02: invalid uuid');
    }
    return _write('upsert:${bookmark.id}');
  }

  @override
  Future<void> deleteBookmark(String id) => _write('delete:$id');

  @override
  Future<RemoteReaderSnapshot> fetch(String userId) async {
    fetches++;
    final failure = failWith;
    if (failure != null) throw failure;
    return snapshot;
  }
}
