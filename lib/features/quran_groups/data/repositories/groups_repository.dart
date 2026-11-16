import 'package:equatable/equatable.dart';

import '../../../../core/errors/result.dart';
import '../entities/entities.dart';
import '../../../../core/quran/portion_unit.dart';
import '../models/models.dart';

class CreateGroupInput extends EquatableInput {
  const CreateGroupInput({
    required this.name,
    required this.timezone,
    required this.visibility,
    required this.joinMode,
    this.shortDescription,
    this.dayStartTime = '00:00',
    this.portionUnit = PortionUnit.juz,
  });

  final String name;
  final String? shortDescription;
  final String timezone;
  final String dayStartTime;
  final GroupVisibility visibility;
  final JoinMode joinMode;
  final PortionUnit portionUnit;

  @override
  List<Object?> get props => [
    name,
    shortDescription,
    timezone,
    dayStartTime,
    visibility,
    joinMode,
    portionUnit,
  ];
}

class CreatedGroup extends EquatableInput {
  const CreatedGroup({required this.groupId, required this.inviteCode});

  final String groupId;
  final String inviteCode;

  @override
  List<Object?> get props => [groupId, inviteCode];
}

class GroupSettingsPatch extends EquatableInput {
  const GroupSettingsPatch({
    this.name,
    this.shortDescription,
    this.timezone,
    this.dayStartTime,
    this.visibility,
    this.joinMode,
    this.portionUnit,
  });

  final String? name;
  final String? shortDescription;
  final String? timezone;
  final String? dayStartTime;
  final GroupVisibility? visibility;
  final JoinMode? joinMode;
  final PortionUnit? portionUnit;

  bool get isEmpty =>
      name == null &&
      shortDescription == null &&
      timezone == null &&
      dayStartTime == null &&
      visibility == null &&
      joinMode == null &&
      portionUnit == null;

  @override
  List<Object?> get props => [
    name,
    shortDescription,
    timezone,
    dayStartTime,
    visibility,
    joinMode,
    portionUnit,
  ];
}

/// Non-generic base for inputs (keeps signatures simple).
abstract class EquatableInput extends Equatable {
  const EquatableInput();
}

/// Groups/joining/management repository (repository contract). Network-only
/// methods return `Failure(network)` when offline — nothing is queued.
abstract class GroupsRepository {
  Future<Result<MyGroupsOverview>> getMyGroups();

  Future<Result<CreatedGroup>> createGroup(CreateGroupInput input);
  Future<Result<MyGroupSummary>> updateGroupSettings(
    String groupId,
    GroupSettingsPatch patch,
  );
  Future<Result<DashboardSnapshot>> startKhatma(
    String groupId,
    int startPortion,
  );
  Future<Result<void>> archiveGroup(String groupId);
  Future<Result<void>> transferOwnership(String groupId, String membershipId);
  Future<Result<String>> regenerateInvite(String groupId);

  Future<Result<List<PublicGroupProfile>>> searchPublicGroups({
    String? query,
    bool needsMembersOnly = true,
    int limit = 20,
    int offset = 0,
  });
  Future<Result<PublicGroupProfile>> getInvitePreview(String code);
  Future<Result<JoinOutcome>> joinGroup({
    String? groupId,
    String? inviteCode,
    JoinSource source = JoinSource.discovery,
  });
  Future<Result<JoinOutcome>> joinAnyGroup(String deviceTimezone);
  Future<Result<void>> cancelJoinRequest(String joinRequestId);
  Future<Result<List<PublicJoinRequestInfo>>> listJoinRequests(String groupId);
  Future<Result<void>> reviewJoinRequest(String joinRequestId, bool approve);

  Future<Result<SeatMap>> getMembers(String groupId);
  Future<Result<void>> moveMemberSeat(
    String groupId,
    String membershipId,
    int targetSeat,
  );
  Future<Result<void>> setMemberRole(
    String groupId,
    String membershipId,
    GroupRole role,
  );
  Future<Result<void>> removeMember(String groupId, String membershipId);
  Future<Result<void>> leaveGroup(String groupId);

  // --- 007 profiles ---
  Future<Result<GroupInfo>> getGroupInfo(String groupId);
  Future<Result<MemberGroupProfile>> getMemberProfile(
    String userId,
    String groupId,
  );
  Future<Result<UserProfile>> updateMyProfile(
    String displayName, {
    String? bio,
    String avatarKey = 'ornament',
  });
  Future<Result<void>> updateGroupDetails(
    String groupId,
    String name, {
    String? description,
  });
  Future<Result<void>> setGroupPhoto(String groupId, String? photoPath);
  Future<Result<String>> uploadGroupPhoto(
    String groupId,
    List<int> bytes,
    String extension,
  );
  Future<Result<List<int>>> getGroupPhotoBytes(String photoPath);
}

class PublicJoinRequestInfo extends EquatableInput {
  const PublicJoinRequestInfo({
    required this.joinRequestId,
    required this.userDisplayName,
    required this.requestedAt,
    required this.source,
  });

  final String joinRequestId;
  final String userDisplayName;
  final DateTime requestedAt;
  final JoinSource source;

  @override
  List<Object?> get props => [
    joinRequestId,
    userDisplayName,
    requestedAt,
    source,
  ];
}
