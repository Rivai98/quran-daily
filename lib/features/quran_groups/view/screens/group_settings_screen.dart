import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/app_section_header.dart';
import '../../../../core/design_system/widgets/confirm_sheet.dart';
import '../../../../core/design_system/widgets/state_panel.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/localization/arabic_numerals.dart';
import '../../../../core/quran/portion_unit.dart';
import '../../cubit/group_settings/group_settings_cubit.dart';

/// S9 group settings (ui-contract): edit fields (owner), timezone/start
/// note, invite code + share (all active members), regenerate (owner,
/// confirm), archive (owner, confirm).
class GroupSettingsScreen extends StatelessWidget {
  const GroupSettingsScreen({
    super.key,
    required this.groupId,
    required this.isOwner,
    this.inviteCode,
    this.portionUnit = PortionUnit.juz,
    this.isActive = true,
    required this.onKhatmaStarted,
  });

  final String groupId;
  final bool isOwner;
  final String? inviteCode;
  final PortionUnit portionUnit;
  final bool isActive;
  final VoidCallback onKhatmaStarted;

  @override
  Widget build(BuildContext context) {
    if (!isOwner) {
      return Scaffold(
        appBar: AppBar(title: const Text(ArabicStrings.settingsTitle)),
        body: StatePanel(
          icon: Icons.lock_outline,
          title: ArabicStrings.roleMember,
          message: ArabicStrings.settingsApplyTomorrowNote,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.settingsTitle)),
      body: BlocConsumer<GroupSettingsCubit, GroupSettingsState>(
        listener: (context, state) {
          if (state.status == GroupSettingsStatus.started) {
            onKhatmaStarted();
          }
        },
        builder: (context, state) {
          final code = state.inviteCode ?? inviteCode;
          return _SettingsForm(
            groupId: groupId,
            inviteCode: code,
            portionUnit: portionUnit,
            isActive: isActive,
            submitting: state.status == GroupSettingsStatus.submitting,
            failure: state.failure,
          );
        },
      ),
    );
  }
}

class _SettingsForm extends StatelessWidget {
  const _SettingsForm({
    required this.groupId,
    required this.inviteCode,
    required this.submitting,
    required this.failure,
    required this.portionUnit,
    required this.isActive,
  });

  final String groupId;
  final String? inviteCode;
  final bool submitting;
  final AppFailure? failure;
  final PortionUnit portionUnit;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final cubit = context.read<GroupSettingsCubit>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    return ListView(
      padding: AppSpacing.screen,
      children: [
        if (failure != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: ShapeDecoration(
              color: colors.missedBg,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.mdBR,
                side: BorderSide(color: colors.danger.withValues(alpha: 0.3)),
              ),
            ),
            child: Text(
              ArabicStrings.authError(failure!.code),
              style: AppTypography.caption.copyWith(color: colors.danger),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppCard(
          child: Padding(
            padding: AppSpacing.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ArabicStrings.inviteCodeLabel, style: AppTypography.label),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ArabicNumerals.format(inviteCode ?? '--------'),
                        style: AppTypography.bodyLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AppButton(
                      label: ArabicStrings.shareInviteAction,
                      variant: AppButtonVariant.tonal,
                      onPressed: () => SharePlus.instance.share(
                        ShareParams(
                          text:
                              '${ArabicStrings.inviteShareMessage}$inviteCode'
                              ' — qurandaily://join/$inviteCode',
                        ),
                      ),
                      icon: const Icon(Icons.share),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: ArabicStrings.regenerateInviteAction,
                  variant: AppButtonVariant.secondary,
                  onPressed: submitting
                      ? null
                      : () => ConfirmSheet.show(
                          context,
                          title: ArabicStrings.regenerateInviteTitle,
                          message: ArabicStrings.regenerateInviteMessage,
                          confirmLabel: ArabicStrings.regenerateInviteConfirm,
                          onConfirm: () => cubit.regenerateInvite(),
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSectionHeader(title: ArabicStrings.settingsTitle),
              TextField(
                controller: nameController,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: ArabicStrings.groupNameLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: descriptionController,
                textDirection: TextDirection.rtl,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: ArabicStrings.shortDescriptionLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                ArabicStrings.settingsApplyTomorrowNote,
                style: AppTypography.caption.copyWith(color: colors.inkMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _PortionUnitSetting(
          current: portionUnit,
          isActive: isActive,
          submitting: submitting,
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: ArabicStrings.save,
          variant: AppButtonVariant.primary,
          expanded: true,
          loading: submitting,
          onPressed: submitting
              ? null
              : () => cubit.saveSettings(
                  name: nameController.text.trim().isEmpty
                      ? null
                      : nameController.text.trim(),
                  shortDescription: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: ArabicStrings.archiveGroupAction,
          variant: AppButtonVariant.secondary,
          expanded: true,
          onPressed: submitting
              ? null
              : () => ConfirmSheet.show(
                  context,
                  title: ArabicStrings.archiveGroupTitle,
                  message: ArabicStrings.archiveGroupMessage,
                  confirmLabel: ArabicStrings.archiveGroupConfirm,
                  onConfirm: () => cubit.archiveGroup(),
                ),
          icon: const Icon(Icons.archive_outlined),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _PortionUnitSetting extends StatefulWidget {
  const _PortionUnitSetting({
    required this.current,
    required this.isActive,
    required this.submitting,
  });
  final PortionUnit current;
  final bool isActive;
  final bool submitting;
  @override
  State<_PortionUnitSetting> createState() => _PortionUnitSettingState();
}

class _PortionUnitSettingState extends State<_PortionUnitSetting> {
  late PortionUnit _selected = widget.current;
  @override
  void didUpdateWidget(covariant _PortionUnitSetting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current) _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DropdownButtonFormField<PortionUnit>(
        initialValue: _selected,
        decoration: InputDecoration(
          labelText: ArabicStrings.portionSelectorTitle,
        ),
        items: [
          for (final unit in PortionUnit.values)
            DropdownMenuItem(
              value: unit,
              child: Text(ArabicStrings.portionUnitName(unit)),
            ),
        ],
        onChanged: widget.submitting
            ? null
            : (value) {
                if (value != null) setState(() => _selected = value);
              },
      ),
      const SizedBox(height: AppSpacing.xs),
      AppButton(
        label: ArabicStrings.confirmPortionChange,
        variant: AppButtonVariant.tonal,
        onPressed: widget.submitting || _selected == widget.current
            ? null
            : () => ConfirmSheet.show(
                context,
                title: ArabicStrings.confirmPortionChange,
                message: widget.isActive
                    ? ArabicStrings.portionChangeAppliesNextCycle
                    : ArabicStrings.portionChangeAppliesImmediately,
                confirmLabel: ArabicStrings.confirmPortionChange,
                onConfirm: () => context
                    .read<GroupSettingsCubit>()
                    .saveSettings(portionUnit: _selected),
              ),
      ),
    ],
  );
}
