import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../../core/storage/local_database.dart';

abstract interface class ProfileLocalDataSource {
  Future<void> cacheProfile(String userId, Map<String, Object?> json);
  Future<({Map<String, Object?> json, DateTime cachedAt})?> getCachedProfile(
    String userId,
  );
}

class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  ProfileLocalDataSourceImpl(this._db);

  final LocalDatabase _db;
  bool _tableEnsured = false;

  Future<void> _ensureTable(Database db) async {
    if (_tableEnsured) return;
    await db.execute('''
      create table if not exists cached_profile (
        user_id text primary key,
        json text not null,
        cached_at integer not null
      )
    ''');
    _tableEnsured = true;
  }

  @override
  Future<void> cacheProfile(String userId, Map<String, Object?> json) async {
    final db = await _db.database;
    await _ensureTable(db);
    await db.insert('cached_profile', {
      'user_id': userId,
      'json': jsonEncode(json),
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<({Map<String, Object?> json, DateTime cachedAt})?> getCachedProfile(
    String userId,
  ) async {
    final db = await _db.database;
    await _ensureTable(db);
    final rows = await db.query(
      'cached_profile',
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
