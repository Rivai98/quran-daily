import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/storage/daos/daos.dart';
import 'package:quran_daily/core/sync/sync_operation.dart';
import 'package:quran_daily/features/quran_groups/cubit/dashboard/dashboard_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/data_sources/khatma_remote_data_source.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/khatma_repository_impl.dart';

import 'cache_first_test.dart' show dashboardJson, logJson, testNow;

import 'package:quran_daily/core/sync/personal_operation_overlay.dart';

class _Remote extends Mock implements KhatmaRemoteDataSource {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LocalDatabase db;
  late _Remote remote;
  late CachedSnapshotsDao cache;
  late SyncQueueDao queue;
  setUpAll(() {
    registerFallbackValue(testNow);
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  setUp(() async {
    db = LocalDatabase();
    await db.open(inMemory: true);
    remote = _Remote();
    cache = CachedSnapshotsDao(db);
    queue = SyncQueueDao(db);
    await cache.upsert('g', dashboardJson());
  });
  tearDown(() => db.close());

  test('rollover retains queued personal context across repository restart (#2 #11)', () async {
    await queue.enqueue(
      SyncOperation(
        id: 'old-day',
        type: SyncOperationType.markComplete,
        assignmentId: 'a',
        clientRecordedAt: testNow,
      ),
    );
    final next = dashboardJson();
    final day = Map<String, Object?>.from(next['today'] as Map);
    day['group_date'] = '2026-11-16';
    day['ends_at'] = '2026-11-16T22:00:00Z';
    next['today'] = day;
    next['assignments'] = [
      {
        'assignment_id': 'b',
        'juz': 1,
        'seat_number': 1,
        'kind': 'seat',
        'status': 'pending',
        'is_me': true,
      },
    ];
    next['my_assignments'] = next['assignments'];
    when(() => remote.getDashboard('g'))
        .thenAnswer((_) async => Success<dynamic>(next));
    when(() => remote.markComplete('a', any(), offlineSync: true))
        .thenAnswer((_) async => const Success<dynamic>(null));
    final nextNoon = DateTime.utc(2026, 11, 16, 12);
    final first = KhatmaRepositoryImpl(
      remote: remote,
      cache: cache,
      queue: queue,
      now: () => nextNoon,
    );
    await first.getDashboard('g');
    final restartedOverlay = PersonalOperationOverlay(
      queue: SyncQueueDao(db),
      snapshots: CachedSnapshotsDao(db),
    );
    final log = await restartedOverlay.log(logJson());
    final yesterday = (log.json['days'] as List).single as Map;
    expect(((yesterday['items'] as List).single as Map)['status'], 'completed');
    final restarted = KhatmaRepositoryImpl(
      remote: remote,
      cache: cache,
      queue: queue,
      now: () => nextNoon,
    );
    final report = await restarted.syncPending();
    expect(report.refreshedGroupIds, {'g'});
    expect(report.remaining, 0);
    verify(() => remote.getDashboard('g')).called(2);
  });

  test(
    'cached dashboard displays while open bookkeeping and network wait (#2 #8)',
    () async {
      final opened = Completer<void>();
      final response = Completer<Result<dynamic>>();
      when(() => remote.getDashboard('g')).thenAnswer((_) => response.future);
      final repository = KhatmaRepositoryImpl(
        remote: remote,
        cache: cache,
        now: () => testNow,
      );
      final cubit = DashboardCubit(
        repository: repository,
        groupId: 'g',
        onOpened: () => opened.future,
      );
      final cached = cubit.stream.firstWhere((state) => state.snapshot != null);
      final refreshing = cubit.refresh();
      final state = await cached.timeout(const Duration(seconds: 2));
      expect(state.snapshot!.isStale, isTrue);
      response.complete(Success(dashboardJson()));
      await refreshing.timeout(const Duration(seconds: 2));
      expect(cubit.state.status, DashboardStatus.success);
      opened.complete();
      await cubit.close();
    },
  );

  test('overlapping replay keeps 50 operations ordered and refreshes each group once (#11)', () async {
    await cache.upsert('h', {
      ...dashboardJson(),
      'group_id': 'h',
      'assignments': [
        {
          'assignment_id': 'b',
          'juz': 1,
          'seat_number': 1,
          'kind': 'seat',
          'status': 'pending',
          'is_me': true,
        },
      ],
    });
    final sent = <String>[];
    final firstSend = Completer<Result<dynamic>>();
    when(() => remote.markComplete(any(), any(), offlineSync: true))
        .thenAnswer((call) {
          sent.add('complete:${call.positionalArguments.first}');
          return sent.length == 1
              ? firstSend.future
              : Future.value(const Success<dynamic>(null));
        });
    when(() => remote.undoCompletion(any())).thenAnswer((call) async {
      sent.add('undo:${call.positionalArguments.first}');
      return const Success<dynamic>(null);
    });
    for (var i = 0; i < 50; i++) {
      await queue.enqueue(
        SyncOperation(
          id: '$i',
          type: i.isEven
              ? SyncOperationType.markComplete
              : SyncOperationType.undoCompletion,
          assignmentId: i % 4 < 2 ? 'a' : 'b',
          clientRecordedAt: testNow,
        ),
      );
    }
    when(() => remote.getDashboard(any())).thenAnswer(
      (call) async => Success<dynamic>({
        ...dashboardJson(),
        'group_id': call.positionalArguments.first,
      }),
    );
    final repository = KhatmaRepositoryImpl(
      remote: remote,
      cache: cache,
      queue: queue,
      now: () => testNow,
    );
    final first = repository.syncPending();
    final second = repository.syncPending();
    expect(identical(first, second), isTrue);
    firstSend.complete(const Success<dynamic>(null));
    final report = await first;
    expect(report.succeeded, 50);
    expect(report.remaining, 0);
    expect(sent, [
      for (var i = 0; i < 50; i++)
        '${i.isEven ? 'complete' : 'undo'}:${i % 4 < 2 ? 'a' : 'b'}',
    ]);
    verify(() => remote.getDashboard('g')).called(1);
    verify(() => remote.getDashboard('h')).called(1);
  });

  test(
    'network replay backs off without losing the next operation (#11)',
    () async {
      var now = testNow;
      await queue.enqueue(
        SyncOperation(
          id: 'one',
          type: SyncOperationType.markComplete,
          assignmentId: 'a',
          clientRecordedAt: now,
        ),
      );
      when(() => remote.markComplete('a', any(), offlineSync: true)).thenAnswer(
        (_) async => const FailureResult<dynamic>(
          NetworkFailure(message: '', code: 'network'),
        ),
      );
      final repository = KhatmaRepositoryImpl(
        remote: remote,
        cache: cache,
        queue: queue,
        now: () => now,
      );
      await repository.syncPending();
      await repository.syncPending();
      verify(() => remote.markComplete('a', any(), offlineSync: true))
          .called(1);
      now = now.add(const Duration(seconds: 61));
      await repository.syncPending();
      verify(() => remote.markComplete('a', any(), offlineSync: true))
          .called(1);
      expect((await queue.pending()).single.attempts, 2);
    },
  );

  test('reminder planning never blocks a completion response (#3)', () async {
    final planning = Completer<void>();
    var planned = false;
    when(() => remote.markComplete('a', any(), offlineSync: false))
        .thenAnswer((_) async => const Success<dynamic>(null));
    when(() => remote.getDashboard('g'))
        .thenAnswer((_) async => Success<dynamic>(dashboardJson()));
    final repository = KhatmaRepositoryImpl(
      remote: remote,
      cache: cache,
      onCompletionChanged: (_) {
        planned = true;
        return planning.future;
      },
    );
    await repository
        .markComplete('a', testNow)
        .timeout(const Duration(seconds: 2));
    expect(planned, isTrue);
    planning.complete();
  });
}
