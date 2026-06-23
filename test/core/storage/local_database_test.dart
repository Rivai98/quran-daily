import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/storage/local_database.dart';

void main() {
  test('defines the initial local cache schema version', () {
    expect(LocalDatabase.schemaVersion, 1);
    expect(LocalDatabase.databaseName, 'quran_daily.db');
  });

  test('creates dashboard, discovery, history, settings, and sync tables', () {
    final migration = LocalDatabaseMigration.version1();
    final joinedStatements = migration.statements.join('\n');

    expect(migration.version, 1);
    expect(joinedStatements, contains(LocalDatabase.dashboardSnapshotsTable));
    expect(joinedStatements, contains(LocalDatabase.publicGroupProfilesTable));
    expect(joinedStatements, contains(LocalDatabase.historySummariesTable));
    expect(joinedStatements, contains(LocalDatabase.quranPartsTable));
    expect(joinedStatements, contains(LocalDatabase.userSettingsTable));
    expect(joinedStatements, contains(LocalDatabase.syncOperationsTable));
  });
}
