import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/storage/daos/daos.dart';
import 'package:quran_daily/core/sync/sync_operation.dart';
import 'package:quran_daily/features/quran_groups/data/data_sources/khatma_remote_data_source.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/khatma_repository.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/khatma_repository_impl.dart';
import 'package:quran_daily/features/quran_groups/data/use_cases/completion_use_cases.dart';

class _Repository extends Mock implements KhatmaRepository {}

class _Remote extends Mock implements KhatmaRemoteDataSource {}

class _Snapshots extends Mock implements CachedSnapshotsDao {}

class _Queue extends Mock implements SyncQueueDao {}

final _recordedAt = DateTime.utc(2026, 11, 15, 12);
final _cachedAt = DateTime.utc(2026, 11, 15, 10);

final _snapshotJson = <String, Object?>{
  'group_id': 'g1',
  'group_name': 'group',
  'my_role': 'member',
  'status': 'active',
  'server_generated_at': '2026-11-15T10:00:00Z',
  'today': {
    'group_date': '2026-11-15',
    'state': 'open',
    'completed_count': 0,
    'late_count': 0,
    'missed_count': 0,
    'unread_count': 0,
    'pending_count': 1,
    'available_count': 29,
    'full_khatma': false,
    'ends_at': '2026-11-15T23:59:00Z',
  },
  'my_assignments': [_assignmentJson('a-1')],
  'assignments': [_assignmentJson('a-1')],
};

Map<String, Object?> _assignmentJson(String id, {String status = 'pending'}) =>
    {
      'assignment_id': id,
      'juz': 1,
      'seat_number': 1,
      'kind': 'seat',
      'status': status,
      'reader_display_name': 'member',
      'is_me': true,
      'is_khatm_juz': false,
      'completed_at': null,
    };

