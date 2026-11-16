import 'package:material_ui/material_ui.dart';

import '../../../../core/design_system/app_colors.dart';
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
      GroupStatus.forming => (
        Icons.hourglass_top_rounded,
        ArabicStrings.formingLabel,
      ),
      GroupStatus.active => (
        Icons.play_circle_outline_rounded,
        ArabicStrings.activeLabel,
      ),
      GroupStatus.archived => (
        Icons.archive_rounded,
        ArabicStrings.groupArchivedLabel,
      ),
    };
    final portionLabel = ArabicStrings.dailyUnitChip(group.portionUnit);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GroupAvatar(name: group.name, size: AppSpacing.xxl),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AppBadge(
                      icon: status.$1,
                      label: status.$2,
                      variant: switch (group.status) {
                        GroupStatus.forming => AppBadgeVariant.info,
                        GroupStatus.active => AppBadgeVariant.primary,
                        GroupStatus.archived => AppBadgeVariant.neutral,
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xxs,
            children: [
              _MetadataItem(
                icon: Icons.people_alt_rounded,
                label: ArabicFormatting.membersProgress(
                  group.activeMemberCount,
                ),
              ),
              _MetadataItem(icon: Icons.menu_book_rounded, label: portionLabel),
              _MetadataItem(
                icon: Icons.location_on_rounded,
                label: ArabicFormatting.timezoneCity(group.timezone),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            children: [
              if (onJoin != null)
                TextButton.icon(
                  label: Text(
                    isPending
                        ? ArabicStrings.pendingApproval
                        : isJoined
                        ? ArabicStrings.joinedSuccessfully
                        : membershipLimitReached || !group.canJoinLimit
                        ? ArabicStrings.membershipLimitReachedAction
                        : ArabicStrings.requestToJoin,
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, AppSpacing.xxl),
                  ),
                  icon: Icon(
                    isPending || isJoined
                        ? Icons.check_circle_rounded
                        : Icons.group_add_rounded,
                    size: AppSpacing.lg,
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
}

class _MetadataItem extends StatelessWidget {
  const _MetadataItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).extension<AppColors>()!.inkMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSpacing.md, color: color),
        const SizedBox(width: AppSpacing.xxs),
        Text(label, style: AppTypography.caption.copyWith(color: color)),
      ],
    );
  }
}
