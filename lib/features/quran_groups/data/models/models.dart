import '../entities/entities.dart';
import '../../../../core/quran/portion_unit.dart';

PortionUnit portionUnitOf(Object? raw) {
  switch (raw) {
    case 'half_juz':
      return PortionUnit.halfJuz;
    case 'hizb':
      return PortionUnit.hizb;
    case 'quarter':
      return PortionUnit.quarter;
    case 'page':
      return PortionUnit.page;
    default:
      return PortionUnit.juz;
  }
}

String portionUnitName(PortionUnit unit) => switch (unit) {
  PortionUnit.juz => 'juz',
  PortionUnit.halfJuz => 'half_juz',
  PortionUnit.hizb => 'hizb',
  PortionUnit.quarter => 'quarter',
  PortionUnit.page => 'page',
};

/// JSON mappers for the RPC read models (snake_case from Postgres).
/// Round-trip safety is tested in models_test.dart.

GroupStatus groupStatusOf(String raw) => GroupStatus.values.firstWhere(
  (v) => v.name == raw || _statusAliases[raw] == v,
  orElse: () => throw ArgumentError('unknown group status: $raw'),
);

const _statusAliases = <String, GroupStatus>{
  'forming': GroupStatus.forming,
  'active': GroupStatus.active,
  'archived': GroupStatus.archived,
};

JoinMode joinModeOf(String raw) =>
    raw == 'auto_accept' ? JoinMode.autoAccept : JoinMode.approval;

String joinModeName(JoinMode mode) =>
    mode == JoinMode.autoAccept ? 'auto_accept' : 'approval';

GroupRole groupRoleOf(String raw) {
  switch (raw) {
    case 'owner':
      return GroupRole.owner;
    case 'supervisor':
      return GroupRole.supervisor;
    default:
      return GroupRole.member;
  }
}

String groupRoleName(GroupRole role) {
  switch (role) {
    case GroupRole.owner:
      return 'owner';
    case GroupRole.supervisor:
      return 'supervisor';
    case GroupRole.member:
      return 'member';
  }
}

DayState dayStateOf(String raw) => DayState.values.firstWhere(
  (v) => v.name == raw,
  orElse: () => DayState.open,
);

AssignmentKind assignmentKindOf(String raw) {
  switch (raw) {
    case 'seat':
      return AssignmentKind.seat;
    case 'override':
      return AssignmentKind.override;
    case 'volunteer':
      return AssignmentKind.volunteer;
    default:
      return AssignmentKind.unassigned;
  }
}

String assignmentKindName(AssignmentKind kind) => kind.name;

AssignmentStatusEnum assignmentStatusOf(String raw) {
  switch (raw) {
    case 'completed':
      return AssignmentStatusEnum.completed;
    case 'missed':
      return AssignmentStatusEnum.missed;
    case 'late':
      return AssignmentStatusEnum.late;
    case 'available':
      return AssignmentStatusEnum.available;
    case 'unread':
      return AssignmentStatusEnum.unread;
    default:
      return AssignmentStatusEnum.pending;
  }
}

String assignmentStatusName(AssignmentStatusEnum status) => status.name;

MyGroupSummary myGroupSummaryFromJson(Map<String, Object?> json) {
  final today = json['today_my_assignment'] as Map<String, Object?>?;
  return MyGroupSummary(
    groupId: json['group_id']! as String,
    name: json['name']! as String,
    status: groupStatusOf(json['status']! as String),
    myRole: groupRoleOf(json['my_role']! as String),
    activeMemberCount: (json['active_member_count'] as num?)?.toInt() ?? 0,
    todayMyJuz: (today?['juz'] as num?)?.toInt(),
    todayMyStatus: today == null
        ? null
        : assignmentStatusOf(today['status']! as String),
    todayMyAssignmentId: today?['assignment_id'] as String?,
    portionUnit: portionUnitOf(json['portion_unit']),
    pendingPortionUnit: json['pending_portion_unit'] == null
        ? null
        : portionUnitOf(json['pending_portion_unit']),
  );
}

Map<String, Object?> myGroupSummaryToJson(MyGroupSummary g) => {
  'group_id': g.groupId,
  'name': g.name,
  'status': g.status.name,
  'my_role': groupRoleName(g.myRole),
  'active_member_count': g.activeMemberCount,
  'portion_unit': portionUnitName(g.portionUnit),
  if (g.pendingPortionUnit != null)
    'pending_portion_unit': portionUnitName(g.pendingPortionUnit!),
  if (g.todayMyAssignmentId != null)
    'today_my_assignment': {
      'assignment_id': g.todayMyAssignmentId,
      'juz': g.todayMyJuz,
      'status': assignmentStatusName(g.todayMyStatus!),
    },
};

PendingJoinRequest pendingJoinRequestFromJson(Map<String, Object?> json) {
  return PendingJoinRequest(
    joinRequestId: json['join_request_id']! as String,
    groupId: json['group_id']! as String,
    groupName: json['group_name']! as String,
    requestedAt: DateTime.parse(json['requested_at']! as String),
    source: (json['source']! as String) == 'invite'
        ? JoinSource.invite
        : ((json['source']! as String) == 'match'
              ? JoinSource.match
              : JoinSource.discovery),
  );
}

