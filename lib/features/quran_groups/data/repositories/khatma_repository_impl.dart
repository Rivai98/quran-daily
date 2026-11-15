import 'dart:async';
import 'dart:math';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/storage/daos/daos.dart';
import '../../../../core/sync/sync_operation.dart';
import '../data_sources/khatma_remote_data_source.dart';
import '../entities/entities.dart';
import '../models/models.dart';
import 'khatma_repository.dart';

/// Network-backed khatma repository with a local dashboard snapshot cache.
class KhatmaRepositoryImpl extends KhatmaRepository {
  KhatmaRepositoryImpl({
    required KhatmaRemoteDataSource remote,
    required CachedSnapshotsDao cache,
    SyncQueueDao? queue,
  }) : _remote = remote,
       _cache = cache,
       _queue = queue;

  final KhatmaRemoteDataSource _remote;
  final CachedSnapshotsDao _cache;
  final SyncQueueDao? _queue;
  final Map<String, StreamController<DashboardSnapshot?>> _updates = {};

  StreamController<DashboardSnapshot?> _controllerFor(String groupId) =>
      _updates.putIfAbsent(
        groupId,
        () => StreamController<DashboardSnapshot?>.broadcast(),
      );

  @override
  Stream<DashboardSnapshot?> watchCachedDashboard(String groupId) async* {
    final cached = await _cache.read(groupId);
    yield cached == null
        ? null
        : dashboardSnapshotFromJson(
            cached.json,
            isStale: true,
            cachedAt: cached.cachedAt,
          );
    yield* _controllerFor(groupId).stream;
  }

  @override
  Future<Result<DashboardSnapshot>> getDashboard(String groupId) async {
    final result = await _remote.getDashboard(groupId);
    return result.when(
      success: (payload) async {
        final json = (payload! as Map).cast<String, Object?>();
        final snapshot = dashboardSnapshotFromJson(json);
        await _cache.upsert(groupId, json);
        _controllerFor(groupId).add(snapshot);
        return Success(snapshot);
      },
      failure: (failure) async {
        if (failure.kind != FailureKind.network) return FailureResult(failure);
        final cached = await _cache.read(groupId);
        if (cached == null) return FailureResult(failure);
        final snapshot = dashboardSnapshotFromJson(
          cached.json,
          isStale: true,
          cachedAt: cached.cachedAt,
        );
        _controllerFor(groupId).add(snapshot);
        return Success(snapshot);
      },
    );
  }

  @override
  Future<Result<DashboardSnapshot>> markComplete(
    String assignmentId,
    DateTime clientRecordedAt,
  ) => _complete(assignmentId, clientRecordedAt, undo: false);
  @override
  Future<Result<DashboardSnapshot>> undoCompletion(String assignmentId) =>
      _complete(assignmentId, DateTime.now(), undo: true);

  Future<Result<DashboardSnapshot>> _complete(
    String assignmentId,
    DateTime recordedAt, {
    required bool undo,
  }) async {
    final cached = await _findAssignment(assignmentId);
    if (cached == null) {
      return const FailureResult(
        UnknownFailure(
          message: 'assignment not cached',
          code: 'assignment_not_cached',
        ),
      );
    }
    final groupId = cached.groupId;
    final remoteResult = undo
        ? await _remote.undoCompletion(assignmentId)
        : await _remote.markComplete(
            assignmentId,
            recordedAt,
            offlineSync: false,
          );
    if (remoteResult.isSuccess) {
      final dashboard = await getDashboard(groupId);
      if (dashboard.isSuccess) return dashboard;
      final snapshot = await _optimistic(
        groupId,
        assignmentId,
        recordedAt,
        undo: undo,
      );
      return snapshot == null ? dashboard : Success(snapshot);
    }
    final failure = remoteResult.failureOrNull;
    if (failure == null) {
      return const FailureResult(
        UnknownFailure(message: 'completion failed', code: 'completion_failed'),
      );
    }
    final queue = _queue;
    if (failure.kind != FailureKind.network || queue == null) {
      return FailureResult(failure);
    }
    final snapshot = await _optimistic(
      groupId,
      assignmentId,
      recordedAt,
      undo: undo,
    );
    if (snapshot == null) return FailureResult(failure);
    await queue.enqueue(
      SyncOperation(
        id: '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}',
        type: undo
            ? SyncOperationType.undoCompletion
            : SyncOperationType.markComplete,
        assignmentId: assignmentId,
        clientRecordedAt: recordedAt,
      ),
    );
    return FailureResult(
      OfflineQueuedFailure(
        message: 'completion queued',
        code: 'offline_queued',
      ),
    );
  }

  Future<({String groupId, Map<String, Object?> json})?> _findAssignment(
    String assignmentId,
  ) async {
    for (final row in await _cache.readAll()) {
      final items = (row.json['assignments'] as List? ?? const []).cast<Map>();
      if (items.any((item) => item['assignment_id'] == assignmentId)) {
        return (groupId: row.groupId, json: row.json);
      }
    }
    return null;
  }

