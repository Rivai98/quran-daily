import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/router.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/widgets/widgets.dart';
import '../../../core/localization/arabic_strings.dart';
import '../../../core/localization/arabic_numerals.dart';
import '../../../core/quran/quran_metadata_repository.dart';
import '../../../core/quran/mushaf/mushaf_repository.dart';
import '../../../core/di/service_locator.dart';
import '../cubit/home_cubit.dart';
import '../data/today_snapshot.dart';
import 'widgets/date_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.metadataRepository});
  final QuranMetadataRepository metadataRepository;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HomeCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(ArabicStrings.homeGreeting)),
    body: BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state.status == HomeStatus.initial ||
            (state.status == HomeStatus.loading && state.snapshot == null)) {
          return const AppPageContent(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.status == HomeStatus.failure && state.snapshot == null) {
          return StatePanel(
            icon: Icons.wifi_off,
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
            padding: AppSpacing.screenContent,
            children: [
              DateHeader(date: DateTime.now()),
              if (state.status == HomeStatus.offline) ...[
                const SizedBox(height: AppSpacing.md),
                const OfflineBanner(message: ArabicStrings.offlineStale),
              ],
              const SizedBox(height: AppSpacing.lg),
              _MainGroupHeroCard(
                group: main,
                metadata: widget.metadataRepository,
                complete: context.read<HomeCubit>().complete,
                undo: context.read<HomeCubit>().undo,
                busyId: state.updatingId,
              ),
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
                Text(
                  ArabicStrings.otherGroupsTitle,
                  style: AppTypography.title,
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final group in others) ...[
                  if (group.items.isEmpty) ...[
                    _TodayItemCard(
                      group: group,
                      metadata: widget.metadataRepository,
                      complete: context.read<HomeCubit>().complete,
                      undo: context.read<HomeCubit>().undo,
                      busyId: state.updatingId,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ] else
                    for (final item in group.items) ...[
                      _TodayItemCard(
                        group: group,
                        item: item,
                        metadata: widget.metadataRepository,
                        complete: context.read<HomeCubit>().complete,
                        undo: context.read<HomeCubit>().undo,
                        busyId: state.updatingId,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                ],
              ],
            ],
          ),
        );
      },
    ),
  );
  Widget _empty(BuildContext context) => ListView(
    padding: AppSpacing.screenContent,
    children: [
      DateHeader(date: DateTime.now()),
      const SizedBox(height: AppSpacing.lg),
      StatePanel(
        icon: Icons.groups,
        title: ArabicStrings.homeEmptyTitle,
        message: '',
        actionLabel: ArabicStrings.joinAnyGroupAction,
        onAction: () => Navigator.pushNamed(context, '/join-any'),
      ),
      const SizedBox(height: AppSpacing.sm),
      AppButton(
        label: ArabicStrings.searchGroupAction,
        variant: AppButtonVariant.secondary,
        expanded: true,
        icon: const Icon(Icons.search),
        onPressed: () => Navigator.pushNamed(context, AppRoutes.discovery),
      ),
      const SizedBox(height: AppSpacing.sm),
      AppButton(
        label: ArabicStrings.joinByInviteAction,
        variant: AppButtonVariant.secondary,
        expanded: true,
        icon: const Icon(Icons.key_outlined),
        onPressed: () => Navigator.pushNamed(context, '/join'),
      ),
      const SizedBox(height: AppSpacing.sm),
      AppButton(
        label: ArabicStrings.createGroup,
        variant: AppButtonVariant.secondary,
        expanded: true,
        icon: const Icon(Icons.add),
        onPressed: () => Navigator.pushNamed(context, '/groups/new'),
      ),
    ],
  );
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
          onTap: () => Navigator.pushNamed(context, AppRoutes.dashboard, arguments: group.groupId),
          child: Row(
            children: [
            GroupAvatar(name: group.name, size: 40),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(group.name, style: AppTypography.title)),
            ],
          ),
        ),
        if (group.day != null) ...[
          const SizedBox(height: AppSpacing.xs),
          LinearProgressIndicator(
            value: group.day!.totalCount == 0
                ? 0
                : group.day!.completedCount / group.day!.totalCount,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            ArabicStrings.cycleProgress(
              group.day!.cycleDay,
              group.day!.cycleLength,
              group.day!.completedCount,
              group.day!.totalCount,
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
          ),
          const SizedBox(height: AppSpacing.sm),
          _status(group.items.first.status),
          const SizedBox(height: AppSpacing.xs),
          if (group.items.first.status == 'completed' ||
              group.items.first.status == 'late') ...[
            Text(ArabicStrings.todayCompleteTitle, style: AppTypography.body),
            TextButton(
              onPressed: group.items.first.canUndo
                  ? () => ConfirmSheet.show(context, title: ArabicStrings.confirmUndoAction, message: ArabicStrings.undoCompletionHint, confirmLabel: ArabicStrings.confirmUndoAction, destructive: true, onConfirm: () => undo(group.items.first))
                  : null,
              child: const Text(ArabicStrings.portionUndoAction),
            ),
          ] else ...[
            AppButton(
              label: ArabicStrings.readNowAction,
              icon: const Icon(Icons.menu_book),
              expanded: true,
              onPressed: () => Navigator.pushNamed(context, AppRoutes.mushafReader, arguments: {'unit': group.portionUnit, 'index': group.items.first.portionIndex, 'assignmentId': group.items.first.assignmentId, 'alreadyCompleted': false}),
            ),
            const SizedBox(height: AppSpacing.xs),
            _CompletionAction(item: group.items.first, complete: complete, undo: undo, busy: busyId == group.items.first.assignmentId),
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showGroupName) Text(group.name, style: AppTypography.title),
        if (item != null) ...[
          const SizedBox(height: AppSpacing.xs),
          _PortionLabel(group: group, item: item!, metadata: metadata),
          const SizedBox(height: AppSpacing.xs),
          _status(item!.status),
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            label: ArabicStrings.openTodayWird,
            variant: AppButtonVariant.secondary,
            expanded: true,
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.dashboard,
              arguments: group.groupId,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
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
  });
  final TodayGroup group;
  final TodayItem item;
  final QuranMetadataRepository metadata;
  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: metadata.load(),
    builder: (context, state) {
      if (state.connectionState != ConnectionState.done || state.hasError) {
        return Text(
          ArabicStrings.portionName(group.portionUnit, item.portionIndex),
          style: AppTypography.quranLabel,
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
          Text(
            ArabicStrings.portionName(group.portionUnit, item.portionIndex),
            style: AppTypography.quranLabel,
          ),
          Text(range, style: AppTypography.caption),
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
                return Text(
                  '${ArabicStrings.pageNumberLabel} ${ArabicNumerals.format(pages.startPage)} – ${ArabicNumerals.format(pages.endPage)}',
                  style: AppTypography.caption,
                );
              },
            ),
        ],
      );
    },
  );
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
            icon: const Icon(Icons.check_circle_outline),
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
