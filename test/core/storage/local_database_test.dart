import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/storage/daos/daos.dart';
import 'package:quran_daily/core/sync/sync_operation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late LocalDatabase db;
  late CachedSnapshotsDao snapshots;
  late CachedGroupsDao groups;
  late CachedHistoryDao history;
  late SyncQueueDao queue;

  setUp(() async {
    db = LocalDatabase();
    await db.open(inMemory: true);
    snapshots = CachedSnapshotsDao(db);
    groups = CachedGroupsDao(db);
    history = CachedHistoryDao(db);
    queue = SyncQueueDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('v1 creates exactly the four contracted tables', () async {
    final tables = await db.tableNames();
    expect(tables, containsAll(<String>[
      'cached_snapshots',
      'cached_groups',
      'cached_history',
      'sync_queue',
    ]));
  });

  group('cached_snapshots', () {
    test('upsert then read returns the same JSON and refreshed cached_at',
        () async {
      await snapshots.upsert('g1', {'k': 'v1'});
      await snapshots.upsert('g1', {'k': 'v2'});

      final row = await snapshots.read('g1');
      expect(row, isNotNull);
      expect(row!.json['k'], 'v2');
      expect(row.cachedAt, isNotNull);
      expect(await snapshots.read('missing'), isNull);
    });
  });

  group('cached_groups', () {
    test('stores per user and replaces the row', () async {
      await groups.upsert('u1', {'groups': <String>[]});
      await groups.upsert('u1', {'groups': <String>['a']});
      await groups.upsert('u2', {'groups': <String>['b']});

      final u1 = await groups.read('u1');
      final u2 = await groups.read('u2');
      expect(u1!.json['groups'], ['a']);
      expect(u2!.json['groups'], ['b']);
    });
  });

  group('cached_history', () {
    test('stores the last page per group', () async {
      await history.upsert('g1', {'page': 1});
      await history.upsert('g1', {'page': 2});
      expect((await history.read('g1'))!.json['page'], 2);
    });
  });

  group('sync_queue', () {
    test('enqueues in order, updates status/attempts, deletes on success',
        () async {
      final a = SyncOperation(
        id: 'op1',
        type: SyncOperationType.markComplete,
        assignmentId: 'as1',
        clientRecordedAt:
            DateTime.fromMillisecondsSinceEpoch(1000),
      );
      final b = SyncOperation(
        id: 'op2',
        type: SyncOperationType.undoCompletion,
        assignmentId: 'as1',
        clientRecordedAt:
            DateTime.fromMillisecondsSinceEpoch(2000),
      );
      await queue.enqueue(a);
      await queue.enqueue(b);

      final pending = await queue.pending();
      expect(pending.map((e) => e.id), ['op1', 'op2'],
          reason: 'creation order must be preserved for replay');

      await queue.update('op1',
          status: SyncOperationStatus.syncing, attempts: 1);
      await queue.update('op1',
          status: SyncOperationStatus.failed,
          attempts: 2,
          lastErrorKind: 'day_closed');

      final afterFail = await queue.pending();
      expect(afterFail.map((e) => e.id), ['op1', 'op2'],
          reason: 'failed op1 stays queued for retry before pending op2');
      expect(afterFail.first.attempts, 2);
      expect(afterFail.first.lastErrorKind, 'day_closed');

      await queue.delete('op1');
      expect((await queue.pending()).map((e) => e.id), ['op2']);
    });

  });
}
