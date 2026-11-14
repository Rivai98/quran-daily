import 'package:equatable/equatable.dart';

/// Shared entities of the quran_groups feature (data-model "read models").
/// All immutable; JSON mapping lives in ../models/.

enum GroupStatus { forming, active, archived }

enum GroupVisibility { public, private }

enum JoinMode { autoAccept, approval }

enum GroupRole { owner, supervisor, member }

enum MembershipStatus { active, left, removed }

enum DayState { open, grace, closed }

enum JoinRequestStatus { pending, approved, rejected, cancelled }

enum JoinSource { discovery, invite, match }

/// One row of the 30-assignment day grid.
enum AssignmentKind { seat, override, volunteer, unassigned }

enum AssignmentStatusEnum { pending, completed, missed, late, available, unread }

class GroupSummary extends Equatable {
  const GroupSummary({
    required this.groupId,
    required this.name,
    required this.status,
    required this.activeMemberCount,
    required this.timezone,
    this.shortDescription,
    this.joinMode,
    this.myRequestStatus,
    this.myJoinRequestId,
  });

  final String groupId;
  final String name;
  final GroupStatus status;
  final int activeMemberCount;
  final String timezone;
  final String? shortDescription;
  final JoinMode? joinMode;

  /// none/pending/rejected for discovery previews (never members).
  final String? myRequestStatus;
  final String? myJoinRequestId;

  @override
  List<Object?> get props => [
        groupId, name, status, activeMemberCount, timezone,
        shortDescription, joinMode, myRequestStatus, myJoinRequestId,
      ];
}

class MyGroupSummary extends Equatable {
  const MyGroupSummary({
    required this.groupId,
    required this.name,
    required this.status,
    required this.myRole,
    required this.activeMemberCount,
    this.todayMyJuz,
    this.todayMyStatus,
    this.todayMyAssignmentId,
  });

  final String groupId;
  final String name;
  final GroupStatus status;
  final GroupRole myRole;
  final int activeMemberCount;
  final int? todayMyJuz;
  final AssignmentStatusEnum? todayMyStatus;
  final String? todayMyAssignmentId;

  @override
  List<Object?> get props => [
        groupId, name, status, myRole, activeMemberCount,
        todayMyJuz, todayMyStatus, todayMyAssignmentId,
      ];
}

class PendingJoinRequest extends Equatable {
  const PendingJoinRequest({
    required this.joinRequestId,
    required this.groupId,
    required this.groupName,
    required this.requestedAt,
    required this.source,
  });

  final String joinRequestId;
  final String groupId;
  final String groupName;
  final DateTime requestedAt;
  final JoinSource source;

  @override
  List<Object?> get props =>
      [joinRequestId, groupId, groupName, requestedAt, source];
}

class MyGroupsOverview extends Equatable {
  const MyGroupsOverview({
    required this.groups,
    required this.pendingRequests,
    required this.isStale,
    this.cachedAt,
  });

  final List<MyGroupSummary> groups;
  final List<PendingJoinRequest> pendingRequests;

  /// True when this overview came from cache after a network failure.
  final bool isStale;
  final DateTime? cachedAt;

  @override
  List<Object?> get props => [groups, pendingRequests, isStale, cachedAt];
}

class SeatMember extends Equatable {
  const SeatMember({
    required this.membershipId,
    required this.displayName,
    required this.role,
    required this.seatNumber,
  });

  final String membershipId;
  final String displayName;
  final GroupRole role;
  final int seatNumber;

  @override
  List<Object?> get props => [membershipId, displayName, role, seatNumber];
}

/// Members + empty seats for the members screen / forming dashboard.
class SeatMap extends Equatable {
  const SeatMap({
    required this.groupId,
    required this.members,
    required this.activeMemberCount,
    this.inviteCode,
  });

  final String groupId;
  final List<SeatMember> members;
  final int activeMemberCount;
  final String? inviteCode;

