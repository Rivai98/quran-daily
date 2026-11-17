import '../../../../core/sync/personal_operation_overlay.dart';
import '../../../../core/auth/session_gateway.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/storage/daos/daos.dart';
import '../data_sources/log_remote_data_source.dart';
import '../entities/log_entities.dart';
import 'log_repository.dart';

class LogRepositoryImpl implements LogRepository {
  const LogRepositoryImpl({
    required this._remote,
    required this._cache,
    required this._session,
    this.pendingOperations,
  });
  final LogRemoteDataSource _remote;
  final CachedHistoryDao _cache;
  final SessionGateway _session;
  final PersonalOperationOverlay? pendingOperations;

  String? get _cacheKey => _session.currentUserId == null
      ? null
      : 'personal-log:${_session.currentUserId}';

  @override
  Future<Result<PersonalLog>> getLog({
    String? before,
    int days = 30,
    void Function(PersonalLog)? onCached,
  }) async {
    final revision = pendingOperations?.revision;
    final cacheKey = _cacheKey;
    if (before == null && cacheKey != null && onCached != null) {
      final cached = await _cache.read(cacheKey);
      if (cached != null && _cacheKey == cacheKey) {
        final log = await _personalLog(cached.json, stale: true);
        if (_cacheKey == cacheKey) onCached(log);
      }
    }
    try {
      final log = await _remote.getLog(before: before, days: days);
      if (revision != pendingOperations?.revision) {
        return await getLog(before: before, days: days);
      }
      if (_cacheKey != cacheKey) {
        return const FailureResult(
          AuthFailure(message: 'session changed', code: 'unauthenticated'),
        );
      }
      final json = _toJson(log);
      final reconciled = await _personalLog(json);
      if (revision != pendingOperations?.revision) {
        return await getLog(before: before, days: days);
      }
      if (before == null && cacheKey != null) {
        await _cache.upsert(cacheKey, json);
      }
      if (revision != pendingOperations?.revision) {
        return await getLog(before: before, days: days);
      }
      if (_cacheKey != cacheKey) {
        return const FailureResult(
          AuthFailure(message: 'session changed', code: 'unauthenticated'),
        );
      }
      return Success(reconciled);
    } on AppFailure catch (failure) {
      if (failure.kind == FailureKind.network &&
          before == null &&
          _cacheKey != null) {
        final cached = await _cache.read(_cacheKey!);
        if (cached != null) {
          return Success(await _personalLog(cached.json, stale: true));
        }
      }
      return FailureResult(failure);
    } catch (error) {
      return FailureResult(
        UnknownFailure(
          message: 'log load failed',
          code: 'unknown',
          cause: error,
        ),
      );
    }
  }

  Future<PersonalLog> _personalLog(
    Map<String, Object?> json, {
    bool stale = false,
  }) async {
    final personal = await pendingOperations?.log(json);
    return PersonalLog.fromJson(personal?.json ?? json)
        .copyWith(isStale: stale || (personal?.hasPending ?? false));
  }

  Map<String, Object?> _toJson(PersonalLog log) => {
    'streak': log.streak,
    'best_streak': log.bestStreak,
    'month': {
      'year': log.month.year,
      'month': log.month.month,
      'full_days': log.month.fullDays,
      'days_with_items': log.month.daysWithItems,
    },
    'next_before': log.nextBefore,
    'days': log.days
        .map(
          (day) => {
            'date': day.date.toIso8601String().substring(0, 10),
            'complete': day.complete,
            'items': day.items
                .map(
                  (item) => {
                    'group_id': item.groupId,
                    'group_name': item.groupName,
                    'portion_unit': item.portionUnit,
                    'portion_index': item.portionIndex,
                    'kind': item.kind.name,
                    'status': item.status.name,
                    'completed_at': item.completedAt?.toIso8601String(),
                    'group_day_id': item.groupDayId,
                  },
                )
                .toList(),
          },
        )
        .toList(),
  };
}
