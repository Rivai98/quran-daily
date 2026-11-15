import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../sync/sync_operation.dart';
import '../local_database.dart';

export '../local_database.dart' show LocalDatabase;

/// `cached_snapshots`: dashboard JSON per group for offline reads.
class CachedSnapshotsDao {
  CachedSnapshotsDao(this._db);

  final LocalDatabase _db;

  Future<void> upsert(String groupId, Map<String, Object?> json) async {
    final db = await _db.database;
    await db.insert('cached_snapshots', {
      'group_id': groupId,
      'json': jsonEncode(json),
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<({Map<String, Object?> json, DateTime cachedAt})?> read(
    String groupId,
  ) async {
    final db = await _db.database;
    final rows = await db.query(
      'cached_snapshots',
      where: 'group_id = ?',
      whereArgs: [groupId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return (
      json: (jsonDecode(rows.first['json']! as String) as Map)
          .cast<String, Object?>(),
      cachedAt: DateTime.fromMillisecondsSinceEpoch(
        rows.first['cached_at']! as int,
      ),
    );
  }

  Future<List<({String groupId, Map<String, Object?> json, DateTime cachedAt})>>
  readAll() async {
    final db = await _db.database;
    final rows = await db.query('cached_snapshots', orderBy: 'cached_at desc');
    return rows
        .map(
          (row) => (
            groupId: row['group_id']! as String,
            json: (jsonDecode(row['json']! as String) as Map)
                .cast<String, Object?>(),
            cachedAt: DateTime.fromMillisecondsSinceEpoch(
              row['cached_at']! as int,
            ),
          ),
        )
        .toList();
  }
}

/// `cached_groups`: my-groups overview JSON per user.
class CachedGroupsDao {
  CachedGroupsDao(this._db);

  final LocalDatabase _db;

  Future<void> upsert(String userId, Map<String, Object?> json) async {
    final db = await _db.database;
    await db.insert('cached_groups', {
      'user_id': userId,
      'json': jsonEncode(json),
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<({Map<String, Object?> json, DateTime cachedAt})?> read(
    String userId,
  ) async {
    final db = await _db.database;
    final rows = await db.query(
      'cached_groups',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return (
      json: (jsonDecode(rows.first['json']! as String) as Map)
          .cast<String, Object?>(),
      cachedAt: DateTime.fromMillisecondsSinceEpoch(
        rows.first['cached_at']! as int,
      ),
    );
  }
}

/// `cached_history`: last history page per group.
class CachedHistoryDao {
  CachedHistoryDao(this._db);

  final LocalDatabase _db;

  Future<void> upsert(String groupId, Map<String, Object?> json) async {
    final db = await _db.database;
    await db.insert('cached_history', {
      'group_id': groupId,
      'json': jsonEncode(json),
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<({Map<String, Object?> json, DateTime cachedAt})?> read(
    String groupId,
  ) async {
    final db = await _db.database;
    final rows = await db.query(
      'cached_history',
      where: 'group_id = ?',
      whereArgs: [groupId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return (
      json: (jsonDecode(rows.first['json']! as String) as Map)
          .cast<String, Object?>(),
      cachedAt: DateTime.fromMillisecondsSinceEpoch(
        rows.first['cached_at']! as int,
      ),
    );
  }
}

class CachedTodayDao {
  CachedTodayDao(this._db);
  final LocalDatabase _db;
  Future<void> upsert(String userId, Map<String, Object?> json) async {
    final db = await _db.database;
    await db.insert('cached_today', {'user_id': userId, 'json': jsonEncode(json), 'cached_at': DateTime.now().millisecondsSinceEpoch}, conflictAlgorithm: ConflictAlgorithm.replace);
  }
  Future<({Map<String, Object?> json, DateTime cachedAt})?> read(String userId) async {
    final db = await _db.database;
    final rows = await db.query('cached_today', where: 'user_id = ?', whereArgs: [userId], limit: 1);
    if (rows.isEmpty) return null;
    return (json: (jsonDecode(rows.first['json']! as String) as Map).cast<String, Object?>(), cachedAt: DateTime.fromMillisecondsSinceEpoch(rows.first['cached_at']! as int));
  }
}

/// `sync_queue`: ordered personal completion operations.
class SyncQueueDao {
  SyncQueueDao(this._db);

  final LocalDatabase _db;

  Future<void> enqueue(SyncOperation op) async {
    final db = await _db.database;
    await db.insert('sync_queue', {
      'id': op.id,
      'op': op.type.name,
      'assignment_id': op.assignmentId,
      'client_recorded_at': op.clientRecordedAt.millisecondsSinceEpoch,
      'status': op.status.name,
      'attempts': op.attempts,
      'last_error_kind': op.lastErrorKind,
      'created_at': (op.createdAt ?? DateTime.now()).millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Pending + failed rows in creation order (replay order matters).
  Future<List<SyncOperation>> pending() async {
    final db = await _db.database;
    final rows = await db.query(
      'sync_queue',
      where: "status in ('pending', 'failed')",
      orderBy: 'created_at asc, rowid asc',
    );
    return rows.map(_fromRow).toList();
  }

  Future<void> update(
    String id, {
    SyncOperationStatus? status,
    int? attempts,
    String? lastErrorKind,
  }) async {
    final db = await _db.database;
    final values = <String, Object?>{
      'status': ?status?.name,
      'attempts': ?attempts,
      'last_error_kind': ?lastErrorKind,
    };
    if (values.isEmpty) return;
    await db.update('sync_queue', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  SyncOperation _fromRow(Map<String, Object?> row) {
    return SyncOperation(
      id: row['id']! as String,
      type: (row['op']! as String) == 'markComplete'
          ? SyncOperationType.markComplete
          : SyncOperationType.undoCompletion,
      assignmentId: row['assignment_id']! as String,
      clientRecordedAt: DateTime.fromMillisecondsSinceEpoch(
        row['client_recorded_at']! as int,
      ),
      status: _statusOf(row['status']! as String),
      attempts: row['attempts']! as int,
      lastErrorKind: row['last_error_kind'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
    );
  }

  SyncOperationStatus _statusOf(String raw) {
    switch (raw) {
      case 'syncing':
        return SyncOperationStatus.syncing;
      case 'failed':
        return SyncOperationStatus.failed;
      default:
        return SyncOperationStatus.pending;
    }
  }
}
