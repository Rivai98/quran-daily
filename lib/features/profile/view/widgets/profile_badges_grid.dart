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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final gap = AppSpacing.xs;
      final width = (constraints.maxWidth - gap) / 2;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final badge in badges)
            SizedBox(width: width, child: _buildBadge(context, badge)),
        ],
      );
    },
  );

  Widget _buildBadge(BuildContext context, ProfileBadge badge) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final badgeInfo = _badgeInfo(badge.code);
    final progress = badgeInfo.current.clamp(0, badgeInfo.target);
    final earnedAt = badge.earnedAt;
    return Semantics(
      button: true,
      label:
          '${badgeInfo.title}? ${earnedAt == null ? ArabicStrings.badgeProgress(progress, badgeInfo.target, badgeInfo.unit) : ArabicStrings.badgeEarned(_date(earnedAt))}',
      child: Material(
        color: colors.surface,
        borderRadius: AppRadius.lgBR,
        child: InkWell(
          borderRadius: AppRadius.lgBR,
          onTap: () => _showDetails(context, badgeInfo, badge, progress),
          child: AppCard(
            padding: AppSpacing.card,
            child: _badgeContents(context, badgeInfo, badge, progress),
          ),
        ),
      ),
    );
  }

  Widget _badgeContents(
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
    final earned = badge.isEarned;
    final earnedAt = badge.earnedAt;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _badgeEmblem(context, badgeInfo, badge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          badgeInfo.title,
          textAlign: TextAlign.center,
          style: AppTypography.label,
          softWrap: true,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          earnedAt == null
              ? ArabicStrings.badgeProgress(
                  progress,
                  badgeInfo.target,
                  badgeInfo.unit,
                )
              : ArabicStrings.badgeEarned(_date(earnedAt)),
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(
            color: earned ? colors.primary : colors.inkMuted,
          ),
          softWrap: true,
        ),
      ],
    );
  }

  Widget _badgeEmblem(
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
  ) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final earned = badge.isEarned;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (earned) _earnedRing(colors),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: earned ? colors.primaryContainer : colors.surfaceMuted,
            border: Border.all(
              color: earned ? colors.accent : colors.border,
              width: earned ? 2 : 1,
            ),
          ),
          child: Icon(
            badgeInfo.icon,
            size: 27,
            color: earned ? colors.primary : colors.inkMuted,
          ),
        ),
        if (!earned) _lockedBadgeMarker(colors),
        if (badge.code == ProfileBadgeCode.portions100)
          _pillThreshold(colors, badgeInfo.target, earned),
        if (badge.code == ProfileBadgeCode.streak7 ||
            badge.code == ProfileBadgeCode.streak30 ||
            badge.code == ProfileBadgeCode.streak100)
          _roundThreshold(colors, badgeInfo.target, earned),
      ],
    );
  }

  Widget _earnedRing(AppColors colors) => Container(
    width: 58,
    height: 58,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: colors.accent.withValues(alpha: .35), width: 3),
    ),
  );

  Widget _lockedBadgeMarker(AppColors colors) => PositionedDirectional(
    end: -3,
    bottom: -3,
    child: Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: colors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: colors.border),
      ),
      child: Icon(Icons.lock_rounded, size: 13, color: colors.inkMuted),
    ),
  );

  Widget _pillThreshold(AppColors colors, int target, bool earned) =>
      PositionedDirectional(
        bottom: -2,
        start: -8,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: earned ? colors.primary : colors.surfaceMuted,
            borderRadius: AppRadius.pillBR,
            border: Border.all(color: colors.surface, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: Text(
              ArabicNumerals.format(target),
              style: AppTypography.caption.copyWith(
                color: earned ? colors.onPrimary : colors.inkMuted,
              ),
            ),
          ),
        ),
      );

  Widget _roundThreshold(AppColors colors, int target, bool earned) =>
      PositionedDirectional(
        bottom: -2,
        start: -5,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: earned ? colors.primary : colors.surfaceMuted,
            shape: BoxShape.circle,
            border: Border.all(color: colors.surface, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Text(
              ArabicNumerals.format(target),
              style: AppTypography.caption.copyWith(
                color: earned ? colors.onPrimary : colors.inkMuted,
              ),
            ),
          ),
        ),
      );

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
