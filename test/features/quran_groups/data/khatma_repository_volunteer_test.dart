import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/storage/daos/daos.dart';
import 'package:quran_daily/features/quran_groups/data/data_sources/khatma_remote_data_source.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/khatma_repository_impl.dart';

class _Remote extends Mock implements KhatmaRemoteDataSource {}

class _Cache extends Mock implements CachedSnapshotsDao {}

const current = <String, Object?>{
  'group_id': 'g1',
  'group_name': 'g',
  'my_role': 'member',
  'status': 'active',
  'server_generated_at': '2026-11-15T10:00:00Z',
  'today': {
    'group_date': '2026-11-15',
    'state': 'open',
    'completed_count': 0,
    'late_count': 0,
    'missed_count': 0,
    'unread_count': 0,
    'pending_count': 1,
    'available_count': 1,
    'full_khatma': false,
    'ends_at': '2026-11-15T23:59:00Z',
  },
  'my_assignments': <Object?>[],
  'assignments': <Object?>[
    {
      'assignment_id': 'a1',
      'juz': 8,
      'seat_number': 8,
      'kind': 'unassigned',
      'status': 'available',
      'is_me': false,
      'is_khatm_juz': false,
    },
  ],
};
const updated = <String, Object?>{
  'group_id': 'g1',
  'group_name': 'g',
  'my_role': 'member',
  'status': 'active',
  'server_generated_at': '2026-11-15T10:01:00Z',
  'today': {
    'group_date': '2026-11-15',
    'state': 'open',
    'completed_count': 0,
    'late_count': 0,
    'missed_count': 0,
    'unread_count': 0,
    'pending_count': 2,
    'available_count': 0,
    'full_khatma': false,
    'ends_at': '2026-11-15T23:59:00Z',
  },
  'my_assignments': <Object?>[
    {
      'assignment_id': 'a1',
      'juz': 8,
      'seat_number': 8,
      'kind': 'volunteer',
      'status': 'pending',
      'is_me': true,
      'is_khatm_juz': false,
    },
  ],
  'assignments': <Object?>[
    {
      'assignment_id': 'a1',
      'juz': 8,
      'seat_number': 8,
      'kind': 'volunteer',
      'status': 'pending',
      'is_me': true,
      'is_khatm_juz': false,
    },
  ],
};

void main() {
  late _Remote remote;
  late _Cache cache;
  late KhatmaRepositoryImpl repository;
  setUp(() {
    remote = _Remote();
    cache = _Cache();
    repository = KhatmaRepositoryImpl(remote: remote, cache: cache);
  });

  test('successful volunteer refreshes and caches the dashboard', () async {
    when(() => cache.readAll()).thenAnswer(
      (_) async => [
        (groupId: 'g1', json: current, cachedAt: DateTime.utc(2026)),
      ],
    );
    when(
      () => remote.volunteer('a1'),
    ).thenAnswer((_) async => const Success<dynamic>({'assignment_id': 'a1'}));
    when(
      () => remote.getDashboard('g1'),
    ).thenAnswer((_) async => const Success<dynamic>(updated));
    when(() => cache.upsert('g1', any())).thenAnswer((_) async {});
    final result = await repository.volunteer('a1');
    expect(result.valueOrNull?.myAssignments.single.kind.name, 'volunteer');
    expect(result.valueOrNull?.today?.availableCount, 0);
    verify(() => cache.upsert('g1', any())).called(1);
  });

  test(
    'taken juz is a conflict and does not pretend the action succeeded',
    () async {
      when(() => cache.readAll()).thenAnswer(
        (_) async => [
          (groupId: 'g1', json: current, cachedAt: DateTime.utc(2026)),
        ],
      );
      when(() => remote.volunteer('a1')).thenAnswer(
        (_) async => const FailureResult<dynamic>(
          SyncConflictFailure(message: 'taken', code: 'juz_already_taken'),
        ),
      );
      final result = await repository.volunteer('a1');
      expect(result.failureOrNull?.kind, FailureKind.conflict);
      verifyNever(() => remote.getDashboard(any()));
    },
  );

  test('offline volunteer returns a network failure', () async {
    when(() => cache.readAll()).thenAnswer(
      (_) async => [
        (groupId: 'g1', json: current, cachedAt: DateTime.utc(2026)),
      ],
    );
    when(() => remote.volunteer('a1')).thenAnswer(
      (_) async => const FailureResult<dynamic>(
        NetworkFailure(message: 'offline', code: 'network'),
      ),
    );
    final result = await repository.volunteer('a1');
    expect(result.failureOrNull?.kind, FailureKind.network);
  });
}
