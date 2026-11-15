import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/router.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/widgets/app_page_content.dart';
import '../../../../core/design_system/widgets/app_section_header.dart';
import '../../../../core/design_system/widgets/offline_banner.dart';
import '../../../../core/design_system/widgets/state_panel.dart';
import '../../../../core/design_system/widgets/confirm_sheet.dart';
import '../../../../core/design_system/widgets/app_snack_bar.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import 'widgets/profile_badges_grid.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_khatmas_list.dart';
import 'widgets/profile_navigation_tile.dart';
import 'widgets/profile_streak_card.dart';
import 'widgets/profile_totals_card.dart';
import '../../settings/cubit/settings_cubit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final cubit = context.read<ProfileCubit>();
        if (cubit.state.status == ProfileStatus.initial) {
          cubit.load();
        }
      }
    });
  }

  Future<void> _openRoute(BuildContext context, String routeName) async {
    final cubit = context.read<ProfileCubit>();
    final changed = await Navigator.of(context).pushNamed<Object?>(routeName);
    // Edited name/avatar (or settings) must show at once on return.
    if (changed == true && !cubit.isClosed) await cubit.refresh();
  }

  void _confirmSignOut(BuildContext context) {
    ConfirmSheet.show(
      context,
      title: ArabicStrings.signOutConfirmTitle,
      message: ArabicStrings.signOutConfirmMessage,
      confirmLabel: ArabicStrings.signOut,
      destructive: true,
      onConfirm: () async {
        final result = await serviceLocator<SettingsCubit>().signOut();
        if (context.mounted) {
          if (result) {
            resetToGate();
          } else {
            AppSnackBar.show(context, ArabicStrings.operationFailed);
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.profileTitle)),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state.status == ProfileStatus.loading && state.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == ProfileStatus.failure && state.profile == null) {
            return StatePanel(
              icon: Icons.error_outline,
              title: ArabicStrings.profileLoadError,
              message: ArabicStrings.operationFailed,
              actionLabel: ArabicStrings.retry,
              onAction: () => context.read<ProfileCubit>().load(),
            );
          }

          final profile = state.profile;
          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => context.read<ProfileCubit>().refresh(),
            child: AppPageContent(
              child: ListView(
                padding: AppSpacing.screenContent,
                children: [
                  if (state.isStale) ...[
                    const OfflineBanner(message: ArabicStrings.offlineStale),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  ProfileHeader(
                    displayName: profile.displayName,
                    avatarKey: profile.avatarKey,
                    memberSince: profile.memberSince,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const AppSectionHeader(
                    title: ArabicStrings.profileStreakSection,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ProfileStreakCard(
                    streak: profile.streak,
                    bestStreak: profile.bestStreak,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const AppSectionHeader(
                    title: ArabicStrings.profileTotalsSection,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ProfileTotalsCard(
                    portionsRead: profile.portionsRead,
                    portionsLate: profile.portionsLate,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const AppSectionHeader(
                    title: ArabicStrings.profileKhatmasSection,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ProfileKhatmasList(khatmas: profile.khatmas),
                  const SizedBox(height: AppSpacing.lg),
                  const AppSectionHeader(
                    title: ArabicStrings.profileBadgesSection,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ProfileBadgesGrid(
                    badges: profile.badges,
                    bestStreak: profile.bestStreak,
                    portionsRead: profile.portionsRead,
                    khatmasCompleted: profile.khatmas.fold(
                      0,
                      (sum, item) => sum + item.completed,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const AppSectionHeader(
                    title: ArabicStrings.profileQuickLinksSection,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ProfileNavigationTile(
                    icon: Icons.person_outline,
                    title: ArabicStrings.myProfileTitle,
                    onTap: () => _openRoute(context, AppRoutes.editMyProfile),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ProfileNavigationTile(
                    icon: Icons.calendar_today_outlined,
                    title: ArabicStrings.profileLogNavigation,
                    onTap: () => _openRoute(context, AppRoutes.log),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ProfileNavigationTile(
                    icon: Icons.settings_outlined,
                    title: ArabicStrings.profileSettingsNavigation,
                    onTap: () => _openRoute(context, AppRoutes.settings),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: ArabicStrings.signOut,
                    icon: const Icon(Icons.logout_rounded),
                    variant: AppButtonVariant.secondary,
                    expanded: true,
                    onPressed: () => _confirmSignOut(context),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
