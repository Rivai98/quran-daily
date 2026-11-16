import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';

/// Builders for the shared entities (dashboard snapshots, seat maps,
/// 30-row grids, history). No Quranic names or boundaries are typed here —
/// use `QuranMetadataRepository` in tests that need real juz labels.
class TestFixtures {
  const TestFixtures._();

  static const groupName = 'مجموعة الفجر';
  static const groupId = 'g-1111';
  static const userId = 'u-1111';
  static const assignmentIdBase = 'a-';

  static GroupDayInfo openDay({int completed = 12}) {
    return GroupDayInfo(
      groupDate: '2026-11-14',
      state: DayState.open,
      completedCount: completed,
      lateCount: 0,
      missedCount: 0,
      unreadCount: 0,
      pendingCount: 30 - completed,
      availableCount: 0,
      fullKhatma: completed >= 30,
      endsAt: DateTime.parse('2026-11-15T00:00:00Z'),
    );
  }

  /// 30 assignment rows; one per juz, exactly once.
  static List<Assignment> grid({
    AssignmentStatusEnum Function(int juz)? statusFor,
    int mySeat = 1,
    String? Function(int juz)? readerFor,
  }) {
    return List.generate(30, (i) {
      final juz = i + 1;
      final seat = ((juz + mySeat - 2) % 30) + 1;
      return Assignment(
        assignmentId: 'a-$juz',
        juz: juz,
        seatNumber: seat,
        kind: AssignmentKind.seat,
        status: statusFor?.call(juz) ?? AssignmentStatusEnum.pending,
        readerDisplayName: readerFor?.call(juz),
        isMe: seat == mySeat,
      );
    });
  }

  static DashboardSnapshot activeDashboard({
    int completed = 12,
    GroupRole myRole = GroupRole.member,
    bool offline = false,
  }) {
    final grid = TestFixtures.grid(
      statusFor: (juz) => juz <= completed
          ? AssignmentStatusEnum.completed
          : AssignmentStatusEnum.pending,
      readerFor: (juz) => juz == 1 ? 'سارة' : 'عضو $juz',
    );
    return DashboardSnapshot(
      groupId: groupId,
      groupName: groupName,
      myRole: myRole,
      status: GroupStatus.active,
      serverGeneratedAt: DateTime.parse('2026-11-14T09:00:00Z'),
      today: openDay(completed: completed),
      myAssignments: grid.where((a) => a.isMe).toList(),
      assignments: grid,
      activeMemberCount: 30,
      inviteCode: 'AB23CD45',
      isStale: offline,
      cachedAt: offline ? DateTime.parse('2026-11-14T08:12:00Z') : null,
    );
  }

  /// 30-row snapshot with empty seats producing available juz.
  static DashboardSnapshot dashboardWithEmptySeats({
    Set<int> emptySeats = const {3, 7, 24},
    int mySeat = 1,
    int completed = 10,
  }) {
    final assignments = List.generate(30, (i) {
      final juz = i + 1;
      final seat = ((juz + mySeat - 2) % 30) + 1;
      final isEmpty = emptySeats.contains(seat);
      return Assignment(
        assignmentId: 'a-$juz',
        juz: juz,
        seatNumber: seat,
        kind: isEmpty ? AssignmentKind.unassigned : AssignmentKind.seat,
        status: isEmpty
            ? AssignmentStatusEnum.available
            : (juz <= completed
                  ? AssignmentStatusEnum.completed
                  : AssignmentStatusEnum.pending),
        readerDisplayName: isEmpty ? null : 'عضو $seat',
        isMe: seat == mySeat,
      );
    });
    return DashboardSnapshot(
      groupId: groupId,
      groupName: groupName,
      myRole: GroupRole.member,
      status: GroupStatus.active,
      serverGeneratedAt: DateTime.parse('2026-11-14T09:00:00Z'),
      today: GroupDayInfo(
        groupDate: '2026-11-14',
        state: DayState.open,
        completedCount: completed,
        lateCount: 0,
        missedCount: 0,
        unreadCount: 0,
        pendingCount: 30 - completed - emptySeats.length,
        availableCount: emptySeats.length,
        fullKhatma: false,
        endsAt: DateTime.parse('2026-11-15T00:00:00Z'),
      ),
      myAssignments: assignments.where((a) => a.isMe).toList(),
      assignments: assignments,
      activeMemberCount: 30 - emptySeats.length,
      inviteCode: 'AB23CD45',
    );
  }

  static SeatMap seatMap({
    List<SeatMember> members = const [],
    String inviteCode = 'AB23CD45',
  }) {
    return SeatMap(
      groupId: groupId,
      members: members,
      activeMemberCount: members.length,
      inviteCode: inviteCode,
    );
  }

  static SeatMember member(
    int seat, {
    GroupRole role = GroupRole.member,
    String? name,
  }) {
    return SeatMember(
      membershipId: 'm-$seat',
      displayName: name ?? 'عضو $seat',
      role: role,
      seatNumber: seat,
    );
  }

  static MyGroupSummary myGroup({
    String groupId = TestFixtures.groupId,
    GroupStatus status = GroupStatus.active,
    GroupRole role = GroupRole.member,
  }) {
    return MyGroupSummary(
      groupId: groupId,
      name: groupName,
      status: status,
      myRole: role,
      activeMemberCount: 12,
    );
  }

  static MyGroupsOverview overview({
    List<MyGroupSummary> groups = const [],
    List<PendingJoinRequest> pending = const [],
    bool stale = false,
  }) {
    return MyGroupsOverview(
      groups: groups,
      pendingRequests: pending,
      isStale: stale,
    );
  }

  static List<HistoryDaySummary> historyPage({int days = 7}) {
    return List.generate(days, (i) {
      final completed = 30 - (i % 3);
      return HistoryDaySummary(
        groupDate: '2026-11-${13 - i}',
        completedCount: completed,
        lateCount: i % 2,
        missedCount: (i % 3) - (i % 2) > 0 ? (i % 3) - (i % 2) : 0,
        unreadCount: 0,
        fullKhatma: completed == 30,
      );
    });
  }
}