Map<String, Object?> pendingJoinRequestToJson(PendingJoinRequest r) => {
  'join_request_id': r.joinRequestId,
  'group_id': r.groupId,
  'group_name': r.groupName,
  'requested_at': r.requestedAt.toIso8601String(),
  'source': r.source.name,
};

PublicGroupProfile publicGroupProfileFromJson(Map<String, Object?> json) {
  return PublicGroupProfile(
    groupId: json['group_id']! as String,
    name: json['name']! as String,
    shortDescription: json['short_description'] as String?,
    status: groupStatusOf(json['status']! as String),
    activeMemberCount: (json['active_member_count'] as num?)?.toInt() ?? 0,
    timezone: json['timezone']! as String,
    joinMode: json['join_mode'] == null
        ? null
        : joinModeOf(json['join_mode']! as String),
    myRequestStatus: json['my_request_status'] as String?,
    myJoinRequestId: json['my_join_request_id'] as String?,
    portionUnit: portionUnitOf(json['portion_unit']),
  );
}

class PublicGroupProfile extends GroupSummary {
  const PublicGroupProfile({
    required super.groupId,
    required super.name,
    required super.status,
    required super.activeMemberCount,
    required super.timezone,
    super.shortDescription,
    super.joinMode,
    super.myRequestStatus,
    super.myJoinRequestId,
    super.portionUnit,
  });
}

Assignment assignmentFromJson(Map<String, Object?> json) {
  return Assignment(
    assignmentId: json['assignment_id']! as String,
    juz: ((json['juz'] ?? json['portion_index']) as num).toInt(),
    portionIndex: (json['portion_index'] as num?)?.toInt(),
    seatNumber: (json['seat_number']! as num).toInt(),
    kind: assignmentKindOf(json['kind']! as String),
    status: assignmentStatusOf(json['status']! as String),
    readerDisplayName: json['reader_display_name'] as String?,
    isMe: json['is_me'] == true,
    completedAt: json['completed_at'] == null
        ? null
        : DateTime.parse(json['completed_at']! as String),
  );
}

Map<String, Object?> assignmentToJson(Assignment a) => {
  'assignment_id': a.assignmentId,
  'juz': a.juz,
  'portion_index': a.portionIndex,
  'seat_number': a.seatNumber,
  'kind': assignmentKindName(a.kind),
  'status': assignmentStatusName(a.status),
  if (a.readerDisplayName != null) 'reader_display_name': a.readerDisplayName,
  'is_me': a.isMe,
  if (a.completedAt != null) 'completed_at': a.completedAt!.toIso8601String(),
};

GroupDayInfo groupDayInfoFromJson(Map<String, Object?> json) {
  return GroupDayInfo(
    groupDate: json['group_date']! as String,
    state: dayStateOf(json['state']! as String),
    completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
    lateCount: (json['late_count'] as num?)?.toInt() ?? 0,
    missedCount: (json['missed_count'] as num?)?.toInt() ?? 0,
    unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    pendingCount: (json['pending_count'] as num?)?.toInt() ?? 0,
    availableCount: (json['available_count'] as num?)?.toInt() ?? 0,
    fullKhatma: json['full_khatma'] == true,
    endsAt: DateTime.parse(json['ends_at']! as String),
  );
}

Map<String, Object?> groupDayInfoToJson(GroupDayInfo d) => {
  'group_date': d.groupDate,
  'state': d.state.name,
  'completed_count': d.completedCount,
  'late_count': d.lateCount,
  'missed_count': d.missedCount,
  'unread_count': d.unreadCount,
  'pending_count': d.pendingCount,
  'available_count': d.availableCount,
  'full_khatma': d.fullKhatma,
  'ends_at': d.endsAt.toIso8601String(),
};

CycleInfo cycleInfoFromJson(Map<String, Object?> json) => CycleInfo(
  number: (json['number'] as num?)?.toInt() ?? 1,
  day: (json['day'] as num?)?.toInt() ?? 1,
  length: (json['length'] as num?)?.toInt() ?? 1,
  completed: (json['completed'] as num?)?.toInt() ?? 0,
  total: (json['total'] as num?)?.toInt() ?? 30,
);

Map<String, Object?> cycleInfoToJson(CycleInfo cycle) => {
  'number': cycle.number,
  'day': cycle.day,
  'length': cycle.length,
  'completed': cycle.completed,
  'total': cycle.total,
};

SeatMember seatMemberFromJson(Map<String, Object?> json) {
  return SeatMember(
    membershipId: json['membership_id']! as String,
    displayName: json['display_name']! as String,
    role: groupRoleOf(json['role']! as String),
    seatNumber: (json['seat_number']! as num).toInt(),
  );
}

SeatMap seatMapFromJson(Map<String, Object?> json) {
  return SeatMap(
    groupId: json['group_id']! as String,
    activeMemberCount: (json['active_member_count'] as num?)?.toInt() ?? 0,
    inviteCode: json['invite_code'] as String?,
    members: ((json['members'] ?? const []) as List)
        .map((e) => seatMemberFromJson((e as Map).cast<String, Object?>()))
        .toList(),
  );
}

