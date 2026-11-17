import '../../../../core/sync/personal_operation_overlay.dart';
import '../../../../core/sync/current_group_day.dart';

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
    required this._remote,
    required this._cache,
    this._queue,
    this._historyDao,
    this._onCompletionChanged,
    this.now = DateTime.now,
    PersonalOperationOverlay? pendingOperations,
  }) : _pendingOperations =
           pendingOperations ??
           (_queue == null
               ? null
               : PersonalOperationOverlay(queue: _queue, snapshots: _cache));

  final KhatmaRemoteDataSource _remote;
  final DateTime Function() now;
  final PersonalOperationOverlay? _pendingOperations;
  final Map<String, Future<Result<DashboardSnapshot>>> _dashboardReads = {};
  final Map<String, int> _versions = {};
  final Map<String, Future<void>> _cacheWrites = {};
  Future<SyncReport>? _syncing;
  DateTime? _retryAfter;
  final CachedSnapshotsDao _cache;
  final SyncQueueDao? _queue;
  final CachedHistoryDao? _historyDao;
  final Future<void> Function(String groupId)? _onCompletionChanged;
  final Map<String, StreamController<DashboardSnapshot?>> _updates = {};

  StreamController<DashboardSnapshot?> _controllerFor(String groupId) =>
      _updates.putIfAbsent(
        groupId,
        () => StreamController<DashboardSnapshot?>.broadcast(),
      );

  @override
  Stream<DashboardSnapshot?> watchCachedDashboard(String groupId) =>
      Stream.multi((events) {
        var changed = false;
        var cancelled = false;
        final subscription = _controllerFor(groupId).stream.listen((snapshot) {
          changed = true;
          events.add(snapshot);
        }, onError: events.addError);
        events.onCancel = () {
          cancelled = true;
          return subscription.cancel();
        };
        _cachedDashboard(groupId).then(
          (snapshot) {
            if (!changed && !cancelled) events.add(snapshot);
          },
          onError: (Object error, StackTrace stack) {
            if (!cancelled) events.addError(error, stack);
          },
        );
      });

  Future<DashboardSnapshot?> _cachedDashboard(String groupId) async {
    final cached = await _cache.read(groupId);
    if (cached == null) return null;
    final personal = await _pendingOperations?.dashboard(cached.json);
    return dashboardSnapshotFromJson(
      currentDashboardJson(personal?.json ?? cached.json, now()),
      isStale: true,
      cachedAt: cached.cachedAt,
    );
  }

  @override
  Future<Result<DashboardSnapshot>> getDashboard(String groupId) {
    final running = _dashboardReads[groupId];
    if (running != null) return running;
    late Future<Result<DashboardSnapshot>> read;
    read = _fetchDashboard(groupId, _versions[groupId] ?? 0).whenComplete(() {
      if (identical(_dashboardReads[groupId], read)) {
        _dashboardReads.remove(groupId);
      }
    });
    _dashboardReads[groupId] = read;
    return read;
  }

  @override
  Future<Result<DashboardSnapshot>> refreshDashboard(String groupId) {
    _invalidateDashboard(groupId);
    return getDashboard(groupId);
  }

  Future<Result<DashboardSnapshot>> _fetchDashboard(
    String groupId,
    int version,
  ) async {
    final result = await _remote.getDashboard(groupId);
    if (version != (_versions[groupId] ?? 0)) return getDashboard(groupId);
    return result.when(
      success: (payload) async {
        final json = (payload! as Map).cast<String, Object?>();
        final snapshot = await _writeCache<DashboardSnapshot?>(
          groupId,
          () async {
            final personal = await _pendingOperations?.dashboard(json);
            if (version != (_versions[groupId] ?? 0)) return null;
            final reconciled = personal?.json ?? json;
            await _cache.upsert(groupId, reconciled);
            final snapshot = dashboardSnapshotFromJson(
              currentDashboardJson(reconciled, now()),
              isStale: personal?.hasPending ?? false,
            );
            _controllerFor(groupId).add(snapshot);
            return snapshot;
          },
        );
        return snapshot == null ? getDashboard(groupId) : Success(snapshot);
      },
      failure: (failure) async {
        if (failure.kind != FailureKind.network) return FailureResult(failure);
        final snapshot = await _cachedDashboard(groupId);
        if (snapshot == null) return FailureResult(failure);
        _controllerFor(groupId).add(snapshot);
        return Success(snapshot);
      },
    );
  }

  Future<T> _writeCache<T>(String groupId, Future<T> Function() write) {
    final previous = _cacheWrites[groupId] ?? Future<void>.value();
    final next = previous.then((_) => write());
    // The caller receives failures; the next independent write can still proceed.
    _cacheWrites[groupId] = next.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return next;
  }

  void _invalidateDashboard(String groupId) {
    _pendingOperations?.changed();
    _versions[groupId] = (_versions[groupId] ?? 0) + 1;
    _dashboardReads.remove(groupId);
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
      final dashboard = await refreshDashboard(groupId);
      if (dashboard.isSuccess) {
        unawaited(_refreshReminders(groupId));
        return dashboard;
      }
      final snapshot = await _writeCache(
        groupId,
        () => _optimistic(groupId, assignmentId, recordedAt, undo: undo),
      );
      if (snapshot != null) unawaited(_refreshReminders(groupId));
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
    final snapshot = await _writeCache(groupId, () async {
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
      // Reads must observe a revision change after the operation is durable.
      _invalidateDashboard(groupId);
      return _optimistic(groupId, assignmentId, recordedAt, undo: undo);
    });
    if (snapshot == null) return FailureResult(failure);
    unawaited(_refreshReminders(groupId));
    return FailureResult(
      OfflineQueuedFailure(
        message: 'completion queued',
        code: 'offline_queued',
      ),
    );
  }

  Future<void> _refreshReminders(String groupId) async {
    try {
      await _onCompletionChanged?.call(groupId);
    } catch (_) {
      // A notification rebuild must not block completion or undo.
    }
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
        currentDashboardJson(json, now()),
        isStale: true,
        cachedAt: row.cachedAt,
      );
    }
    final nextStatus = undo
        ? (state == 'grace' ? 'missed' : 'pending')
        : (state == 'grace' ? 'late' : 'completed');
    if (undo && oldStatus != 'completed' && oldStatus != 'late') {
      return dashboardSnapshotFromJson(
        currentDashboardJson(json, now()),
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
      currentDashboardJson(json, now()),
      isStale: true,
      cachedAt: row.cachedAt,
    );
    _controllerFor(groupId).add(snapshot);
    return snapshot;
  }

  @override
  Future<Result<DashboardSnapshot>> volunteer(String assignmentId) async {
    final cached = await _findAssignment(assignmentId);
    if (cached == null) {
      return const FailureResult(
        UnknownFailure(
          message: 'assignment not cached',
          code: 'assignment_not_cached',
        ),
      );
    }
    final result = await _remote.volunteer(assignmentId);
    if (result.isFailure) return FailureResult(result.failureOrNull!);
    return refreshDashboard(cached.groupId);
  }

  @override
  Future<Result<DashboardSnapshot>> overrideAssignment(
    String assignmentId,
    String membershipId,
  ) async {
    final cached = await _findAssignment(assignmentId);
    if (cached == null) {
      return const FailureResult(
        UnknownFailure(
          message: 'assignment not cached',
          code: 'assignment_not_cached',
        ),
      );
    }
    final result = await _remote.overrideAssignment(assignmentId, membershipId);
    return result.when(
      success: (_) => refreshDashboard(cached.groupId),
      failure: FailureResult<DashboardSnapshot>.new,
    );
  }

  @override
  Future<Result<List<HistoryDaySummary>>> getHistory(
    String groupId, {
    String? beforeDate,
    int limit = 30,
  }) async {
    final params = <String, Object?>{
      'p_group_id': groupId,
      'p_before_date': ?beforeDate,
      'p_limit': limit,
    };

    final result = await _remote.call('get_history', params);

    return result.when(
      success: (payload) async {
        final rawList = (payload as List).cast<dynamic>();
        final days = rawList
            .map(
              (e) =>
                  historyDaySummaryFromJson((e as Map).cast<String, Object?>()),
            )
            .toList();

        if (beforeDate == null) {
          await _historyDao?.upsert(groupId, {
            'days': days.map(historyDaySummaryToJson).toList(),
          });
        }
        return Success(days);
      },
      failure: (failure) async {
        if (beforeDate == null) {
          final cached = await _historyDao?.read(groupId);
          if (cached != null) {
            final rawList = (cached.json['days'] as List?) ?? const [];
            final days = rawList
                .map(
                  (e) => historyDaySummaryFromJson(
                    (e as Map).cast<String, Object?>(),
                  ),
                )
                .toList();
            return Success(days);
          }
        }
        return FailureResult(failure);
      },
    );
  }

  @override
  Future<Result<HistoryDaySummary>> getHistoryDay(
    String groupId,
    String groupDate,
  ) async {
    final params = <String, Object?>{
      'p_group_id': groupId,
      'p_group_date': groupDate,
    };

    final result = await _remote.call('get_history_day', params);

    return result.when(
      success: (payload) {
        final json = (payload as Map).cast<String, Object?>();
        return Success(historyDaySummaryFromJson(json));
      },
      failure: (failure) => FailureResult(failure),
    );
  }

  Future<String?> _operationGroup(String assignmentId) async {
    for (final row in await _cache.readAll()) {
      final assignments = row.json['assignments'] as List? ?? const [];
      final contexts = row.json['_pending_contexts'] as Map? ?? const {};
      if (assignments.any(
            (raw) => (raw as Map)['assignment_id'] == assignmentId,
          ) ||
          contexts.containsKey(assignmentId)) {
        return row.groupId;
      }
    }
    return null;
  }

  @override
  Future<SyncReport> syncPending() => _syncing ??= _replay().whenComplete(() {
    _syncing = null;
  });

  Future<SyncReport> _replay() async {
    final queue = _queue;
    if (queue == null) {
      return const SyncReport(succeeded: 0, failed: 0, remaining: 0);
    }
    final operations = await queue.pending();
    if (_retryAfter?.isAfter(now()) ?? false) {
      return SyncReport(succeeded: 0, failed: 0, remaining: operations.length);
    }
    var succeeded = 0;
    var failed = 0;
    final affected = <String>{};
    for (final op in operations) {
      if (op.status == SyncOperationStatus.failed) {
        failed++;
        continue;
      }
      // Keep the operation pending until acknowledgment so concurrent reads
      // continue to overlay its personal status while the RPC is in flight.
      await queue.update(op.id, attempts: op.attempts + 1);
      final result = op.type == SyncOperationType.markComplete
          ? await _remote.markComplete(
              op.assignmentId,
              op.clientRecordedAt,
              offlineSync: true,
            )
          : await _remote.undoCompletion(op.assignmentId);
      if (result.isSuccess) {
        final groupId = await _operationGroup(op.assignmentId);
        if (groupId != null) {
          affected.add(groupId);
          _invalidateDashboard(groupId);
        }
        await queue.delete(op.id);
        _retryAfter = null;
        succeeded++;
      } else {
        final error = result.failureOrNull!;
        if (error.kind == FailureKind.network) {
          await queue.update(
            op.id,
            status: SyncOperationStatus.pending,
            lastErrorKind: error.code,
          );
          _retryAfter = now().add(
            Duration(seconds: min(60, 1 << min(op.attempts, 6))),
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
    final refreshed = <String>{};
    for (final groupId in affected) {
      if ((await getDashboard(groupId)).isSuccess) refreshed.add(groupId);
      unawaited(_refreshReminders(groupId));
    }
    return SyncReport(
      succeeded: succeeded,
      failed: failed,
      remaining: (await queue.pending()).length,
      refreshedGroupIds: refreshed,
    );
  }
}
