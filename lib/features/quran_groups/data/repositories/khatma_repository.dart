import '../../../../core/errors/result.dart';
import '../entities/entities.dart';

class SyncReport {
  const SyncReport({
    required this.succeeded,
    required this.failed,
    required this.remaining,
    this.refreshedGroupIds = const {},
  });

  final int succeeded;
  final int failed;
  final int remaining;
  final Set<String> refreshedGroupIds;
}

/// Daily khatma read/completion repository (repository contract).
abstract class KhatmaRepository {
  /// Shared network revalidation; caches the result with pending personal
  /// operations applied. Network failure returns stale cache when available.
  /// Views subscribe to [watchCachedDashboard] for immediate cached content.
  Future<Result<DashboardSnapshot>> getDashboard(String groupId);

  /// Emits the cached snapshot (or null) whenever the cache changes.
  Stream<DashboardSnapshot?> watchCachedDashboard(String groupId);

  /// Online call; offline: optimistic cache update + enqueue + offlineQueued.
  Future<Result<DashboardSnapshot>> markComplete(
    String assignmentId,
    DateTime clientRecordedAt,
  );
  Future<Result<DashboardSnapshot>> undoCompletion(String assignmentId);

  /// Network-only.
  Future<Result<DashboardSnapshot>> volunteer(String assignmentId);
  Future<Result<DashboardSnapshot>> overrideAssignment(
    String assignmentId,
    String membershipId,
  );

  /// Network + cache last page.
  Future<Result<List<HistoryDaySummary>>> getHistory(
    String groupId, {
    String? beforeDate,
    int limit = 30,
  });
  Future<Result<HistoryDaySummary>> getHistoryDay(
    String groupId,
    String groupDate,
  );

  /// Replays the sync queue in order; `day_closed` maps to a failed item.
  Future<SyncReport> syncPending();
}

extension KhatmaHistoryCycles on KhatmaRepository {
  Future<Result<List<HistoryCycleSummary>>> getHistoryCycles(
    String groupId, {
    String? beforeDate,
    int limit = 30,
  }) async {
    final result = await getHistory(
      groupId,
      beforeDate: beforeDate,
      limit: limit,
    );
    return result.when(
      success: (days) => Success(groupHistoryByCycle(days)),
      failure: FailureResult<List<HistoryCycleSummary>>.new,
    );
  }
}
