import 'package:flutter/material.dart';

class DashboardProgressHeader extends StatelessWidget {
  const DashboardProgressHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('مجموعة الفجر', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('اليوم: 21 يونيو 2026 - توقيت القاهرة',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: 12 / 30,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '12 / 30',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('نسبة إتمام ورد اليوم: 40%', style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
