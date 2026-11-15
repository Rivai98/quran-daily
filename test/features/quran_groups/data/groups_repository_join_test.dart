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
import 'package:quran_daily/features/quran_groups/data/models/models.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository_impl.dart';

class _Rpc extends Mock implements RpcClient {}

class _Remote extends Mock implements GroupsRemoteDataSource {}

class _Cache extends Mock implements CachedGroupsDao {}

class _Session extends Mock implements SessionGateway {}

class _Connectivity extends Mock implements ConnectivityService {}

void main() {
  late _Rpc rpc;
  late _Remote remote;
  late _Cache cache;
  late _Session session;
  late _Connectivity connectivity;
  late GroupsRepositoryImpl repository;

  setUp(() {
    rpc = _Rpc();
    remote = _Remote();
    cache = _Cache();
    session = _Session();
    connectivity = _Connectivity();
    repository = GroupsRepositoryImpl(
      rpc: rpc,
      remote: remote,
      cache: cache,
      sessionGateway: session,
      connectivity: connectivity,
    );
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
  });

  test(
    'search maps public cards and forwards paging/filter arguments',
    () async {
      when(() => rpc.call<dynamic>('search_public_groups', any())).thenAnswer(
        (_) async => const Success<dynamic>([
          {
            'group_id': 'g1',
            'name': 'حلقة الفجر',
            'short_description': 'ورد يومي',
            'status': 'active',
            'active_member_count': 28,
            'timezone': 'Africa/Cairo',
            'join_mode': 'approval',
            'my_request_status': 'pending',
            'my_join_request_id': 'r1',
          },
        ]),
      );

      final result = await repository.searchPublicGroups(
        query: 'فجر',
        needsMembersOnly: false,
        limit: 10,
        offset: 20,
      );

      expect(result.valueOrNull!.single, isA<PublicGroupProfile>());
      expect(result.valueOrNull!.single.myJoinRequestId, 'r1');
      verify(
        () => rpc.call<dynamic>('search_public_groups', {
          'p_query': 'فجر',
          'p_needs_members_only': false,
          'p_limit': 10,
          'p_offset': 20,
        }),
      ).called(1);
    },
  );

  test('invite preview maps a pending request', () async {
    when(() => rpc.call<dynamic>('get_invite_preview', any())).thenAnswer(
      (_) async => const Success<dynamic>({
        'group_id': 'g1',
        'name': 'حلقة الفجر',
        'status': 'forming',
        'active_member_count': 1,
        'timezone': 'Africa/Cairo',
        'join_mode': 'auto_accept',
        'my_request_status': 'pending',
        'my_join_request_id': 'r2',
        'can_join_limit': false,
      }),
    );

    final result = await repository.getInvitePreview('AB234567');

    expect(result.valueOrNull!.myRequestStatus, 'pending');
    expect(result.valueOrNull!.myJoinRequestId, 'r2');
    expect(result.valueOrNull!.canJoinLimit, isFalse);
    verify(
      () => rpc.call<dynamic>('get_invite_preview', {
        'p_invite_code': 'AB234567',
      }),
    ).called(1);
  });

  test('join group parses active and pending outcomes', () async {
    when(() => rpc.call<dynamic>('join_group', any())).thenAnswer(
      (_) async => const Success<dynamic>({
        'result': 'pending',
        'join_request_id': 'r3',
      }),
    );

    final result = await repository.joinGroup(
      inviteCode: 'AB234567',
      source: JoinSource.invite,
    );

    expect(result.valueOrNull!.joined, isFalse);
    expect(result.valueOrNull!.joinRequestId, 'r3');
    verify(
      () => rpc.call<dynamic>('join_group', {
        'p_invite_code': 'AB234567',
        'p_source': 'invite',
      }),
    ).called(1);
  });

  test('join any maps the assigned seat', () async {
    when(() => rpc.call<dynamic>('join_any_group', any())).thenAnswer(
      (_) async => const Success<dynamic>({
        'result': 'joined',
        'membership_id': 'm1',
        'seat_number': 4,
      }),
    );

    final result = await repository.joinAnyGroup('Africa/Cairo');

    expect(result.valueOrNull!.seatNumber, 4);
    verify(
      () => rpc.call<dynamic>('join_any_group', {
        'p_device_timezone': 'Africa/Cairo',
      }),
    ).called(1);
  });

  test('cancel request uses the request identifier', () async {
    when(
      () => rpc.call<dynamic>('cancel_join_request', any()),
    ).thenAnswer((_) async => const Success<dynamic>(null));

    final result = await repository.cancelJoinRequest('r4');

    expect(result.isSuccess, isTrue);
    verify(
      () =>
          rpc.call<dynamic>('cancel_join_request', {'p_join_request_id': 'r4'}),
    ).called(1);
  });

  test('offline discovery returns network failure without RPC', () async {
    when(() => connectivity.isOnline).thenAnswer((_) async => false);

    final result = await repository.searchPublicGroups();

    expect(result.failureOrNull!.kind, FailureKind.network);
    verifyNever(() => rpc.call<dynamic>('search_public_groups', any()));
  });
}
