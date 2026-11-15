import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/assignment_status.dart';
import '../../../../core/design_system/widgets/app_avatar.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/app_section_header.dart';
import '../../../../core/design_system/widgets/state_panel.dart';
import '../../../../core/design_system/widgets/skeleton.dart';
import '../../../../core/design_system/widgets/offline_banner.dart';
import '../../../../core/design_system/widgets/status_chip.dart';
import '../../../../core/localization/arabic_initials.dart';
import '../../../../core/localization/arabic_numerals.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/quran/portion_unit.dart';
import '../../cubit/member_profile/member_profile_cubit.dart';
import '../../data/entities/entities.dart';

AssignmentStatus _toDesignStatus(AssignmentStatusEnum s) =>
    AssignmentStatus.values.byName(s.name);

class MemberProfileArgs {
  const MemberProfileArgs({required this.userId, required this.groupId});

  final String userId;
  final String groupId;

  factory MemberProfileArgs.fromDynamic(dynamic raw) {
    if (raw is MemberProfileArgs) return raw;
    if (raw is Map) {
      return MemberProfileArgs(
        userId: raw['userId'] as String? ?? '',
        groupId: raw['groupId'] as String? ?? '',
      );
    }
    return const MemberProfileArgs(userId: '', groupId: '');
  }
}

class MemberProfileScreen extends StatefulWidget {
  const MemberProfileScreen({
    super.key,
    required this.userId,
    required this.groupId,
  });

