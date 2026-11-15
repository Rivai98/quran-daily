import 'package:flutter/material.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/localization/arabic_numerals.dart';
import '../../../../core/localization/arabic_formatting.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../data/entities/log_entities.dart';

class StreakHeader extends StatelessWidget {
  const StreakHeader({super.key, required this.log});
  final PersonalLog log;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Padding(
      padding: AppSpacing.card,
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ArabicStrings.logCurrentStreak}: '
                  '${ArabicFormatting.isolate(ArabicNumerals.format(log.streak))}',
                  style: AppTypography.title,
                ),
                Text(
                  '${ArabicStrings.logBestStreak}: '
                  '${ArabicFormatting.isolate(ArabicNumerals.format(log.bestStreak))}',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
