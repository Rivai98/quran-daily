import 'package:flutter/material.dart';

import '../../../../core/localization/arabic_strings.dart';
import 'status_chip.dart';

class AssignmentList extends StatelessWidget {
  const AssignmentList({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('أحمد محمد', 'جزء 1 - الفاتحة إلى البقرة 141', ArabicStrings.completed,
          ReadingStatus.completed),
      ('سارة علي', 'جزء 2 - البقرة 142 إلى 252', ArabicStrings.pending,
          ReadingStatus.pending),
      ('محمود حسن', 'جزء 3 - البقرة 253 إلى آل عمران 92', ArabicStrings.late,
          ReadingStatus.late),
      ('هدى خالد', 'جزء 10 - الأنفال 41 إلى التوبة 92', ArabicStrings.missed,
          ReadingStatus.missed),
    ];

    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(row.$1.substring(0, 1))),
                title: Text(row.$1),
                subtitle: Text(row.$2),
                trailing: StatusChip(label: row.$3, status: row.$4),
              ),
            ),
          ),
      ],
    );
  }
}
