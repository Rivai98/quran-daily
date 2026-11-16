import 'package:material_ui/material_ui.dart';

import '../../reminders/view/notification_onboarding.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/router.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_radius.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/widgets/widgets.dart';
import '../../../core/design_system/widgets/continue_reading_card.dart';
import '../../../core/localization/arabic_strings.dart';
import '../../../core/localization/arabic_formatting.dart';
import '../../../core/localization/arabic_numerals.dart';
import '../../../core/quran/quran_metadata_repository.dart';
import '../../../core/quran/portion_unit.dart';
import '../../../core/quran/mushaf/mushaf_repository.dart';
import '../../../core/di/service_locator.dart';
import '../../profile/data/entities/profile_entities.dart';
import '../../shell/shell_cubit.dart';
import '../cubit/home_cubit.dart';
import '../data/today_snapshot.dart';
import 'widgets/date_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.metadataRepository,
    this.displayName,
    this.date,
  });
  final QuranMetadataRepository metadataRepository;
  final String? displayName;
  final DateTime? date;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<HomeCubit>().load();
      // First run only: explain and ask for notification permission.
      if (mounted) await NotificationOnboarding.maybeAsk(context);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        ArabicStrings.homeGreeting(widget.displayName),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.title.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ),
    body: BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state.status == HomeStatus.initial ||
            (state.status == HomeStatus.loading && state.snapshot == null)) {
          return const AppPageContent(child: _HomeSkeleton());
        }
        if (state.status == HomeStatus.failure && state.snapshot == null) {
          return StatePanel(
            icon: Icons.wifi_off_rounded,
            title: ArabicStrings.todayLoadError,
            message: ArabicStrings.networkFailure,
            actionLabel: ArabicStrings.retry,
            onAction: () => context.read<HomeCubit>().refresh(),
            isError: true,
          );
        }
        final groups = state.snapshot?.groups ?? const <TodayGroup>[];
        if (groups.isEmpty) return _empty(context);
        final main = groups.firstWhere(
          (g) => g.isMain,
          orElse: () => groups.first,
        );
        final others = groups.where((g) => g.groupId != main.groupId).toList();
        return RefreshIndicator(
          onRefresh: context.read<HomeCubit>().refresh,
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [
              DateHeader(date: widget.date ?? DateTime.now()),
              if (state.status == HomeStatus.offline) ...[
                const SizedBox(height: AppSpacing.md),
                const OfflineBanner(message: ArabicStrings.offlineStale),
              ],
              const SizedBox(height: AppSpacing.md),
              _MainGroupHeroCard(
                group: main,
                metadata: widget.metadataRepository,
                complete: context.read<HomeCubit>().complete,
                undo: context.read<HomeCubit>().undo,
                busyId: state.updatingId,
              ),
              if (state.tomorrowPortions.containsKey(main.groupId) ||
                  state.khatmasEndingToday.contains(main.groupId)) ...[
                const SizedBox(height: AppSpacing.xs),
                _TomorrowWirdLine(
                  group: main,
                  portionIndex: state.tomorrowPortions[main.groupId],
                  metadata: widget.metadataRepository,
                  endsToday: state.khatmasEndingToday.contains(main.groupId),
                ),
              ],
              for (final item in main.items.skip(1)) ...[
                const SizedBox(height: AppSpacing.sm),
                _TodayItemCard(
                  group: main,
                  item: item,
                  showGroupName: false,
                  metadata: widget.metadataRepository,
                  complete: context.read<HomeCubit>().complete,
                  undo: context.read<HomeCubit>().undo,
                  busyId: state.updatingId,
                ),
              ],
              if (others.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _SecondGroupCard(
                  group: others.first,
                  item: others.first.items.isEmpty
                      ? null
                      : others.first.items.first,
                  metadata: widget.metadataRepository,
                ),
              ],
              if (serviceLocator.isRegistered<MushafRepository>()) ...[
                const SizedBox(height: AppSpacing.lg),
                FutureBuilder<void>(
                  future: serviceLocator<MushafRepository>().load(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done ||
                        snapshot.hasError) {
                      return const SizedBox.shrink();
                    }
                    final repository = serviceLocator<MushafRepository>();
                    return ContinueReadingCard(
                      repository: repository,
                      metadata: widget.metadataRepository,
                      onOpenPage: (page) => AppRoutes.pushReader(
                        context,
                        arguments: {'page': page},
                      ),
                    );
                  },
                ),
              ],
              if (state.profile != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _UpcomingBadgeCard(profile: state.profile!),
              ],
            ],
          ),
        );
      },
    ),
  );
  Widget _empty(BuildContext context) => ListView(
    padding: const EdgeInsetsDirectional.fromSTEB(
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.xl,
    ),
    children: [
      DateHeader(date: widget.date ?? DateTime.now()),
      const SizedBox(height: AppSpacing.lg),
      StatePanel.empty(
        icon: Icons.groups_rounded,
        title: ArabicStrings.homeEmptyTitle,
        message: ArabicStrings.groupsNeedMembersEntry,
        actionLabel: ArabicStrings.searchGroupAction,
        actionIcon: const Icon(Icons.search_rounded),
        onAction: () => Navigator.pushNamed(context, AppRoutes.discovery),
        secondaryActionLabel: ArabicStrings.createGroup,
        secondaryActionIcon: const Icon(Icons.add_circle_outline_rounded),
        onSecondaryAction: () => Navigator.pushNamed(context, '/groups/new'),
      ),
    ],
  );
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: AppSpacing.screenContent,
    children: const [
      SkeletonBox(width: 150, height: 24),
      SizedBox(height: AppSpacing.md),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 120, height: 20),
            SizedBox(height: AppSpacing.sm),
            SkeletonBox(height: 8),
            SizedBox(height: AppSpacing.md),
            SkeletonBox(width: 220, height: 20),
            SizedBox(height: AppSpacing.sm),
            SkeletonBox(height: 48),
          ],
        ),
      ),
      SizedBox(height: AppSpacing.sm),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 160, height: 20),
            SizedBox(height: AppSpacing.sm),
            SkeletonBox(height: 20),
          ],
        ),
      ),
    ],
  );
}