  Future<DashboardSnapshot?> _optimistic(
    String groupId,
    String assignmentId,
    DateTime recordedAt, {
    required bool undo,
  }) async {
    final row = await _cache.read(groupId);
    if (row == null) return null;
    final json = Map<String, Object?>.from(row.json);
    final day = Map<String, Object?>.from(json['today']! as Map);
    final rawAssignments = (json['assignments'] as List)
        .map(
          (v) => Map<String, Object?>.from((v as Map).cast<String, Object?>()),
        )
        .toList();
    final current = rawAssignments.firstWhere(
      (a) => a['assignment_id'] == assignmentId,
    );
    final oldStatus = current['status'] as String;
    final state = day['state'] as String;
    if ((!undo && (oldStatus == 'completed' || oldStatus == 'late')) ||
        (undo && (oldStatus == 'pending' || oldStatus == 'missed'))) {
      return dashboardSnapshotFromJson(
        json,
        isStale: true,
        cachedAt: row.cachedAt,
      );
    }
    final nextStatus = undo
        ? (state == 'grace' ? 'missed' : 'pending')
        : (state == 'grace' ? 'late' : 'completed');
    if (undo && oldStatus != 'completed' && oldStatus != 'late') {
      return dashboardSnapshotFromJson(
        json,
        isStale: true,
        cachedAt: row.cachedAt,
      );
    }
    current['status'] = nextStatus;
    current['completed_at'] = undo
        ? null
        : recordedAt.toUtc().toIso8601String();
    for (final values in [json['my_assignments'] as List? ?? const []]) {
      for (final value in values) {
        final assignment = value as Map;
        if (assignment['assignment_id'] == assignmentId) {
          assignment['status'] = nextStatus;
          assignment['completed_at'] = current['completed_at'];
        }
      }
    }
    final countKey = switch (oldStatus) {
      'completed' => 'completed_count',
      'late' => 'late_count',
      'missed' => 'missed_count',
      'pending' => 'pending_count',
      'available' => 'available_count',
      _ => 'unread_count',
    };
    final nextCountKey = switch (nextStatus) {
      'completed' => 'completed_count',
      'late' => 'late_count',
      'missed' => 'missed_count',
      'pending' => 'pending_count',
      'available' => 'available_count',
      _ => 'unread_count',
    };
    day[countKey] = ((day[countKey] as num?)?.toInt() ?? 0) - 1;
    day[nextCountKey] = ((day[nextCountKey] as num?)?.toInt() ?? 0) + 1;
    day['full_khatma'] =
        ((day['completed_count'] as num).toInt() +
            (day['late_count'] as num).toInt()) ==
        30;
    json['today'] = day;
    json['assignments'] = rawAssignments;
    await _cache.upsert(groupId, json);
    final snapshot = dashboardSnapshotFromJson(
      json,
      isStale: true,
      cachedAt: row.cachedAt,
    );
    _controllerFor(groupId).add(snapshot);
    return snapshot;
  }

  @override
  Future<Result<DashboardSnapshot>> volunteer(String assignmentId) =>
      _notImplemented();
  @override
  Future<Result<DashboardSnapshot>> overrideAssignment(
    String assignmentId,
    String membershipId,
  ) => _notImplemented();
  @override
  Future<Result<List<HistoryDaySummary>>> getHistory(
    String groupId, {
    String? beforeDate,
    int limit = 30,
  }) => _notImplemented();
  @override
  Future<Result<HistoryDaySummary>> getHistoryDay(
    String groupId,
    String groupDate,
  ) => _notImplemented();
  @override
  Future<SyncReport> syncPending() async {
    final queue = _queue;
    if (queue == null) {
      return const SyncReport(succeeded: 0, failed: 0, remaining: 0);
    }
    var succeeded = 0;
    var failed = 0;
    for (final op in await queue.pending()) {
      if (op.status == SyncOperationStatus.failed &&
          op.lastErrorKind == 'day_closed') {
        failed++;
        continue;
      }
      await queue.update(
        op.id,
        status: SyncOperationStatus.syncing,
        attempts: op.attempts + 1,
      );
      final result = op.type == SyncOperationType.markComplete
          ? await _remote.markComplete(
              op.assignmentId,
              op.clientRecordedAt,
              offlineSync: true,
            )
          : await _remote.undoCompletion(op.assignmentId);
      if (result.isSuccess) {
        await queue.delete(op.id);
        succeeded++;
        final row = await _findAssignment(op.assignmentId);
        if (row != null) await getDashboard(row.groupId);
      } else {
        final error = result.failureOrNull!;
        if (error.kind == FailureKind.network) {
          await queue.update(
            op.id,
            status: SyncOperationStatus.pending,
            lastErrorKind: error.code,
          );
          break;
        }
        await queue.update(
          op.id,
          status: SyncOperationStatus.failed,
          lastErrorKind: error.code,
        );
        failed++;
      }
    }
    return SyncReport(
      succeeded: succeeded,
      failed: failed,
      remaining: (await queue.pending()).length,
    );
  }

  Future<Result<T>> _notImplemented<T>() async => const FailureResult(
    UnknownFailure(message: 'not implemented', code: 'not_implemented'),
  );
}
