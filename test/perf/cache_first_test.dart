import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:quran_daily/core/auth/session_gateway.dart';
import 'package:quran_daily/core/storage/daos/daos.dart';
import 'package:quran_daily/core/sync/personal_operation_overlay.dart';
import 'package:quran_daily/core/sync/sync_operation.dart';
import 'package:quran_daily/features/home/cubit/home_cubit.dart';
import 'package:quran_daily/features/home/data/today_remote_data_source.dart';
import 'package:quran_daily/features/home/data/today_repository_impl.dart';
import 'package:quran_daily/features/home/data/today_snapshot.dart';
import 'package:quran_daily/features/log/data/data_sources/log_remote_data_source.dart';
import 'package:quran_daily/features/log/data/entities/log_entities.dart';
import 'package:quran_daily/features/log/data/repositories/log_repository_impl.dart';
import 'package:quran_daily/features/quran_groups/data/data_sources/khatma_remote_data_source.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/khatma_repository_impl.dart';

class _Session extends Mock implements SessionGateway {}

class _TodayCache extends Mock implements CachedTodayDao {}

class _TodayRemote extends Mock implements TodayRemoteDataSource {}

class _LogRemote extends Mock implements LogRemoteDataSource {}

class _KhatmaRemote extends Mock implements KhatmaRemoteDataSource {}

