import '../../../../core/auth/session_gateway.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/network/rpc_client.dart';
import '../../../../core/storage/daos/daos.dart';
import '../data_sources/groups_remote_data_source.dart';
import '../entities/entities.dart';
import '../models/models.dart';
import 'groups_repository.dart';

/// Groups repository over Supabase RPCs + SQLite cache (repository
/// contract): network-first; `getMyGroups` falls back to cache on network
/// failure flagged stale; all other methods are network-only.
class GroupsRepositoryImpl implements GroupsRepository {
  GroupsRepositoryImpl({
    required RpcClient rpc,
    required GroupsRemoteDataSource remote,
    required CachedGroupsDao cache,
    required SessionGateway sessionGateway,
    required ConnectivityService connectivity,
  })  : _rpc = rpc,
        _remote = remote,
        _cache = cache,
        _session = sessionGateway,
        _connectivity = connectivity;

  final RpcClient _rpc;
  final GroupsRemoteDataSource _remote;
  final CachedGroupsDao _cache;
  final SessionGateway _session;
  final ConnectivityService _connectivity;

  @override
  Future<Result<MyGroupsOverview>> getMyGroups() async {
    final userId = _session.currentUserId;
    if (userId == null) {
      return const FailureResult(
        AuthFailure(message: 'no session', code: 'unauthenticated'),
      );
    }

    final result = await _remote.call('get_my_groups');
    return result.when(
      success: (payload) async {
        final json = (payload! as Map).cast<String, Object?>();
        final overview = MyGroupsOverview(
          groups: ((json['groups'] ?? const []) as List)
              .map((e) => myGroupSummaryFromJson(
                  (e as Map).cast<String, Object?>()))
              .toList(),
          pendingRequests: ((json['pending_requests'] ?? const []) as List)
              .map((e) => pendingJoinRequestFromJson(
                  (e as Map).cast<String, Object?>()))
              .toList(),
          isStale: false,
        );
        await _cache.upsert(
          userId,
          {
            'groups': json['groups'] ?? [],
            'pending_requests': json['pending_requests'] ?? [],
          },
        );
        return Success(overview);
      },
      failure: (failure) async {
        if (failure.kind != FailureKind.network) {
          return FailureResult(failure);
        }
        final cached = await _cache.read(userId);
        if (cached == null) {
          return FailureResult(failure);
        }
        final json = cached.json;
        return Success(MyGroupsOverview(
          groups: ((json['groups'] ?? const []) as List)
              .map((e) =>
                  myGroupSummaryFromJson((e as Map).cast<String, Object?>()))
              .toList(),
          pendingRequests: ((json['pending_requests'] ?? const []) as List)
              .map((e) =>
                  pendingJoinRequestFromJson((e as Map).cast<String, Object?>()))
              .toList(),
          isStale: true,
          cachedAt: cached.cachedAt,
        ));
      },
    );
  }

