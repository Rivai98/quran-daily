import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/widgets/offline_banner.dart';
import '../../../../core/design_system/widgets/islamic_ornament.dart';
import '../../../../core/design_system/widgets/skeleton.dart';
import '../../../../core/design_system/widgets/state_panel.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../cubit/log_cubit.dart';
import '../cubit/log_state.dart';
import '../data/entities/log_entities.dart';
import '../data/repositories/log_repository.dart';
import 'log_day_detail_screen.dart';
import 'widgets/log_day_tile.dart';
import 'widgets/month_summary.dart';
import 'widgets/streak_header.dart';

class LogScreen extends StatelessWidget {
  const LogScreen({super.key, this.repository});
  final LogRepository? repository;
  @override
  Widget build(BuildContext context) {
    try {
      if (context.read<LogCubit?>() != null) return const _LogView();
    } catch (_) {}
    final repo = repository ?? (serviceLocator.isRegistered<LogRepository>() ? serviceLocator<LogRepository>() : _EmptyLogRepository());
    return BlocProvider(create: (_) => LogCubit(repository: repo)..load(), child: const _LogView());
  }
}

class _EmptyLogRepository implements LogRepository {
  @override
  Future<Result<PersonalLog>> getLog({String? before, int days = 30}) async => Success(PersonalLog(
    streak: 0, bestStreak: 0,
    month: LogMonthSummary(year: DateTime.now().year, month: DateTime.now().month, fullDays: 0, daysWithItems: 0),
    days: const [], nextBefore: null,
  ));
}

class _LogView extends StatefulWidget {
  const _LogView();
  @override
  State<_LogView> createState() => _LogViewState();
}

class _LogViewState extends State<_LogView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<LogCubit>().state.status == LogStatus.initial) context.read<LogCubit>().load();
    });
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(ArabicStrings.logScreenTitle)),
    body: BlocBuilder<LogCubit, LogState>(builder: (context, state) {
      if (state.status == LogStatus.initial || state.status == LogStatus.loading) {
        return ListView(padding: AppSpacing.screenContent, children: const [SkeletonBox(height: 88), SizedBox(height: AppSpacing.lg), SkeletonBox(height: 72), SizedBox(height: AppSpacing.lg), SkeletonBox(height: 120), SizedBox(height: AppSpacing.md), SkeletonBox(height: 120)]);
      }
      if (state.status == LogStatus.failure) {
        return StatePanel(icon: Icons.error_outline, title: ArabicStrings.logErrorTitle, message: ArabicStrings.logErrorMessage, actionLabel: ArabicStrings.retryAction, onAction: context.read<LogCubit>().load, isError: true);
      }
      if (state.status == LogStatus.empty) {
        return IslamicOrnamentBand(height: 220, child: StatePanel(icon: Icons.auto_awesome_outlined, title: ArabicStrings.logEmptyTitle, message: ArabicStrings.logEmptyMessage));
      }
      final log = state.log;
      if (log == null) return const SizedBox.shrink();
      final daysByWeek = <String, List<LogDay>>{};
      for (final day in log.days) {
        final monday = day.date.subtract(Duration(days: day.date.weekday - DateTime.monday));
        final key = '${monday.year}-${monday.month}-${monday.day}';
        daysByWeek.putIfAbsent(key, () => []).add(day);
      }
      return RefreshIndicator(
        onRefresh: context.read<LogCubit>().refresh,
        child: ListView(padding: AppSpacing.screenContent, children: [
          if (state.status == LogStatus.offline) const OfflineBanner(message: ArabicStrings.offlineStale),
          StreakHeader(log: log),
          const SizedBox(height: AppSpacing.lg),
          MonthSummary(summary: log.month),
          for (final days in daysByWeek.values) ...[
            Padding(padding: const EdgeInsetsDirectional.only(top: AppSpacing.md, bottom: AppSpacing.xs), child: Text(ArabicStrings.logWeekLabel, style: Theme.of(context).textTheme.titleSmall)),
            for (final day in days)
              Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: LogDayTile(day: day, onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LogDayDetailScreen(day: day))))),
          ],
          if (state.hasMore) Padding(padding: const EdgeInsets.only(top: AppSpacing.md), child: AppButton(label: ArabicStrings.loadMoreHistory, variant: AppButtonVariant.tonal, loading: state.isLoadingMore, onPressed: state.isLoadingMore ? null : context.read<LogCubit>().loadMore)),
        ]),
      );
    }),
  );
}