class _TomorrowWirdLine extends StatelessWidget {
  const _TomorrowWirdLine({
    required this.group,
    required this.portionIndex,
    required this.metadata,
    required this.endsToday,
  });
  final TodayGroup group;
  final int? portionIndex;
  final QuranMetadataRepository metadata;
  final bool endsToday;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(
      start: AppSpacing.md,
      end: AppSpacing.md,
    ),
    child: FutureBuilder<void>(
      future: metadata.load(),
      builder: (context, snapshot) {
        if (endsToday) {
          return _MetaLine(
            icon: Icons.event_available_rounded,
            label: ArabicStrings.khatmaEndsToday,
          );
        }
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.hasError ||
            portionIndex == null) {
          return const SizedBox.shrink();
        }
        final portion = group.portionUnit == PortionUnit.page
            ? '${ArabicStrings.pageNumberLabel} ${ArabicFormatting.isolate(ArabicNumerals.format(portionIndex!))}'
            : ArabicStrings.portionName(group.portionUnit, portionIndex!);
        final colors = Theme.of(context).extension<AppColors>()!;
        return Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: colors.inkMuted),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                ArabicStrings.tomorrowPortion(portion),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(color: colors.inkMuted),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _SecondGroupCard extends StatelessWidget {
  const _SecondGroupCard({
    required this.group,
    required this.item,
    required this.metadata,
  });
  final TodayGroup group;
  final TodayItem? item;
  final QuranMetadataRepository metadata;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: AppSpacing.compactCard,
    child: InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.dashboard,
        arguments: group.groupId,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GroupAvatar(
                name: group.name,
                photoPath: group.photoPath,
                size: 40,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  group.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).extension<AppColors>()!.inkMuted,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (item == null)
            Text(
              group.day?.restDay == true
                  ? ArabicStrings.restDay
                  : ArabicStrings.noAssignmentToday,
              style: AppTypography.body,
            )
          else
            _PortionLabel(
              group: group,
              item: item!,
              metadata: metadata,
              status: item!.status,
            ),
        ],
      ),
    ),
  );
}

