import '../../../../core/errors/result.dart';
import '../../../../core/network/rpc_client.dart';
import '../entities/entities.dart';
import '../models/models.dart';
import '../repositories/groups_repository.dart';

/// Remote call shapes for groups RPCs (thin; mapping lives in the impl).
abstract class GroupsRemoteDataSource {
  Future<Result<dynamic>> call(String function,
      [Map<String, Object?>? params]);
}

/// Builds the RPC param objects (snake_case names match the SQL contract).
class GroupsParams {
  const GroupsParams._();

  static Map<String, Object?> createGroup(CreateGroupInput input) => {
        'p_name': input.name,
        'p_short_description': input.shortDescription ?? '',
        'p_timezone': input.timezone,
        'p_day_start_time': input.dayStartTime,
        'p_visibility': input.visibility.name,
        'p_join_mode': joinModeName(input.joinMode),
      };

  static Map<String, Object?> updateGroupSettings(
      String groupId, GroupSettingsPatch patch) {
    final joinMode = patch.joinMode == null
        ? null
        : joinModeName(patch.joinMode!);
    return {
      'p_group_id': groupId,
      'p_name': ?patch.name,
      'p_short_description': ?patch.shortDescription,
      'p_timezone': ?patch.timezone,
      'p_day_start_time': ?patch.dayStartTime,
      'p_visibility': ?patch.visibility?.name,
      'p_join_mode': ?joinMode,
    };
  }

  static Map<String, Object?> startKhatma(String groupId, int startJuz) =>
      {'p_group_id': groupId, 'p_start_juz': startJuz};

  static Map<String, Object?> byGroupId(String groupId) =>
      {'p_group_id': groupId};

  static Map<String, Object?> transfer(
          String groupId, String membershipId) =>
      {'p_group_id': groupId, 'p_new_owner_membership_id': membershipId};

  static Map<String, Object?> join({
    String? groupId,
    String? inviteCode,
    JoinSource source = JoinSource.discovery,
  }) =>
      {
        'p_group_id': ?groupId,
        'p_invite_code': ?inviteCode,
        'p_source': source.name,
      };

  static Map<String, Object?> joinAny(String deviceTimezone) =>
      {'p_device_timezone': deviceTimezone};

  static Map<String, Object?> joinRequestId(String joinRequestId) =>
      {'p_join_request_id': joinRequestId};

  static Map<String, Object?> review(String joinRequestId, bool approve) =>
      {'p_join_request_id': joinRequestId, 'p_decision': approve ? 'approve' : 'reject'};

  static Map<String, Object?> moveSeat(
          String groupId, String membershipId, int targetSeat) =>
      {
        'p_group_id': groupId,
        'p_membership_id': membershipId,
        'p_target_seat': targetSeat,
      };

  static Map<String, Object?> setRole(
          String groupId, String membershipId, GroupRole role) =>
      {
        'p_group_id': groupId,
        'p_membership_id': membershipId,
        'p_role': groupRoleName(role),
      };

  static Map<String, Object?> remove(
          String groupId, String membershipId) =>
      {'p_group_id': groupId, 'p_membership_id': membershipId};
}

/// Default implementation delegating to [RpcClient].
class GroupsRemoteDataSourceImpl implements GroupsRemoteDataSource {
  GroupsRemoteDataSourceImpl(this._rpc);

  final RpcClient _rpc;

  @override
  Future<Result<dynamic>> call(String function,
      [Map<String, Object?>? params]) {
    return _rpc.call<dynamic>(function, params);
  }
}
