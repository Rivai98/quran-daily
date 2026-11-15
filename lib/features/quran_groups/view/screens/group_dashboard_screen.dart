import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/router.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/progress_header.dart';
import '../../../../core/design_system/widgets/app_snack_bar.dart';
import '../../../../core/design_system/widgets/state_panel.dart';
import '../../../../core/localization/arabic_numerals.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/quran/quran_metadata_repository.dart';
import '../../cubit/dashboard/dashboard_cubit.dart';
import '../../data/entities/entities.dart';
import '../widgets/available_juz_list.dart';
import '../widgets/juz_grid.dart';
import '../widgets/my_juz_card.dart';
import '../widgets/offline_stale_banner.dart';
import '../widgets/validation_banner.dart';

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
            title: Text(snapshot?.groupName ?? ArabicStrings.dashboardTitle),
            actions: [
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
      return _forming(snapshot);
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (snapshot.isStale) ...[
              const OfflineStaleBanner(),
              const SizedBox(height: AppSpacing.sm),
            ],
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
            ProgressHeader(
              completed: completed,
              total: 30,
              variant: ProgressVariant.bar,
              caption: ArabicStrings.assignmentGroupDate,
            ),
            const SizedBox(height: AppSpacing.lg),
            JuzGrid(assignments: snapshot.assignments),
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
              onVolunteer: (assignment) => context
                  .read<DashboardCubit>()
                  .volunteer(assignment.assignmentId),
              volunteeringAssignmentId: state.volunteeringAssignmentId,
            ),
          ],
        ),
      ),
    );
  }

  Widget _forming(DashboardSnapshot snapshot) {
    final members = snapshot.seats?.members ?? const <SeatMember>[];
    return ListView(
      padding: AppSpacing.screen,
      children: [
        Text(ArabicStrings.formingDashboard, style: AppTypography.headline),
        const SizedBox(height: AppSpacing.md),
        ProgressHeader(
          completed: snapshot.activeMemberCount,
          total: 30,
          variant: ProgressVariant.bar,
          caption: ArabicStrings.activeMembersCount,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(ArabicStrings.memberSeats, style: AppTypography.title),
        const SizedBox(height: AppSpacing.sm),
        for (final member in members)
          ListTile(
            leading: CircleAvatar(
              child: Text(ArabicNumerals.format(member.seatNumber)),
            ),
            title: Text(member.displayName, style: AppTypography.body),
          ),
      ],
    );
  }
}
