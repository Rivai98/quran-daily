import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/widgets/app_avatar.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/confirm_sheet.dart';
import '../../../../core/design_system/widgets/state_panel.dart';
import '../../../../core/design_system/widgets/halaqa_logo.dart';
import '../../../../core/design_system/widgets/skeleton.dart';
import '../../../../core/design_system/widgets/app_banner.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../cubit/join_requests/join_requests_cubit.dart';
import '../../data/entities/entities.dart';

class JoinRequestsScreen extends StatefulWidget {
  const JoinRequestsScreen({super.key, required this.groupId});
  final String groupId;
  @override
  State<JoinRequestsScreen> createState() => _JoinRequestsScreenState();
}

class _JoinRequestsScreenState extends State<JoinRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<JoinRequestsCubit>().load(widget.groupId);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(ArabicStrings.joinRequestsTitle)),
    body: BlocBuilder<JoinRequestsCubit, JoinRequestsState>(
      builder: (context, state) {
        if ((state.status == JoinRequestsStatus.loading ||
                state.status == JoinRequestsStatus.initial) &&
            state.requests.isEmpty) {
          return const _JoinRequestsSkeleton();
        }
        if ((state.status == JoinRequestsStatus.failure ||
                state.status == JoinRequestsStatus.offline) &&
            state.requests.isEmpty) {
          return StatePanel(
            icon: state.status == JoinRequestsStatus.offline
                ? Icons.cloud_off_rounded
                : Icons.error_outline_rounded,
            title: state.status == JoinRequestsStatus.offline
                ? ArabicStrings.offlineStale
                : ArabicStrings.operationFailed,
            message: state.status == JoinRequestsStatus.offline
                ? ArabicStrings.networkFailure
                : ArabicStrings.errorMessage(state.failure?.code ?? ''),
            actionLabel: ArabicStrings.retry,
            onAction: () =>
                context.read<JoinRequestsCubit>().load(widget.groupId),
          );
        }
        if (state.status == JoinRequestsStatus.groupFull) {
          return StatePanel(
            icon: Icons.group_off_rounded,
            title: ArabicStrings.groupFull,
            message: ArabicStrings.groupFull,
          );
        }
        if (state.status == JoinRequestsStatus.membershipLimit) {
          return StatePanel(
            icon: Icons.group_off_rounded,
            title: ArabicStrings.joinError,
            message: ArabicStrings.membershipLimitMessage,
            actionLabel: ArabicStrings.groupSelectionTitle,
            onAction: () => Navigator.of(context).pushNamed('/groups'),
            isError: true,
          );
        }
        if (state.requests.isEmpty) {
          return StatePanel.empty(
            icon: Icons.inbox_rounded,
            title: ArabicStrings.noJoinRequests,
            message: ArabicStrings.noJoinRequestsHint,
            actionLabel: ArabicStrings.groupSelectionTitle,
            onAction: () => Navigator.of(context).pushNamed('/groups'),
            illustration: const HalaqaLogo(size: 80),
          );
        }
        return Stack(
          children: [
            ListView(
              padding: AppSpacing.screen,
              children: [
                if (state.status == JoinRequestsStatus.failure ||
                    state.status == JoinRequestsStatus.offline) ...[
                  AppBanner(
                    icon: state.status == JoinRequestsStatus.offline
                        ? Icons.cloud_off_rounded
                        : Icons.error_outline_rounded,
                    message: state.status == JoinRequestsStatus.offline
                        ? ArabicStrings.networkFailure
                        : ArabicStrings.errorMessage(state.failure?.code ?? ''),
                    variant: state.status == JoinRequestsStatus.offline
                        ? AppBannerVariant.warning
                        : AppBannerVariant.error,
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        context.read<JoinRequestsCubit>().load(widget.groupId),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text(ArabicStrings.retry),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                for (final request in state.requests)
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            UserAvatar(
                              displayName: request.userDisplayName,
                              size: 44,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request.userDisplayName,
                                    style: AppTypography.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Row(
                                    children: [
                                      Icon(
                                        request.source == JoinSource.invite
                                            ? Icons.link_rounded
                                            : request.source == JoinSource.match
                                            ? Icons.auto_awesome_rounded
                                            : Icons.public_rounded,
                                        size: 18,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: AppSpacing.xxs),
                                      Expanded(
                                        child: Text(
                                          request.source == JoinSource.invite
                                              ? ArabicStrings.requestFromInvite
                                              : request.source ==
                                                    JoinSource.match
                                              ? ArabicStrings.requestFromMatch
                                              : ArabicStrings
                                                    .requestFromDiscovery,
                                          style: AppTypography.caption,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Icon(
                              Icons.schedule_rounded,
                              size: 18,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            AppButton(
                              label: ArabicStrings.approveRequestAction,
                              icon: const Icon(Icons.check_rounded),
                              variant: AppButtonVariant.tonal,
                              onPressed: () => ConfirmSheet.show(
                                context,
                                title: ArabicStrings.approveRequestAction,
                                message: ArabicStrings.approveRequestConfirm,
                                confirmLabel:
                                    ArabicStrings.approveRequestAction,
                                onConfirm: () =>
                                    context.read<JoinRequestsCubit>().review(
                                      request.joinRequestId,
                                      approve: true,
                                    ),
                              ),
                            ),
                            AppButton(
                              label: ArabicStrings.rejectRequestAction,
                              icon: const Icon(Icons.close_rounded),
                              variant: AppButtonVariant.secondary,
                              onPressed: () => ConfirmSheet.show(
                                context,
                                title: ArabicStrings.rejectRequestAction,
                                message: ArabicStrings.rejectRequestConfirm,
                                confirmLabel: ArabicStrings.rejectRequestAction,
                                onConfirm: () =>
                                    context.read<JoinRequestsCubit>().review(
                                      request.joinRequestId,
                                      approve: false,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (state.status == JoinRequestsStatus.submitting ||
                state.status == JoinRequestsStatus.loading)
              const Align(
                alignment: AlignmentDirectional.topCenter,
                child: LinearProgressIndicator(),
              ),
          ],
        );
      },
    ),
  );
}

class _JoinRequestsSkeleton extends StatelessWidget {
  const _JoinRequestsSkeleton();

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: AppSpacing.screen,
    itemCount: 3,
    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
    itemBuilder: (_, _) => const SkeletonBox(height: 156),
  );
}