class _UpcomingBadgeCard extends StatelessWidget {
  const _UpcomingBadgeCard({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final khatmas = profile.khatmas.fold<int>(
      0,
      (sum, item) => sum + item.completed,
    );
    final earned = profile.badges
        .where((badge) => badge.isEarned)
        .map((badge) => badge.code)
        .toSet();
    final candidates =
        <
              ({
                ProfileBadgeCode code,
                int current,
                int target,
                String title,
                String unit,
              })
            >[
              (
                code: ProfileBadgeCode.firstKhatma,
                current: khatmas,
                target: 1,
                title: ArabicStrings.badgeFirstKhatmaTitle,
                unit: 'khatma',
              ),
              (
                code: ProfileBadgeCode.streak7,
                current: profile.streak,
                target: 7,
                title: ArabicStrings.badgeStreak7Title,
                unit: 'day',
              ),
              (
                code: ProfileBadgeCode.streak30,
                current: profile.streak,
                target: 30,
                title: ArabicStrings.badgeStreak30Title,
                unit: 'day',
              ),
              (
                code: ProfileBadgeCode.streak100,
                current: profile.streak,
                target: 100,
                title: ArabicStrings.badgeStreak100Title,
                unit: 'day',
              ),
              (
                code: ProfileBadgeCode.portions100,
                current: profile.portionsRead,
                target: 100,
                title: ArabicStrings.badgePortions100Title,
                unit: 'portion',
              ),
            ]
            .where((item) => !earned.contains(item.code))
            .toList();
    if (candidates.isEmpty) return const SizedBox.shrink();
    candidates.sort(
      (a, b) => (a.target - a.current).compareTo(b.target - b.current),
    );
    final next = candidates.first;
    final remaining = (next.target - next.current).clamp(0, next.target);
    final progress = next.current.clamp(0, next.target) / next.target;
    final colors = Theme.of(context).extension<AppColors>()!;
    return AppCard(
      padding: AppSpacing.compactCard,
      child: InkWell(
        onTap: () => context.read<ShellCubit>().select(3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium_outlined, color: colors.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    ArabicStrings.badgeComingTitle,
                    style: AppTypography.title,
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: colors.inkMuted),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              ArabicStrings.badgeRemaining(
                remaining,
                next.title,
                unit: next.unit,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: AppRadius.pillBR,
              child: LinearProgressIndicator(
                minHeight: AppSpacing.xxs,
                value: progress,
                color: colors.primary,
                backgroundColor: colors.surfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainGroupHeroCard extends StatelessWidget {
  const _MainGroupHeroCard({
    required this.group,
    required this.metadata,
    required this.complete,
    required this.undo,
    required this.busyId,
  });
  final TodayGroup group;
  final QuranMetadataRepository metadata;
  final Future<void> Function(TodayItem) complete, undo;
  final String? busyId;
  @override
  Widget build(BuildContext context) => AppCard(
    highlighted: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.dashboard,
            arguments: group.groupId,
          ),
          child: Row(
            children: [
              GroupAvatar(
                name: group.name,
                photoPath: group.photoPath,
                size: 40,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(group.name, style: AppTypography.title)),
            ],
          ),
        ),
        if (group.day != null && group.activeMemberCount > 0) ...[
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: AppRadius.pillBR,
            child: LinearProgressIndicator(
              minHeight: AppSpacing.xs,
              value: group.activeMemberCount == 0
                  ? 0
                  : group.day!.completedMemberCount / group.activeMemberCount,
              color: Theme.of(context).extension<AppColors>()!.primary,
              backgroundColor: Theme.of(context)
                  .extension<AppColors>()!
                  .surfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            ArabicStrings.homeGroupProgress(
              group.day!.cycleDay + 1,
              group.day!.completedMemberCount,
              group.activeMemberCount,
            ),
            style: AppTypography.caption,
          ),
        ],
        if (group.day?.restDay == true) ...[
          const SizedBox(height: AppSpacing.md),
          Text(ArabicStrings.restDay, style: AppTypography.bodyLarge),
        ] else if (group.items.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _PortionLabel(
            group: group,
            item: group.items.first,
            metadata: metadata,
            status: group.items.first.status,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (group.items.first.status == 'completed' ||
              group.items.first.status == 'late') ...[
            Text(ArabicStrings.todayCompleteTitle, style: AppTypography.body),
            TextButton(
              onPressed: group.items.first.canUndo
                  ? () => ConfirmSheet.show(
                      context,
                      title: ArabicStrings.confirmUndoAction,
                      message: ArabicStrings.undoCompletionHint,
                      confirmLabel: ArabicStrings.confirmUndoAction,
                      destructive: true,
                      onConfirm: () => undo(group.items.first),
                    )
                  : null,
              child: const Text(ArabicStrings.portionUndoAction),
            ),
          ] else ...[
            AppButton(
              label: ArabicStrings.readNowAction,
              icon: const Icon(Icons.auto_stories_rounded),
              expanded: true,
              onPressed: () => AppRoutes.pushReader(
                context,
                arguments: {
                  'unit': group.portionUnit,
                  'index': group.items.first.portionIndex,
                  'assignmentId': group.items.first.assignmentId,
                  'alreadyCompleted': false,
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            _CompletionAction(
              item: group.items.first,
              complete: complete,
              undo: undo,
              busy: busyId == group.items.first.assignmentId,
            ),
          ],
        ],
      ],
    ),
  );
}

class _TodayItemCard extends StatelessWidget {
  const _TodayItemCard({
    required this.group,
    this.item,
    this.showGroupName = true,
    required this.metadata,
    required this.complete,
    required this.undo,
    required this.busyId,
  });
  final TodayGroup group;
  final TodayItem? item;
  final bool showGroupName;
  final QuranMetadataRepository metadata;
  final Future<void> Function(TodayItem) complete, undo;
  final String? busyId;
  @override
  Widget build(BuildContext context) => AppCard(
    padding: AppSpacing.card,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showGroupName)
          Row(
            children: [
              GroupAvatar(
                name: group.name,
                photoPath: group.photoPath,
                size: 40,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  group.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title,
                ),
              ),
            ],
          ),
        if (item != null) ...[
          const SizedBox(height: AppSpacing.xs),
          _PortionLabel(
            group: group,
            item: item!,
            metadata: metadata,
            status: item!.status,
          ),
          const SizedBox(height: AppSpacing.xs),
          if (item!.status != 'completed' && item!.status != 'late') ...[
            AppButton(
              label: ArabicStrings.readNowAction,
              variant: AppButtonVariant.secondary,
              expanded: true,
              icon: const Icon(Icons.auto_stories_rounded),
              onPressed: () => AppRoutes.pushReader(
                context,
                arguments: {
                  'unit': group.portionUnit,
                  'index': item!.portionIndex,
                  'assignmentId': item!.assignmentId,
                  'alreadyCompleted': false,
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          _CompletionAction(
            item: item!,
            complete: complete,
            undo: undo,
            busy: busyId == item!.assignmentId,
          ),
        ] else
          Text(
            group.day?.restDay == true
                ? ArabicStrings.restDay
                : ArabicStrings.noAssignmentToday,
            style: AppTypography.body,
          ),
      ],
    ),
  );
}

class _PortionLabel extends StatelessWidget {
  const _PortionLabel({
    required this.group,
    required this.item,
    required this.metadata,
    required this.status,
  });
  final TodayGroup group;
  final TodayItem item;
  final QuranMetadataRepository metadata;
  final String status;
  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: metadata.load(),
    builder: (context, state) {
      if (state.connectionState != ConnectionState.done || state.hasError) {
        return Row(
          children: [
            Expanded(
              child: Text(
                ArabicStrings.portionName(group.portionUnit, item.portionIndex),
                style: AppTypography.quranLabel,
              ),
            ),
            _status(status),
          ],
        );
      }
      final portion = metadata.portion(group.portionUnit, item.portionIndex);
      final range = ArabicStrings.portionRange(
        metadata.suraName(portion.startSura),
        portion.startAya,
        metadata.suraName(portion.endSura),
        portion.endAya,
      );
      final mushaf = serviceLocator.isRegistered<MushafRepository>()
          ? serviceLocator<MushafRepository>()
          : null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  ArabicStrings.portionName(
                    group.portionUnit,
                    item.portionIndex,
                  ),
                  style: AppTypography.quranLabel,
                ),
              ),
              _status(status),
            ],
          ),
          _MetaLine(icon: Icons.menu_book_rounded, label: range),
          if (mushaf != null)
            FutureBuilder<void>(
              future: mushaf.load(),
              builder: (context, mushafState) {
                if (mushafState.connectionState != ConnectionState.done ||
                    mushafState.hasError) {
                  return const SizedBox.shrink();
                }
                final pages = mushaf.portionRange(
                  group.portionUnit,
                  item.portionIndex,
                );
                return _MetaLine(
                  icon: Icons.auto_stories_rounded,
                  label: ArabicStrings.pageRangeLabel(
                    pages.startPage,
                    pages.endPage,
                  ),
                );
              },
            ),
        ],
      );
    },
  );
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).extension<AppColors>()!.inkMuted;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: AppSpacing.xxs),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(label, style: AppTypography.caption)),
        ],
      ),
    );
  }
}