void main() {
  test('MarkAssignmentComplete uses the injected clock', () async {
    final repository = _Repository();
    final expected = DashboardSnapshot(
      groupId: 'g1',
      groupName: 'group',
      myRole: GroupRole.member,
      status: GroupStatus.active,
      serverGeneratedAt: _recordedAt,
    );
    when(
      () => repository.markComplete('a-1', _recordedAt),
    ).thenAnswer((_) async => Success(expected));

    final result = await MarkAssignmentComplete(
      repository,
      clock: () => _recordedAt,
    )('a-1');

    expect(result.valueOrNull, expected);
    verify(() => repository.markComplete('a-1', _recordedAt)).called(1);
  });

  test('UndoAssignmentCompletion delegates to the repository', () async {
    final repository = _Repository();
    when(() => repository.undoCompletion('a-1')).thenAnswer(
      (_) async => const FailureResult<DashboardSnapshot>(
        NetworkFailure(message: 'offline', code: 'network'),
      ),
    );

    final result = await UndoAssignmentCompletion(repository)('a-1');

    expect(result.failureOrNull?.kind, FailureKind.network);
    verify(() => repository.undoCompletion('a-1')).called(1);
  });

  test('SyncPendingCompletions returns the repository report', () async {
    final repository = _Repository();
    const report = SyncReport(succeeded: 2, failed: 1, remaining: 1);
    when(repository.syncPending).thenAnswer((_) async => report);

    expect(await SyncPendingCompletions(repository)(), report);
  });

  group('KhatmaRepositoryImpl offline completion queue', () {
    late _Remote remote;
    late _Snapshots snapshots;
    late _Queue queue;
    late KhatmaRepositoryImpl repository;

    setUp(() {
      remote = _Remote();
      snapshots = _Snapshots();
      queue = _Queue();
      repository = KhatmaRepositoryImpl(
        remote: remote,
        cache: snapshots,
        queue: queue,
      );
      registerFallbackValue(
        SyncOperation(
          id: 'fallback',
          type: SyncOperationType.markComplete,
          assignmentId: 'a-1',
          clientRecordedAt: _recordedAt,
        ),
      );
      when(() => snapshots.readAll()).thenAnswer(
        (_) async => [
          (groupId: 'g1', json: _snapshotJson, cachedAt: _cachedAt),
        ],
      );
      when(
        () => snapshots.read('g1'),
      ).thenAnswer((_) async => (json: _snapshotJson, cachedAt: _cachedAt));
      when(() => snapshots.upsert('g1', any())).thenAnswer((_) async {});
      when(() => queue.enqueue(any())).thenAnswer((_) async {});
      when(
        () => queue.update(
          any(),
          status: any(named: 'status'),
          attempts: any(named: 'attempts'),
          lastErrorKind: any(named: 'lastErrorKind'),
        ),
      ).thenAnswer((_) async {});
      when(() => queue.delete(any())).thenAnswer((_) async {});
    });

    test(
      'network failure updates the cache optimistically and queues the operation',
      () async {
        when(
          () => remote.markComplete('a-1', _recordedAt, offlineSync: false),
        ).thenAnswer(
          (_) async => const FailureResult<dynamic>(
            NetworkFailure(message: 'offline', code: 'network'),
          ),
        );

        final result = await repository.markComplete('a-1', _recordedAt);

        expect(result.failureOrNull?.kind, FailureKind.offlineQueued);
        verify(() => queue.enqueue(any(that: isA<SyncOperation>()))).called(1);
        final written =
            verify(() => snapshots.upsert('g1', captureAny())).captured.single
                as Map<String, Object?>;
        expect((written['assignments']! as List).single['status'], 'completed');
        expect((written['today']! as Map)['completed_count'], 1);
      },
    );

    test(
      'sync replays queued work in order and removes successful operations',
      () async {
        final first = SyncOperation(
          id: 'op1',
          type: SyncOperationType.markComplete,
          assignmentId: 'a-1',
          clientRecordedAt: _recordedAt,
          createdAt: _cachedAt,
        );
        final second = SyncOperation(
          id: 'op2',
          type: SyncOperationType.undoCompletion,
          assignmentId: 'a-1',
          clientRecordedAt: _recordedAt,
          createdAt: _cachedAt.add(const Duration(seconds: 1)),
        );
        var reads = 0;
        when(
          () => queue.pending(),
        ).thenAnswer((_) async => reads++ == 0 ? [first, second] : []);
        when(
          () => remote.markComplete('a-1', _recordedAt, offlineSync: true),
        ).thenAnswer((_) async => const Success<dynamic>({}));
        when(
          () => remote.undoCompletion('a-1'),
        ).thenAnswer((_) async => const Success<dynamic>({}));
        when(
          () => remote.getDashboard('g1'),
        ).thenAnswer((_) async => Success<dynamic>(_snapshotJson));

        final report = await repository.syncPending();

        expect(report.succeeded, 2);
        expect(report.failed, 0);
        expect(report.remaining, 0);
        verifyInOrder([
          () => remote.markComplete('a-1', _recordedAt, offlineSync: true),
          () => remote.getDashboard('g1'),
          () => remote.undoCompletion('a-1'),
          () => remote.getDashboard('g1'),
        ]);
        verify(() => queue.delete('op1')).called(1);
        verify(() => queue.delete('op2')).called(1);
      },
    );

    test('day_closed sync failure is marked failed and reported', () async {
      final operation = SyncOperation(
        id: 'op1',
        type: SyncOperationType.markComplete,
        assignmentId: 'a-1',
        clientRecordedAt: _recordedAt,
      );
      var reads = 0;
      when(
        () => queue.pending(),
      ).thenAnswer((_) async => reads++ == 0 ? [operation] : []);
      when(
        () => remote.markComplete('a-1', _recordedAt, offlineSync: true),
      ).thenAnswer(
        (_) async => const FailureResult<dynamic>(
          SyncConflictFailure(message: 'day closed', code: 'day_closed'),
        ),
      );

      final report = await repository.syncPending();

      expect(report.failed, 1);
      expect(report.remaining, 0);
      verify(
        () => queue.update(
          'op1',
          status: SyncOperationStatus.failed,
          lastErrorKind: 'day_closed',
        ),
      ).called(1);
    });
  });
}
