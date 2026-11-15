import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/storage/daos/daos.dart';
import 'package:quran_daily/features/quran_groups/data/data_sources/khatma_remote_data_source.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/khatma_repository_impl.dart';

class _Remote extends Mock implements KhatmaRemoteDataSource {}

class _Cache extends Mock implements CachedSnapshotsDao {}

void main() {
  late _Remote remote;
  late _Cache cache;
  late KhatmaRepositoryImpl repository;

  setUp(() {
    remote = _Remote();
    cache = _Cache();
    repository = KhatmaRepositoryImpl(remote: remote, cache: cache);
  });

  const snapshotJson = <String, Object?>{
    'group_id': 'g1',
    'group_name': 'test',
    'my_role': 'member',
    'status': 'active',
    'server_generated_at': '2026-11-15T00:00:00Z',
    'today': {
      'group_date': '2026-11-15',
      'state': 'open',
      'completed_count': 0,
      'late_count': 0,
      'missed_count': 0,
      'unread_count': 29,
      'pending_count': 1,
      'available_count': 0,
      'full_khatma': false,
      'ends_at': '2026-11-16T00:00:00Z',
    },
    'my_assignments': <Object?>[],
    'assignments': <Object?>[],
  };

  test('network success returns and caches the dashboard snapshot', () async {
    when(
      () => remote.getDashboard('g1'),
    ).thenAnswer((_) async => const Success<dynamic>(snapshotJson));
    when(() => cache.upsert('g1', any())).thenAnswer((_) async {});

    final result = await repository.getDashboard('g1');

    expect(result.valueOrNull?.groupId, 'g1');
    expect(result.valueOrNull?.isStale, isFalse);
    verify(() => cache.upsert('g1', any())).called(1);
  });

  test(
    'network failure returns cached dashboard with stale marker and time',
    () async {
      final cachedAt = DateTime.parse('2026-11-14T22:00:00Z');
      when(() => remote.getDashboard('g1')).thenAnswer(
        (_) async => const FailureResult<dynamic>(
          NetworkFailure(message: 'offline', code: 'network'),
        ),
      );
      when(
        () => cache.read('g1'),
      ).thenAnswer((_) async => (json: snapshotJson, cachedAt: cachedAt));

      final result = await repository.getDashboard('g1');

      expect(result.valueOrNull?.isStale, isTrue);
      expect(result.valueOrNull?.cachedAt, cachedAt);
    },
  );

  test('network failure without a cached snapshot stays a failure', () async {
    when(() => remote.getDashboard('g1')).thenAnswer(
      (_) async => const FailureResult<dynamic>(
        NetworkFailure(message: 'offline', code: 'network'),
      ),
    );
    when(() => cache.read('g1')).thenAnswer((_) async => null);

    final result = await repository.getDashboard('g1');

    expect(result.isFailure, isTrue);
  });

  test('cache watcher emits the initial cached snapshot', () async {
    final cachedAt = DateTime.parse('2026-11-14T22:00:00Z');
    when(
      () => cache.read('g1'),
    ).thenAnswer((_) async => (json: snapshotJson, cachedAt: cachedAt));

    final snapshots = await repository
        .watchCachedDashboard('g1')
        .take(1)
        .toList();

    expect(snapshots.single?.isStale, isTrue);
    expect(snapshots.single?.cachedAt, cachedAt);
  });

  test('cache watcher emits null when no dashboard was cached', () async {
    when(() => cache.read('g1')).thenAnswer((_) async => null);

    final snapshots = await repository
        .watchCachedDashboard('g1')
        .take(1)
        .toList();

    expect(snapshots, [null]);
  });
}
