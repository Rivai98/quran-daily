import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/features/log/data/entities/log_entities.dart';

void main() {
  test('parses personal log summary, pagination, groups and statuses', () {
    final log = PersonalLog.fromJson({
      'streak': 5,
      'best_streak': 12,
      'month': {
        'year': 2026,
        'month': 11,
        'full_days': 9,
        'days_with_items': 12,
      },
      'next_before': '2026-10-15',
      'days': [
        {
          'date': '2026-11-14',
          'complete': false,
          'items': [
            {
              'group_id': 'g1',
              'group_name': 'مجموعة',
              'portion_unit': 'juz',
              'portion_index': 3,
              'kind': 'volunteer',
              'status': 'late',
              'completed_at': '2026-11-14T19:00:00Z',
              'group_day_id': 'd1',
            },
          ],
        },
      ],
    });

    expect(log.streak, 5);
    expect(log.bestStreak, 12);
    expect(log.month.fullDays, 9);
    expect(log.nextBefore, '2026-10-15');
    expect(log.days.single.items.single.status, LogItemStatus.late);
    expect(log.days.single.items.single.kind, LogItemKind.volunteer);
    expect(
      log.days.single.items.single.completedAt,
      DateTime.utc(2026, 11, 14, 19),
    );
  });
}
