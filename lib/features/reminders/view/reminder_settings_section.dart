import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/widgets/app_card.dart';
import '../../../core/design_system/widgets/app_snack_bar.dart';
import '../../../core/localization/arabic_numerals.dart';
import '../../../core/localization/arabic_strings.dart';
import '../cubit/reminders_cubit.dart';
import '../domain/reminder_planner.dart';

class ReminderSettingsSection extends StatelessWidget {
  const ReminderSettingsSection({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<RemindersCubit, RemindersState>(
    listenWhen: (previous, current) =>
        current.status == RemindersStatus.failure &&
        previous.status != RemindersStatus.failure,
    listener: (context, state) => AppSnackBar.show(
      context,
      state.failureMessage == 'load'
          ? ArabicStrings.reminderLoadFailed
          : ArabicStrings.reminderSaveFailed,
    ),
    builder: (context, state) {
      final cubit = context.read<RemindersCubit>();
      final current = state.personalSettings;
      PersonalReminderSettings updated({
        bool? enabled,
        bool? fajrEnabled,
        bool? asrEnabled,
        bool? nightEnabled,
        int? fajrOffsetMinutes,
        int? asrOffsetMinutes,
        String? nightTime,
        String? calculationMethod,
        String? cityName,
        double? latitude,
        double? longitude,
      }) => PersonalReminderSettings(
        enabled: enabled ?? current.enabled,
        fajrEnabled: fajrEnabled ?? current.fajrEnabled,
        asrEnabled: asrEnabled ?? current.asrEnabled,
        nightEnabled: nightEnabled ?? current.nightEnabled,
        fajrOffsetMinutes: fajrOffsetMinutes ?? current.fajrOffsetMinutes,
        asrOffsetMinutes: asrOffsetMinutes ?? current.asrOffsetMinutes,
        nightTime: nightTime ?? current.nightTime,
        calculationMethod: calculationMethod ?? current.calculationMethod,
        cityName: cityName ?? current.cityName,
        latitude: latitude ?? current.latitude,
        longitude: longitude ?? current.longitude,
      );
      void save(PersonalReminderSettings value) =>
          cubit.savePersonalSettings(value);

      return AppCard(
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_active_outlined, size: 24),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      ArabicStrings.remindersTitle,
                      style: AppTypography.title,
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.notifications_active_outlined),
                title: const Text(ArabicStrings.reminderActivate),
                value: current.enabled,
                onChanged: (value) =>
                    _setReminderEnabled(context, cubit, updated, value),
              ),
              if (current.enabled) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.wb_twilight_rounded),
                  title: const Text(ArabicStrings.reminderFajr),
                  value: current.fajrEnabled,
                  onChanged: (value) => save(updated(fajrEnabled: value)),
                ),
                if (current.fajrEnabled)
                  _offsetControl(
                    label: ArabicStrings.reminderOffset,
                    value: current.fajrOffsetMinutes,
                    onChanged: (value) =>
                        save(updated(fajrOffsetMinutes: value)),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.wb_sunny_outlined),
                  title: const Text(ArabicStrings.reminderAsr),
                  value: current.asrEnabled,
                  onChanged: (value) => save(updated(asrEnabled: value)),
                ),
                if (current.asrEnabled)
                  _offsetControl(
                    label: ArabicStrings.reminderOffset,
                    value: current.asrOffsetMinutes,
                    onChanged: (value) =>
                        save(updated(asrOffsetMinutes: value)),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.nightlight_outlined),
                  title: const Text(ArabicStrings.reminderNight),
                  value: current.nightEnabled,
                  onChanged: (value) => save(updated(nightEnabled: value)),
                ),
                if (current.nightEnabled)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(ArabicStrings.reminderNightTime),
                    subtitle: Text(ArabicNumerals.format(current.nightTime)),
                    onTap: () async {
                      final parts = current.nightTime.split(':');
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: int.tryParse(parts.first) ?? 22,
                          minute: int.tryParse(parts.last) ?? 30,
                        ),
                      );
                      if (picked != null) {
                        save(
                          updated(
                            nightTime:
                                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
                          ),
                        );
                      }
                    },
                  ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: current.calculationMethod,
                  decoration: const InputDecoration(
                    labelText: ArabicStrings.reminderCalculationMethod,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'egyptian',
                      child: Text(ArabicStrings.reminderEgyptMethod),
                    ),
                    DropdownMenuItem(
                      value: 'umm_al_qura',
                      child: Text(ArabicStrings.reminderUmmAlQuraMethod),
                    ),
                    DropdownMenuItem(
                      value: 'muslim_world_league',
                      child: Text(ArabicStrings.reminderMwlMethod),
                    ),
                    DropdownMenuItem(
                      value: 'karachi',
                      child: Text(ArabicStrings.reminderKarachiMethod),
                    ),
                    DropdownMenuItem(
                      value: 'north_america',
                      child: Text(ArabicStrings.reminderIsnaMethod),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) save(updated(calculationMethod: value));
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _cityCoordinates.containsKey(current.cityName)
                      ? current.cityName
                      : ArabicStrings.cityCairo,
                  decoration: const InputDecoration(
                    labelText: ArabicStrings.reminderLocation,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ArabicStrings.cityCairo,
                      child: Text(ArabicStrings.cityCairo),
                    ),
                    DropdownMenuItem(
                      value: ArabicStrings.cityAlexandria,
                      child: Text(ArabicStrings.cityAlexandria),
                    ),
                    DropdownMenuItem(
                      value: ArabicStrings.cityMakkah,
                      child: Text(ArabicStrings.cityMakkah),
                    ),
                    DropdownMenuItem(
                      value: ArabicStrings.cityMadinah,
                      child: Text(ArabicStrings.cityMadinah),
                    ),
                    DropdownMenuItem(
                      value: ArabicStrings.cityRiyadh,
                      child: Text(ArabicStrings.cityRiyadh),
                    ),
                    DropdownMenuItem(
                      value: ArabicStrings.cityAmman,
                      child: Text(ArabicStrings.cityAmman),
                    ),
                    DropdownMenuItem(
                      value: ArabicStrings.cityJerusalem,
                      child: Text(ArabicStrings.cityJerusalem),
                    ),
                    DropdownMenuItem(
                      value: ArabicStrings.cityDoha,
                      child: Text(ArabicStrings.cityDoha),
                    ),
                    DropdownMenuItem(
                      value: ArabicStrings.cityDubai,
                      child: Text(ArabicStrings.cityDubai),
                    ),
                    DropdownMenuItem(
                      value: ArabicStrings.cityKuwait,
                      child: Text(ArabicStrings.cityKuwait),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    final point = _cityCoordinates[value]!;
                    save(
                      updated(
                        cityName: value,
                        latitude: point.$1,
                        longitude: point.$2,
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => _sendTestNotification(context, cubit),
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text(ArabicStrings.reminderTest),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );

  Future<void> _sendTestNotification(
    BuildContext context,
    RemindersCubit cubit,
  ) async {
    final granted = await _requestNotificationPermission(context, cubit);
    if (granted) await cubit.sendTestNotification();
  }

  Future<void> _setReminderEnabled(
    BuildContext context,
    RemindersCubit cubit,
    PersonalReminderSettings Function({
      bool? enabled,
      bool? fajrEnabled,
      bool? asrEnabled,
      bool? nightEnabled,
      int? fajrOffsetMinutes,
      int? asrOffsetMinutes,
      String? nightTime,
      String? calculationMethod,
      String? cityName,
      double? latitude,
      double? longitude,
    })
    updated,
    bool enabled,
  ) async {
    if (!enabled) {
      await cubit.savePersonalSettings(updated(enabled: false));
      return;
    }
    if (await _requestNotificationPermission(context, cubit)) {
      await cubit.savePersonalSettings(updated(enabled: true));
    }
  }

  Future<bool> _requestNotificationPermission(
    BuildContext context,
    RemindersCubit cubit,
  ) async {
    final continueToPermission = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(ArabicStrings.reminderPermissionTitle),
        content: const Text(ArabicStrings.reminderPermissionExplain),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(ArabicStrings.reminderPermissionLater),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(ArabicStrings.reminderPermissionContinue),
          ),
        ],
      ),
    );
    if (continueToPermission != true || !context.mounted) return false;
    final granted = await cubit.requestNotificationPermission();
    if (!context.mounted) return false;
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(ArabicStrings.reminderPermissionDenied)),
      );
      return false;
    }
    return true;
  }

  Widget _offsetControl({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$label: ${ArabicNumerals.format(value)}',
        style: AppTypography.caption,
      ),
      Slider(
        value: value.toDouble(),
        min: 0,
        max: 120,
        divisions: 24,
        onChanged: (v) => onChanged(v.round()),
      ),
    ],
  );

  static const _cityCoordinates = <String, (double, double)>{
    ArabicStrings.cityCairo: (30.0444, 31.2357),
    ArabicStrings.cityAlexandria: (31.2001, 29.9187),
    ArabicStrings.cityMakkah: (21.3891, 39.8579),
    ArabicStrings.cityMadinah: (24.5247, 39.5692),
    ArabicStrings.cityRiyadh: (24.7136, 46.6753),
    ArabicStrings.cityAmman: (31.9539, 35.9106),
    ArabicStrings.cityJerusalem: (31.7683, 35.2137),
    ArabicStrings.cityDoha: (25.2854, 51.5310),
    ArabicStrings.cityDubai: (25.2048, 55.2708),
    ArabicStrings.cityKuwait: (29.3759, 47.9774),
  };
}
