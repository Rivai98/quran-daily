import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/assignment_status.dart' as ds;
import '../../../../core/design_system/widgets/confirm_sheet.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/offline_banner.dart';
import '../../../../core/design_system/widgets/state_panel.dart';
import '../../../../core/design_system/widgets/status_chip.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/quran/quran_metadata_repository.dart';
import '../../../../core/quran/mushaf/mushaf_repository.dart';
import '../../../../core/di/service_locator.dart';
import '../../cubit/assignment/assignment_cubit.dart';
import '../../cubit/assignment/assignment_state.dart';
import '../../data/entities/entities.dart';

class PersonalAssignmentScreen extends StatefulWidget {
  const PersonalAssignmentScreen({
    super.key,
    required this.snapshot,
    required this.metadataRepository,
  });
  final DashboardSnapshot snapshot;
  final QuranMetadataRepository metadataRepository;

  @override
  State<PersonalAssignmentScreen> createState() =>
      _PersonalAssignmentScreenState();
}

class _PersonalAssignmentScreenState extends State<PersonalAssignmentScreen> {
  late final Future<void> _metadata = widget.metadataRepository.load();
  MushafRepository? get _mushaf =>
      serviceLocator.isRegistered<MushafRepository>()
      ? serviceLocator<MushafRepository>()
      : null;
  late final Future<void>? _mushafLoad = _mushaf?.load();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.assignmentDetailTitle)),
      body: BlocBuilder<AssignmentCubit, AssignmentState>(
        builder: (context, state) {
          final current = state.assignment;
          final completed =
              current.status == AssignmentStatusEnum.completed ||
              current.status == AssignmentStatusEnum.late;
          return ListView(
            padding: AppSpacing.screen,
            children: [
              if (state.dayState == DayState.grace)
                const OfflineBanner(
                  message: ArabicStrings.gracePeriodNotice,
                  icon: Icons.hourglass_bottom_rounded,
                ),
              AppCard(
                padding: AppSpacing.card,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        Text(
                          ArabicStrings.portionName(
                            widget.snapshot.portionUnit,
                            current.portionIndex,
                          ),
                          style: AppTypography.quranLabel,
                        ),
                        StatusChip(
                          status: ds.AssignmentStatus.values.byName(
                            current.status.name,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FutureBuilder<void>(
                      future: _metadata,
                      builder: (context, metadataState) {
                        if (metadataState.connectionState !=
                                ConnectionState.done ||
                            metadataState.hasError) {
                          return const SizedBox.shrink();
                        }
                        final info = widget.metadataRepository.portion(
                          widget.snapshot.portionUnit,
                          current.portionIndex,
                        );
                        final pageSource = _mushaf;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.auto_stories_rounded,
                                  size: 20,
                                  color: Theme.of(
                                    context,
                                  ).extension<AppColors>()!.inkMuted,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    ArabicStrings.portionRange(
                                      widget.metadataRepository.suraName(
                                        info.startSura,
                                      ),
                                      info.startAya,
                                      widget.metadataRepository.suraName(
                                        info.endSura,
                                      ),
                                      info.endAya,
                                    ),
                                    style: AppTypography.bodyLarge,
                                  ),
                                ),
                              ],
                            ),
                            if (pageSource != null)
                              FutureBuilder<void>(
                                future: _mushafLoad,
                                builder: (context, pageState) {
                                  if (pageState.connectionState !=
                                          ConnectionState.done ||
                                      pageState.hasError) {
                                    return const SizedBox.shrink();
                                  }
                                  final pages = pageSource.portionRange(
                                    widget.snapshot.portionUnit,
                                    current.portionIndex,
                                  );
                                  return Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      top: AppSpacing.xs,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.bookmark_outline_rounded,
                                          size: 18,
                                          color: Theme.of(
                                            context,
                                          ).extension<AppColors>()!.inkMuted,
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Text(
                                          ArabicStrings.pageRangeLabel(
                                            pages.startPage,
                                            pages.endPage,
                                          ),
                                          style: AppTypography.caption,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (state.status == AssignmentActionStatus.queued)
                const OfflineBanner(
                  message: ArabicStrings.syncQueued,
                  icon: Icons.cloud_upload_rounded,
                ),
              if (state.status == AssignmentActionStatus.failure)
                StatePanel(
                  icon: Icons.error_outline_rounded,
                  title: ArabicStrings.dashboardLoadError,
                  message: ArabicStrings.errorMessage(
                    state.failure?.code ?? '',
                  ),
                  actionLabel: ArabicStrings.retry,
                  onAction: context.read<AssignmentCubit>().retrySync,
                  isError: true,
                ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: ArabicStrings.readNowAction,
                icon: const Icon(Icons.menu_book_rounded),
                variant: AppButtonVariant.secondary,
                expanded: true,
                onPressed: () => AppRoutes.pushReader(
                  context,
                  arguments: {
                    'unit': widget.snapshot.portionUnit,
                    'index': current.portionIndex,
                    'assignmentId': current.assignmentId,
                    'alreadyCompleted': completed,
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (!completed)
                AppButton(
                  label: ArabicStrings.completeAction,
                  icon: const Icon(Icons.check_rounded),
                  expanded: true,
                  loading: state.status == AssignmentActionStatus.loading,
                  onPressed: state.status == AssignmentActionStatus.loading
                      ? null
                      : () => context.read<AssignmentCubit>().complete(
                          DateTime.now(),
                        ),
                ),
              if (completed)
                AppButton(
                  label: ArabicStrings.undoAction,
                  variant: AppButtonVariant.secondary,
                  icon: const Icon(Icons.undo_rounded),
                  expanded: true,
                  onPressed: state.status == AssignmentActionStatus.loading
                      ? null
                      : () async {
                          await ConfirmSheet.show(
                            context,
                            title: ArabicStrings.undoAction,
                            message: ArabicStrings.undoCompletionHint,
                            confirmLabel: ArabicStrings.confirmUndoAction,
                            destructive: true,
                            onConfirm: context.read<AssignmentCubit>().undo,
                          );
                        },
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
          );
        },
      ),
    );
  }
}