  List<int> get emptySeats {
    final occupied = members.map((m) => m.seatNumber).toSet();
    return [for (var s = 1; s <= 30; s++) if (!occupied.contains(s)) s];
  }

  @override
  List<Object?> get props => [groupId, members, activeMemberCount, inviteCode];
}

class JoinOutcome extends Equatable {
  const JoinOutcome({
    required this.joined,
    this.membershipId,
    this.seatNumber,
    this.joinRequestId,
  });

  /// true = active membership now; false = pending request.
  final bool joined;
  final String? membershipId;
  final int? seatNumber;
  final String? joinRequestId;

  @override
  List<Object?> get props => [joined, membershipId, seatNumber, joinRequestId];
}

class GroupDayInfo extends Equatable {
  const GroupDayInfo({
    required this.groupDate,
    required this.state,
    required this.completedCount,
    required this.lateCount,
    required this.missedCount,
    required this.unreadCount,
    required this.pendingCount,
    required this.availableCount,
    required this.fullKhatma,
    required this.endsAt,
  });

  final String groupDate;
  final DayState state;
  final int completedCount;
  final int lateCount;
  final int missedCount;
  final int unreadCount;
  final int pendingCount;
  final int availableCount;
  final bool fullKhatma;
  final DateTime endsAt;

  @override
  List<Object?> get props => [
        groupDate, state, completedCount, lateCount, missedCount,
        unreadCount, pendingCount, availableCount, fullKhatma, endsAt,
      ];
}

class Assignment extends Equatable {
  const Assignment({
    required this.assignmentId,
    required this.juz,
    required this.seatNumber,
    required this.kind,
    required this.status,
    this.readerDisplayName,
    this.isMe = false,
    this.completedAt,
  });

  final String assignmentId;
  final int juz;
  final int seatNumber;
  final AssignmentKind kind;
  final AssignmentStatusEnum status;
  final String? readerDisplayName;
  final bool isMe;
  final DateTime? completedAt;

  @override
  List<Object?> get props => [
        assignmentId, juz, seatNumber, kind, status,
        readerDisplayName, isMe, completedAt,
      ];
}

class DashboardSnapshot extends Equatable {
  const DashboardSnapshot({
    required this.groupId,
    required this.groupName,
    required this.myRole,
    required this.status,
    required this.serverGeneratedAt,
    this.today,
    this.myAssignments = const [],
    this.assignments = const [],
    this.seats,
    this.activeMemberCount = 0,
    this.inviteCode,
    this.isStale = false,
    this.cachedAt,
  });

  final String groupId;
  final String groupName;
  final GroupRole myRole;
  final GroupStatus status;
  final DateTime serverGeneratedAt;

  final GroupDayInfo? today;

  /// My seat + volunteered/overridden rows.
  final List<Assignment> myAssignments;
  final List<Assignment> assignments;

  /// Forming groups return members per seat instead of assignments.
  final SeatMap? seats;
  final int activeMemberCount;
  final String? inviteCode;

  /// Set when this snapshot was served from cache after a network failure.
  final bool isStale;
  final DateTime? cachedAt;

  @override
  List<Object?> get props => [
        groupId, groupName, myRole, status, serverGeneratedAt, today,
        myAssignments, assignments, seats, activeMemberCount, inviteCode,
        isStale, cachedAt,
      ];
}

class HistoryDaySummary extends Equatable {
  const HistoryDaySummary({
    required this.groupDate,
    required this.completedCount,
    required this.lateCount,
    required this.missedCount,
    required this.unreadCount,
    required this.fullKhatma,
    this.myResult,
    this.perJuz,
  });

  final String groupDate;
  final int completedCount;
  final int lateCount;
  final int missedCount;
  final int unreadCount;
  final bool fullKhatma;

  /// My own row for regular members.
  final Assignment? myResult;

  /// Per-juz detail, owner/supervisor only.
  final List<Assignment>? perJuz;

  @override
  List<Object?> get props => [
        groupDate, completedCount, lateCount, missedCount, unreadCount,
        fullKhatma, myResult, perJuz,
      ];
}
