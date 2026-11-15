import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/widgets/widgets.dart';
import '../../../../core/localization/arabic_formatting.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../data/entities/entities.dart';
import '../../data/models/models.dart';
import '../../../../core/quran/quran_metadata_repository.dart';
import '../../cubit/discovery/discovery_cubit.dart';
import 'join_status_badge.dart';
import 'portion_unit_chip.dart';

class PublicGroupCard extends StatelessWidget {
  const PublicGroupCard({
    super.key,
    required this.group,
    this.onJoin,
    this.joinState,
    this.metadataRepository,
  });

  final PublicGroupProfile group;
  final VoidCallback? onJoin;
  final GroupJoinState? joinState;
  final QuranMetadataRepository? metadataRepository;

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
          Row(
            children: [
              GroupAvatar(name: group.name, size: 36),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  group.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          if ((group.shortDescription ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              group.shortDescription!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                Icons.people_outline,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Flexible(
                child: Text(
                  ArabicFormatting.membersProgress(group.activeMemberCount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              PortionUnitChip(
                unit: group.portionUnit,
                metadataRepository:
                    metadataRepository ?? QuranMetadataRepository(),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  _timezoneCity(group.timezone),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _GroupStatusBadge(
            icon: icon,
            label: statusLabel,
            status: group.status,
          ),
          if (isPending || isJoined) ...[
            const SizedBox(height: AppSpacing.sm),
            JoinStatusBadge(pending: isPending),
          ],
          if (onJoin != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed:
                  !group.canJoinLimit ||
                      isPending ||
                      isJoined ||
                      joinState == GroupJoinState.joining
                  ? null
                  : onJoin,
              icon: joinState == GroupJoinState.joining
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      isPending || isJoined
                          ? Icons.check_circle
                          : Icons.group_add_outlined,
                    ),
              label: Text(
                isPending
                    ? ArabicStrings.pendingApproval
                    : isJoined
                    ? ArabicStrings.joinedSuccessfully
                    : ArabicStrings.requestToJoin,
              ),
            ),
            if (!group.canJoinLimit) ...[
              const SizedBox(height: AppSpacing.xs),
              StatePanel(
                icon: Icons.group_off_outlined,
                title: ArabicStrings.joinError,
                message: ArabicStrings.membershipLimitMessage,
                actionLabel: ArabicStrings.groupSelectionTitle,
                onAction: () => Navigator.of(context).pushNamed('/groups'),
                isError: true,
              ),
            ],
          ],
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
