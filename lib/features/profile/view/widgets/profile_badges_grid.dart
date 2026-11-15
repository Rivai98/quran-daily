import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/localization/arabic_numerals.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../data/entities/profile_entities.dart';

class ProfileBadgesGrid extends StatelessWidget {
  const ProfileBadgesGrid({
    super.key,
    required this.badges,
    required this.bestStreak,
    required this.portionsRead,
    required this.khatmasCompleted,
  });

  final List<ProfileBadge> badges;
  final int bestStreak;
  final int portionsRead;
  final int khatmasCompleted;

  ({
    String title,
    String desc,
    IconData icon,
    int current,
    int target,
    String unit,
  })
  _badgeInfo(ProfileBadgeCode code) {
    switch (code) {
      case ProfileBadgeCode.firstKhatma:
        return (
          title: ArabicStrings.badgeFirstKhatmaTitle,
          desc: ArabicStrings.badgeFirstKhatmaDesc,
          icon: Icons.auto_stories_rounded,
          current: khatmasCompleted,
          target: 1,
          unit: ArabicStrings.badgeProgressKhatmas,
        );
      case ProfileBadgeCode.streak7:
        return (
          title: ArabicStrings.badgeStreak7Title,
          desc: ArabicStrings.badgeStreak7Desc,
          icon: Icons.local_fire_department_rounded,
          current: bestStreak,
          target: 7,
          unit: ArabicStrings.badgeProgressDays,
        );
      case ProfileBadgeCode.streak30:
        return (
          title: ArabicStrings.badgeStreak30Title,
          desc: ArabicStrings.badgeStreak30Desc,
          icon: Icons.local_fire_department_rounded,
          current: bestStreak,
          target: 30,
          unit: ArabicStrings.badgeProgressDays,
        );
      case ProfileBadgeCode.streak100:
        return (
          title: ArabicStrings.badgeStreak100Title,
          desc: ArabicStrings.badgeStreak100Desc,
          icon: Icons.local_fire_department_rounded,
          current: bestStreak,
          target: 100,
          unit: ArabicStrings.badgeProgressDays,
        );
      case ProfileBadgeCode.portions100:
        return (
          title: ArabicStrings.badgePortions100Title,
          desc: ArabicStrings.badgePortions100Desc,
          icon: Icons.menu_book_rounded,
          current: portionsRead,
          target: 100,
          unit: ArabicStrings.badgeProgressPortions,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < badges.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colors.border),
            _buildBadge(context, badges[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, ProfileBadge badge) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final info = _badgeInfo(badge.code);
    final progress = info.current.clamp(0, info.target);
    final earned = badge.isEarned;
    final earnedAt = badge.earnedAt;
    final status = earnedAt == null
        ? ArabicStrings.badgeProgress(progress, info.target, info.unit)
        : ArabicStrings.badgeEarned(_date(earnedAt));
    return Semantics(
      button: true,
      label: '${info.title}، $status',
      child: InkWell(
        onTap: () => _showDetails(context, info, badge, progress),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: earned ? colors.primaryContainer : colors.surfaceMuted,
                  border: Border.all(
                    color: earned ? colors.accent : colors.border,
                    width: earned ? 2 : 1,
                  ),
                ),
                child: Icon(
                  info.icon,
                  size: 24,
                  color: earned ? colors.primary : colors.inkMuted,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    if (!earned) ...[
                      ClipRRect(
                        borderRadius: AppRadius.pillBR,
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          value: progress / info.target,
                          color: colors.primary,
                          backgroundColor: colors.surfaceMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                    ],
                    Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: earned ? colors.primary : colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                earned ? Icons.verified_rounded : Icons.lock_outline_rounded,
                size: 20,
                color: earned ? colors.primary : colors.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(
    BuildContext context,
    ({
      String title,
      String desc,
      IconData icon,
      int current,
      int target,
      String unit,
    })
    badgeInfo,
    ProfileBadge badge,
    int progress,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _badgeDetails(context, badgeInfo, badge, progress),
    );
  }

  Widget _badgeDetails(
    BuildContext context,
    ({
      String title,
      String desc,
      IconData icon,
      int current,
      int target,
      String unit,
    })
    badgeInfo,
    ProfileBadge badge,
    int progress,
  ) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final earnedAt = badge.earnedAt;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                badgeInfo.icon,
                color: badge.isEarned ? colors.primary : colors.inkMuted,
                size: 28,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(badgeInfo.title, style: AppTypography.title),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(badgeInfo.desc, style: AppTypography.body),
          const SizedBox(height: AppSpacing.md),
          Text(
            earnedAt == null
                ? ArabicStrings.badgeProgress(
                    progress,
                    badgeInfo.target,
                    badgeInfo.unit,
                  )
                : ArabicStrings.badgeEarned(_date(earnedAt)),
            style: AppTypography.label.copyWith(
              color: badge.isEarned ? colors.primary : colors.inkMuted,
            ),
          ),
          if (earnedAt == null) ...[
            const SizedBox(height: AppSpacing.xs),
            LinearProgressIndicator(
              value: progress / badgeInfo.target,
              color: colors.primary,
              backgroundColor: colors.surfaceMuted,
            ),
          ],
        ],
      ),
    );
  }

  String _date(DateTime date) =>
      '${ArabicNumerals.format(date.year)}/${ArabicNumerals.format(date.month)}/${ArabicNumerals.format(date.day)}';
}
