import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/app_card.dart';

class ProfileNavigationTile extends StatelessWidget {
  const ProfileNavigationTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: AppRadius.lgBR,
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.card,
          child: Row(
            children: [
              Icon(icon, color: colors.primary, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(title, style: AppTypography.title)),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.inkMuted,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
