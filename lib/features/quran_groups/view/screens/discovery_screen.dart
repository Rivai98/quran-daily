import 'package:material_ui/material_ui.dart';

import '../../../../core/design_system/app_typography.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/widgets/widgets.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../cubit/discovery/discovery_cubit.dart';
import '../../cubit/group_list/group_list_cubit.dart';
import '../../data/entities/entities.dart';
import '../widgets/public_group_card.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  late final ScrollController _scrollController;
  // Owns the query text so it survives every rebuild (loading, empty,
  // failure) while the user is typing.
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_loadMoreWhenNeeded);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (context.read<DiscoveryCubit>().state.status ==
            DiscoveryStatus.initial) {
          context.read<DiscoveryCubit>().load();
        }
        if (context.read<GroupListCubit>().state.status ==
            GroupListStatus.initial) {
          context.read<GroupListCubit>().refresh();
        }
      }
    });
  }

  void _loadMoreWhenNeeded() {
    if (_scrollController.position.extentAfter < AppSpacing.xxl) {
      context.read<DiscoveryCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadMoreWhenNeeded)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeGroups = context.select<GroupListCubit, int>((cubit) {
      final groups = cubit.state.overview?.groups ?? const [];
      return groups.where((group) => group.status == GroupStatus.active).length;
    });
    final membershipLimitReached = activeGroups >= 2;

    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.discoveryScreenTitle)),
      body: BlocListener<DiscoveryCubit, DiscoveryState>(
        listenWhen: (previous, current) =>
            previous.failure != current.failure && current.failure != null,
        listener: (context, state) => AppSnackBar.show(
          context,
          ArabicStrings.authError(state.failure!.code),
          actionLabel: state.failure?.code == 'membership_limit'
              ? ArabicStrings.groupSelectionTitle
              : null,
          onAction: state.failure?.code == 'membership_limit'
              ? () => Navigator.of(context).pushNamed('/groups')
              : null,
        ),
        child: BlocBuilder<DiscoveryCubit, DiscoveryState>(
          builder: (context, state) {
            final searching = state.query.trim().isNotEmpty;
            // The skeleton is only for the very first load; once the user
            // searches, the field and the page stay on screen.
            if (state.status == DiscoveryStatus.initial ||
                (state.status == DiscoveryStatus.loading &&
                    state.groups.isEmpty &&
                    !searching)) {
              return const _DiscoverySkeleton();
            }
            if (state.groups.isEmpty &&
                state.status == DiscoveryStatus.empty &&
                !searching) {
              return StatePanel.empty(
                icon: Icons.search_off_rounded,
                title: ArabicStrings.noPublicGroups,
                message: ArabicStrings.publicDiscoveryHint,
                actionLabel: ArabicStrings.retry,
                actionIcon: const Icon(Icons.refresh_rounded),
                onAction: () => context.read<DiscoveryCubit>().load(),
                illustration: const HalaqaLogo(size: 80),
              );
            }
            final failed =
                state.status == DiscoveryStatus.failure ||
                state.status == DiscoveryStatus.offline;
            if (state.groups.isEmpty && failed && !searching) {
              return StatePanel(
                icon: state.status == DiscoveryStatus.offline
                    ? Icons.wifi_off_rounded
                    : Icons.error_outline_rounded,
                title: state.status == DiscoveryStatus.offline
                    ? ArabicStrings.discoveryOffline
                    : ArabicStrings.joinError,
                message: ArabicStrings.authError(
                  state.failure?.code ?? 'network',
                ),
                actionLabel: ArabicStrings.retry,
                actionIcon: const Icon(Icons.refresh_rounded),
                onAction: () => context.read<DiscoveryCubit>().load(),
                isError: state.status == DiscoveryStatus.failure,
              );
            }
            return AppPageContent(
              child: ListView(
                controller: _scrollController,
                padding: AppSpacing.screenContent,
                children: [
                  AppTextField(
                    controller: _searchController,
                    label: ArabicStrings.searchGroupLabel,
                    prefixIcon: Icons.search_rounded,
                    onChanged: context.read<DiscoveryCubit>().search,
                    onSubmitted: (query) => context
                        .read<DiscoveryCubit>()
                        .search(query, submit: true),
                  ),
                  if (membershipLimitReached) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const _MembershipLimitBanner(),
                  ],
                  if (state.status == DiscoveryStatus.loading) ...[
                    const SizedBox(height: AppSpacing.xs),
                    const LinearProgressIndicator(),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  if (state.groups.isEmpty && searching && failed)
                    AppBanner.error(
                      message: ArabicStrings.authError(
                        state.failure?.code ?? 'network',
                      ),
                    )
                  else if (state.groups.isEmpty &&
                      state.status != DiscoveryStatus.loading &&
                      searching)
                    const _NoSearchResults(),
                  for (final group in state.groups) ...[
                    PublicGroupCard(
                      group: group,
                      joinState: state.joinStates[group.groupId],
                      membershipLimitReached: membershipLimitReached,
                      onJoin: () => context.read<DiscoveryCubit>().join(group),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  AppButton(
                    label: ArabicStrings.iHaveInviteLink,
                    variant: AppButtonVariant.secondary,
                    expanded: true,
                    icon: const Icon(Icons.link_rounded),
                    onPressed: () => Navigator.pushNamed(context, '/join'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      key: const ValueKey('discovery-no-results'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 40, color: colors.inkMuted),
          const SizedBox(height: AppSpacing.xs),
          Text(
            ArabicStrings.discoveryNoResultsTitle,
            textAlign: TextAlign.center,
            style: AppTypography.title,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            ArabicStrings.discoveryNoResultsHint,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: colors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _MembershipLimitBanner extends StatelessWidget {
  const _MembershipLimitBanner();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        border: Border.all(color: colors.primary.withValues(alpha: 0.32)),
        borderRadius: AppRadius.mdBR,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: colors.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '${ArabicStrings.membershipLimitMessage} ${ArabicStrings.membershipLimitNextStep}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/groups'),
              child: Text(ArabicStrings.groupSelectionTitle),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverySkeleton extends StatelessWidget {
  const _DiscoverySkeleton();

  @override
  Widget build(BuildContext context) => AppPageContent(
    child: ListView(
      padding: AppSpacing.screenContent,
      children: const [
        SkeletonBox(height: 52),
        SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 160, height: 20),
              SizedBox(height: AppSpacing.sm),
              SkeletonBox(width: 240, height: 18),
              SizedBox(height: AppSpacing.sm),
              SkeletonBox(height: 40),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 140, height: 20),
              SizedBox(height: AppSpacing.sm),
              SkeletonBox(width: 220, height: 18),
              SizedBox(height: AppSpacing.sm),
              SkeletonBox(height: 40),
            ],
          ),
        ),
      ],
    ),
  );
}
