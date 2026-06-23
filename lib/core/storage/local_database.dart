import 'dart:io';

import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  const LocalDatabase({this.databasePath});

  static const databaseName = 'quran_daily.db';
  static const schemaVersion = 1;

  static const dashboardSnapshotsTable = 'dashboard_snapshots';
  static const publicGroupProfilesTable = 'public_group_profiles';
  static const historySummariesTable = 'history_summaries';
  static const quranPartsTable = 'quran_parts';
  static const userSettingsTable = 'user_settings';
  static const syncOperationsTable = 'sync_operations';

  final String? databasePath;

  Future<Database> open() async {
    final resolvedPath =
        databasePath ?? '${await getDatabasesPath()}${Platform.pathSeparator}$databaseName';

    return openDatabase(
      resolvedPath,
      version: schemaVersion,
      onCreate: (database, version) async {
        for (final migration in LocalDatabaseMigration.all) {
          if (migration.version <= version) {
            await migration.apply(database);
          }
        }
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        for (final migration in LocalDatabaseMigration.all) {
          if (migration.version > oldVersion && migration.version <= newVersion) {
            await migration.apply(database);
          }
        }
      },
    );
  }
}

class LocalDatabaseMigration {
  const LocalDatabaseMigration({
    required this.version,
    required this.statements,
  });

  final int version;
  final List<String> statements;

  static List<LocalDatabaseMigration> get all => [version1()];

  static LocalDatabaseMigration version1() {
    return const LocalDatabaseMigration(
      version: 1,
      statements: [
        '''
CREATE TABLE IF NOT EXISTS dashboard_snapshots (
  group_id TEXT PRIMARY KEY,
  payload TEXT NOT NULL,
  cached_at TEXT NOT NULL,
  is_stale INTEGER NOT NULL DEFAULT 0
)
''',
        '''
CREATE TABLE IF NOT EXISTS public_group_profiles (
  cache_key TEXT NOT NULL,
  group_id TEXT NOT NULL,
  payload TEXT NOT NULL,
  cached_at TEXT NOT NULL,
  PRIMARY KEY (cache_key, group_id)
)
''',
        '''
CREATE TABLE IF NOT EXISTS history_summaries (
  group_id TEXT NOT NULL,
  cycle_date TEXT NOT NULL,
  payload TEXT NOT NULL,
  cached_at TEXT NOT NULL,
  PRIMARY KEY (group_id, cycle_date)
)
''',
        '''
CREATE TABLE IF NOT EXISTS quran_parts (
  part_number INTEGER PRIMARY KEY,
  display_label TEXT NOT NULL,
  reading_range_label TEXT NOT NULL,
  sort_order INTEGER NOT NULL
)
''',
        '''
CREATE TABLE IF NOT EXISTS user_settings (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  selected_group_id TEXT,
  quran_text_scale REAL NOT NULL DEFAULT 1.0,
  preferred_locale TEXT NOT NULL DEFAULT 'ar',
  last_dashboard_cache_at TEXT
)
''',
        '''
CREATE TABLE IF NOT EXISTS sync_operations (
  id TEXT PRIMARY KEY,
  operation_type TEXT NOT NULL,
  assignment_id TEXT NOT NULL,
  payload TEXT NOT NULL,
  created_at TEXT NOT NULL,
  sync_status TEXT NOT NULL,
  last_error TEXT
)
''',
      ],
    );
  }

  Future<void> apply(Database database) async {
    for (final statement in statements) {
      await database.execute(statement);
    }
  }
}
