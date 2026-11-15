import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design_system/app_button.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/widgets/app_card.dart';
import '../../../core/design_system/widgets/app_snack_bar.dart';
import '../../../core/localization/arabic_numerals.dart';
import '../../../core/localization/arabic_strings.dart';
import '../cubit/reminders_cubit.dart';
import '../domain/reminder_planner.dart';

/// Owner schedule editor and device-local member mute controls.
class GroupReminderSection extends StatefulWidget {
  const GroupReminderSection({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.isOwner,
  });
  final String groupId;
  final String groupName;
  final bool isOwner;

  @override
  State<GroupReminderSection> createState() => _GroupReminderSectionState();
}

class _GroupReminderSectionState extends State<GroupReminderSection> {
  late bool _fajrOn = true;
  late bool _asrOn = true;
  late bool _nightOn = true;
  late int _fajrOffset = 20;
  late int _asrOffset = 20;
  late String _nightTime = '22:30';
  late String? _message;
  late final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cubit = context.read<RemindersCubit>();
    cubit.loadGroupSchedule(widget.groupId);
    cubit.loadGroupMute(widget.groupId);
    for (final slot in ReminderSlot.values) {
      cubit.loadMute(widget.groupId, slot);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _applySchedule(GroupReminderSchedule schedule) {
    _fajrOn = schedule.fajrOn;
    _asrOn = schedule.asrOn;
    _nightOn = schedule.nightOn;
    _fajrOffset = schedule.fajrOffsetMinutes;
    _asrOffset = schedule.asrOffsetMinutes;
    _nightTime = schedule.nightTime;
    _message = schedule.message;
    _messageController.text = schedule.message ?? '';
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<RemindersCubit, RemindersState>(
    listenWhen: (previous, current) =>
        previous.groupSchedule != current.groupSchedule ||
        (current.status == RemindersStatus.failure &&
            previous.status != RemindersStatus.failure),
    listener: (context, state) {
      if (state.status == RemindersStatus.failure) {
        AppSnackBar.show(
          context,
          state.failureMessage == 'load'
              ? ArabicStrings.reminderLoadFailed
              : ArabicStrings.reminderSaveFailed,
        );
        return;
      }
      final schedule = state.groupSchedule;
      if (widget.isOwner && schedule != null) {
        setState(() => _applySchedule(schedule));
      }
    },
    builder: (context, state) {
      final cubit = context.read<RemindersCubit>();
      return AppCard(
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ArabicStrings.reminderGroupTitle,
                style: AppTypography.title,
              ),
              if (widget.isOwner) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.wb_twilight_rounded),
                  title: const Text(ArabicStrings.reminderFajr),
                  value: _fajrOn,
                  onChanged: (v) => setState(() => _fajrOn = v),
                ),
                if (_fajrOn)
                  _offsetControl(
                    ArabicStrings.reminderOffset,
                    _fajrOffset,
                    (v) => setState(() => _fajrOffset = v),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.wb_sunny_outlined),
                  title: const Text(ArabicStrings.reminderAsr),
                  value: _asrOn,
                  onChanged: (v) => setState(() => _asrOn = v),
                ),
                if (_asrOn)
                  _offsetControl(
                    ArabicStrings.reminderOffset,
                    _asrOffset,
                    (v) => setState(() => _asrOffset = v),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.nightlight_outlined),
                  title: const Text(ArabicStrings.reminderNight),
                  value: _nightOn,
                  onChanged: (v) => setState(() => _nightOn = v),
                ),
                if (_nightOn)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(ArabicStrings.reminderNightTime),
                    subtitle: Text(ArabicNumerals.format(_nightTime)),
                    onTap: () async {
                      final p = _nightTime.split(':');
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: int.parse(p[0]),
                          minute: int.parse(p[1]),
                        ),
                      );
                      if (time != null) {
                        setState(
                          () => _nightTime =
                              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                        );
                      }
                    },
                  ),
                TextField(
                  controller: _messageController,
                  maxLength: 80,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    labelText: ArabicStrings.reminderGroupMessage,
                    helperText: ArabicStrings.reminderMessageLimit,
                  ),
                  onChanged: (value) =>
                      _message = value.trim().isEmpty ? null : value.trim(),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: ArabicStrings.reminderSave,
                  variant: AppButtonVariant.tonal,
                  onPressed: state.status == RemindersStatus.saving
                      ? null
                      : () => cubit.saveGroupSchedule(
                          GroupReminderSchedule(
                            groupId: widget.groupId,
                            groupName: widget.groupName,
                            fajrOn: _fajrOn,
                            fajrOffsetMinutes: _fajrOffset,
                            asrOn: _asrOn,
                            asrOffsetMinutes: _asrOffset,
                            nightOn: _nightOn,
                            nightTime: _nightTime,
                            message: _message,
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  ArabicStrings.reminderOwnerOnly,
                  style: AppTypography.caption,
                ),
              ] else ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(ArabicStrings.reminderMuteGroup),
                  value: state.groupMuted,
                  onChanged: (value) =>
                      cubit.setGroupMuted(widget.groupId, value),
                ),
                for (final slot in ReminderSlot.values)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_slotName(slot)),
                    subtitle: const Text(ArabicStrings.reminderMute),
                    value:
                        state.mutes['${widget.groupId}:${slot.name}'] ?? false,
                    onChanged: (value) =>
                        cubit.setMuted(widget.groupId, slot, value),
                  ),
              ],
            ],
          ),
        ),
      );
    },
  );

  Widget _offsetControl(String title, int value, ValueChanged<int> changed) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: ${ArabicNumerals.format(value)}',
            style: AppTypography.caption,
          ),
          Slider(
            value: value.toDouble(),
            min: 0,
            max: 180,
            divisions: 36,
            onChanged: (v) => changed(v.round()),
          ),
        ],
      );

  String _slotName(ReminderSlot slot) => switch (slot) {
    ReminderSlot.fajr => ArabicStrings.reminderFajr,
    ReminderSlot.asr => ArabicStrings.reminderAsr,
    ReminderSlot.night => ArabicStrings.reminderNight,
  };
}
