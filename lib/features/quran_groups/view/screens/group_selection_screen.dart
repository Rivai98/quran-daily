import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/router.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/widgets.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/localization/arabic_formatting.dart';
import '../../data/entities/entities.dart';
import '../../cubit/group_list/group_list_cubit.dart';
import '../../../../core/quran/quran_metadata_repository.dart';

/// S1 group selection (ui-contract): my groups list + pending requests +
/// entry points when empty.
class GroupSelectionScreen extends StatefulWidget {
  const GroupSelectionScreen({super.key, this.metadataRepository});
  final QuranMetadataRepository? metadataRepository;

  @override
  State<GroupSelectionScreen> createState() => _GroupSelectionScreenState();
}

class _GroupSelectionScreenState extends State<GroupSelectionScreen> {
  final _fallbackMetadata = QuranMetadataRepository();
  QuranMetadataRepository get _metadataRepository =>
      widget.metadataRepository ?? _fallbackMetadata;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<GroupListCubit>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      body: BlocConsumer<GroupListCubit, GroupListState>(
        listenWhen: (previous, current) =>
            previous.status == current.status &&
            previous.failure != current.failure &&
            current.failure != null,
        listener: (context, state) => AppSnackBar.showError(
          context,
          ArabicStrings.authError(state.failure!.code),
        ),
        builder: (context, state) {
          switch (state.status) {
            case GroupListStatus.initial:
            case GroupListStatus.loading:
              return const _SkeletonList();
            case GroupListStatus.empty:
              return const _EmptyEntryPoints();
            case GroupListStatus.failure:
              return StatePanel(
                icon: Icons.wifi_off_rounded,
                title: ArabicStrings.createGroupFailure,
                message: ArabicStrings.authError('network'),
                actionLabel: ArabicStrings.retry,
                actionIcon: const Icon(Icons.refresh_rounded),
                actionVariant: AppButtonVariant.secondary,
                onAction: () => context.read<GroupListCubit>().refresh(),
                isError: true,
              );
            case GroupListStatus.success:
            case GroupListStatus.offline:
              return _GroupList(
                state: state,
                metadataRepository: _metadataRepository,
              );
          }
        },
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return AppPageContent(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _GroupHeader(),
          Padding(
            padding: AppSpacing.screenContent,
            child: Column(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  const SkeletonBox(height: 72),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyEntryPoints extends StatelessWidget {
  const _EmptyEntryPoints();

  @override
  Widget build(BuildContext context) {
    return AppPageContent(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _GroupHeader(),
          Padding(
            padding: AppSpacing.screenContent,
            child: Column(
              children: [
                StatePanel.empty(
                  icon: Icons.groups_rounded,
                  title: ArabicStrings.noApprovedGroups,
                  message: ArabicStrings.groupSelectionEmptyMessage,
                  actionLabel: ArabicStrings.searchGroupAction,
                  onAction: () async {
                    await Navigator.pushNamed(context, '/discover');
                    if (context.mounted) {
                      await context.read<GroupListCubit>().refresh();
                    }
                  },
                  actionVariant: AppButtonVariant.primary,
                  actionIcon: const Icon(Icons.search_rounded),
                  secondaryActionLabel: ArabicStrings.createGroup,
                  secondaryActionIcon: const Icon(
                    Icons.add_circle_outline_rounded,
                  ),
                  onSecondaryAction: () async {
                    await Navigator.pushNamed(context, '/groups/new');
                    if (context.mounted) {
                      await context.read<GroupListCubit>().refresh();
                    }
                  },
                  illustration: const HalaqaLogo(size: 80),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/join'),
                  icon: const Icon(Icons.link_rounded),
                  label: Text(ArabicStrings.iHaveInviteLink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: AppSpacing.screenH,
    child: AppSectionHeader(title: ArabicStrings.groupSelectionTitle),
  );
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard();
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(ArabicStrings.groupShortcutsTitle, style: AppTypography.title),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/discover'),
          icon: const Icon(Icons.search_rounded),
          label: Text(ArabicStrings.searchGroupAction),
        ),
        const SizedBox(height: AppSpacing.xs),
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/join'),
          icon: const Icon(Icons.link_rounded),
          label: Text(ArabicStrings.iHaveInviteLink),
        ),
      ],
    ),
  );
}

class _GroupList extends StatelessWidget {
  const _GroupList({required this.state, required this.metadataRepository});

  final GroupListState state;
  final QuranMetadataRepository metadataRepository;

  @override
  Widget build(BuildContext context) {
    final overview = state.overview!;
    return AppPageContent(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _GroupHeader(),
          Padding(
            padding: AppSpacing.screenContent,
            child: Column(
              children: [
                if (state.isStale) ...[
                  const OfflineBanner(message: ArabicStrings.offlineStale),
                  const SizedBox(height: AppSpacing.md),
                ],
                for (final group in overview.groups) ...[
                  _MyGroupRow(
                    group: group,
                    metadataRepository: metadataRepository,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                for (final request in overview.pendingRequests) ...[
                  _PendingRow(request: request),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const SizedBox(height: AppSpacing.md),
                const _ShortcutCard(),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: ArabicStrings.createGroup,
                  variant: AppButtonVariant.primary,
                  expanded: true,
                  onPressed: () async {
                    await Navigator.pushNamed(context, '/groups/new');
                    if (context.mounted) {
                      await context.read<GroupListCubit>().refresh();
                    }
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyGroupRow extends StatelessWidget {
  const _MyGroupRow({required this.group, required this.metadataRepository});

  final MyGroupSummary group;
  final QuranMetadataRepository metadataRepository;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final roleMarker = switch (group.myRole) {
      GroupRole.owner => ArabicStrings.roleOwner,
      GroupRole.supervisor => ArabicStrings.roleSupervisor,
      GroupRole.member => ArabicStrings.roleMember,
    };
    final statusIcon = group.status == GroupStatus.active
        ? Icons.play_circle_outline_rounded
        : Icons.hourglass_top_rounded;
    final statusLabel = group.status == GroupStatus.active
        ? ArabicStrings.activeLabel
        : ArabicStrings.formingLabel;
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () async {
        await Navigator.pushNamed(
          context,
          AppRoutes.dashboard,
          arguments: group.groupId,
        );
        if (context.mounted) {
          await context.read<GroupListCubit>().refresh();
        }
      },
      child: Padding(
        padding: AppSpacing.card,
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
                          style: AppTypography.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      AppBadge(
                        icon: statusIcon,
                        label: statusLabel,
                        variant: group.status == GroupStatus.active
                            ? AppBadgeVariant.primary
                            : AppBadgeVariant.info,
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
                _MetaItem(
                  icon: Icons.menu_book_rounded,
                  label: ArabicStrings.dailyUnitChip(group.portionUnit),
                  color: colors.inkMuted,
                ),
                _MetaItem(
                  icon: Icons.people_alt_rounded,
                  label: roleMarker,
                  color: colors.inkMuted,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetaItem(
                  icon: Icons.people_alt_rounded,
                  label: ArabicStrings.groupSeatsProgressLabel,
                  color: colors.inkMuted,
                ),
                const SizedBox(height: AppSpacing.xxs),
                ClipRRect(
                  borderRadius: AppRadius.pillBR,
                  child: LinearProgressIndicator(
                    value: (group.activeMemberCount / 30).clamp(0.0, 1.0),
                    minHeight: AppSpacing.xs,
                    backgroundColor: colors.surfaceMuted,
                    color: group.status == GroupStatus.active
                        ? colors.completedFg
                        : colors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  ArabicFormatting.membersProgress(group.activeMemberCount),
                  style: AppTypography.caption.copyWith(color: colors.inkMuted),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact pending join-request card, styled like the group cards above:
/// emblem, name (2 lines max), status badge with a quiet cancel action, and
/// one muted line explaining what happens next.
class _PendingRow extends StatelessWidget {
  const _PendingRow({required this.request});

  final PendingJoinRequest request;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.card,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GroupAvatar(name: request.groupName, size: AppSpacing.xxl),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.groupName,
                    style: AppTypography.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      const AppBadge(
                        icon: Icons.schedule_rounded,
                        label: ArabicStrings.pendingShortLabel,
                        variant: AppBadgeVariant.warning,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context
                            .read<GroupListCubit>()
                            .cancelJoinRequest(request.joinRequestId),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.inkMuted,
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                        ),
                        child: const Text(
                          ArabicStrings.cancelJoinRequestAction,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    ArabicStrings.pendingRequestHint,
                    style: AppTypography.caption.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: AppSpacing.md, color: color),
      const SizedBox(width: AppSpacing.xxs),
      Text(label, style: AppTypography.caption.copyWith(color: color)),
    ],
  );
}
