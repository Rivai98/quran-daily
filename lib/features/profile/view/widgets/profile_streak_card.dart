import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/localization/arabic_strings.dart';

class ProfileStreakCard extends StatelessWidget {
  const ProfileStreakCard({
    super.key,
    required this.streak,
    required this.bestStreak,
  });

  final int streak;
  final int bestStreak;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_fire_department,
              color: colors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ArabicStrings.profileStreakDays(streak),
                  style: AppTypography.display,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  ArabicStrings.bestStreak(bestStreak),
                  style: AppTypography.caption.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
