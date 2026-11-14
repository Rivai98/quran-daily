import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import 'dense_info_row.dart';
import '../../../../core/design_system/app_radius.dart';

class HistoryDaySummaryTile extends StatelessWidget {
  const HistoryDaySummaryTile({
    required this.day,
    required this.count,
    required this.percent,
    required this.detail,
    super.key,
  });

  final String day;
  final String count;
  final String percent;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return DenseInfoRow(
      icon: Icons.calendar_today,
      title: day,
      subtitle: '$count - $detail',
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: AppRadius.smBR,
        ),
        child: Text(
          percent,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
