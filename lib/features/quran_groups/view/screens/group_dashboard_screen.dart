import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/router.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/app_avatar.dart';
import '../../../../core/design_system/widgets/progress_header.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/app_section_header.dart';
import '../../../../core/design_system/widgets/app_snack_bar.dart';
import '../../../../core/design_system/widgets/state_panel.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/quran/quran_metadata_repository.dart';
import '../../cubit/dashboard/dashboard_cubit.dart';
import '../../data/entities/entities.dart';
import '../widgets/available_juz_list.dart';
import '../widgets/forming_group_view.dart';
import '../widgets/juz_grid.dart';
import '../widgets/my_juz_card.dart';
import '../widgets/offline_stale_banner.dart';
import '../widgets/override_assignment_sheet.dart';
import '../widgets/portion_detail_sheet.dart';
import '../widgets/validation_banner.dart';
import '../widgets/portion_unit_chip.dart';

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
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xxs,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GroupAvatar(
                            name: snapshot.groupName,
                            size: 32,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              snapshot.groupName,
                              overflow: TextOverflow.ellipsis,
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
                icon: const Icon(Icons.menu_book),
              ),
              if (snapshot != null) ..._groupActions(context, snapshot),
              IconButton(
                tooltip: ArabicStrings.settingsTitle,
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.settings),
                icon: const Icon(Icons.settings),
              ),
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
      return Center(
        child: Semantics(
          label: ArabicStrings.loading,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (snapshot == null) {
      return StatePanel(
        icon: Icons.cloud_off,
        title: ArabicStrings.dashboardLoadError,
        message: ArabicStrings.networkFailure,
        actionLabel: ArabicStrings.retry,
        onAction: context.read<DashboardCubit>().refresh,
        isError: true,
      );
    }

    if (snapshot.status == GroupStatus.forming) {
      return _forming(context, state);
    }

    final today = snapshot.today;
    if (today == null) {
      return StatePanel(
        icon: Icons.menu_book,
        title: ArabicStrings.noAssignmentToday,
        message: ArabicStrings.noAssignmentToday,
        actionLabel: ArabicStrings.refresh,
        onAction: context.read<DashboardCubit>().refresh,
      );
    }

    final myAssignment = snapshot.myAssignments.isNotEmpty;
    final completed = snapshot.assignments
        .where(
          (assignment) =>
              assignment.status == AssignmentStatusEnum.completed ||
              assignment.status == AssignmentStatusEnum.late,
        )
        .length;

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
                  const OfflineStaleBanner(),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (snapshot.pendingPortionUnit != null) ...[
                  ValidationBanner(
                    icon: Icons.schedule,
                    message: ArabicStrings.pendingPortionChange(
                      snapshot.pendingPortionUnit!,
                    ),
                    color: Theme.of(context).extension<AppColors>()!.pendingFg,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: PortionUnitChip(
                    unit: snapshot.portionUnit,
                    metadataRepository: metadataRepository,
                  ),
                ),
                if (today.fullKhatma) ...[
                  Builder(
                    builder: (context) {
                      final colors = Theme.of(context).extension<AppColors>()!;
                      return ValidationBanner(
                        icon: Icons.verified,
                        message: ArabicStrings.fullKhatmaBanner,
                        color: colors.completedFg,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (today.state == DayState.grace) ...[
                  Builder(
                    builder: (context) {
                      final colors = Theme.of(context).extension<AppColors>()!;
                      return ValidationBanner(
                        icon: Icons.hourglass_bottom,
                        message: ArabicStrings.gracePeriodNotice,
                        color: colors.pendingFg,
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
                  StatePanel(
                    icon: Icons.menu_book,
                    title: ArabicStrings.noAssignmentToday,
                    message: ArabicStrings.noAssignmentToday,
                  ),
                const SizedBox(height: AppSpacing.lg),
                if (snapshot.cycle != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: AppSpacing.sm,
                    ),
                    child: Text(
                      ArabicStrings.cycleProgress(
                        snapshot.cycle!.day,
                        snapshot.cycle!.length,
                        snapshot.cycle!.completed,
                        snapshot.cycle!.total,
                      ),
                      style: AppTypography.title,
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
                        completed: snapshot.cycle?.completed ?? completed,
                        total: snapshot.cycle?.total ?? 30,
                        variant: ProgressVariant.bar,
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
                        onAssignmentTap: (assignment) {
                          if (snapshot.myRole == GroupRole.owner &&
                              assignment.status == AssignmentStatusEnum.pending) {
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
      'isOwner': isOwner,
      'isSupervisor': snapshot.myRole == GroupRole.supervisor,
      'inviteCode': snapshot.seats?.inviteCode,
      'portionUnit': snapshot.portionUnit,
      'isActive': snapshot.status == GroupStatus.active,
    };
    return [
      IconButton(
        tooltip: ArabicStrings.openHistoryAction,
        onPressed: () => Navigator.pushNamed(
          context,
          AppRoutes.history,
          arguments: snapshot.groupId,
        ),
        icon: const Icon(Icons.history),
      ),
      PopupMenuButton<String>(
          tooltip: ArabicStrings.groupMenuTooltip,
          icon: const Icon(Icons.manage_accounts),
          onSelected: (route) async {
            if (route == 'set-main') {
              await context.read<DashboardCubit>().pinAsMain();
              return;
            }
            await Navigator.pushNamed(context, route, arguments: args);
            if (context.mounted) {
              await context.read<DashboardCubit>().refresh();
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'set-main', child: Text(ArabicStrings.setMainGroupAction)),
            if (canManage) ...[
            const PopupMenuItem(
              value: AppRoutes.members,
              child: Text(ArabicStrings.manageMembersAction),
            ),
            const PopupMenuItem(
              value: AppRoutes.joinRequests,
              child: Text(ArabicStrings.reviewJoinRequestsAction),
            ),
            if (isOwner)
              const PopupMenuItem(
                value: AppRoutes.groupSettings,
                child: Text(ArabicStrings.groupSettingsAction),
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
