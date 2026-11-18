import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/network/connectivity_service.dart';
import 'package:quran_daily/core/storage/daos/daos.dart';
import 'package:quran_daily/features/quran_groups/cubit/dashboard/dashboard_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/data_sources/khatma_remote_data_source.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/khatma_repository_impl.dart';
import 'package:quran_daily/features/quran_groups/data/use_cases/completion_use_cases.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _Connectivity implements ConnectivityService {
  final controller = StreamController<bool>.broadcast();

  @override
  Stream<bool> get online => controller.stream;

  @override
  Future<bool> get isOnline async => false;
}

class _Remote implements KhatmaRemoteDataSource {
  @override
  Future<Result<dynamic>> call(
    String function, [
    Map<String, Object?>? params,
  ]) async => throw UnimplementedError(function);

  bool online = true;
  bool completed = false;
  int syncCalls = 0;

  Map<String, Object?> get dashboard => {
    'group_id': 'g1',
    'group_name': 'group',
    'my_role': 'member',
    'status': 'active',
    'server_generated_at': '2026-11-15T10:00:00Z',
    'today': {
      'group_date': '2026-11-15',
      'state': 'open',
      'completed_count': completed ? 1 : 0,
      'late_count': 0,
      'missed_count': 0,
      'unread_count': 29,
      'pending_count': completed ? 0 : 1,
      'available_count': 0,
      'full_khatma': false,
      'ends_at': '2026-11-16T00:00:00Z',
    },
    'my_assignments': [
      {
        'assignment_id': 'a1',
        'juz': 1,
        'seat_number': 1,
        'kind': 'seat',
        'status': completed ? 'completed' : 'pending',
        'is_me': true,
      },
    ],
    'assignments': [
      {
        'assignment_id': 'a1',
        'juz': 1,
        'seat_number': 1,
        'kind': 'seat',
        'status': completed ? 'completed' : 'pending',
        'is_me': true,
      },
    ],
  };

  @override
  Future<Result<dynamic>> getDashboard(String groupId) async => online
      ? Success<dynamic>(dashboard)
      : const FailureResult<dynamic>(
          NetworkFailure(message: 'offline', code: 'network'),
        );

  @override
  Future<Result<dynamic>> markComplete(
    String assignmentId,
    DateTime recordedAt, {
    required bool offlineSync,
  }) async {
    if (!online) {
      return const FailureResult<dynamic>(
        NetworkFailure(message: 'offline', code: 'network'),
      );
    }
    if (offlineSync) syncCalls++;
    completed = true;
    return const Success<dynamic>(null);
  }

  @override
  Future<Result<dynamic>> undoCompletion(String assignmentId) async =>
      const Success<dynamic>(null);

  @override
  Future<Result<dynamic>> volunteer(String assignmentId) async =>
      const Success<dynamic>(null);

  @override
  Future<Result<dynamic>> overrideAssignment(
    String assignmentId,
    String membershipId,
  ) async => const Success<dynamic>(null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cached dashboard completes offline and syncs on reconnect', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final database = LocalDatabase();
    await database.open(inMemory: true);
    final cache = CachedSnapshotsDao(database);
    final queue = SyncQueueDao(database);
    final remote = _Remote();
    final connectivity = _Connectivity();
    final repository = KhatmaRepositoryImpl(
      remote: remote,
      cache: cache,
      queue: queue,
    );
    final cubit = DashboardCubit(
      repository: repository,
      groupId: 'g1',
      connectivityService: connectivity,
      syncPending: SyncPendingCompletions(repository),
    );
    addTearDown(() async {
      await cubit.close();
      await connectivity.controller.close();
      await database.close();
    });

    expect((await repository.getDashboard('g1')).valueOrNull, isNotNull);
    remote.online = false;
    final offlineDashboard = await repository.getDashboard('g1');
    expect(offlineDashboard.valueOrNull?.isStale, isTrue);
    final completion = await repository.markComplete(
      'a1',
      DateTime.utc(2026, 11, 15),
    );
    expect(completion.failureOrNull?.code, 'offline_queued');
    expect(
      (await repository.getDashboard('g1'))
          .valueOrNull
          ?.myAssignments
          .single
          .status
          .name,
      'completed',
    );
    expect((await queue.pending()).length, 1);

    remote.online = true;
    connectivity.controller.add(true);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(remote.syncCalls, 1);
    expect(await queue.pending(), isEmpty);
    expect((await repository.getDashboard('g1')).valueOrNull?.isStale, isFalse);
    expect(
      (await repository.getDashboard('g1'))
          .valueOrNull
          ?.myAssignments
          .single
          .status
          .name,
      'completed',
    );
  });
}
