import '../../../core/sync/personal_operation_overlay.dart';
import '../../../core/sync/current_group_day.dart';
import '../../../core/auth/session_gateway.dart';
import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../../../core/storage/daos/daos.dart';
import 'today_remote_data_source.dart';
import 'today_repository.dart';
import 'today_snapshot.dart';

class TodayRepositoryImpl implements TodayRepository {
  TodayRepositoryImpl({
    required this._remote,
    required this._cache,
    required this._session,
    this.pendingOperations,
    this.now = DateTime.now,
  });
  final TodayRemoteDataSource _remote;
  final CachedTodayDao _cache;
  final SessionGateway _session;
  final PersonalOperationOverlay? pendingOperations;
  final DateTime Function() now;
  final Map<String, Future<Result<TodaySnapshot>>> _refreshes = {};

  @override
  Future<Result<TodaySnapshot>> getToday({
    void Function(TodaySnapshot)? onCached,
  }) async {
    final userId = _session.currentUserId;
    if (userId == null) {
      return const FailureResult(
        AuthFailure(message: 'no session', code: 'unauthenticated'),
      );
    }
    if (onCached != null) {
      final cached = await _cache.read(userId);
      if (cached != null && _session.currentUserId == userId) {
        final snapshot = await _snapshot(cached.json, stale: true);
        if (_session.currentUserId == userId) onCached(snapshot);
      }
    }
    return _refreshes.putIfAbsent(
      userId,
      () => _fetch(userId).whenComplete(() {
        _refreshes.remove(userId);
      }),
    );
  }

  Future<TodaySnapshot> _snapshot(
    Map<String, Object?> json, {
    bool stale = false,
  }) async {
    final personal = await pendingOperations?.today(json);
    return TodaySnapshot.fromJson(
      currentTodayJson(personal?.json ?? json, now()),
      isStale: stale || (personal?.hasPending ?? false),
    );
  }

  Future<Result<TodaySnapshot>> _fetch(String userId) async {
    final revision = pendingOperations?.revision;
    try {
      final raw = await _remote.getToday();
      if (revision != pendingOperations?.revision) return await _fetch(userId);
      final json = (raw as Map).cast<String, Object?>();
      if (_session.currentUserId != userId) {
        return const FailureResult(
          AuthFailure(message: 'session changed', code: 'unauthenticated'),
        );
      }
      final snapshot = await _snapshot(json);
      if (revision != pendingOperations?.revision) return await _fetch(userId);
      await _cache.upsert(userId, json);
      if (revision != pendingOperations?.revision) return await _fetch(userId);
      if (_session.currentUserId != userId) {
        return const FailureResult(
          AuthFailure(message: 'session changed', code: 'unauthenticated'),
        );
      }
      return Success(snapshot);
    } catch (error) {
      final cached = _session.currentUserId != userId
          ? null
          : await _cache.read(userId);
      if (cached != null) {
        return Success(await _snapshot(cached.json, stale: true));
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
