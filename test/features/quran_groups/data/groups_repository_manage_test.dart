import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/auth/session_gateway.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/network/connectivity_service.dart';
import 'package:quran_daily/core/network/rpc_client.dart';
import 'package:quran_daily/core/storage/daos/daos.dart';
import 'package:quran_daily/features/quran_groups/data/data_sources/groups_remote_data_source.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository_impl.dart';

class _Rpc extends Mock implements RpcClient {}

class _Remote extends Mock implements GroupsRemoteDataSource {}

class _Cache extends Mock implements CachedGroupsDao {}

class _Session extends Mock implements SessionGateway {}

class _Connectivity extends Mock implements ConnectivityService {}

void main() {
  test('management actions call their matching RPCs and parameters', () async {
    final rpc = _Rpc();
    final remote = _Remote();
    final connectivity = _Connectivity();
    final repository = GroupsRepositoryImpl(
      rpc: rpc,
      remote: remote,
      cache: _Cache(),
      sessionGateway: _Session(),
      connectivity: connectivity,
    );
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(
      () => rpc.call<dynamic>(any(), any()),
    ).thenAnswer((_) async => const Success<dynamic>(null));
    when(() => rpc.call<dynamic>('get_group_members', any())).thenAnswer(
      (_) async => const Success<dynamic>({
        'group_id': 'g',
        'members': [],
        'active_member_count': 0,
      }),
    );

    expect((await repository.listJoinRequests('g')).isSuccess, isTrue);
    expect((await repository.reviewJoinRequest('r', true)).isSuccess, isTrue);
    expect((await repository.getMembers('g')).isSuccess, isTrue);
    expect((await repository.moveMemberSeat('g', 'm', 3)).isSuccess, isTrue);
    expect(
      (await repository.setMemberRole(
        'g',
        'm',
        GroupRole.supervisor,
      )).isSuccess,
      isTrue,
    );
    expect((await repository.removeMember('g', 'm')).isSuccess, isTrue);
    expect((await repository.leaveGroup('g')).isSuccess, isTrue);
    expect((await repository.transferOwnership('g', 'm')).isSuccess, isTrue);
    expect((await repository.archiveGroup('g')).isSuccess, isTrue);

    verify(
      () => rpc.call<dynamic>(
        'list_join_requests',
        any(that: containsPair('p_group_id', 'g')),
      ),
    ).called(1);
    verify(() => rpc.call<dynamic>('review_join_request', any())).called(1);
    verify(() => rpc.call<dynamic>('get_group_members', any())).called(1);
    verify(
      () => rpc.call<dynamic>(
        'move_member_seat',
        any(that: containsPair('p_target_seat', 3)),
      ),
    ).called(1);
    verify(
      () => rpc.call<dynamic>(
        'set_member_role',
        any(that: containsPair('p_role', 'supervisor')),
      ),
    ).called(1);
    verify(() => rpc.call<dynamic>('remove_member', any())).called(1);
    verify(() => rpc.call<dynamic>('leave_group', any())).called(1);
    verify(() => rpc.call<dynamic>('transfer_ownership', any())).called(1);
    verify(() => rpc.call<dynamic>('archive_group', any())).called(1);
  });
}
