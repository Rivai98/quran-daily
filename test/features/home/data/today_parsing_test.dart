import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/features/home/data/today_snapshot.dart';

void main() {
  test(
    'parses the get_my_today contract including nullable day and item status',
    () {
      final snapshot = TodaySnapshot.fromJson({
        'server_generated_at': '2026-11-15T12:00:00Z',
        'main_group_id': 'g1',
        'membership_count': 1,
        'membership_limit': 2,
        'groups': [
          {
            'group_id': 'g1',
            'name': 'مجموعة',
            'role': 'owner',
            'status': 'active',
            'portion_unit': 'juz',
            'is_main': true,
            'active_member_count': 12,
            'photo_path': 'g1/photo.jpg',
            'day': {
              'group_date': '2026-11-15',
              'day_index': 1,
              'state': 'open',
              'ends_at': '2026-11-16T00:00:00Z',
              'closes_at': '2026-11-16T02:00:00Z',
              'cycle_number': 1,
              'cycle_day': 1,
              'cycle_length': 30,
              'completed_count': 4,
              'completed_member_count': 3,
              'total_count': 30,
              'rest_day': false,
            },
            'items': [
              {
                'assignment_id': 'a1',
                'kind': 'seat',
                'seat_number': 2,
                'portion_index': 8,
                'status': 'pending',
                'can_undo': true,
              },
            ],
          },
        ],
      });
      expect(snapshot.groups.single.day?.completedCount, 4);
      expect(snapshot.groups.single.day?.completedMemberCount, 3);
      expect(snapshot.groups.single.activeMemberCount, 12);
      expect(snapshot.groups.single.photoPath, 'g1/photo.jpg');
      expect(snapshot.groups.single.items.single.portionIndex, 8);
      expect(snapshot.mainGroupId, 'g1');
    },
  );
}
