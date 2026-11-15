import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/auth/session_gateway.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/network/rpc_client.dart';
import '../../../../core/network/supabase_client_provider.dart';
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
    SupabaseClientProvider? clientProvider,
  }) : _rpc = rpc,
       _remote = remote,
       _cache = cache,
       _session = sessionGateway,
       _connectivity = connectivity,
       _clientProvider = clientProvider;

  final RpcClient _rpc;
  final GroupsRemoteDataSource _remote;
  final CachedGroupsDao _cache;
  final SessionGateway _session;
  final ConnectivityService _connectivity;
  final SupabaseClientProvider? _clientProvider;
  final Map<String, Uint8List> _photoCache = {};

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
              .map(
                (e) =>
                    myGroupSummaryFromJson((e as Map).cast<String, Object?>()),
              )
              .toList(),
          pendingRequests: ((json['pending_requests'] ?? const []) as List)
              .map(
                (e) => pendingJoinRequestFromJson(
                  (e as Map).cast<String, Object?>(),
                ),
              )
              .toList(),
          isStale: false,
        );
        await _cache.upsert(userId, {
          'groups': json['groups'] ?? [],
          'pending_requests': json['pending_requests'] ?? [],
        });
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
        return Success(
          MyGroupsOverview(
            groups: ((json['groups'] ?? const []) as List)
                .map(
                  (e) => myGroupSummaryFromJson(
                    (e as Map).cast<String, Object?>(),
                  ),
                )
                .toList(),
            pendingRequests: ((json['pending_requests'] ?? const []) as List)
                .map(
                  (e) => pendingJoinRequestFromJson(
                    (e as Map).cast<String, Object?>(),
                  ),
                )
                .toList(),
            isStale: true,
            cachedAt: cached.cachedAt,
          ),
        );
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
        return Success(
          CreatedGroup(
            groupId: json['group_id']! as String,
            inviteCode: json['invite_code']! as String,
          ),
        );
      },
      failure: (failure) => FailureResult(failure),
    );
  }

  @override
  Future<Result<MyGroupSummary>> updateGroupSettings(
    String groupId,
    GroupSettingsPatch patch,
  ) async {
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
    String groupId,
    int startPortion,
  ) async {
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
    final dashboard = await _rpc.call<dynamic>('get_dashboard', {
      'p_group_id': groupId,
    });
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
    String groupId,
    String membershipId,
  ) async => _simpleCall(
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
    final result = await _rpc.call<dynamic>(
      'regenerate_invite',
      GroupsParams.byGroupId(groupId),
    );
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
      success: (payload) => Success(
        ((payload ?? const []) as List)
            .map(
              (e) => publicGroupProfileFromJson(
                (e as Map).cast<String, Object?>(),
              ),
            )
            .toList(),
      ),
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
    final result = await _rpc.call<dynamic>('get_invite_preview', {
      'p_invite_code': code,
    });
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
      GroupsParams.join(
        groupId: groupId,
        inviteCode: inviteCode,
        source: source,
      ),
    );
    return result.when(
      success: (payload) => Success(
        joinOutcomeFromJson((payload! as Map).cast<String, Object?>()),
      ),
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
      success: (payload) => Success(
        joinOutcomeFromJson((payload! as Map).cast<String, Object?>()),
      ),
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
    String groupId,
  ) async {
    if (!await _online) {
      return const FailureResult(
        NetworkFailure(message: 'offline', code: 'network'),
      );
    }
    final result = await _rpc.call<dynamic>(
      'list_join_requests',
      GroupsParams.byGroupId(groupId),
    );
    return result.when(
      success: (payload) => Success(
        ((payload ?? const []) as List).map((e) {
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
        }).toList(),
      ),
      failure: (failure) => FailureResult(failure),
    );
  }

  @override
  Future<Result<void>> reviewJoinRequest(
    String joinRequestId,
    bool approve,
  ) async => _simpleCall(
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
    final result = await _rpc.call<dynamic>(
      'get_group_members',
      GroupsParams.byGroupId(groupId),
    );
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
    String groupId,
    String membershipId,
    int targetSeat,
  ) async => _simpleCall(
    'move_member_seat',
    GroupsParams.moveSeat(groupId, membershipId, targetSeat),
  );

  @override
  Future<Result<void>> setMemberRole(
    String groupId,
    String membershipId,
    GroupRole role,
  ) async => _simpleCall(
    'set_member_role',
    GroupsParams.setRole(groupId, membershipId, role),
  );

  @override
  Future<Result<void>> removeMember(
    String groupId,
    String membershipId,
  ) async =>
      _simpleCall('remove_member', GroupsParams.remove(groupId, membershipId));

  @override
  Future<Result<void>> leaveGroup(String groupId) async =>
      _simpleCall('leave_group', GroupsParams.byGroupId(groupId));

  // --- 007 profiles ---
  @override
  Future<Result<GroupInfo>> getGroupInfo(String groupId) async {
    if (!await _online) {
      return const FailureResult(
        NetworkFailure(message: 'offline', code: 'network'),
      );
    }
    final result = await _remote.call(
      'get_group_info',
      GroupsParams.byGroupId(groupId),
    );
    return result.when(
      success: (payload) =>
          Success(groupInfoFromJson((payload! as Map).cast<String, Object?>())),
      failure: (failure) => FailureResult(failure),
    );
  }

  @override
  Future<Result<MemberGroupProfile>> getMemberProfile(
    String userId,
    String groupId,
  ) async {
    if (!await _online) {
      return const FailureResult(
        NetworkFailure(message: 'offline', code: 'network'),
      );
    }
    final result = await _remote.call(
      'get_member_profile',
      GroupsParams.memberProfile(userId, groupId),
    );
    return result.when(
      success: (payload) => Success(
        memberGroupProfileFromJson((payload! as Map).cast<String, Object?>()),
      ),
      failure: (failure) => FailureResult(failure),
    );
  }

  @override
  Future<Result<UserProfile>> updateMyProfile(
    String displayName, {
    String? bio,
    String avatarKey = 'ornament',
  }) async {
    if (!await _online) {
      return const FailureResult(
        NetworkFailure(message: 'offline', code: 'network'),
      );
    }
    final result = await _remote.call(
      'update_my_profile',
      GroupsParams.updateMyProfile(displayName, bio, avatarKey),
    );
    return result.when(
      success: (payload) => Success(
        userProfileFromJson((payload! as Map).cast<String, Object?>()),
      ),
      failure: (failure) => FailureResult(failure),
    );
  }

  @override
  Future<Result<void>> updateGroupDetails(
    String groupId,
    String name, {
    String? description,
  }) async {
    return _simpleCall(
      'update_group_details',
      GroupsParams.updateGroupDetails(groupId, name, description),
    );
  }

  @override
  Future<Result<void>> setGroupPhoto(String groupId, String? photoPath) async {
    return _simpleCall(
      'set_group_photo',
      GroupsParams.setGroupPhoto(groupId, photoPath),
    );
  }

  @override
  Future<Result<String>> uploadGroupPhoto(
    String groupId,
    List<int> bytes,
    String extension,
  ) async {
    if (!await _online) {
      return const FailureResult(
        NetworkFailure(message: 'offline', code: 'network'),
      );
    }
    final client = _clientProvider?.client;
    if (client == null) {
      return const FailureResult(
        UnknownFailure(
          message: 'storage client unavailable',
          code: 'storage_unavailable',
        ),
      );
    }
    try {
      final ext = extension.replaceAll('.', '').toLowerCase();
      final mime = switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
      final fileName = '${DateTime.now().microsecondsSinceEpoch}.$ext';
      final path = '$groupId/$fileName';
      final u8Bytes = Uint8List.fromList(bytes);

      await client.storage
          .from('group-photos')
          .uploadBinary(
            path,
            u8Bytes,
            fileOptions: FileOptions(contentType: mime, upsert: true),
          );
      _photoCache[path] = u8Bytes;
      return Success(path);
    } catch (e) {
      return FailureResult(
        UnknownFailure(message: e.toString(), code: 'upload_failed'),
      );
    }
  }

  @override
  Future<Result<List<int>>> getGroupPhotoBytes(String photoPath) async {
    if (_photoCache.containsKey(photoPath)) {
      return Success(_photoCache[photoPath]!);
    }
    if (!await _online) {
      return const FailureResult(
        NetworkFailure(message: 'offline', code: 'network'),
      );
    }
    final client = _clientProvider?.client;
    if (client == null) {
      return const FailureResult(
        UnknownFailure(
          message: 'storage client unavailable',
          code: 'storage_unavailable',
        ),
      );
    }
    try {
      final bytes = await client.storage
          .from('group-photos')
          .download(photoPath);
      _photoCache[photoPath] = bytes;
      return Success(bytes);
    } catch (e) {
      return FailureResult(
        UnknownFailure(message: e.toString(), code: 'download_failed'),
      );
    }
  }

  Future<Result<void>> _simpleCall(
    String function,
    Map<String, Object?> params,
  ) async {
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
