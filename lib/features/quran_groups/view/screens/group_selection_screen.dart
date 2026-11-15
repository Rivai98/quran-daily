import 'package:flutter/material.dart';
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
      body: BlocBuilder<GroupListCubit, GroupListState>(
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
    Widget secondary(String label, IconData icon, String route) => Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
      child: AppButton(
        label: label,
        variant: AppButtonVariant.secondary,
        expanded: true,
        icon: Icon(icon),
        onPressed: () async {
          await Navigator.pushNamed(context, route);
          if (context.mounted) {
            await context.read<GroupListCubit>().refresh();
          }
        },
      ),
    );

    // S1 empty state (ui-contract): join-any is the one primary action.
    return AppPageContent(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _GroupHeader(),
          Padding(
            padding: AppSpacing.screenContent,
            child: Column(
              children: [
                StatePanel(
                  icon: Icons.groups_rounded,
                  title: ArabicStrings.noApprovedGroups,
                  message: ArabicStrings.groupsNeedMembersEntry,
                  actionLabel: ArabicStrings.joinAnyGroupAction,
                  onAction: () async {
                    await Navigator.pushNamed(context, '/join-any');
                    if (context.mounted) {
                      await context.read<GroupListCubit>().refresh();
                    }
                  },
                  actionVariant: AppButtonVariant.primary,
                  actionIcon: const Icon(Icons.volunteer_activism_rounded),
                  illustration: const HalaqaLogo(size: 80),
                ),
                secondary(
                  ArabicStrings.searchGroupAction,
                  Icons.search_rounded,
                  '/discover',
                ),
                secondary(
                  ArabicStrings.createGroup,
                  Icons.add_circle_outline_rounded,
                  '/groups/new',
                ),
                secondary(
                  ArabicStrings.iHaveInviteLink,
                  Icons.link_rounded,
                  '/join',
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
  Widget build(BuildContext context) => IslamicOrnamentBand(
    height: AppSpacing.xxl + AppSpacing.md,
    contentPadding: AppSpacing.md,
    refined: true,
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        ArabicStrings.groupSelectionTitle,
        style: AppTypography.headline,
      ),
    ),
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
    final statusColor = group.status == GroupStatus.active
        ? colors.primary
        : colors.infoFg;
    final statusBackground = group.status == GroupStatus.active
        ? colors.primaryContainer
        : colors.infoBg;
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: AppRadius.lgBR,
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
                        _GroupStatusBadge(
                          icon: statusIcon,
                          label: statusLabel,
                          foreground: statusColor,
                          background: statusBackground,
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
                    style: AppTypography.caption.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({required this.request});

  final PendingJoinRequest request;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return AppCard(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.groupName,
                    style: AppTypography.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                _GroupStatusBadge(
                  icon: Icons.schedule_rounded,
                  label: ArabicStrings.pendingShortLabel,
                  foreground: colors.infoFg,
                  background: colors.infoBg,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: ArabicStrings.cancel,
              variant: AppButtonVariant.secondary,
              icon: const Icon(Icons.close_rounded),
              onPressed: () => context.read<GroupListCubit>().cancelJoinRequest(
                request.joinRequestId,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupStatusBadge extends StatelessWidget {
  const _GroupStatusBadge({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: AppSpacing.xl),
    padding: const EdgeInsetsDirectional.symmetric(
      horizontal: AppSpacing.xs,
      vertical: AppSpacing.xxs,
    ),
    decoration: BoxDecoration(
      color: background,
      borderRadius: AppRadius.pillBR,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSpacing.sm, color: foreground),
        const SizedBox(width: AppSpacing.xxs),
        Text(label, style: AppTypography.caption.copyWith(color: foreground)),
      ],
    ),
  );
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
