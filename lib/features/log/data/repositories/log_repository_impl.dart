import '../../../../core/auth/session_gateway.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/storage/daos/daos.dart';
import '../data_sources/log_remote_data_source.dart';
import '../entities/log_entities.dart';
import 'log_repository.dart';

class LogRepositoryImpl implements LogRepository {
  const LogRepositoryImpl({
    required LogRemoteDataSource remote,
    required CachedHistoryDao cache,
    required SessionGateway session,
  }) : _remote = remote,
       _cache = cache,
       _session = session;
  final LogRemoteDataSource _remote;
  final CachedHistoryDao _cache;
  final SessionGateway _session;

  String? get _cacheKey => _session.currentUserId == null
      ? null
      : 'personal-log:${_session.currentUserId}';

  @override
  Future<Result<PersonalLog>> getLog({String? before, int days = 30}) async {
    try {
      final log = await _remote.getLog(before: before, days: days);
      if (before == null && _cacheKey != null) {
        await _cache.upsert(_cacheKey!, _toJson(log));
      }
      return Success(log);
    } on AppFailure catch (failure) {
      if (failure.kind == FailureKind.network &&
          before == null &&
          _cacheKey != null) {
        final cached = await _cache.read(_cacheKey!);
        if (cached != null) {
          return Success(
            PersonalLog.fromJson(cached.json).copyWith(isStale: true),
          );
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
