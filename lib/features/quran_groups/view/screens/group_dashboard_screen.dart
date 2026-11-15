import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/router.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/assignment_status.dart';
import '../../../../core/design_system/widgets/app_avatar.dart';
import '../../../../core/design_system/widgets/progress_header.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/app_section_header.dart';
import '../../../../core/design_system/widgets/status_chip.dart';
import '../../../../core/design_system/widgets/app_snack_bar.dart';
import '../../../../core/design_system/widgets/app_banner.dart';
import '../../../../core/design_system/widgets/offline_banner.dart';
import '../../../../core/design_system/widgets/state_panel.dart';
import '../../../../core/design_system/widgets/skeleton.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/quran/quran_metadata_repository.dart';
import '../../cubit/dashboard/dashboard_cubit.dart';
import '../../data/entities/entities.dart';
import '../widgets/available_juz_list.dart';
import '../widgets/forming_group_view.dart';
import '../widgets/juz_grid.dart';
import '../widgets/my_juz_card.dart';
import '../widgets/override_assignment_sheet.dart';
import '../widgets/portion_detail_sheet.dart';

class GroupDashboardScreen extends StatelessWidget {
  const GroupDashboardScreen({super.key, required this.metadataRepository});

  final QuranMetadataRepository metadataRepository;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DashboardCubit, DashboardState>(
      listenWhen: (previous, current) =>
          previous.volunteerFeedbackCode != current.volunteerFeedbackCode &&
          current.volunteerFeedbackCode != null,
      listener: (context, state) => AppSnackBar.show(
        context,
        ArabicStrings.volunteerFailureMessage(state.volunteerFeedbackCode!),
      ),
      builder: (context, state) {
        final snapshot = state.snapshot;
        return Scaffold(
          appBar: AppBar(
            title: snapshot != null
                ? InkWell(
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.groupInfo,
                      arguments: snapshot.groupId,
                    ),
                    borderRadius: AppRadius.smBR,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GroupAvatar(name: snapshot.groupName, size: 32),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  snapshot.groupName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.people_alt_rounded,
                                      size: 16,
                                      color: Theme.of(
                                        context,
                                      ).extension<AppColors>()!.inkMuted,
                                    ),
                                    const SizedBox(width: AppSpacing.xxs),
                                    Flexible(
                                      child: Text(
                                        ArabicStrings.groupDashboardMeta(
                                          snapshot.activeMemberCount,
                                          snapshot.portionUnit,
                                        ),
                                        style: AppTypography.caption.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).extension<AppColors>()!.inkMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const Text(ArabicStrings.dashboardTitle),
            actions: [
              IconButton(
                tooltip: ArabicStrings.mushafTitle,
                onPressed: () => Navigator.pushNamed(context, AppRoutes.mushaf),
                icon: const Icon(Icons.menu_book_rounded),
              ),
              if (snapshot != null) ..._groupActions(context, snapshot),
            ],
          ),
          body: _body(context, state),
        );
      },
    );
  }

  Widget _body(BuildContext context, DashboardState state) {
    final snapshot = state.snapshot;
    if (state.status == DashboardStatus.loading && snapshot == null) {
      return const _DashboardSkeleton();
    }
    if (snapshot == null) {
      return StatePanel.error(
        icon: Icons.cloud_off_rounded,
        title: ArabicStrings.dashboardLoadError,
        message: ArabicStrings.networkFailure,
        actionLabel: ArabicStrings.retry,
        onAction: context.read<DashboardCubit>().refresh,
      );
    }

    if (snapshot.status == GroupStatus.forming) {
      return _forming(context, state);
    }

    final today = snapshot.today;
    if (today == null) {
      return StatePanel.empty(
        icon: Icons.menu_book_rounded,
        title: ArabicStrings.noAssignmentToday,
        message: ArabicStrings.noPublishedCycle,
        actionLabel: ArabicStrings.refresh,
        onAction: context.read<DashboardCubit>().refresh,
      );
    }

    final completedMembers = today.completedCount + today.lateCount;
    final myAssignment = snapshot.myAssignments.isNotEmpty;
    return RefreshIndicator(
      onRefresh: context.read<DashboardCubit>().refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screen,
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (snapshot.isStale) ...[
                  const OfflineBanner(
                    message: ArabicStrings.offlineStale,
                    icon: Icons.wifi_off_rounded,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (snapshot.pendingPortionUnit != null) ...[
                  AppBanner.warning(
                    icon: Icons.schedule_rounded,
                    message: ArabicStrings.pendingPortionChange(
                      snapshot.pendingPortionUnit!,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (today.fullKhatma) ...[
                  Builder(
                    builder: (context) {
                      return AppBanner.success(
                        icon: Icons.verified_rounded,
                        message: ArabicStrings.fullKhatmaBanner,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (today.state == DayState.grace) ...[
                  Builder(
                    builder: (context) {
                      return AppBanner.warning(
                        icon: Icons.hourglass_bottom_rounded,
                        message: ArabicStrings.gracePeriodNotice,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (myAssignment)
                  MyJuzCard(
                    snapshot: snapshot,
                    metadataRepository: metadataRepository,
                    onOpen: () => Navigator.pushNamed(
                      context,
                      AppRoutes.assignment,
                      arguments: snapshot,
                    ),
                  )
                else
                  StatePanel.empty(
                    icon: Icons.menu_book_rounded,
                    title: ArabicStrings.noAssignmentToday,
                    message: ArabicStrings.noPublishedCycle,
                    actionLabel: ArabicStrings.refresh,
                    onAction: context.read<DashboardCubit>().refresh,
                  ),
                const SizedBox(height: AppSpacing.lg),
                if (snapshot.cycle != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 20,
                          color: Theme.of(
                            context,
                          ).extension<AppColors>()!.inkMuted,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          ArabicStrings.cycleDayProgress(
                            snapshot.cycle!.day,
                            snapshot.cycle!.length,
                          ),
                          style: AppTypography.title,
                        ),
                      ],
                    ),
                  ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AppSectionHeader(
                        title: ArabicStrings.assignmentGroupDate,
                      ),
                      ProgressHeader(
                        completed: completedMembers.clamp(
                          0,
                          snapshot.activeMemberCount,
                        ),
                        total: snapshot.activeMemberCount,
                        variant: ProgressVariant.bar,
                        caption: ArabicStrings.groupProgressLabel(
                          completedMembers.clamp(0, snapshot.activeMemberCount),
                          snapshot.activeMemberCount,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AppSectionHeader(title: ArabicStrings.juzGridTitle),
                      JuzGrid(
                        assignments: snapshot.assignments,
                        unit: snapshot.portionUnit,
                        showMissed:
                            snapshot.myRole == GroupRole.owner ||
                            snapshot.myRole == GroupRole.supervisor,
                        onAssignmentTap: (assignment) {
                          if (snapshot.myRole == GroupRole.owner &&
                              assignment.status ==
                                  AssignmentStatusEnum.pending) {
                            _openOverride(context, assignment);
                          } else {
                            PortionDetailSheet.show(
                              context,
                              assignment: assignment,
                              unit: snapshot.portionUnit,
                              groupId: snapshot.groupId,
                              metadataRepository: metadataRepository,
                              onVolunteer: () => context
                                  .read<DashboardCubit>()
                                  .volunteer(assignment.assignmentId),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          const StatusChip(status: AssignmentStatus.completed),
                          const StatusChip(status: AssignmentStatus.pending),
                          if (snapshot.myRole == GroupRole.owner ||
                              snapshot.myRole == GroupRole.supervisor)
                            const StatusChip(status: AssignmentStatus.missed),
                          const StatusChip(status: AssignmentStatus.available),
                        ],
                      ),
                    ],
                  ),
                ),
                if (snapshot.assignments.any(
                  (assignment) =>
                      assignment.juz == 30 &&
                      assignment.status == AssignmentStatusEnum.completed,
                )) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(ArabicStrings.khatmaDuaNote, style: AppTypography.body),
                ],
                const SizedBox(height: AppSpacing.lg),
                AvailableJuzList(
                  assignments: snapshot.assignments,
                  metadataRepository: metadataRepository,
                  unit: snapshot.portionUnit,
                  onVolunteer: (assignment) => context
                      .read<DashboardCubit>()
                      .volunteer(assignment.assignmentId),
                  volunteeringAssignmentId: state.volunteeringAssignmentId,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openOverride(
    BuildContext context,
    Assignment assignment,
  ) async {
    final cubit = context.read<DashboardCubit>();
    final seats = await cubit.getActiveMembers();
    if (!context.mounted || seats == null || seats.members.isEmpty) return;
    await OverrideAssignmentSheet.show(
      context,
      members: seats.members,
      onSubmit: (membershipId) =>
          cubit.overrideAssignment(assignment.assignmentId, membershipId),
    );
  }

  List<Widget> _groupActions(BuildContext context, DashboardSnapshot snapshot) {
    final isOwner = snapshot.myRole == GroupRole.owner;
    final canManage = isOwner || snapshot.myRole == GroupRole.supervisor;
    final args = <String, Object?>{
      'groupId': snapshot.groupId,
      'groupName': snapshot.groupName,
      'isOwner': isOwner,
      'isSupervisor': snapshot.myRole == GroupRole.supervisor,
      'inviteCode': snapshot.seats?.inviteCode,
      'portionUnit': snapshot.portionUnit,
      'isActive': snapshot.status == GroupStatus.active,
    };
    return [
      PopupMenuButton<String>(
        tooltip: ArabicStrings.groupMenuTooltip,
        icon: const Icon(Icons.manage_accounts_rounded),
        onSelected: (route) async {
          if (route == 'set-main') {
            await context.read<DashboardCubit>().pinAsMain();
            if (context.mounted) {
              AppSnackBar.show(context, ArabicStrings.mainGroupSet);
            }
            return;
          }
          if (route == AppRoutes.history) {
            await Navigator.pushNamed(
              context,
              route,
              arguments: snapshot.groupId,
            );
            return;
          }
          await Navigator.pushNamed(context, route, arguments: args);
          if (context.mounted) {
            await context.read<DashboardCubit>().refresh();
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'set-main',
            child: _GroupMenuRow(
              icon: Icons.push_pin_rounded,
              label: ArabicStrings.setMainGroupAction,
            ),
          ),
          const PopupMenuItem(
            value: AppRoutes.history,
            child: _GroupMenuRow(
              icon: Icons.history_rounded,
              label: ArabicStrings.openHistoryAction,
            ),
          ),
          if (canManage) ...[
            const PopupMenuItem(
              value: AppRoutes.members,
              child: _GroupMenuRow(
                icon: Icons.people_alt_rounded,
                label: ArabicStrings.manageMembersAction,
              ),
            ),
            const PopupMenuItem(
              value: AppRoutes.joinRequests,
              child: _GroupMenuRow(
                icon: Icons.person_add_alt_1_rounded,
                label: ArabicStrings.reviewJoinRequestsAction,
              ),
            ),
            if (isOwner)
              const PopupMenuItem(
                value: AppRoutes.groupSettings,
                child: _GroupMenuRow(
                  icon: Icons.tune_rounded,
                  label: ArabicStrings.groupSettingsAction,
                ),
              ),
          ],
        ],
      ),
    ];
  }

  Widget _forming(BuildContext context, DashboardState state) {
    final snapshot = state.snapshot!;
    final cubit = context.read<DashboardCubit>();
    return FormingGroupView(
      groupId: snapshot.groupId,
      groupName: snapshot.groupName,
      inviteCode: snapshot.seats?.inviteCode,
      activeMemberCount: snapshot.activeMemberCount,
      isOwner: snapshot.myRole == GroupRole.owner,
      seatMap: snapshot.seats,
      onStartKhatma: cubit.startKhatma,
      portionUnit: snapshot.portionUnit,
      metadataRepository: metadataRepository,
    );
  }
}

/// Overflow menu row: leading icon tinted with the item's text color.
class _GroupMenuRow extends StatelessWidget {
  const _GroupMenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = DefaultTextStyle.of(context).style.color;
    return Row(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(label)),
      ],
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: AppSpacing.screen,
    children: const [
      SkeletonBox(height: 188),
      SizedBox(height: AppSpacing.lg),
      SkeletonBox(height: 112),
      SizedBox(height: AppSpacing.lg),
      SkeletonBox(height: 284),
    ],
  );
}
