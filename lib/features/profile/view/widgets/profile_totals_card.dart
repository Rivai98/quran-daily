import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/localization/arabic_strings.dart';

class ProfileTotalsCard extends StatelessWidget {
  const ProfileTotalsCard({
    super.key,
    required this.portionsRead,
    required this.portionsLate,
  });

  final int portionsRead;
  final int portionsLate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(Icons.menu_book_rounded, color: colors.primary, size: 24),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ArabicStrings.portionsReadCount(portionsRead),
                        style: AppTypography.label,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 36,
            width: 1,
            color: colors.border,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          ),
          Expanded(
            child: Row(
              children: [
                Icon(Icons.history_rounded, color: colors.lateFg, size: 24),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ArabicStrings.portionsLateCount(portionsLate),
                        style: AppTypography.label.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
