import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/router.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/widgets.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../data/entities/entities.dart';
import '../../cubit/group_list/group_list_cubit.dart';
import '../../../../core/quran/quran_metadata_repository.dart';
import '../widgets/portion_unit_chip.dart';

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
                icon: Icons.wifi_off,
                title: ArabicStrings.createGroupFailure,
                message: ArabicStrings.authError('network'),
                actionLabel: ArabicStrings.retry,
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
                  icon: Icons.groups,
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
                ),
                secondary(
                  ArabicStrings.searchGroupAction,
                  Icons.search,
                  '/discover',
                ),
                secondary(
                  ArabicStrings.createGroup,
                  Icons.add_circle_outline,
                  '/groups/new',
                ),
                secondary(ArabicStrings.iHaveInviteLink, Icons.link, '/join'),
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
    height: 168,
    child: LayoutBuilder(
      builder: (context, constraints) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(ArabicStrings.appName, style: AppTypography.headline),
          if (constraints.maxHeight > 80) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(ArabicStrings.groupsHeaderSubtitle, style: AppTypography.body),
          ],
        ],
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
          icon: const Icon(Icons.search),
          label: Text(ArabicStrings.searchGroupAction),
        ),
        const SizedBox(height: AppSpacing.xs),
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/join'),
          icon: const Icon(Icons.link),
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
                  icon: const Icon(Icons.add_circle_outline),
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

    return AppCard(
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
                  CircleAvatar(
                    radius: AppSpacing.lg,
                    backgroundColor: colors.primaryContainer,
                    child: Text(
                      group.name.trim().isEmpty
                          ? ArabicStrings.groupSelectionTitle.substring(0, 1)
                          : group.name.trim().characters.first,
                      style: AppTypography.title.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      group.name,
                      style: AppTypography.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.chevron_left, color: colors.inkMuted),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: ShapeDecoration(
                  color: group.status == GroupStatus.active
                      ? colors.completedBg
                      : colors.infoBg,
                  shape: const StadiumBorder(),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      group.status == GroupStatus.active
                          ? Icons.check_circle
                          : Icons.schedule,
                      size: 20,
                      color: group.status == GroupStatus.active
                          ? colors.completedFg
                          : colors.infoFg,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      group.status == GroupStatus.active
                          ? ArabicStrings.activeLabel
                          : ArabicStrings.formingLabel,
                      style: AppTypography.caption.copyWith(
                        color: group.status == GroupStatus.active
                            ? colors.completedFg
                            : colors.infoFg,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              PortionUnitChip(
                unit: group.portionUnit,
                metadataRepository: metadataRepository,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xxs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: ShapeDecoration(
                      color: colors.surfaceMuted,
                      shape: const StadiumBorder(),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          group.myRole == GroupRole.owner
                              ? Icons.verified_user_outlined
                              : group.myRole == GroupRole.supervisor
                              ? Icons.admin_panel_settings_outlined
                              : Icons.person_outline,
                          size: 18,
                          color: colors.inkMuted,
                          semanticLabel: roleMarker,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          roleMarker,
                          style: AppTypography.caption.copyWith(
                            color: colors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.groups_outlined,
                        size: 18,
                        color: colors.inkMuted,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        ArabicStrings.membersProgress(group.activeMemberCount),
                        style: AppTypography.caption.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
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
            Text(
              request.groupName,
              style: AppTypography.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Row(
              children: [
                Icon(Icons.hourglass_top, size: 16, color: colors.infoFg),
                const SizedBox(width: AppSpacing.xxs),
                Expanded(
                  child: Text(
                    ArabicStrings.pendingApproval,
                    style: AppTypography.caption.copyWith(color: colors.infoFg),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: ArabicStrings.cancel,
              variant: AppButtonVariant.secondary,
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
