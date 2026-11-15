import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/localization/arabic_numerals.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../data/entities/profile_entities.dart';

class ProfileBadgesGrid extends StatelessWidget {
  const ProfileBadgesGrid({
    super.key,
    required this.badges,
  });

  final List<ProfileBadge> badges;

  ({String title, String desc, IconData icon}) _badgeInfo(
    ProfileBadgeCode code,
  ) {
    switch (code) {
      case ProfileBadgeCode.firstKhatma:
        return (
          title: ArabicStrings.badgeFirstKhatmaTitle,
          desc: ArabicStrings.badgeFirstKhatmaDesc,
          icon: Icons.auto_awesome,
        );
      case ProfileBadgeCode.streak7:
        return (
          title: ArabicStrings.badgeStreak7Title,
          desc: ArabicStrings.badgeStreak7Desc,
          icon: Icons.looks_one_outlined,
        );
      case ProfileBadgeCode.streak30:
        return (
          title: ArabicStrings.badgeStreak30Title,
          desc: ArabicStrings.badgeStreak30Desc,
          icon: Icons.calendar_month_outlined,
        );
      case ProfileBadgeCode.streak100:
        return (
          title: ArabicStrings.badgeStreak100Title,
          desc: ArabicStrings.badgeStreak100Desc,
          icon: Icons.military_tech_outlined,
        );
      case ProfileBadgeCode.portions100:
        return (
          title: ArabicStrings.badgePortions100Title,
          desc: ArabicStrings.badgePortions100Desc,
          icon: Icons.menu_book,
        );
    }
  }

  String _formatDate(DateTime dt) {
    return '${ArabicNumerals.format(dt.year)}/${ArabicNumerals.format(dt.month)}/${ArabicNumerals.format(dt.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - AppSpacing.xs * 2) / 3;
        return Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final badge in badges)
              SizedBox(
                width: width,
                child: _buildBadgeCard(context, colors, badge),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBadgeCard(
    BuildContext context,
    AppColors colors,
    ProfileBadge badge,
  ) {
    final info = _badgeInfo(badge.code);
    final isEarned = badge.isEarned;

    return AppCard(
      padding: AppSpacing.compactCard,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isEarned ? colors.primaryContainer : colors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEarned ? info.icon : Icons.lock_outline,
              color: isEarned ? colors.accent : colors.inkMuted,
              size: 20,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  info.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: isEarned ? colors.ink : colors.inkMuted,
                  ),
                ),
                Text(
                  isEarned
                      ? ArabicStrings.badgeEarned(_formatDate(badge.earnedAt!))
                      : ArabicStrings.badgeLocked,
                  style: AppTypography.caption.copyWith(
                    color: isEarned ? colors.primary : colors.inkMuted,
                    fontWeight: isEarned ? FontWeight.w600 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
