import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/app_button.dart';
import '../../../core/design_system/widgets/halaqa_logo.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/localization/arabic_strings.dart';
import '../data/notification_scheduler.dart';
import '../data/reminder_planning_service.dart';
import '../data/reminders_repository.dart';
import '../domain/reminder_planner.dart';

/// First-run notification onboarding: once per install, after sign-in, explain
/// the daily reminders and ask the system permission. If granted, the default
/// reminders (after Fajr, after Asr, night 22:30) are switched on.
class NotificationOnboarding {
  const NotificationOnboarding._();

  static const _shownKey = 'notification_onboarding_shown_v1';
  static bool _checking = false;

  static Future<void> maybeAsk(BuildContext context) async {
    if (_checking) return;
    _checking = true;
    try {
      final prefs = SharedPreferencesAsync();
      if (await prefs.getBool(_shownKey) ?? false) return;
      if (!serviceLocator.isRegistered<NotificationScheduler>() ||
          !serviceLocator.isRegistered<RemindersRepository>()) {
        return;
      }
      if (!context.mounted) return;
      final allow = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => const _OnboardingSheet(),
      );
      await prefs.setBool(_shownKey, true);
      if (allow != true) return;
      final granted =
          await serviceLocator<NotificationScheduler>().requestPermissions() ??
          false;
      if (!granted) return;
      final repository = serviceLocator<RemindersRepository>();
      final current = await repository.loadPersonalSettings();
      await repository.savePersonalSettings(
        PersonalReminderSettings(
          fajrEnabled: current.fajrEnabled,
          asrEnabled: current.asrEnabled,
          nightEnabled: current.nightEnabled,
          fajrOffsetMinutes: current.fajrOffsetMinutes,
          asrOffsetMinutes: current.asrOffsetMinutes,
          nightTime: current.nightTime,
          calculationMethod: current.calculationMethod,
          cityName: current.cityName,
          latitude: current.latitude,
          longitude: current.longitude,
          enabled: true,
        ),
      );
      if (serviceLocator.isRegistered<ReminderPlanningService>()) {
        await serviceLocator<ReminderPlanningService>().refresh();
      }
    } on Object {
      // Onboarding must never block or crash the app.
    } finally {
      _checking = false;
    }
  }
}

class _OnboardingSheet extends StatelessWidget {
  const _OnboardingSheet();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    Widget row(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTypography.body)),
        ],
      ),
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: HalaqaLogo(size: 72)),
            const SizedBox(height: AppSpacing.md),
            Text(
              ArabicStrings.reminderOnboardingTitle,
              textAlign: TextAlign.center,
              style: AppTypography.headline,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              ArabicStrings.reminderOnboardingExplain,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: colors.inkMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            row(Icons.wb_twilight_rounded, ArabicStrings.reminderOnboardingFajr),
            row(Icons.wb_sunny_rounded, ArabicStrings.reminderOnboardingAsr),
            row(
              Icons.nights_stay_rounded,
              ArabicStrings.reminderOnboardingNight,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              ArabicStrings.reminderOnboardingSettings,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: colors.inkMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              expanded: true,
              icon: const Icon(Icons.notifications_active_rounded),
              label: ArabicStrings.reminderOnboardingAllow,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              expanded: true,
              variant: AppButtonVariant.text,
              label: ArabicStrings.reminderPermissionLater,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
