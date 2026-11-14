import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/models/models.dart';

void main() {
  group('mappers round-trip', () {
    test('MyGroupSummary', () {
      const g = MyGroupSummary(
        groupId: 'g1',
        name: 'حلقة الفجر',
        status: GroupStatus.active,
        myRole: GroupRole.owner,
        activeMemberCount: 7,
        todayMyJuz: 5,
        todayMyStatus: AssignmentStatusEnum.pending,
        todayMyAssignmentId: 'a5',
      );
      final restored = myGroupSummaryFromJson(myGroupSummaryToJson(g));
      expect(restored, g);
    });

    test('MyGroupSummary without today assignment', () {
      const g = MyGroupSummary(
        groupId: 'g1',
        name: 'حلقة',
        status: GroupStatus.forming,
        myRole: GroupRole.member,
        activeMemberCount: 1,
      );
      expect(myGroupSummaryFromJson(myGroupSummaryToJson(g)), g);
    });

    test('PendingJoinRequest', () {
      final r = PendingJoinRequest(
        joinRequestId: 'jr1',
        groupId: 'g1',
        groupName: 'حلقة',
        requestedAt: DateTime.parse('2026-11-14T10:00:00Z'),
        source: JoinSource.invite,
      );
      expect(pendingJoinRequestFromJson(pendingJoinRequestToJson(r)), r);
    });

    test('Assignment (all kinds and statuses)', () {
      for (final kind in AssignmentKind.values) {
        for (final status in AssignmentStatusEnum.values) {
          final a = Assignment(
            assignmentId: 'a-$kind-$status',
            juz: 12,
            seatNumber: 9,
            kind: kind,
            status: status,
            readerDisplayName:
                kind == AssignmentKind.unassigned ? null : 'سارة',
            isMe: true,
            completedAt: status == AssignmentStatusEnum.completed
                ? DateTime.parse('2026-11-14T08:00:00Z')
                : null,
          );
          expect(assignmentFromJson(assignmentToJson(a)), a,
              reason: '$kind/$status');
        }
      }
    });

    test('GroupDayInfo', () {
      final d = GroupDayInfo(
        groupDate: '2026-11-14',
        state: DayState.open,
        completedCount: 12,
        lateCount: 1,
        missedCount: 2,
        unreadCount: 3,
        pendingCount: 11,
        availableCount: 1,
        fullKhatma: false,
        endsAt: DateTime.parse('2026-11-15T00:00:00Z'),
      );
      expect(groupDayInfoFromJson(groupDayInfoToJson(d)), d);
    });

    test('SeatMap with empty seats derived', () {
      final seatMap = SeatMap(
        groupId: 'g1',
        activeMemberCount: 2,
        inviteCode: 'AB23CD45',
        members: const [
          SeatMember(
            membershipId: 'm1',
            displayName: 'سارة',
            role: GroupRole.owner,
            seatNumber: 1,
          ),
          SeatMember(
            membershipId: 'm2',
            displayName: 'أحمد',
            role: GroupRole.member,
            seatNumber: 3,
          ),
        ],
      );
      expect(seatMap.emptySeats.length, 28);
      expect(seatMap.emptySeats.contains(1), isFalse);
      expect(seatMap.emptySeats.contains(2), isTrue);
      expect(seatMap.emptySeats.contains(3), isFalse);
    });

    test('DashboardSnapshot active shape', () {
      final snapshot = DashboardSnapshot(
        groupId: 'g1',
        groupName: 'حلقة الفجر',
        myRole: GroupRole.member,
        status: GroupStatus.active,
        serverGeneratedAt: DateTime.parse('2026-11-14T09:00:00Z'),
        today: GroupDayInfo(
          groupDate: '2026-11-14',
          state: DayState.open,
          completedCount: 5,
          lateCount: 0,
          missedCount: 0,
          unreadCount: 0,
          pendingCount: 24,
          availableCount: 1,
          fullKhatma: false,
          endsAt: DateTime.parse('2026-11-15T00:00:00Z'),
        ),
        myAssignments: [
          Assignment(
            assignmentId: 'a5',
            juz: 5,
            seatNumber: 1,
            kind: AssignmentKind.seat,
            status: AssignmentStatusEnum.pending,
            isMe: true,
          ),
        ],
        assignments: List.generate(
          30,
          (i) => Assignment(
            assignmentId: 'a${i + 1}',
            juz: i + 1,
            seatNumber: ((i + 1) % 30) + 1,
            kind: AssignmentKind.seat,
            status: i < 5
                ? AssignmentStatusEnum.completed
                : AssignmentStatusEnum.pending,
          ),
        ),
        activeMemberCount: 29,
        inviteCode: 'AB23CD45',
      );

      final restored =
          dashboardSnapshotFromJson(dashboardSnapshotToJson(snapshot));
      expect(restored.groupId, snapshot.groupId);
      expect(restored.today, snapshot.today);
      expect(restored.myAssignments, snapshot.myAssignments);
      expect(restored.assignments.length, 30);
      expect(restored.assignments.map((a) => a.juz).toSet().length, 30,
          reason: 'each of the 30 juz appears exactly once');
      expect(restored.isStale, isFalse);
    });

    test('DashboardSnapshot forming shape', () {
      final snapshot = DashboardSnapshot(
        groupId: 'g1',
        groupName: 'حلقة',
        myRole: GroupRole.owner,
        status: GroupStatus.forming,
        serverGeneratedAt: DateTime.parse('2026-11-14T09:00:00Z'),
        seats: SeatMap(
          groupId: 'g1',
          activeMemberCount: 2,
          inviteCode: 'AB23CD45',
          members: const [
            SeatMember(
              membershipId: 'm1',
              displayName: 'سارة',
              role: GroupRole.owner,
              seatNumber: 1,
            ),
          ],
        ),
        activeMemberCount: 2,
        inviteCode: 'AB23CD45',
      );

      final restored =
          dashboardSnapshotFromJson(dashboardSnapshotToJson(snapshot));
      expect(restored.seats!.members.single.seatNumber, 1);
      expect(restored.assignments, isEmpty);
    });

    test('HistoryDaySummary member shape (no perJuz)', () {
      final h = HistoryDaySummary(
        groupDate: '2026-11-13',
        completedCount: 28,
        lateCount: 1,
        missedCount: 1,
        unreadCount: 0,
        fullKhatma: false,
        myResult: Assignment(
          assignmentId: 'a17',
          juz: 17,
          seatNumber: 17,
          kind: AssignmentKind.seat,
          status: AssignmentStatusEnum.missed,
        ),
      );
      final restored = historyDaySummaryFromJson(historyDaySummaryToJson(h));
      expect(restored, h);
      expect(restored.perJuz, isNull);
    });

    test('HistoryDaySummary supervisor shape (perJuz)', () {
      final h = HistoryDaySummary(
        groupDate: '2026-11-13',
        completedCount: 28,
        lateCount: 1,
        missedCount: 1,
        unreadCount: 0,
        fullKhatma: false,
        perJuz: List.generate(
          30,
          (i) => Assignment(
            assignmentId: 'a${i + 1}',
            juz: i + 1,
            seatNumber: i + 1,
            kind: AssignmentKind.seat,
            status: i == 16
                ? AssignmentStatusEnum.missed
                : AssignmentStatusEnum.completed,
          ),
        ),
      );
      final restored = historyDaySummaryFromJson(historyDaySummaryToJson(h));
      expect(restored, h);
      expect(restored.perJuz!.length, 30);
    });

    test('JoinOutcome joined and pending shapes', () {
      final joined = JoinOutcome(
        joined: true,
        membershipId: 'm9',
        seatNumber: 4,
      );
      final pending = JoinOutcome(
        joined: false,
        joinRequestId: 'jr7',
      );

      expect(
        joinOutcomeFromJson({
          'result': 'joined',
          'membership_id': 'm9',
          'seat_number': 4,
        }),
        joined,
      );
      expect(
        joinOutcomeFromJson({
          'result': 'pending',
          'join_request_id': 'jr7',
        }),
        pending,
      );
    });

    test('enum decoders reject unknown group status', () {
      expect(() => groupStatusOf('bogus'), throwsArgumentError);
    });
  });
}
