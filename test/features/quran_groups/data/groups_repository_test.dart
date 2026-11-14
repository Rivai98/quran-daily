import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/auth/session_gateway.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/network/connectivity_service.dart';
import 'package:quran_daily/core/network/rpc_client.dart';
import 'package:quran_daily/core/storage/daos/daos.dart';
import 'package:quran_daily/features/quran_groups/data/data_sources/groups_remote_data_source.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository_impl.dart';

class _MockRpc extends Mock implements RpcClient {}

class _MockRemote extends Mock implements GroupsRemoteDataSource {}

class _MockGroups extends Mock implements CachedGroupsDao {}

class _MockSession extends Mock implements SessionGateway {}

class _MockConnectivity extends Mock implements ConnectivityService {}

void main() {
  late _MockRpc rpc;
  late _MockRemote remote;
  late _MockGroups cache;
  late _MockSession session;
  late _MockConnectivity connectivity;
  late GroupsRepositoryImpl repository;

  setUp(() {
    rpc = _MockRpc();
    remote = _MockRemote();
    cache = _MockGroups();
    session = _MockSession();
    connectivity = _MockConnectivity();
    repository = GroupsRepositoryImpl(
      rpc: rpc,
      remote: remote,
      cache: cache,
      sessionGateway: session,
      connectivity: connectivity,
    );
    registerFallbackValue(const CreateGroupInput(
      name: 'x',
      timezone: 'Africa/Cairo',
      visibility: GroupVisibility.private,
      joinMode: JoinMode.approval,
    ));
  });

  group('getMyGroups', () {
    test('network success caches and returns the overview', () async {
      when(() => session.currentUserId).thenReturn('u1');
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(() => remote.call('get_my_groups', null))
          .thenAnswer((_) async => const Success<dynamic>({
                'groups': [
                  {
                    'group_id': 'g1',
                    'name': 'حلقة',
                    'status': 'active',
                    'my_role': 'owner',
                    'active_member_count': 5,
                  }
                ],
                'pending_requests': [],
              }));
      when(() => cache.upsert('u1', any()))
          .thenAnswer((_) async => Future<void>.value());

      final result = await repository.getMyGroups();

      expect(result.isSuccess, isTrue);
      result.when(
        success: (overview) {
          expect(overview.groups.single.groupId, 'g1');
          expect(overview.isStale, isFalse);
        },
        failure: (_) => fail('expected success'),
      );
      verify(() => cache.upsert('u1', any())).called(1);
    });

    test('network failure falls back to cache flagged stale', () async {
      when(() => session.currentUserId).thenReturn('u1');
      when(() => connectivity.isOnline).thenAnswer((_) async => false);
      when(() => remote.call('get_my_groups', null))
          .thenAnswer((_) async => const FailureResult<dynamic>(NetworkFailure(
                message: 'network',
                code: 'network',
              )));
      when(() => cache.read('u1')).thenAnswer((_) async => (
            json: {
              'groups': <Object?>[],
              'pending_requests': <Object?>[],
            },
            cachedAt: DateTime.parse('2026-11-14T08:12:00Z'),
          ));

      final result = await repository.getMyGroups();

      result.when(
        success: (overview) {
          expect(overview.isStale, isTrue);
          expect(overview.cachedAt, isNotNull);
        },
        failure: (_) => fail('expected cached fallback'),
      );
    });

    test('network failure without cache returns failure', () async {
      when(() => session.currentUserId).thenReturn('u1');
      when(() => connectivity.isOnline).thenAnswer((_) async => false);
      when(() => remote.call('get_my_groups', null))
          .thenAnswer((_) async => const FailureResult<dynamic>(NetworkFailure(
                message: 'network',
                code: 'network',
              )));
      when(() => cache.read('u1')).thenAnswer((_) async => null);

      final result = await repository.getMyGroups();

      expect(result.failureOrNull!.kind, FailureKind.network);
    });

    test('unauthenticated user gets unauthenticated failure', () async {
      when(() => session.currentUserId).thenReturn(null);

      final result = await repository.getMyGroups();

      expect(result.failureOrNull!.kind, FailureKind.unauthenticated);
      verifyNever(() => rpc.call<dynamic>('get_my_groups', null));
    });
  });

  group('createGroup', () {
    test('maps validation failure kind', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(() => rpc.call<dynamic>('create_group', any())).thenAnswer(
          (_) async => const FailureResult<dynamic>(AuthFailure(
                message: 'validation_failed',
                code: 'validation_failed',
              )));

      final result = await repository.createGroup(const CreateGroupInput(
        name: 'حلقة',
        timezone: 'Africa/Cairo',
        visibility: GroupVisibility.public,
        joinMode: JoinMode.approval,
      ));

      expect(result.failureOrNull!.kind, FailureKind.validation);
    });

    test('maps owner_group_limit to limitReached', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(() => rpc.call<dynamic>('create_group', any())).thenAnswer(
          (_) async => const FailureResult<dynamic>(
              AuthFailure(message: 'owner_group_limit', code: 'owner_group_limit')));

      final result = await repository.createGroup(const CreateGroupInput(
        name: 'حلقة',
        timezone: 'Africa/Cairo',
        visibility: GroupVisibility.public,
        joinMode: JoinMode.approval,
      ));

      expect(result.failureOrNull!.kind, FailureKind.limitReached);
    });

    test('offline returns network failure without queueing', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => false);

      final result = await repository.createGroup(const CreateGroupInput(
        name: 'حلقة',
        timezone: 'Africa/Cairo',
        visibility: GroupVisibility.public,
        joinMode: JoinMode.approval,
      ));

      expect(result.failureOrNull!.kind, FailureKind.network);
      verifyNever(() => rpc.call<dynamic>('create_group', any()));
    });

    test('success returns CreatedGroup with invite code', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(() => rpc.call<dynamic>('create_group', any()))
          .thenAnswer((_) async => const Success<dynamic>({
                'group_id': 'g9',
                'invite_code': 'AB23CD45',
              }));

      final result = await repository.createGroup(const CreateGroupInput(
        name: 'حلقة',
        timezone: 'Africa/Cairo',
        visibility: GroupVisibility.public,
        joinMode: JoinMode.approval,
      ));

      result.when(
        success: (created) => expect(created.inviteCode, 'AB23CD45'),
        failure: (_) => fail('expected success'),
      );
    });
  });

  group('startKhatma', () {
    test('delegates to rpc with the start juz', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(() => rpc.call<dynamic>(
            'start_khatma',
            any(that: containsPair('p_start_juz', 5)),
          )).thenAnswer((_) async => const Success<dynamic>({
                'group_id': 'g1',
                'group_name': 'حلقة',
                'my_role': 'owner',
                'status': 'active',
                'server_generated_at': '2026-11-14T09:00:00Z',
                'active_member_count': 2,
                'invite_code': 'AB23CD45',
              }));

      final result = await repository.startKhatma('g1', 5);

      expect(result.isSuccess, isTrue);
      verify(() => rpc.call<dynamic>(
            'start_khatma',
            any(that: containsPair('p_group_id', 'g1')),
          )).called(1);
    });

    test('group_not_forming maps to conflict', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(() => rpc.call<dynamic>('start_khatma', any())).thenAnswer(
          (_) async => const FailureResult<dynamic>(AuthFailure(
              message: 'group_not_forming', code: 'group_not_forming')));

      final result = await repository.startKhatma('g1', 1);

      expect(result.failureOrNull!.kind, FailureKind.conflict);
    });
  });
}
