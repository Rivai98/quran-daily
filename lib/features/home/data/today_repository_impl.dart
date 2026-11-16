import '../../../core/auth/session_gateway.dart';
import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../../../core/storage/daos/daos.dart';
import 'today_remote_data_source.dart';
import 'today_repository.dart';
import 'today_snapshot.dart';

class TodayRepositoryImpl implements TodayRepository {
  const TodayRepositoryImpl({
    required this._remote,
    required this._cache,
    required this._session,
  });
  final TodayRemoteDataSource _remote;
  final CachedTodayDao _cache;
  final SessionGateway _session;
  @override
  Future<Result<TodaySnapshot>> getToday() async {
    try {
      final raw = await _remote.getToday();
      final json = (raw as Map).cast<String, Object?>();
      final snapshot = TodaySnapshot.fromJson(json);
      final userId = _session.currentUserId;
      if (userId != null) await _cache.upsert(userId, json);
      return Success(snapshot);
    } catch (error) {
      final userId = _session.currentUserId;
      final cached = userId == null ? null : await _cache.read(userId);
      if (cached != null) {
        return Success(TodaySnapshot.fromJson(cached.json, isStale: true));
      }
      if (error is AppFailure) return FailureResult(error);
      return const FailureResult(
        NetworkFailure(message: 'today unavailable', code: 'network'),
      );
    }
  }

  @override
  Future<Result<void>> setMainGroup(String? groupId) async {
    try {
      await _remote.setMainGroup(groupId);
      return const Success(null);
    } catch (error) {
      return FailureResult(
        error is AppFailure
            ? error
            : const NetworkFailure(
                message: 'main group update failed',
                code: 'network',
              ),
      );
    }
  }

  @override
  Future<void> markGroupOpened(String groupId) =>
      _remote.markGroupOpened(groupId);
}
