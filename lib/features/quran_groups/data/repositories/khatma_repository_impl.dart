import '../../../../core/errors/result.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/storage/daos/daos.dart';
import '../data_sources/khatma_remote_data_source.dart';
import '../entities/entities.dart';
import '../models/models.dart';
import 'khatma_repository.dart';

/// Khatma repository over Supabase RPCs + SQLite cache (repository contract).
/// US7 implements history methods: getHistory (cache last page) and getHistoryDay.
class KhatmaRepositoryImpl implements KhatmaRepository {
  KhatmaRepositoryImpl({
    required KhatmaRemoteDataSource remote,
    required CachedHistoryDao historyDao,
    ConnectivityService? connectivity,
  })  : _remote = remote,
        _historyDao = historyDao,
        _connectivity = connectivity;

  final KhatmaRemoteDataSource _remote;
  final CachedHistoryDao _historyDao;
  final ConnectivityService? _connectivity;

  ConnectivityService? get connectivity => _connectivity;

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
            .map((e) => historyDaySummaryFromJson(
                (e as Map).cast<String, Object?>()))
            .toList();

        if (beforeDate == null) {
          await _historyDao.upsert(groupId, {
            'days': days.map(historyDaySummaryToJson).toList(),
          });
        }
        return Success(days);
      },
      failure: (failure) async {
        if (beforeDate == null) {
          final cached = await _historyDao.read(groupId);
          if (cached != null) {
            final rawList = (cached.json['days'] as List?) ?? const [];
            final days = rawList
                .map((e) => historyDaySummaryFromJson(
                    (e as Map).cast<String, Object?>()))
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

  @override
  Future<Result<DashboardSnapshot>> getDashboard(String groupId) =>
      throw UnimplementedError('US1 owns getDashboard');

  @override
  Stream<DashboardSnapshot?> watchCachedDashboard(String groupId) =>
      throw UnimplementedError('US1 owns watchCachedDashboard');

  @override
  Future<Result<DashboardSnapshot>> markComplete(
          String assignmentId, DateTime clientRecordedAt) =>
      throw UnimplementedError('US3 owns markComplete');

  @override
  Future<Result<DashboardSnapshot>> undoCompletion(String assignmentId) =>
      throw UnimplementedError('US3 owns undoCompletion');

  @override
  Future<Result<DashboardSnapshot>> volunteer(String assignmentId) =>
      throw UnimplementedError('US5 owns volunteer');

  @override
  Future<Result<DashboardSnapshot>> overrideAssignment(
          String assignmentId, String membershipId) =>
      throw UnimplementedError('US6 owns overrideAssignment');

  @override
  Future<SyncReport> syncPending() =>
      throw UnimplementedError('US3 owns syncPending');
}
