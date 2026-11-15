import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/widgets.dart';
import '../../../../core/localization/arabic_formatting.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../data/entities/entities.dart';
import '../../data/models/models.dart';
import '../../../../core/quran/quran_metadata_repository.dart';
import '../../cubit/discovery/discovery_cubit.dart';

class PublicGroupCard extends StatelessWidget {
  const PublicGroupCard({
    super.key,
    required this.group,
    this.onJoin,
    this.joinState,
    this.metadataRepository,
    this.membershipLimitReached = false,
  });

  final PublicGroupProfile group;
  final VoidCallback? onJoin;
  final GroupJoinState? joinState;
  final QuranMetadataRepository? metadataRepository;
  final bool membershipLimitReached;

  @override
  Widget build(BuildContext context) {
    final isPending =
        joinState == GroupJoinState.pending ||
        group.myRequestStatus == 'pending';
    final isJoined = joinState == GroupJoinState.joined;
    final canJoin = group.canJoinLimit && !membershipLimitReached;
    final status = switch (group.status) {
      GroupStatus.forming => (Icons.hourglass_top, ArabicStrings.formingLabel),
      GroupStatus.active => (
        Icons.play_circle_outline,
        ArabicStrings.activeLabel,
      ),
      GroupStatus.archived => (
        Icons.archive_outlined,
        ArabicStrings.groupArchivedLabel,
      ),
    };
    final portionLabel = ArabicStrings.dailyUnitChip(group.portionUnit);
    final metadata = [
      ArabicFormatting.membersProgress(group.activeMemberCount),
      portionLabel,
      _timezoneCity(group.timezone),
    ].join(ArabicStrings.groupCitySeparator);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GroupAvatar(name: group.name, size: AppSpacing.xl),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  group.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            metadata,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: Theme.of(context).extension<AppColors>()!.inkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            children: [
              _GroupStatusBadge(
                icon: status.$1,
                label: status.$2,
                groupStatus: group.status,
              ),
              if (onJoin != null)
                AppButton(
                  label: isPending
                      ? ArabicStrings.pendingApproval
                      : isJoined
                      ? ArabicStrings.joinedSuccessfully
                      : membershipLimitReached || !group.canJoinLimit
                      ? ArabicStrings.membershipLimitReachedAction
                      : ArabicStrings.requestToJoin,
                  variant: AppButtonVariant.secondary,
                  loading: joinState == GroupJoinState.joining,
                  icon: Icon(
                    isPending || isJoined
                        ? Icons.check_circle
                        : Icons.group_add_outlined,
                  ),
                  onPressed:
                      canJoin &&
                          !isPending &&
                          !isJoined &&
                          joinState != GroupJoinState.joining
                      ? onJoin
                      : null,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _timezoneCity(String timezone) {
    final city = timezone.split('/').last.replaceAll('_', ' ');
    return switch (city) {
      'Cairo' => 'القاهرة',
      'Riyadh' => 'الرياض',
      'Makkah' => 'مكة',
      'Madinah' => 'المدينة',
      'UTC' => 'التوقيت العالمي',
      _ => 'التوقيت المحلي',
    };
  }
}

class _GroupStatusBadge extends StatelessWidget {
  const _GroupStatusBadge({
    required this.icon,
    required this.label,
    required this.groupStatus,
  });

  final IconData icon;
  final String label;
  final GroupStatus groupStatus;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final foreground = switch (groupStatus) {
      GroupStatus.forming => colors.infoFg,
      GroupStatus.active => colors.primary,
      GroupStatus.archived => colors.inkMuted,
    };
    final background = switch (groupStatus) {
      GroupStatus.forming => colors.infoBg,
      GroupStatus.active => colors.primaryContainer,
      GroupStatus.archived => colors.surfaceMuted,
    };
    return Container(
      constraints: const BoxConstraints(minHeight: AppSpacing.xl),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: foreground.withValues(alpha: 0.32)),
        borderRadius: AppRadius.pillBR,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSpacing.md, color: foreground),
          const SizedBox(width: AppSpacing.xxs),
          Text(label, style: AppTypography.caption.copyWith(color: foreground)),
        ],
      ),
    );
  }
}
