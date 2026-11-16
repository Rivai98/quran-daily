import 'package:material_ui/material_ui.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/localization/arabic_formatting.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../data/entities/log_entities.dart';

class MonthSummary extends StatelessWidget {
  const MonthSummary({super.key, required this.summary});
  final LogMonthSummary summary;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      children: [
        const Icon(Icons.calendar_month_rounded),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            ArabicStrings.logMonthSummary,
            style: AppTypography.title,
          ),
        ),
        Text(
          ArabicFormatting.completedProgress(
            summary.fullDays,
            summary.daysWithItems,
          ),
          style: AppTypography.label,
        ),
      ],
    ),
  );
}
