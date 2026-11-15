import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/storage/daos/daos.dart';
import 'package:quran_daily/features/quran_groups/data/data_sources/khatma_remote_data_source.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/khatma_repository_impl.dart';

import '../../../helpers/test_fixtures.dart';

class _MockRemote extends Mock implements KhatmaRemoteDataSource {}
class _MockHistoryDao extends Mock implements CachedHistoryDao {}
class _MockSnapshots extends Mock implements CachedSnapshotsDao {}

void main() {
  late _MockRemote remote;
  late _MockHistoryDao historyDao;
  late KhatmaRepositoryImpl repository;

  const groupId = TestFixtures.groupId;

  setUp(() {
    remote = _MockRemote();
    historyDao = _MockHistoryDao();
    when(() => historyDao.upsert(any(), any())).thenAnswer((_) async {});

    repository = KhatmaRepositoryImpl(
      remote: remote,
      historyDao: historyDao,
      cache: _MockSnapshots(),
    );
  });

  group('getHistory', () {
    test('online success caches last page and returns days', () async {
      final daysPayload = [
        {
          'group_date': '2026-11-14',
          'completed_count': 28,
          'late_count': 2,
          'missed_count': 0,
          'unread_count': 0,
          'full_khatma': true,
        },
        {
          'group_date': '2026-11-13',
          'completed_count': 25,
          'late_count': 0,
          'missed_count': 5,
          'unread_count': 0,
          'full_khatma': false,
        },
      ];

      when(() => remote.call('get_history', any()))
          .thenAnswer((_) async => Success(daysPayload));

      final result = await repository.getHistory(groupId);

      expect(result.isSuccess, isTrue);
      final days = result.valueOrNull!;
      expect(days.length, 2);
      expect(days.first.groupDate, '2026-11-14');
      expect(days.first.fullKhatma, isTrue);
      verify(() => historyDao.upsert(groupId, any())).called(1);
    });

    test('offline fallback returns cached days when available', () async {
      when(() => remote.call('get_history', any())).thenAnswer(
        (_) async => const FailureResult(NetworkFailure(message: 'offline', code: 'network')),
      );

      when(() => historyDao.read(groupId)).thenAnswer(
        (_) async => (
          json: {
            'days': [
              {
                'group_date': '2026-11-14',
                'completed_count': 28,
                'late_count': 2,
                'missed_count': 0,
                'unread_count': 0,
                'full_khatma': true,
              }
            ]
          },
          cachedAt: DateTime(2026, 11, 14),
        ),
      );

      final result = await repository.getHistory(groupId);

      expect(result.isSuccess, isTrue);
      final days = result.valueOrNull!;
      expect(days.length, 1);
      expect(days.first.groupDate, '2026-11-14');
    });

    test('offline without cache returns NetworkFailure', () async {
      when(() => remote.call('get_history', any())).thenAnswer(
        (_) async => const FailureResult(NetworkFailure(message: 'offline', code: 'network')),
      );
      when(() => historyDao.read(groupId)).thenAnswer((_) async => null);

      final result = await repository.getHistory(groupId);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('paging passes beforeDate to remote call and does not overwrite cache', () async {
      when(() => remote.call('get_history', {
        'p_group_id': groupId,
        'p_before_date': '2026-11-13',
        'p_limit': 30,
      })).thenAnswer((_) async => const Success([]));

      final result = await repository.getHistory(groupId, beforeDate: '2026-11-13');

      expect(result.isSuccess, isTrue);
      verifyNever(() => historyDao.upsert(any(), any()));
    });
  });

  group('getHistoryDay', () {
    test('success returns day detail', () async {
      final dayPayload = {
        'group_date': '2026-11-10',
        'completed_count': 28,
        'late_count': 2,
        'missed_count': 0,
        'unread_count': 0,
        'full_khatma': true,
        'my_result': {
          'assignment_id': 'a-1',
          'juz': 3,
          'seat_number': 3,
          'kind': 'seat',
          'status': 'completed',
          'reader_display_name': 'قارئ',
          'is_me': true,
        },
        'per_juz': [
          {
            'assignment_id': 'a-1',
            'juz': 1,
            'seat_number': 1,
            'kind': 'seat',
            'status': 'completed',
            'reader_display_name': 'المالك',
            'is_me': false,
          }
        ],
      };

      when(() => remote.call('get_history_day', {
        'p_group_id': groupId,
        'p_group_date': '2026-11-10',
      })).thenAnswer((_) async => Success(dayPayload));

      final result = await repository.getHistoryDay(groupId, '2026-11-10');

      expect(result.isSuccess, isTrue);
      final detail = result.valueOrNull!;
      expect(detail.groupDate, '2026-11-10');
      expect(detail.fullKhatma, isTrue);
      expect(detail.myResult?.seatNumber, 3);
      expect(detail.perJuz?.length, 1);
    });

    test('error maps failure', () async {
      when(() => remote.call('get_history_day', any())).thenAnswer(
        (_) async => const FailureResult(UnknownFailure(message: 'day_not_found', code: 'day_not_found')),
      );

      final result = await repository.getHistoryDay(groupId, '2026-11-01');

      expect(result.isFailure, isTrue);
    });
  });
}
