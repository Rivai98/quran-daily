import 'package:flutter/material.dart';

import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/theme/app_spacing.dart';

class MemberSlotReadiness extends StatelessWidget {
  const MemberSlotReadiness({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ArabicStrings.groupReadiness,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(ArabicStrings.memberCount29),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              value: 29 / 30,
              minHeight: 12,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              ArabicStrings.publishBlocked,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
