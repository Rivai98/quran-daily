import 'dart:async';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/storage/daos/daos.dart';
import '../data_sources/khatma_remote_data_source.dart';
import '../entities/entities.dart';
import '../models/models.dart';
import 'khatma_repository.dart';

/// Network-backed khatma repository with a local dashboard snapshot cache.
class KhatmaRepositoryImpl extends KhatmaRepository {
  KhatmaRepositoryImpl({
    required KhatmaRemoteDataSource remote,
    required CachedSnapshotsDao cache,
  }) : _remote = remote,
       _cache = cache;

  final KhatmaRemoteDataSource _remote;
  final CachedSnapshotsDao _cache;
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

  // Completion, volunteering, and history operations are added by their
  // dependent story phases. Keep the shared contract compilable meanwhile.
  @override
  Future<Result<DashboardSnapshot>> markComplete(
    String assignmentId,
    DateTime clientRecordedAt,
  ) => _notImplemented();
  @override
  Future<Result<DashboardSnapshot>> undoCompletion(String assignmentId) =>
      _notImplemented();
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
  Future<SyncReport> syncPending() async =>
      const SyncReport(succeeded: 0, failed: 0, remaining: 0);

  Future<Result<T>> _notImplemented<T>() async => const FailureResult(
    UnknownFailure(message: 'not implemented', code: 'not_implemented'),
  );
}
