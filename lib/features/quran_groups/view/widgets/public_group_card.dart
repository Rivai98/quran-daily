import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/widgets/widgets.dart';
import '../../../../core/localization/arabic_numerals.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../data/entities/entities.dart';
import '../../data/models/models.dart';
import '../../cubit/discovery/discovery_cubit.dart';
import 'join_status_badge.dart';

class PublicGroupCard extends StatelessWidget {
  const PublicGroupCard({
    super.key,
    required this.group,
    this.onJoin,
    this.joinState,
  });

  final PublicGroupProfile group;
  final VoidCallback? onJoin;
  final GroupJoinState? joinState;

  @override
  Widget build(BuildContext context) {
    final isPending =
        joinState == GroupJoinState.pending ||
        group.myRequestStatus == 'pending';
    final isJoined = joinState == GroupJoinState.joined;
    final icon = switch (group.status) {
      GroupStatus.forming => Icons.hourglass_top,
      GroupStatus.active => Icons.play_circle_outline,
      GroupStatus.archived => Icons.archive_outlined,
    };
    final statusLabel = switch (group.status) {
      GroupStatus.forming => ArabicStrings.formingLabel,
      GroupStatus.active => ArabicStrings.activeLabel,
      GroupStatus.archived => ArabicStrings.groupArchivedLabel,
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(group.name, style: Theme.of(context).textTheme.titleMedium),
          if ((group.shortDescription ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              group.shortDescription!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _InfoChip(
                icon: Icons.people_outline,
                label:
                    '${ArabicNumerals.format(group.activeMemberCount)} / ${ArabicNumerals.format(30)} ${ArabicStrings.activeMemberCountLabel}',
              ),
              _GroupStatusBadge(
                icon: icon,
                label: statusLabel,
                status: group.status,
              ),
              _InfoChip(
                icon: Icons.schedule,
                label: '${ArabicStrings.groupTimezoneLabel}: ${group.timezone}',
              ),
            ],
          ),
          if (isPending || isJoined) ...[
            const SizedBox(height: AppSpacing.sm),
            JoinStatusBadge(pending: isPending),
          ],
          if (onJoin != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: isPending || isJoined
                  ? (isPending
                        ? ArabicStrings.pendingApproval
                        : ArabicStrings.joinGroupAction)
                  : ArabicStrings.requestToJoin,
              icon: Icon(
                isPending || isJoined
                    ? Icons.check_circle
                    : Icons.group_add_outlined,
              ),
              variant: AppButtonVariant.tonal,
              expanded: true,
              loading: joinState == GroupJoinState.joining,
              onPressed:
                  isPending || isJoined || joinState == GroupJoinState.joining
                  ? null
                  : onJoin,
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupStatusBadge extends StatelessWidget {
  const _GroupStatusBadge({
    required this.icon,
    required this.label,
    required this.status,
  });

  final IconData icon;
  final String label;
  final GroupStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final foreground = switch (status) {
      GroupStatus.forming => colors.infoFg,
      GroupStatus.active => colors.primary,
      GroupStatus.archived => colors.inkMuted,
    };
    final background = switch (status) {
      GroupStatus.forming => colors.infoBg,
      GroupStatus.active => colors.primaryContainer,
      GroupStatus.archived => colors.surfaceMuted,
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: foreground.withValues(alpha: 0.32)),
        borderRadius: AppRadius.smBR,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: foreground),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        border: Border.all(color: colors.border),
        borderRadius: AppRadius.smBR,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: colors.inkMuted),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
