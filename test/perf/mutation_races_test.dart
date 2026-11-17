import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:quran_daily/core/auth/session_gateway.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/network/connectivity_service.dart';
import 'package:quran_daily/core/network/rpc_client.dart';
import 'package:quran_daily/core/storage/daos/daos.dart';
import 'package:quran_daily/core/sync/personal_operation_overlay.dart';
import 'package:quran_daily/core/sync/sync_operation.dart';
import 'package:quran_daily/features/home/data/today_remote_data_source.dart';
import 'package:quran_daily/features/home/data/today_repository_impl.dart';
import 'package:quran_daily/features/quran_groups/data/data_sources/khatma_remote_data_source.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/khatma_repository_impl.dart';
import 'package:quran_daily/features/quran_groups/data/data_sources/groups_remote_data_source.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository_impl.dart';

import 'cache_first_test.dart' show dashboardJson, todayJson, testNow;

class Remote extends Mock implements KhatmaRemoteDataSource {}

class TodayRemote extends Mock implements TodayRemoteDataSource {}

class TodayCache extends Mock implements CachedTodayDao {}

class Session extends Mock implements SessionGateway {}

class Rpc extends Mock implements RpcClient {}

class Connectivity extends Mock implements ConnectivityService {}

class GroupsRemote extends Mock implements GroupsRemoteDataSource {}

