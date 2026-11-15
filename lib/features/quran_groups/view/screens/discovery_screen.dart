import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/widgets/widgets.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../cubit/discovery/discovery_cubit.dart';
import '../widgets/public_group_card.dart';
import '../../../../core/quran/quran_metadata_repository.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key, this.metadataRepository});
  final QuranMetadataRepository? metadataRepository;

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  late final QuranMetadataRepository _fallbackMetadata =
      QuranMetadataRepository();
  QuranMetadataRepository get _metadataRepository =>
      widget.metadataRepository ?? _fallbackMetadata;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_loadMoreWhenNeeded);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          context.read<DiscoveryCubit>().state.status ==
              DiscoveryStatus.initial) {
        context.read<DiscoveryCubit>().load();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.discoveryScreenTitle)),
      body: BlocBuilder<DiscoveryCubit, DiscoveryState>(
        builder: (context, state) {
          if (state.status == DiscoveryStatus.initial ||
              (state.status == DiscoveryStatus.loading &&
                  state.groups.isEmpty)) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == DiscoveryStatus.empty) {
            return StatePanel(
              icon: Icons.search_off,
              title: ArabicStrings.noPublicGroups,
              message: ArabicStrings.publicDiscoveryHint,
              actionLabel: ArabicStrings.retry,
              onAction: () => context.read<DiscoveryCubit>().load(),
            );
          }
          if (state.status == DiscoveryStatus.failure ||
              state.status == DiscoveryStatus.offline) {
            return StatePanel(
              icon: state.status == DiscoveryStatus.offline
                  ? Icons.wifi_off
                  : Icons.error_outline,
              title: state.status == DiscoveryStatus.offline
                  ? ArabicStrings.discoveryOffline
                  : ArabicStrings.joinError,
              message: ArabicStrings.authError(
                state.failure?.code ?? 'network',
              ),
              actionLabel: ArabicStrings.retry,
              onAction: () => context.read<DiscoveryCubit>().load(),
              isError: state.status == DiscoveryStatus.failure,
            );
          }
          return ListView(
            controller: _scrollController,
            padding: AppSpacing.screen,
            children: [
              TextField(
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: ArabicStrings.searchGroupLabel,
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: context.read<DiscoveryCubit>().search,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: ArabicStrings.joinAnyGroupAction,
                icon: const Icon(Icons.groups_outlined),
                variant: AppButtonVariant.primary,
                expanded: true,
                onPressed: () => Navigator.pushNamed(context, '/join-any'),
              ),
              const SizedBox(height: AppSpacing.md),
              if (state.failure != null) ...[
                _JoinFailureNotice(),
                const SizedBox(height: AppSpacing.sm),
              ],
              for (final group in state.groups) ...[
                PublicGroupCard(
                  group: group,
                  metadataRepository: _metadataRepository,
                  joinState: state.joinStates[group.groupId],
                  onJoin: () => context.read<DiscoveryCubit>().join(group),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (state.status == DiscoveryStatus.loading)
                const Padding(
                  padding: EdgeInsetsDirectional.all(AppSpacing.md),
                  child: Center(child: CircularProgressIndicator()),
                ),
              AppButton(
                label: ArabicStrings.iHaveInviteLink,
                variant: AppButtonVariant.secondary,
                expanded: true,
                onPressed: () => Navigator.pushNamed(context, '/join'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _JoinFailureNotice extends StatelessWidget {
  const _JoinFailureNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.danger.withValues(alpha: 0.08),
        border: Border.all(color: colors.danger.withValues(alpha: 0.32)),
        borderRadius: AppRadius.smBR,
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.danger),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              ArabicStrings.joinError,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