DashboardSnapshot dashboardSnapshotFromJson(
  Map<String, Object?> json, {
  bool isStale = false,
  DateTime? cachedAt,
}) {
  final status = groupStatusOf(json['status']! as String);
  final seats = json['seats'] == null
      ? null
      : seatMapFromJson((json['seats']! as Map).cast<String, Object?>());
  return DashboardSnapshot(
    groupId: json['group_id']! as String,
    groupName: json['group_name']! as String,
    myRole: groupRoleOf(json['my_role']! as String),
    status: status,
    serverGeneratedAt: DateTime.parse(json['server_generated_at']! as String),
    today: json['today'] == null
        ? null
        : groupDayInfoFromJson((json['today']! as Map).cast<String, Object?>()),
    myAssignments: ((json['my_assignments'] ?? const []) as List)
        .map((e) => assignmentFromJson((e as Map).cast<String, Object?>()))
        .toList(),
    assignments: ((json['assignments'] ?? const []) as List)
        .map((e) => assignmentFromJson((e as Map).cast<String, Object?>()))
        .toList(),
    seats: seats,
    activeMemberCount: (json['active_member_count'] as num?)?.toInt() ?? 0,
    inviteCode: json['invite_code'] as String?,
    portionUnit: portionUnitOf(json['portion_unit']),
    pendingPortionUnit: json['pending_portion_unit'] == null
        ? null
        : portionUnitOf(json['pending_portion_unit']),
    cycle: json['cycle'] == null
        ? null
        : cycleInfoFromJson((json['cycle']! as Map).cast<String, Object?>()),
    isStale: isStale,
    cachedAt: cachedAt,
  );
}

Map<String, Object?> dashboardSnapshotToJson(DashboardSnapshot s) => {
  'group_id': s.groupId,
  'group_name': s.groupName,
  'my_role': groupRoleName(s.myRole),
  'status': s.status.name,
  'server_generated_at': s.serverGeneratedAt.toIso8601String(),
  if (s.today != null) 'today': groupDayInfoToJson(s.today!),
  'my_assignments': s.myAssignments.map(assignmentToJson).toList(),
  'assignments': s.assignments.map(assignmentToJson).toList(),
  if (s.seats != null)
    'seats': {
      'group_id': s.seats!.groupId,
      'active_member_count': s.seats!.activeMemberCount,
      'invite_code': s.seats!.inviteCode,
      'members': s.seats!.members
          .map(
            (m) => {
              'membership_id': m.membershipId,
              'display_name': m.displayName,
              'role': groupRoleName(m.role),
              'seat_number': m.seatNumber,
            },
          )
          .toList(),
    },
  'active_member_count': s.activeMemberCount,
  'portion_unit': portionUnitName(s.portionUnit),
  if (s.pendingPortionUnit != null)
    'pending_portion_unit': portionUnitName(s.pendingPortionUnit!),
  if (s.cycle != null) 'cycle': cycleInfoToJson(s.cycle!),
  if (s.inviteCode != null) 'invite_code': s.inviteCode,
};

HistoryDaySummary historyDaySummaryFromJson(Map<String, Object?> json) {
  final perJuz = json['per_juz'] == null
      ? null
      : ((json['per_juz']!) as List)
            .map((e) => assignmentFromJson((e as Map).cast<String, Object?>()))
            .toList();
  return HistoryDaySummary(
    groupDate: json['group_date']! as String,
    completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
    lateCount: (json['late_count'] as num?)?.toInt() ?? 0,
    missedCount: (json['missed_count'] as num?)?.toInt() ?? 0,
    unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    fullKhatma: json['full_khatma'] == true,
    myResult: json['my_result'] == null
        ? null
        : assignmentFromJson(
            (json['my_result']! as Map).cast<String, Object?>(),
          ),
    perJuz: perJuz,
    cycleNumber: (json['cycle_number'] as num?)?.toInt(),
    cycleDay: (json['cycle_day'] as num?)?.toInt(),
  );
}

Map<String, Object?> historyDaySummaryToJson(HistoryDaySummary h) => {
  'group_date': h.groupDate,
  'completed_count': h.completedCount,
  'late_count': h.lateCount,
  'missed_count': h.missedCount,
  'unread_count': h.unreadCount,
  'full_khatma': h.fullKhatma,
  if (h.cycleNumber != null) 'cycle_number': h.cycleNumber,
  if (h.cycleDay != null) 'cycle_day': h.cycleDay,
  if (h.myResult != null) 'my_result': assignmentToJson(h.myResult!),
  if (h.perJuz != null) 'per_juz': h.perJuz!.map(assignmentToJson).toList(),
};

JoinOutcome joinOutcomeFromJson(Map<String, Object?> json) {
  return JoinOutcome(
    joined: json['result'] == 'joined',
    membershipId: json['membership_id'] as String?,
    seatNumber: (json['seat_number'] as num?)?.toInt(),
    joinRequestId: json['join_request_id'] as String?,
  );
}
