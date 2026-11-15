import 'dart:convert';

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
class SqfliteReaderStorage implements ReaderStorage {
  SqfliteReaderStorage({required LocalDatabase database, required this.userId})
    : _database = database;

  final LocalDatabase _database;
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
