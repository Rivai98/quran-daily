import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../data/entities/profile_entities.dart';

class ProfileKhatmasList extends StatelessWidget {
  const ProfileKhatmasList({
    super.key,
    required this.khatmas,
  });

  final List<ProfileKhatma> khatmas;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    if (khatmas.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline,
                  color: colors.inkMuted, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  ArabicStrings.noKhatmasYet,
                  style: AppTypography.body.copyWith(color: colors.inkMuted),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < khatmas.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.xs),
          AppCard(
            child: Row(
              children: [
                Icon(Icons.groups_outlined, color: colors.primary, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    khatmas[i].groupName,
                    style: AppTypography.title,
                  ),
                ),
                Text(
                  ArabicStrings.khatmasCount(khatmas[i].completed),
                  style: AppTypography.label.copyWith(color: colors.primary),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
