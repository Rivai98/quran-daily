import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';

/// Local SQLite cache (data-model v3): dashboard snapshots, my groups,
/// history pages, and the personal sync queue. Used only by repositories.
class LocalDatabase {
  LocalDatabase({this.databasePath});

  static const databaseName = 'quran_daily.db';
  static const schemaVersion = 3;

  final String? databasePath;

  Database? _db;

  /// Opens (or creates) the database; [inMemory] is for tests.
  Future<Database> open({bool inMemory = false}) async {
    if (_db != null && _db!.isOpen) return _db!;

    if (inMemory) {
      _db = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: schemaVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
      return _db!;
    }

    final dir =
        databasePath ??
        '${await getDatabasesPath()}${Platform.pathSeparator}$databaseName';
    _db = await openDatabase(
      dir,
      version: schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      create table cached_snapshots (
        group_id text primary key,
        json text not null,
        cached_at integer not null
      )
    ''');
    await db.execute('''
      create table cached_groups (
        user_id text primary key,
        json text not null,
        cached_at integer not null
      )
    ''');
    await db.execute('''
      create table cached_history (
        group_id text primary key,
        json text not null,
        cached_at integer not null
      )
    ''');
    await db.execute('''
      create table sync_queue (
        id text primary key,
        op text not null,
        assignment_id text not null,
        client_recorded_at integer not null,
        status text not null default 'pending',
        attempts integer not null default 0,
        last_error_kind text,
        created_at integer not null
      )
    ''');
    await _createMushafTables(db);
    await _createTodayCache(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // v2 was used by both spec 003 (Mushaf tables) and spec 005 (Today
    // cache) on their branches; v3 makes sure both exist either way.
    if (oldVersion < 3) {
      await _createMushafTables(db);
      await _createTodayCache(db);
    }
  }

  Future<void> _createTodayCache(Database db) async {
    await db.execute(
      'create table if not exists cached_today (user_id text primary key, json text not null, cached_at integer not null)',
    );
  }

  Future<void> _createMushafTables(Database db) async {
    await db.execute('''
      create table if not exists reading_positions (
        user_id text primary key,
        page integer not null,
        updated_at integer not null
      )
    ''');
    await db.execute('''
      create table if not exists bookmarks (
        id text primary key,
        user_id text not null,
        page integer not null,
        surah integer,
        ayah integer,
        note text,
        created_at integer not null
      )
    ''');
    await db.execute('''
      create table if not exists mushaf_sync_queue (
        id text primary key,
        operation text not null,
        payload text not null,
        created_at integer not null
      )
    ''');
  }

  /// Raw access for DAOs.
  Future<Database> get database async {
    if (_db == null || !_db!.isOpen) {
      await open();
    }
    return _db!;
  }

  Future<List<String>> tableNames() async {
    final db = await database;
    final rows = await db.rawQuery(
      "select name from sqlite_master where type = 'table' and name not like 'sqlite_%'",
    );
    return rows.map((r) => r['name']! as String).toList();
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

/// Convenience: encode/decode the JSON column safely.
Map<String, Object?> decodeJson(String raw) =>
    (jsonDecode(raw) as Map).cast<String, Object?>();

String encodeJson(Map<String, Object?> value) => jsonEncode(value);
