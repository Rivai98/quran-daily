import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/router.dart';
import '../../../core/design_system/app_button.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/widgets/app_card.dart';
import '../../../core/design_system/widgets/app_page_content.dart';
import '../../../core/design_system/widgets/confirm_sheet.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/localization/arabic_numerals.dart';
import '../../../core/localization/arabic_strings.dart';
import '../../reminders/cubit/reminders_cubit.dart';
import '../../reminders/view/reminder_settings_section.dart';
import '../../mushaf/cubit/mushaf_font_download_cubit.dart';
import '../../mushaf/view/mushaf_font_download_section.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.cubit});

  final SettingsCubit? cubit;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<SettingsCubit>.value(
        value: cubit!,
        child: const _SettingsView(),
      );
    }
    return BlocProvider<SettingsCubit>(
      create: (_) => serviceLocator<SettingsCubit>()..loadSettings(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  void _onSignOut(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    ConfirmSheet.show(
      context,
      title: ArabicStrings.signOutConfirmTitle,
      message: ArabicStrings.signOutConfirmMessage,
      confirmLabel: ArabicStrings.signOut,
      destructive: true,
      onConfirm: () => cubit.signOut(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.settingsTitle)),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listener: (context, state) {
          if (state.status == SettingsStatus.signedOut) {
            resetToGate();
          } else if (state.status == SettingsStatus.failure &&
              state.failure != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.failure!.message)));
          }
        },
        builder: (context, state) {
          final cubit = context.read<SettingsCubit>();
          final percentLabel = ArabicNumerals.percent(
            (state.quranTextScale * 100).round(),
          );

          return AppPageContent(
            child: ListView(
              padding: AppSpacing.screenContent,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ArabicStrings.quranTextSizeTitle,
                        style: AppTypography.title,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(percentLabel, style: AppTypography.label),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Slider(
                  value: state.quranTextScale,
                  min: SettingsCubit.minQuranTextScale,
                  max: SettingsCubit.maxQuranTextScale,
                  divisions: 15,
                  label: percentLabel,
                  onChanged: (val) => cubit.setQuranTextScale(val),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Center(
                    child: Text(
                      ArabicStrings.quranPreviewText,
                      style: AppTypography.quranLabel,
                      textScaler: TextScaler.linear(state.quranTextScale),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                if (serviceLocator.isRegistered<MushafFontDownloadCubit>()) ...[
                  const SizedBox(height: AppSpacing.lg),
                  BlocProvider<MushafFontDownloadCubit>(
                    create: (_) =>
                        serviceLocator<MushafFontDownloadCubit>()..load(),
                    child: const MushafFontDownloadSection(),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  padding: AppSpacing.card,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 28),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ArabicStrings.myProfileTitle,
                                  style: AppTypography.title,
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  ArabicStrings.editProfile,
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: ArabicStrings.editProfile,
                        variant: AppButtonVariant.secondary,
                        expanded: true,
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.editMyProfile,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (serviceLocator.isRegistered<RemindersCubit>()) ...[
                  BlocProvider<RemindersCubit>(
                    create: (_) =>
                        serviceLocator<RemindersCubit>()
                          ..loadPersonalSettings(),
                    child: const ReminderSettingsSection(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                if (state.isAdmin) ...[
                  AppButton(
                    label: ArabicStrings.adminEntry,
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    variant: AppButtonVariant.secondary,
                    expanded: true,
                    onPressed: () => Navigator.of(context).pushNamed('/admin'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                AppButton(
                  label: ArabicStrings.signOut,
                  icon: const Icon(Icons.logout),
                  variant: AppButtonVariant.secondary,
                  expanded: true,
                  loading: state.status == SettingsStatus.signingOut,
                  onPressed: state.status == SettingsStatus.signingOut
                      ? null
                      : () => _onSignOut(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
