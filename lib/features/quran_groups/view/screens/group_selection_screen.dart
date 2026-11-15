import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/router.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/widgets.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/localization/arabic_numerals.dart';
import '../../data/entities/entities.dart';
import '../../cubit/group_list/group_list_cubit.dart';

/// S1 group selection (ui-contract): my groups list + pending requests +
/// entry points when empty.
class GroupSelectionScreen extends StatefulWidget {
  const GroupSelectionScreen({super.key});

  @override
  State<GroupSelectionScreen> createState() => _GroupSelectionScreenState();
}

class _GroupSelectionScreenState extends State<GroupSelectionScreen> {
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
      appBar: AppBar(title: const Text(ArabicStrings.groupSelectionTitle)),
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
              return _GroupList(state: state);
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
    return ListView(
      padding: AppSpacing.screen,
      children: [
        for (var i = 0; i < 4; i++) ...[
          const SkeletonBox(height: 72),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _EmptyEntryPoints extends StatelessWidget {
  const _EmptyEntryPoints();

  @override
  Widget build(BuildContext context) {
    return StatePanel(
      icon: Icons.groups,
      title: ArabicStrings.noApprovedGroups,
      message: ArabicStrings.groupsNeedMembersEntry,
      actionLabel: ArabicStrings.joinAnyGroupAction,
      onAction: () => Navigator.pushNamed(context, '/discover'),
      actionVariant: AppButtonVariant.primary,
    );
  }
}

class _GroupList extends StatelessWidget {
  const _GroupList({required this.state});

  final GroupListState state;

  @override
  Widget build(BuildContext context) {
    final overview = state.overview!;
    return ListView(
      padding: AppSpacing.screen,
      children: [
        if (state.isStale) ...[
          const OfflineBanner(message: ArabicStrings.offlineStale),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final group in overview.groups) ...[
          _MyGroupRow(group: group),
          const SizedBox(height: AppSpacing.sm),
        ],
        for (final request in overview.pendingRequests) ...[
          _PendingRow(request: request),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: ArabicStrings.createGroup,
          variant: AppButtonVariant.tonal,
          expanded: true,
          onPressed: () => Navigator.pushNamed(context, '/groups/new'),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}

class _MyGroupRow extends StatelessWidget {
  const _MyGroupRow({required this.group});

  final MyGroupSummary group;

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
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        onTap: () => Navigator.pushNamed(context, AppRoutes.dashboard,
            arguments: group.groupId),
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(group.name,
                        style: AppTypography.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 2),
                    decoration: ShapeDecoration(
                      color: group.status == GroupStatus.active
                          ? colors.completedBg
                          : colors.pendingBg,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      group.status == GroupStatus.active
                          ? ArabicStrings.activeLabel
                          : ArabicStrings.formingLabel,
                      style: AppTypography.caption.copyWith(
                        color: group.status == GroupStatus.active
                            ? colors.completedFg
                            : colors.pendingFg,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Row(
                children: [
                  Text(roleMarker,
                      style: AppTypography.caption
                          .copyWith(color: colors.inkMuted)),
                  Text(
                    ' · ${ArabicNumerals.ratio(group.activeMemberCount, 30)}',
                    style: AppTypography.caption
                        .copyWith(color: colors.inkMuted),
                  ),
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
            Text(request.groupName,
                style: AppTypography.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: AppSpacing.xxs),
            Row(
              children: [
                Icon(Icons.hourglass_top, size: 16, color: colors.pendingFg),
                const SizedBox(width: AppSpacing.xxs),
                Expanded(
                  child: Text(
                    ArabicStrings.pendingApproval,
                    style:
                        AppTypography.caption.copyWith(color: colors.pendingFg),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: ArabicStrings.cancel,
              variant: AppButtonVariant.secondary,
              onPressed: () => context
                  .read<GroupListCubit>()
                  .cancelJoinRequest(request.joinRequestId),
            ),
          ],
        ),
      ),
    );
  }
}