class _CompletionAction extends StatelessWidget {
  const _CompletionAction({
    required this.item,
    required this.complete,
    required this.undo,
    required this.busy,
  });
  final TodayItem item;
  final Future<void> Function(TodayItem) complete, undo;
  final bool busy;
  @override
  Widget build(BuildContext context) {
    final done = item.status == 'completed' || item.status == 'late';
    if (done) {
      return TextButton(
        onPressed: item.canUndo
            ? () => ConfirmSheet.show(
                context,
                title: ArabicStrings.confirmUndoAction,
                message: ArabicStrings.undoCompletionHint,
                confirmLabel: ArabicStrings.confirmUndoAction,
                destructive: true,
                onConfirm: () => undo(item),
              )
            : null,
        child: const Text(ArabicStrings.portionUndoAction),
      );
    }
    return AppButton(
      label: ArabicStrings.portionCompleteAction,
      variant: AppButtonVariant.tonal,
      expanded: true,
      loading: busy,
      icon: const Icon(Icons.check_circle_outline_rounded),
      onPressed: () => complete(item),
    );
  }
}

Widget _status(String value) => StatusChip(
  status: switch (value) {
    'completed' => AssignmentStatus.completed,
    'late' => AssignmentStatus.late,
    'missed' => AssignmentStatus.missed,
    'available' => AssignmentStatus.available,
    'unread' => AssignmentStatus.unread,
    _ => AssignmentStatus.pending,
  },
);