  Future<bool> get _online async {
    try {
      return await _connectivity.isOnline;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<Result<CreatedGroup>> createGroup(CreateGroupInput input) async {
    if (!await _online) {
      return const FailureResult(
        NetworkFailure(message: 'offline', code: 'network'),
      );
    }
    final result = await _rpc.call<dynamic>(
      'create_group',
      GroupsParams.createGroup(input),
    );
    return result.when(
      success: (payload) {
        final json = (payload! as Map).cast<String, Object?>();
        return Success(CreatedGroup(
          groupId: json['group_id']! as String,
          inviteCode: json['invite_code']! as String,
        ));
      },
      failure: (failure) => FailureResult(failure),
    );
  }

  @override
  Future<Result<MyGroupSummary>> updateGroupSettings(
      String groupId, GroupSettingsPatch patch) async {
    if (!await _online) {
      return const FailureResult(
        NetworkFailure(message: 'offline', code: 'network'),
      );
    }
    final result = await _rpc.call<dynamic>(
      'update_group_settings',
      GroupsParams.updateGroupSettings(groupId, patch),
    );
    return result.when(
      success: (payload) {
        final json = (payload! as Map).cast<String, Object?>();
        return Success(myGroupSummaryFromJson(json));
      },
      failure: (failure) => FailureResult(failure),
    );
  }

  @override
  Future<Result<DashboardSnapshot>> startKhatma(
      String groupId, int startPortion) async {
    if (!await _online) {
      return const FailureResult(
        NetworkFailure(message: 'offline', code: 'network'),
      );
    }
    final result = await _rpc.call<dynamic>(
      'start_khatma',
      GroupsParams.startKhatma(groupId, startPortion),
    );
    if (result.isFailure) return FailureResult(result.failureOrNull!);
    // start_khatma returns a summary ({today: true, status, ...}), not the
    // dashboard read model, so load the fresh dashboard after starting.
    final dashboard = await _rpc.call<dynamic>(
      'get_dashboard',
      {'p_group_id': groupId},
    );
    return dashboard.when(
      success: (payload) {
        final json = (payload! as Map).cast<String, Object?>();
        return Success(dashboardSnapshotFromJson(json));
      },
      failure: (failure) => FailureResult(failure),
    );
  }

  @override
  Future<Result<void>> archiveGroup(String groupId) async =>
      _simpleCall('archive_group', GroupsParams.byGroupId(groupId));

  @override
  Future<Result<void>> transferOwnership(
          String groupId, String membershipId) async =>
      _simpleCall(
        'transfer_ownership',
        GroupsParams.transfer(groupId, membershipId),
      );

  @override
  Future<Result<String>> regenerateInvite(String groupId) async {
    if (!await _online) {
      return const FailureResult(
        NetworkFailure(message: 'offline', code: 'network'),
      );
    }
    final result =
        await _rpc.call<dynamic>('regenerate_invite', GroupsParams.byGroupId(groupId));
    return result.when(
      success: (payload) {
        final json = (payload! as Map).cast<String, Object?>();
        return Success(json['invite_code']! as String);
      },
      failure: (failure) => FailureResult(failure),
    );
  }

  @override
  Future<Result<List<PublicGroupProfile>>> searchPublicGroups({
    String? query,
    bool needsMembersOnly = true,
    int limit = 20,
    int offset = 0,
  }) async {
    if (!await _online) {
      return const FailureResult(
        NetworkFailure(message: 'offline', code: 'network'),
      );
    }
    final result = await _rpc.call<dynamic>('search_public_groups', {
      'p_query': ?query,
      'p_needs_members_only': needsMembersOnly,
      'p_limit': limit,
      'p_offset': offset,
    });
    return result.when(
      success: (payload) => Success(((payload ?? const []) as List)
          .map((e) =>
              publicGroupProfileFromJson((e as Map).cast<String, Object?>()))
          .toList()),
      failure: (failure) => FailureResult(failure),
    );
  }

  @override
  Future<Result<PublicGroupProfile>> getInvitePreview(String code) async {
    if (!await _online) {
      return const FailureResult(
        NetworkFailure(message: 'offline', code: 'network'),
      );
    }
    final result = await _rpc
        .call<dynamic>('get_invite_preview', {'p_invite_code': code});
    return result.when(
      success: (payload) => Success(
        publicGroupProfileFromJson((payload! as Map).cast<String, Object?>()),
      ),
      failure: (failure) => FailureResult(failure),
    );
  }

  @override
  Future<Result<JoinOutcome>> joinGroup({
    String? groupId,
    String? inviteCode,
    JoinSource source = JoinSource.discovery,
  }) async {
    if (!await _online) {
      return const FailureResult(
        NetworkFailure(message: 'offline', code: 'network'),
      );
    }
    final result = await _rpc.call<dynamic>(
      'join_group',
      GroupsParams.join(groupId: groupId, inviteCode: inviteCode, source: source),
    );
    return result.when(
      success: (payload) => Success(joinOutcomeFromJson(
          (payload! as Map).cast<String, Object?>())),
      failure: (failure) => FailureResult(failure),
    );
  }

  @override
  Future<Result<JoinOutcome>> joinAnyGroup(String deviceTimezone) async {
    if (!await _online) {
      return const FailureResult(
        NetworkFailure(message: 'offline', code: 'network'),
      );
    }
    final result = await _rpc.call<dynamic>(
      'join_any_group',
      GroupsParams.joinAny(deviceTimezone),
    );
    return result.when(
      success: (payload) => Success(joinOutcomeFromJson(
          (payload! as Map).cast<String, Object?>())),
      failure: (failure) => FailureResult(failure),
    );
  }

  @override
  Future<Result<void>> cancelJoinRequest(String joinRequestId) async =>
      _simpleCall(
        'cancel_join_request',
        GroupsParams.joinRequestId(joinRequestId),
      );

  @override
  Future<Result<List<PublicJoinRequestInfo>>> listJoinRequests(
      String groupId) async {
    if (!await _online) {
      return const FailureResult(
        NetworkFailure(message: 'offline', code: 'network'),
      );
    }
    final result =
        await _rpc.call<dynamic>('list_join_requests', GroupsParams.byGroupId(groupId));
    return result.when(
      success: (payload) => Success(((payload ?? const []) as List)
          .map((e) {
            final json = (e as Map).cast<String, Object?>();
            return PublicJoinRequestInfo(
              joinRequestId: json['join_request_id']! as String,
              userDisplayName: json['user_display_name']! as String,
              requestedAt: DateTime.parse(json['requested_at']! as String),
              source: (json['source']! as String) == 'invite'
                  ? JoinSource.invite
                  : ((json['source']! as String) == 'match'
                      ? JoinSource.match
                      : JoinSource.discovery),
            );
          })
          .toList()),
      failure: (failure) => FailureResult(failure),
    );
  }

  @override
  Future<Result<void>> reviewJoinRequest(
      String joinRequestId, bool approve) async =>
      _simpleCall(
        'review_join_request',
        GroupsParams.review(joinRequestId, approve),
      );

  @override
  Future<Result<SeatMap>> getMembers(String groupId) async {
    if (!await _online) {
      return const FailureResult(
        NetworkFailure(message: 'offline', code: 'network'),
      );
    }
    final result =
        await _rpc.call<dynamic>('get_group_members', GroupsParams.byGroupId(groupId));
    return result.when(
      success: (payload) {
        final json = (payload! as Map).cast<String, Object?>();
        return Success(seatMapFromJson(json));
      },
      failure: (failure) => FailureResult(failure),
    );
  }

  @override
  Future<Result<void>> moveMemberSeat(
      String groupId, String membershipId, int targetSeat) async =>
      _simpleCall(
        'move_member_seat',
        GroupsParams.moveSeat(groupId, membershipId, targetSeat),
      );

  @override
  Future<Result<void>> setMemberRole(
      String groupId, String membershipId, GroupRole role) async =>
      _simpleCall('set_member_role', GroupsParams.setRole(groupId, membershipId, role));

  @override
  Future<Result<void>> removeMember(
          String groupId, String membershipId) async =>
      _simpleCall('remove_member', GroupsParams.remove(groupId, membershipId));

  @override
  Future<Result<void>> leaveGroup(String groupId) async =>
      _simpleCall('leave_group', GroupsParams.byGroupId(groupId));

  Future<Result<void>> _simpleCall(
      String function, Map<String, Object?> params) async {
    if (!await _online) {
      return const FailureResult(
        NetworkFailure(message: 'offline', code: 'network'),
      );
    }
    final result = await _rpc.call<dynamic>(function, params);
    return result.when(
      success: (_) => const Success<void>(null),
      failure: (failure) => FailureResult(failure),
    );
  }
}