  final String userId;
  final String groupId;

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MemberProfileCubit>().load(widget.userId, widget.groupId);
      }
    });
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'owner':
        return ArabicStrings.memberRoleOwner;
      case 'supervisor':
        return ArabicStrings.memberRoleSupervisor;
      case 'former_member':
        return ArabicStrings.memberRoleFormer;
      default:
        return ArabicStrings.memberRoleMember;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.memberProfileTitle)),
      body: BlocBuilder<MemberProfileCubit, MemberProfileState>(
        builder: (context, state) {
          if ((state.status == MemberProfileStatus.loading ||
                  state.status == MemberProfileStatus.initial) &&
              state.profile == null) {
            return const _MemberProfileSkeleton();
          }

          if (state.status == MemberProfileStatus.notAccessible) {
            return StatePanel(
              icon: Icons.lock_outline_rounded,
              title: ArabicStrings.profileNotAccessible,
              message: ArabicStrings.profileNotAccessible,
              isError: true,
            );
          }

          if (state.status == MemberProfileStatus.offline &&
              state.profile == null) {
            return StatePanel(
              icon: Icons.cloud_off_rounded,
              title: ArabicStrings.networkFailure,
              message: ArabicStrings.networkFailure,
              actionLabel: ArabicStrings.retry,
              onAction: () => context.read<MemberProfileCubit>().load(
                widget.userId,
                widget.groupId,
              ),
              isError: true,
            );
          }

          if (state.profile == null) {
            return StatePanel(
              icon: Icons.error_outline_rounded,
              title: ArabicStrings.operationFailed,
              message: ArabicStrings.errorMessage(state.failure?.code ?? ''),
              actionLabel: ArabicStrings.retry,
              onAction: () => context.read<MemberProfileCubit>().load(
                widget.userId,
                widget.groupId,
              ),
              isError: true,
            );
          }

          final profile = state.profile!;
          final initials =
              (profile.initials != null && profile.initials!.isNotEmpty)
              ? profile.initials!
              : displayInitials(profile.displayName);

          return RefreshIndicator(
            onRefresh: () => context.read<MemberProfileCubit>().refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.screen,
              child: Align(
                alignment: AlignmentDirectional.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.status == MemberProfileStatus.offline)
                        const OfflineBanner(
                          message: ArabicStrings.networkFailure,
                        ),
                      if (state.status == MemberProfileStatus.failure) ...[
                        Text(
                          ArabicStrings.errorMessage(state.failure?.code ?? ''),
                          style: AppTypography.body.copyWith(
                            color: colors.danger,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => context
                              .read<MemberProfileCubit>()
                              .load(widget.userId, widget.groupId),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text(ArabicStrings.retry),
                        ),
                      ],
                      // Header card with avatar & basic info
                      AppCard(
                        padding: AppSpacing.card,
                        child: Column(
                          children: [
                            UserAvatar(
                              initials: initials,
                              avatarKey: profile.avatarKey,
                              size: 72,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              profile.displayName,
                              style: AppTypography.headline,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: AppSpacing.xs,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.primaryContainer,
                                    borderRadius: AppRadius.smBR,
                                  ),
                                  child: Text(
                                    _roleLabel(profile.role),
                                    style: AppTypography.caption.copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (profile.seatNumber != null)
                                  Text(
                                    ArabicStrings.historySeat(
                                      ArabicNumerals.format(
                                        profile.seatNumber!,
                                      ),
                                    ),
                                    style: AppTypography.caption.copyWith(
                                      color: colors.inkMuted,
                                    ),
                                  ),
                              ],
                            ),
                            if (profile.bio != null &&
                                profile.bio!.trim().isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                profile.bio!,
                                style: AppTypography.body,
                                textAlign: TextAlign.center,
                              ),
                            ] else ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                ArabicStrings.noBio,
                                style: AppTypography.caption.copyWith(
                                  color: colors.inkMuted,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${ArabicStrings.memberSince} ${ArabicNumerals.format(profile.memberSince.year)}/${ArabicNumerals.format(profile.memberSince.month)}/${ArabicNumerals.format(profile.memberSince.day)}',
                              style: AppTypography.caption.copyWith(
                                color: colors.inkMuted,
                              ),
                            ),
                            if (profile.isMe) ...[
                              const SizedBox(height: AppSpacing.md),
                              AppButton(
                                label: ArabicStrings.editProfile,
                                icon: const Icon(Icons.edit_rounded),
                                variant: AppButtonVariant.secondary,
                                onPressed: () async {
                                  await Navigator.pushNamed(
                                    context,
                                    AppRoutes.editMyProfile,
                                  );
                                  if (context.mounted) {
                                    context
                                        .read<MemberProfileCubit>()
                                        .refresh();
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Metrics Cards
                      Row(
                        children: [
                          Expanded(
                            child: AppCard(
                              padding: AppSpacing.compactCard,
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.local_fire_department_rounded,
                                    size: 20,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    ArabicStrings.currentStreak,
                                    style: AppTypography.caption.copyWith(
                                      color: colors.inkMuted,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    ArabicStrings.streakDays(
                                      profile.currentStreak,
                                    ),
                                    style: AppTypography.title,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: AppCard(
                              padding: AppSpacing.compactCard,
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.donut_large_rounded,
                                    size: 20,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    ArabicStrings.completionRate,
                                    style: AppTypography.caption.copyWith(
                                      color: colors.inkMuted,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    ArabicStrings.completionPercentage(
                                      profile.completionRate ?? 0,
                                    ),
                                    style: AppTypography.title,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: AppCard(
                              padding: AppSpacing.compactCard,
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.auto_stories_rounded,
                                    size: 20,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    ArabicStrings.portionsRead,
                                    style: AppTypography.caption.copyWith(
                                      color: colors.inkMuted,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    ArabicNumerals.format(profile.portionsRead),
                                    style: AppTypography.title,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Recent Days Section
                      const AppSectionHeader(title: ArabicStrings.recentDays),
                      const SizedBox(height: AppSpacing.xs),
                      if (profile.recentDays.isEmpty)
                        AppCard(
                          padding: AppSpacing.card,
                          child: Center(
                            child: Text(
                              ArabicStrings.noAssignmentToday,
                              style: AppTypography.caption.copyWith(
                                color: colors.inkMuted,
                              ),
                            ),
                          ),
                        )
                      else
                        for (final day in profile.recentDays)
                          Container(
                            margin: const EdgeInsetsDirectional.only(
                              bottom: AppSpacing.xs,
                            ),
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: AppRadius.smBR,
                              border: Border.all(color: colors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ArabicStrings.portionName(
                                          PortionUnit.juz,
                                          day.portionIndex,
                                        ),
                                        style: AppTypography.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      Wrap(
                                        spacing: AppSpacing.xs,
                                        runSpacing: AppSpacing.xxs,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            ArabicNumerals.format(
                                              day.groupDate,
                                            ),
                                            style: AppTypography.caption
                                                .copyWith(
                                                  color: colors.inkMuted,
                                                ),
                                          ),
                                          if (day.kind ==
                                              AssignmentKind.volunteer)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: colors.primaryContainer,
                                                borderRadius: AppRadius.smBR,
                                              ),
                                              child: Text(
                                                ArabicStrings.tagVolunteer,
                                                style: AppTypography.caption
                                                    .copyWith(
                                                      color: colors.primary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                StatusChip(status: _toDesignStatus(day.status)),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MemberProfileSkeleton extends StatelessWidget {
  const _MemberProfileSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: AppSpacing.screen,
    children: const [
      SkeletonBox(height: 240),
      SizedBox(height: AppSpacing.lg),
      SkeletonBox(height: 112),
      SizedBox(height: AppSpacing.lg),
      SkeletonBox(height: 184),
    ],
  );
}
