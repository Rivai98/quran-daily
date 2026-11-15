import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/app_avatar.dart';
import '../../../../core/design_system/widgets/confirm_sheet.dart';
import '../../../../core/design_system/widgets/state_panel.dart';
import '../../../../core/design_system/widgets/skeleton.dart';
import '../../../../core/design_system/widgets/app_banner.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/localization/arabic_numerals.dart';
import '../../../../app/router.dart';
import '../../cubit/members/members_cubit.dart';
import '../../data/entities/entities.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({
    super.key,
    required this.groupId,
    required this.isOwner,
    required this.isSupervisor,
  });
  final String groupId;
  final bool isOwner;
  final bool isSupervisor;
  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MembersCubit>().load(widget.groupId);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(ArabicStrings.memberManagementTitle)),
    body: BlocBuilder<MembersCubit, MembersState>(
      builder: (context, state) {
        if ((state.status == MembersStatus.loading ||
                state.status == MembersStatus.initial) &&
            state.members == null) {
          return const _MembersSkeleton();
        }
        if ((state.status == MembersStatus.failure ||
                state.status == MembersStatus.offline) &&
            state.members == null) {
          return StatePanel(
            icon: state.status == MembersStatus.offline
                ? Icons.cloud_off_rounded
                : Icons.error_outline_rounded,
            title: state.status == MembersStatus.offline
                ? ArabicStrings.offlineStale
                : ArabicStrings.operationFailed,
            message: state.status == MembersStatus.offline
                ? ArabicStrings.networkFailure
                : ArabicStrings.errorMessage(state.failure?.code ?? ''),
            actionLabel: ArabicStrings.retry,
            onAction: () => context.read<MembersCubit>().load(widget.groupId),
          );
        }
        if (state.status == MembersStatus.empty || state.members == null) {
          return StatePanel(
            icon: Icons.group_rounded,
            title: ArabicStrings.noActiveMembers,
            message: ArabicStrings.noActiveMembers,
          );
        }
        return Stack(
          children: [
            ListView(
              padding: AppSpacing.screen,
              children: [
                if (state.status == MembersStatus.failure ||
                    state.status == MembersStatus.offline) ...[
                  AppBanner(
                    icon: state.status == MembersStatus.offline
                        ? Icons.cloud_off_rounded
                        : Icons.error_outline_rounded,
                    message: state.status == MembersStatus.offline
                        ? ArabicStrings.networkFailure
                        : ArabicStrings.errorMessage(state.failure?.code ?? ''),
                    variant: state.status == MembersStatus.offline
                        ? AppBannerVariant.warning
                        : AppBannerVariant.error,
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        context.read<MembersCubit>().load(widget.groupId),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text(ArabicStrings.retry),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  children: [
                    Icon(
                      Icons.people_alt_rounded,
                      size: 20,
                      color: Theme.of(context).extension<AppColors>()!.inkMuted,
                    ),
                    Text(
                      '${ArabicStrings.activeMembersLabel}: ${ArabicNumerals.format(state.members!.activeMemberCount)}',
                      style: AppTypography.title,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                for (final member in state.members!.members) ...[
                  _member(context, member),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (!widget.isOwner)
                  AppButton(
                    label: ArabicStrings.leaveGroupAction,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => ConfirmSheet.show(
                      context,
                      title: ArabicStrings.leaveGroupAction,
                      message: ArabicStrings.leaveGroupConfirm,
                      confirmLabel: ArabicStrings.leaveGroupAction,
                      onConfirm: () => context.read<MembersCubit>().leave(),
                    ),
                  ),
              ],
            ),
            if (state.status == MembersStatus.submitting ||
                state.status == MembersStatus.loading)
              const Align(
                alignment: AlignmentDirectional.topCenter,
                child: LinearProgressIndicator(),
              ),
          ],
        );
      },
    ),
  );

  Widget _member(BuildContext context, SeatMember member) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            UserAvatar(
              displayName: member.displayName,
              avatarKey: member.avatarKey,
              size: 48,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                member.displayName,
                style: AppTypography.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            InkWell(
              onTap: member.userId == null
                  ? null
                  : () => Navigator.pushNamed(
                      context,
                      AppRoutes.memberProfile,
                      arguments: {
                        'userId': member.userId,
                        'groupId': widget.groupId,
                      },
                    ),
              child: Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).extension<AppColors>()!.primaryContainer,
                  borderRadius: AppRadius.pillBR,
                ),
                child: Text(
                  member.role == GroupRole.owner
                      ? ArabicStrings.groupOwner
                      : member.role == GroupRole.supervisor
                      ? ArabicStrings.roleSupervisor
                      : ArabicStrings.memberRole,
                  style: AppTypography.caption.copyWith(
                    color: Theme.of(
                      context,
                    ).extension<AppColors>()!.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Icon(
              Icons.event_seat_rounded,
              size: 18,
              color: Theme.of(context).extension<AppColors>()!.inkMuted,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Expanded(
              child: Text(
                ArabicStrings.historySeat(
                  ArabicNumerals.format(member.seatNumber),
                ),
                style: AppTypography.body,
              ),
            ),
          ],
        ),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            if (widget.isOwner || widget.isSupervisor)
              PopupMenuButton<int>(
                tooltip: ArabicStrings.moveSeatAction,
                onSelected: (seat) => context.read<MembersCubit>().moveSeat(
                  member.membershipId,
                  seat,
                ),
                itemBuilder: (_) => List.generate(
                  30,
                  (i) => PopupMenuItem(
                    value: i + 1,
                    child: Text(ArabicNumerals.format(i + 1)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swap_vert_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      ArabicStrings.moveSeatAction,
                      style: AppTypography.label.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.isOwner && member.role != GroupRole.owner)
              PopupMenuButton<GroupRole>(
                tooltip: ArabicStrings.roleChangeAction,
                onSelected: (role) => context.read<MembersCubit>().setRole(
                  member.membershipId,
                  role,
                ),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: GroupRole.member,
                    child: Text(ArabicStrings.memberRole),
                  ),
                  PopupMenuItem(
                    value: GroupRole.supervisor,
                    child: Text(ArabicStrings.roleSupervisor),
                  ),
                ],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      ArabicStrings.roleChangeAction,
                      style: AppTypography.label.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.isOwner && member.role != GroupRole.owner)
              TextButton.icon(
                onPressed: () => ConfirmSheet.show(
                  context,
                  title: ArabicStrings.removeMemberAction,
                  message: ArabicStrings.removeMemberConfirm,
                  confirmLabel: ArabicStrings.removeMemberAction,
                  onConfirm: () =>
                      context.read<MembersCubit>().remove(member.membershipId),
                ),
                icon: const Icon(Icons.person_remove_rounded),
                label: Text(ArabicStrings.removeMemberAction),
              ),
            if (widget.isOwner && member.role != GroupRole.owner)
              TextButton.icon(
                onPressed: () => ConfirmSheet.show(
                  context,
                  title: ArabicStrings.transferOwnershipAction,
                  message: ArabicStrings.transferOwnershipConfirm,
                  confirmLabel: ArabicStrings.transferOwnershipAction,
                  onConfirm: () => context.read<MembersCubit>().transfer(
                    member.membershipId,
                  ),
                ),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: Text(ArabicStrings.transferOwnershipAction),
              ),
          ],
        ),
      ],
    ),
  );
}

class _MembersSkeleton extends StatelessWidget {
  const _MembersSkeleton();

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: AppSpacing.screen,
    itemCount: 5,
    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
    itemBuilder: (_, _) => const SkeletonBox(height: 112),
  );
}