final testNow = DateTime.utc(2026, 11, 15, 12);
Map<String, Object?> todayJson() => {
  'server_generated_at': testNow.toIso8601String(),
  'main_group_id': 'g',
  'groups': [
    {
      'group_id': 'g',
      'name': 'group',
      'role': 'member',
      'status': 'active',
      'portion_unit': 'juz',
      'is_main': true,
      'day': {
        'group_date': '2026-11-15',
        'state': 'open',
        'ends_at': '2026-11-15T22:00:00Z',
        'closes_at': '2026-11-16T00:00:00Z',
        'cycle_number': 1,
        'cycle_day': 0,
        'cycle_length': 1,
        'completed_count': 0,
        'total_count': 1,
        'rest_day': false,
      },
      'items': [
        {
          'assignment_id': 'a',
          'kind': 'seat',
          'seat_number': 1,
          'portion_index': 1,
          'status': 'pending',
          'can_undo': false,
        },
      ],
    },
  ],
};
Map<String, Object?> dashboardJson() => {
  'group_id': 'g',
  'group_name': 'group',
  'my_role': 'member',
  'status': 'active',
  'server_generated_at': testNow.toIso8601String(),
  'today': {
    'group_date': '2026-11-15',
    'state': 'open',
    'completed_count': 0,
    'pending_count': 1,
    'ends_at': '2026-11-15T22:00:00Z',
  },
  'assignments': [
    {
      'assignment_id': 'a',
      'juz': 1,
      'seat_number': 1,
      'kind': 'seat',
      'status': 'pending',
      'is_me': true,
    },
  ],
  'my_assignments': [
    {
      'assignment_id': 'a',
      'juz': 1,
      'seat_number': 1,
      'kind': 'seat',
      'status': 'pending',
      'is_me': true,
    },
  ],
};
Map<String, Object?> logJson() => {
  'streak': 0,
  'best_streak': 0,
  'month': {'year': 2026, 'month': 11, 'full_days': 0, 'days_with_items': 1},
  'next_before': null,
  'days': [
    {
      'date': '2026-11-15',
      'complete': false,
      'items': [
        {
          'group_id': 'g',
          'group_name': 'group',
          'portion_unit': 'juz',
          'portion_index': 1,
          'kind': 'seat',
          'status': 'pending',
          'group_day_id': 'd',
        },
      ],
    },
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LocalDatabase db;
  late _Session session;
  late PersonalOperationOverlay overlay;
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  setUp(() async {
    db = LocalDatabase();
    await db.open(inMemory: true);
    session = _Session();
    when(() => session.currentUserId).thenReturn('u');
    overlay = PersonalOperationOverlay(
      queue: SyncQueueDao(db),
      snapshots: CachedSnapshotsDao(db),
    );
  });
  tearDown(() => db.close());

  test(
    'an operation queued during a cache write still wins over the refresh (#2)',
    () async {
      final cache = _TodayCache();
      final remote = _TodayRemote();
      final writing = Completer<void>();
      final release = Completer<void>();
      var writes = 0;
      when(remote.getToday).thenAnswer((_) async => todayJson());
      when(() => cache.upsert('u', any())).thenAnswer((_) async {
        if (writes++ == 0) {
          writing.complete();
          await release.future;
        }
      });
      final repository = TodayRepositoryImpl(
        remote: remote,
        cache: cache,
        session: session,
        pendingOperations: overlay,
        now: () => testNow,
      );
      final request = repository.getToday();
      await writing.future;
      await SyncQueueDao(db).enqueue(
        SyncOperation(
          id: 'during-write',
          type: SyncOperationType.markComplete,
          assignmentId: 'a',
          clientRecordedAt: testNow,
        ),
      );
      overlay.changed();
      release.complete();
      expect(
        (await request).valueOrNull!.groups.single.items.single.status,
        'completed',
      );
    },
  );

  test('a refresh started before replay cannot revert acknowledged completion (#2 #11)', () async {
    final queue = SyncQueueDao(db);
    await queue.enqueue(
      SyncOperation(
        id: 'op',
        type: SyncOperationType.markComplete,
        assignmentId: 'a',
        clientRecordedAt: testNow,
      ),
    );
    final old = Completer<Object?>();
    final remote = _TodayRemote();
    when(remote.getToday).thenAnswer((_) => old.future);
    final repository = TodayRepositoryImpl(
      remote: remote,
      cache: CachedTodayDao(db),
      session: session,
      pendingOperations: overlay,
      now: () => testNow,
    );
    final request = repository.getToday();
    await Future<void>.delayed(Duration.zero);
    await queue.delete('op');
    overlay.changed();
    final completed = todayJson();
    final group = (completed['groups'] as List).single as Map;
    (group['items'] as List).single['status'] = 'completed';
    when(remote.getToday).thenAnswer((_) async => completed);
    old.complete(todayJson());
    final snapshot = (await request).valueOrNull!;
    expect(snapshot.groups.single.items.single.status, 'completed');
  });

  test('Home shows cached Today before a slow refresh; pending completion survives (#2)', () async {
    await CachedTodayDao(db).upsert('u', todayJson());
    await SyncQueueDao(db).enqueue(
      SyncOperation(
        id: 'op',
        type: SyncOperationType.markComplete,
        assignmentId: 'a',
        clientRecordedAt: testNow,
      ),
    );
    final response = Completer<Object?>();
    final remote = _TodayRemote();
    when(remote.getToday).thenAnswer((_) => response.future);
    final repository = TodayRepositoryImpl(
      remote: remote,
      cache: CachedTodayDao(db),
      session: session,
      pendingOperations: overlay,
      now: () => testNow,
    );
    final khatma = KhatmaRepositoryImpl(
      remote: _KhatmaRemote(),
      cache: CachedSnapshotsDao(db),
    );
    final cubit = HomeCubit(repository: repository, khatmaRepository: khatma);
    final cached = cubit.stream.firstWhere((s) => s.snapshot != null);
    final loading = cubit.load();
    final state = await cached;
    expect(state.status, HomeStatus.offline);
    expect(state.snapshot!.groups.single.items.single.status, 'completed');
    response.complete(todayJson());
    await loading;
    expect(
      cubit.state.snapshot!.groups.single.items.single.status,
      'completed',
    );
    expect(cubit.state.snapshot!.isStale, isTrue);
    await cubit.close();
  });

  test(
    'cached Today discards expired group day at its own midnight (#2)',
    () async {
      await CachedTodayDao(db).upsert('u', todayJson());
      final response = Completer<Object?>();
      final remote = _TodayRemote();
      when(remote.getToday).thenAnswer((_) => response.future);
      final repository = TodayRepositoryImpl(
        remote: remote,
        cache: CachedTodayDao(db),
        session: session,
        now: () => DateTime.utc(2026, 11, 15, 22),
      );
      final cached = Completer<TodaySnapshot>();
      final refresh = repository.getToday(onCached: cached.complete);
      final snapshot = await cached.future;
      expect(snapshot.groups.single.day, isNull);
      expect(snapshot.groups.single.items, isEmpty);
      response.complete(todayJson());
      expect((await refresh).valueOrNull!.groups.single.items, isEmpty);
    },
  );

  test(
    'personal log shows cache before remote and preserves queued undo (#2)',
    () async {
      await CachedSnapshotsDao(db).upsert('g', dashboardJson());
      await CachedHistoryDao(db).upsert('personal-log:u', logJson());
      final queue = SyncQueueDao(db);
      await queue.enqueue(
        SyncOperation(
          id: 'complete',
          type: SyncOperationType.markComplete,
          assignmentId: 'a',
          clientRecordedAt: testNow,
        ),
      );
      await queue.enqueue(
        SyncOperation(
          id: 'undo',
          type: SyncOperationType.undoCompletion,
          assignmentId: 'a',
          clientRecordedAt: testNow,
        ),
      );
      final response = Completer<PersonalLog>();
      final remote = _LogRemote();
      when(() => remote.getLog(before: null, days: 30))
          .thenAnswer((_) => response.future);
      final repository = LogRepositoryImpl(
        remote: remote,
        cache: CachedHistoryDao(db),
        session: session,
        pendingOperations: overlay,
      );
      final cached = Completer<PersonalLog>();
      final refresh = repository.getLog(onCached: cached.complete);
      expect((await cached.future).isStale, isTrue);
      final fresh = logJson();
      final item =
          ((fresh['days'] as List).single['items'] as List).single as Map;
      item['status'] = 'completed';
      response.complete(PersonalLog.fromJson(fresh));
      final log = (await refresh).valueOrNull!;
      expect(log.days.single.items.single.status, LogItemStatus.pending);
      expect(log.isStale, isTrue);
    },
  );
}
