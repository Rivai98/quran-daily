import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/widgets/offline_banner.dart';
import '../../../../core/design_system/widgets/skeleton.dart';
import '../../../../core/design_system/widgets/state_panel.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../cubit/history/history_cubit.dart';
import '../../cubit/history/history_state.dart';
import '../../cubit/selected_group/selected_group_cubit.dart';
import '../../data/entities/entities.dart';
import '../../data/repositories/khatma_repository.dart';
import '../widgets/history_day_card.dart';
import '../widgets/history_day_detail.dart';

/// S10 History Screen: lists daily khatma summaries with drill-down (ui-contract).
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, this.groupId});

  final String? groupId;

  @override
  Widget build(BuildContext context) {
    // If a HistoryCubit is already provided above us, use it.
    try {
      final existingCubit = context.read<HistoryCubit?>();
      if (existingCubit != null) {
        return const _HistoryView();
      }
    } catch (_) {}

    final effectiveGroupId =
        groupId ??
        context.read<SelectedGroupCubit?>()?.state.selectedGroupId ??
        '';

    return BlocProvider<HistoryCubit>(
      create: (context) {
        if (serviceLocator.isRegistered<KhatmaRepository>()) {
          final repo = serviceLocator<KhatmaRepository>();
          return HistoryCubit(groupId: effectiveGroupId, repository: repo)
            ..loadHistory();
        }
        return HistoryCubit(
          groupId: effectiveGroupId,
          repository: _FallbackKhatmaRepository(),
        );
      },
      child: const _HistoryView(),
    );
  }
}

class _FallbackKhatmaRepository implements KhatmaRepository {
  @override
  Future<Result<List<HistoryDaySummary>>> getHistory(
    String groupId, {
    String? beforeDate,
    int limit = 30,
  }) async => const Success([]);

  @override
  Future<Result<HistoryDaySummary>> getHistoryDay(
    String groupId,
    String groupDate,
  ) async => const FailureResult(
    UnknownFailure(message: 'not found', code: 'not_found'),
  );

  @override
  Future<Result<DashboardSnapshot>> getDashboard(String groupId) =>
      throw UnimplementedError();

  @override
  Stream<DashboardSnapshot?> watchCachedDashboard(String groupId) =>
      throw UnimplementedError();

  @override
  Future<Result<DashboardSnapshot>> markComplete(
    String assignmentId,
    DateTime clientRecordedAt,
  ) => throw UnimplementedError();

  @override
  Future<Result<DashboardSnapshot>> undoCompletion(String assignmentId) =>
      throw UnimplementedError();

  @override
  Future<Result<DashboardSnapshot>> volunteer(String assignmentId) =>
      throw UnimplementedError();

  @override
  Future<Result<DashboardSnapshot>> overrideAssignment(
    String assignmentId,
    String membershipId,
  ) => throw UnimplementedError();

  @override
  Future<SyncReport> syncPending() => throw UnimplementedError();
}

class _HistoryView extends StatefulWidget {
  const _HistoryView();

  @override
  State<_HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<_HistoryView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final cubit = context.read<HistoryCubit>();
        if (cubit.state.status == HistoryStatus.initial) {
          cubit.loadHistory();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.historyScreenTitle)),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          if (state.selectedDay != null) {
            return HistoryDayDetail(
              day: state.selectedDay!,
              onClose: () => context.read<HistoryCubit>().clearSelectedDay(),
            );
          }

          switch (state.status) {
            case HistoryStatus.initial:
            case HistoryStatus.loading:
              return const _SkeletonList();

            case HistoryStatus.empty:
              return const StatePanel(
                icon: Icons.history,
                title: ArabicStrings.emptyHistoryTitle,
                message: ArabicStrings.emptyHistoryDesc,
              );

            case HistoryStatus.failure:
              return StatePanel(
                icon: Icons.error_outline,
                title: ArabicStrings.historyErrorTitle,
                message: ArabicStrings.historyErrorDesc,
                actionLabel: ArabicStrings.retryAction,
                actionVariant: AppButtonVariant.secondary,
                onAction: () => context.read<HistoryCubit>().loadHistory(),
              );

            case HistoryStatus.offline:
              return Column(
                children: [
                  const OfflineBanner(message: ArabicStrings.offlineStale),
                  Expanded(
                    child: state.days.isEmpty
                        ? const StatePanel(
                            icon: Icons.history,
                            title: ArabicStrings.emptyHistoryTitle,
                            message: ArabicStrings.emptyHistoryDesc,
                          )
                        : _DaysList(days: state.days, hasMore: state.hasMore),
                  ),
                ],
              );

            case HistoryStatus.success:
              return _DaysList(
                days: state.days,
                hasMore: state.hasMore,
                isLoadingMore: state.isLoadingMore,
              );
          }
        },
      ),
    );
  }
}

class _DaysList extends StatelessWidget {
  const _DaysList({
    required this.days,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final List<dynamic> days;
  final bool hasMore;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: AppSpacing.screen,
      itemCount: days.length + (hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        if (index == days.length) {
          return AppButton(
            label: ArabicStrings.loadMoreHistory,
            variant: AppButtonVariant.tonal,
            loading: isLoadingMore,
            onPressed: () => context.read<HistoryCubit>().loadMore(),
          );
        }

        final day = days[index];
        return HistoryDayCard(
          day: day,
          onTap: () =>
              context.read<HistoryCubit>().loadDayDetail(day.groupDate),
        );
      },
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: AppSpacing.screen,
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, index) => const SkeletonBox(height: 120),
    );
  }
}