class DelayedQueue extends SyncQueueDao {
  DelayedQueue(super.db);
  final started = Completer<void>();
  final release = Completer<void>();
  @override
  Future<void> enqueue(SyncOperation op) async {
    started.complete();
    await release.future;
    await super.enqueue(op);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LocalDatabase db;
  late Remote remote;
  late CachedSnapshotsDao snapshots;
  setUpAll(() {
    registerFallbackValue(testNow);
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  setUp(() async {
    db = LocalDatabase();
    await db.open(inMemory: true);
    snapshots = CachedSnapshotsDao(db);
    final json = dashboardJson();
    (json['today'] as Map)['late_count'] = 0;
    await snapshots.upsert('g', json);
    remote = Remote();
  });
  tearDown(() => db.close());

  for (final action in ['volunteer', 'override']) {
    test(
      '$action must not reuse a dashboard read started before mutation',
      () async {
        final oldResponse = Completer<Result<dynamic>>();
        final started = Completer<void>();
        when(() => remote.getDashboard('g')).thenAnswer((_) {
          if (!started.isCompleted) {
            started.complete();
            return oldResponse.future;
          }
          return Future.value(Success<dynamic>(dashboardJson()));
        });
        final mutationReached = Completer<void>();
        Future<Result<dynamic>> acknowledge(Invocation _) async {
          mutationReached.complete();
          return const Success<dynamic>(null);
        }

        when(() => remote.volunteer('a')).thenAnswer(acknowledge);
        when(() => remote.overrideAssignment('a', 'member'))
            .thenAnswer(acknowledge);
        final repo = KhatmaRepositoryImpl(
          remote: remote,
          cache: snapshots,
          now: () => testNow,
        );
        final opening = repo.getDashboard('g');
        await started.future;
        final mutation = action == 'volunteer'
            ? repo.volunteer('a')
            : repo.overrideAssignment('a', 'member');
        await mutationReached.future;
        await Future<void>.delayed(Duration.zero);
        final old = dashboardJson();
        ((old['assignments'] as List).single as Map)['is_me'] = false;
        old['my_assignments'] = <Object?>[];
        oldResponse.complete(Success<dynamic>(old));
        await opening;
        expect((await mutation).valueOrNull!.assignments.single.isMe, isTrue);
      },
    );
  }

  test(
    'starting a khatma must not reuse the forming dashboard in flight',
    () async {
      final oldResponse = Completer<Result<dynamic>>();
      final readStarted = Completer<void>();
      when(() => remote.getDashboard('g')).thenAnswer((_) {
        if (!readStarted.isCompleted) {
          readStarted.complete();
          return oldResponse.future;
        }
        return Future.value(Success<dynamic>(dashboardJson()));
      });
      final khatma = KhatmaRepositoryImpl(
        remote: remote,
        cache: snapshots,
        now: () => testNow,
      );
      final opening = khatma.getDashboard('g');
      await readStarted.future;
      final rpc = Rpc();
      final connectivity = Connectivity();
      final session = Session();
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(() => session.currentUserId).thenReturn('u');
      final mutationReached = Completer<void>();
      when(() => rpc.call<dynamic>('start_khatma', any()))
          .thenAnswer((_) async {
            mutationReached.complete();
            return const Success<dynamic>(null);
          });
      final groups = GroupsRepositoryImpl(
        rpc: rpc,
        remote: GroupsRemote(),
        cache: CachedGroupsDao(db),
        sessionGateway: session,
        connectivity: connectivity,
        khatmaRepository: khatma,
      );
      final starting = groups.startKhatma('g', 1);
      await mutationReached.future;
      await Future<void>.delayed(Duration.zero);
      oldResponse.complete(
        Success<dynamic>({...dashboardJson(), 'status': 'forming'}),
      );
      await opening;
      expect((await starting).valueOrNull!.status, GroupStatus.active);
    },
  );

  for (final operation in SyncOperationType.values) {
    test(
      'Today refresh preserves ${operation.name} queued during its cache write',
      () async {
        final isUndo = operation == SyncOperationType.undoCompletion;
        final originalToday = todayJson();
        if (isUndo) {
          final dashboard = dashboardJson();
          final day = dashboard['today'] as Map;
          day['completed_count'] = 1;
          day['pending_count'] = 0;
          day['late_count'] = 0;
          for (final key in ['assignments', 'my_assignments']) {
            ((dashboard[key] as List).single as Map)['status'] = 'completed';
          }
          await snapshots.upsert('g', dashboard);
          final group = (originalToday['groups'] as List).single as Map;
          ((group['items'] as List).single as Map)['status'] = 'completed';
        }
        final queue = DelayedQueue(db);
        final overlay = PersonalOperationOverlay(
          queue: queue,
          snapshots: snapshots,
        );
        when(() => remote.markComplete('a', any(), offlineSync: false))
            .thenAnswer(
              (_) async => const FailureResult<dynamic>(
                NetworkFailure(message: '', code: 'network'),
              ),
            );
        when(() => remote.undoCompletion('a')).thenAnswer(
          (_) async => const FailureResult<dynamic>(
            NetworkFailure(message: '', code: 'network'),
          ),
        );
        final khatma = KhatmaRepositoryImpl(
          remote: remote,
          cache: snapshots,
          queue: queue,
          pendingOperations: overlay,
          now: () => testNow,
        );
        final mutation = isUndo
            ? khatma.undoCompletion('a')
            : khatma.markComplete('a', testNow);
        await queue.started.future;
        final todayRemote = TodayRemote();
        when(todayRemote.getToday).thenAnswer((_) async => originalToday);
        final session = Session();
        when(() => session.currentUserId).thenReturn('u');
        final cache = TodayCache();
        final writing = Completer<void>();
        final releaseWrite = Completer<void>();
        when(() => cache.upsert('u', any())).thenAnswer((_) async {
          if (!writing.isCompleted) {
            writing.complete();
            await releaseWrite.future;
          }
        });
        final today = TodayRepositoryImpl(
          remote: todayRemote,
          cache: cache,
          session: session,
          pendingOperations: overlay,
          now: () => testNow,
        );
        final request = today.getToday();
        await writing.future;
        queue.release.complete();
        await mutation;
        releaseWrite.complete();
        expect(
          (await request).valueOrNull!.groups.single.items.single.status,
          isUndo ? 'pending' : 'completed',
        );
        expect((await queue.pending()).single.type, operation);
      },
    );
  }
}
