import 'dart:convert';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/storage/local_database.dart';

class ReaderBookmark extends Equatable {
  const ReaderBookmark({
    required this.id,
    required this.page,
    this.surah,
    this.ayah,
    this.note,
    this.createdAt,
  });

  /// Random RFC 4122 v4 id; the server's `bookmarks.id` is a uuid.
  static String newId([Random? random]) {
    final rng = random ?? Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  final String id;
  final int page;
  final int? surah;
  final int? ayah;
  final String? note;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, page, surah, ayah, note, createdAt];
}

class ReaderSyncOperation extends Equatable {
  const ReaderSyncOperation({
    required this.id,
    required this.operation,
    required this.payload,
    required this.createdAt,
  });

  final String id;
  final String operation;
  final Map<String, Object?> payload;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, operation, payload, createdAt];
}

/// The account's last free-reading page as stored on the server.
class RemoteReadingPosition extends Equatable {
  const RemoteReadingPosition({required this.page, required this.updatedAt});

  final int page;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [page, updatedAt];
}

/// Everything the server holds for the signed-in reader.
class RemoteReaderSnapshot extends Equatable {
  const RemoteReaderSnapshot({this.position, this.bookmarks = const []});

  final RemoteReadingPosition? position;
  final List<ReaderBookmark> bookmarks;

  @override
  List<Object?> get props => [position, bookmarks];
}

/// Sync-side view of the local reader store (used by the Mushaf sync
/// repository only; screens and cubits use [ReaderStorage]).
abstract interface class ReaderSyncStore {
  String get userId;
  Future<List<ReaderSyncOperation>> pendingSyncOperations();
  Future<void> markSyncOperationComplete(String id);

  /// Replaces local state with the server's, without queueing writes.
  /// Skipped while this user still has unsent local changes, so a pull
  /// never overwrites work that has not reached the server yet. The
  /// position is only taken when it is newer than the local one.
  Future<void> applyRemote(RemoteReaderSnapshot snapshot);
}

abstract class ReaderStorage {
  Future<int?> lastPage();
  Future<void> savePage(int page);
  Future<List<ReaderBookmark>> bookmarks();
  Future<void> addBookmark(ReaderBookmark bookmark);
  Future<void> removeBookmark(String id);
  Future<List<ReaderSyncOperation>> pendingSyncOperations();
  Future<void> markSyncOperationComplete(String id);
}

/// Offline-first reader state backed by SQLite. Writes are recorded for sync.
class SqfliteReaderStorage implements ReaderStorage, ReaderSyncStore {
  SqfliteReaderStorage({required LocalDatabase database, required this.userId})
    : _database = database;

  final LocalDatabase _database;
  @override
  final String userId;

  @override
  Future<int?> lastPage() async {
    final db = await _database.database;
    final rows = await db.query(
      'reading_positions',
      columns: ['page'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['page']! as int;
  }

  @override
  Future<void> savePage(int page) async {
    final db = await _database.database;
    final updatedAt = DateTime.now().millisecondsSinceEpoch;
    await db.insert('reading_positions', {
      'user_id': userId,
      'page': page,
      'updated_at': updatedAt,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await _enqueue(db, 'position_upsert', {
      'user_id': userId,
      'page': page,
      'updated_at': updatedAt,
    });
  }

  @override
  Future<List<ReaderBookmark>> bookmarks() async {
    final db = await _database.database;
    final rows = await db.query(
      'bookmarks',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at desc',
    );
    return rows
        .map(
          (row) => ReaderBookmark(
            id: row['id']! as String,
            page: row['page']! as int,
            surah: row['surah'] as int?,
            ayah: row['ayah'] as int?,
            note: row['note'] as String?,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              row['created_at']! as int,
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> addBookmark(ReaderBookmark bookmark) async {
    final db = await _database.database;
    final createdAt =
        (bookmark.createdAt ?? DateTime.now()).millisecondsSinceEpoch;
    final row = <String, Object?>{
      'id': bookmark.id,
      'user_id': userId,
      'page': bookmark.page,
      'surah': bookmark.surah,
      'ayah': bookmark.ayah,
      'note': bookmark.note,
      'created_at': createdAt,
    };
    await db.insert(
      'bookmarks',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _enqueue(db, 'bookmark_upsert', row);
  }

  @override
  Future<void> removeBookmark(String id) async {
    final db = await _database.database;
    await db.delete(
      'bookmarks',
      where: 'id = ? and user_id = ?',
      whereArgs: [id, userId],
    );
    await _enqueue(db, 'bookmark_delete', {'id': id, 'user_id': userId});
  }

  @override
  Future<List<ReaderSyncOperation>> pendingSyncOperations() async {
    final db = await _database.database;
    final rows = await db.query('mushaf_sync_queue', orderBy: 'created_at asc');
    return rows
        .map(
          (row) => ReaderSyncOperation(
            id: row['id']! as String,
            operation: row['operation']! as String,
            payload: (jsonDecode(row['payload']! as String) as Map)
                .cast<String, Object?>(),
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              row['created_at']! as int,
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> markSyncOperationComplete(String id) async {
    final db = await _database.database;
    await db.delete('mushaf_sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> applyRemote(RemoteReaderSnapshot snapshot) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      final queued = await txn.query('mushaf_sync_queue', columns: ['payload']);
      final hasPending = queued.any(
        (row) =>
            (jsonDecode(row['payload']! as String) as Map)['user_id'] == userId,
      );
      if (hasPending) return;

      final position = snapshot.position;
      if (position != null) {
        final local = await txn.query(
          'reading_positions',
          columns: ['updated_at'],
          where: 'user_id = ?',
          whereArgs: [userId],
          limit: 1,
        );
        final remoteAt = position.updatedAt.millisecondsSinceEpoch;
        if (local.isEmpty || (local.first['updated_at']! as int) < remoteAt) {
          await txn.insert('reading_positions', {
            'user_id': userId,
            'page': position.page,
            'updated_at': remoteAt,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      await txn.delete('bookmarks', where: 'user_id = ?', whereArgs: [userId]);
      for (final bookmark in snapshot.bookmarks) {
        await txn.insert('bookmarks', {
          'id': bookmark.id,
          'user_id': userId,
          'page': bookmark.page,
          'surah': bookmark.surah,
          'ayah': bookmark.ayah,
          'note': bookmark.note,
          'created_at':
              (bookmark.createdAt ?? DateTime.now()).millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> _enqueue(
    Database db,
    String operation,
    Map<String, Object?> payload,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = '$now-$operation-${payload['page'] ?? payload['id'] ?? userId}';
    await db.insert('mushaf_sync_queue', {
      'id': id,
      'operation': operation,
      'payload': jsonEncode(payload),
      'created_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
