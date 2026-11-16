import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/app_snack_bar.dart';
import '../../../../core/design_system/widgets/app_text_field.dart';
import '../../../../core/design_system/widgets/confirm_sheet.dart';
import '../../../../core/design_system/widgets/state_panel.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../widgets/invite_code_row.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/quran/portion_unit.dart';
import '../../../reminders/cubit/reminders_cubit.dart';
import '../../../reminders/view/group_reminder_section.dart';
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
    this.groupName,
    required this.onKhatmaStarted,
  });

  final String groupId;
  final bool isOwner;
  final String? inviteCode;
  final PortionUnit portionUnit;
  final bool isActive;
  final String? groupName;
  final VoidCallback onKhatmaStarted;

  @override
  Widget build(BuildContext context) {
    if (!isOwner) {
      return Scaffold(
        appBar: AppBar(title: const Text(ArabicStrings.reminderGroupTitle)),
        body: serviceLocator.isRegistered<RemindersCubit>()
            ? ListView(
                padding: AppSpacing.screen,
                children: [
                  BlocProvider<RemindersCubit>(
                    create: (_) => serviceLocator<RemindersCubit>(),
                    child: GroupReminderSection(
                      groupId: groupId,
                      groupName: groupName ?? groupId,
                      isOwner: false,
                    ),
                  ),
                ],
              )
            : StatePanel(
                icon: Icons.lock_rounded,
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
          } else if (state.status == GroupSettingsStatus.success) {
            AppSnackBar.show(context, ArabicStrings.groupSettingsSaved);
          }
        },
        builder: (context, state) {
          final code = state.inviteCode ?? inviteCode;
          return _SettingsForm(
            groupId: groupId,
            groupName: groupName ?? groupId,
            inviteCode: code,
            portionUnit: portionUnit,
            isActive: isActive,
            submitting: state.status == GroupSettingsStatus.submitting,
            failure: state.failure,
            description: state.description,
          );
        },
      ),
    );
  }
}

class _SettingsForm extends StatefulWidget {
  const _SettingsForm({
    required this.groupId,
    required this.groupName,
    required this.inviteCode,
    required this.submitting,
    required this.failure,
    required this.portionUnit,
    required this.isActive,
    this.description,
  });

  final String? description;
  final String groupId;
  final String groupName;
  final String? inviteCode;
  final bool submitting;
  final AppFailure? failure;
  final PortionUnit portionUnit;
  final bool isActive;

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;

  String get groupId => widget.groupId;
  String get groupName => widget.groupName;
  String? get inviteCode => widget.inviteCode;
  bool get submitting => widget.submitting;
  AppFailure? get failure => widget.failure;
  PortionUnit get portionUnit => widget.portionUnit;
  bool get isActive => widget.isActive;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: groupName == groupId ? '' : groupName,
    );
    descriptionController = TextEditingController(
      text: widget.description ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _SettingsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The current description arrives after the first frame; prefill it
    // unless the owner has already started typing.
    final description = widget.description;
    if (description != null &&
        description != oldWidget.description &&
        descriptionController.text.trim().isEmpty) {
      descriptionController.text = description;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final cubit = context.read<GroupSettingsCubit>();
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
                _GroupSettingsSectionTitle(
                  icon: Icons.link_rounded,
                  title: ArabicStrings.inviteCodeLabel,
                ),
                const SizedBox(height: AppSpacing.xxs),
                if (inviteCode == null)
                  Text(
                    ArabicStrings.showInviteCode,
                    style: AppTypography.bodyLarge,
                  )
                else
                  InviteCodeRow(code: inviteCode!, groupName: groupName),
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
              const _GroupSettingsSectionTitle(
                icon: Icons.tune_rounded,
                title: ArabicStrings.settingsTitle,
              ),
              AppTextField(
                label: ArabicStrings.groupNameLabel,
                controller: nameController,
                prefixIcon: Icons.groups_rounded,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: ArabicStrings.shortDescriptionLabel,
                controller: descriptionController,
                prefixIcon: Icons.notes_rounded,
                minLines: 2,
                maxLines: 4,
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
        if (serviceLocator.isRegistered<RemindersCubit>()) ...[
          AppButton(
            label: ArabicStrings.reminderGroupTitle,
            variant: AppButtonVariant.secondary,
            expanded: true,
            icon: const Icon(Icons.notifications_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    _GroupRemindersPage(groupId: groupId, groupName: groupName),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _GroupSettingsSectionTitle(
                icon: Icons.menu_book_rounded,
                title: ArabicStrings.portionSelectorTitle,
              ),
              _PortionUnitSetting(
                current: portionUnit,
                isActive: isActive,
                submitting: submitting,
              ),
            ],
          ),
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
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _GroupSettingsSectionTitle(
                icon: Icons.archive_rounded,
                title: ArabicStrings.archiveGroupAction,
              ),
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
                icon: const Icon(Icons.archive_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _GroupSettingsSectionTitle extends StatelessWidget {
  const _GroupSettingsSectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
    child: Row(
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(title, style: AppTypography.title)),
      ],
    ),
  );
}

class _GroupRemindersPage extends StatelessWidget {
  const _GroupRemindersPage({required this.groupId, required this.groupName});
  final String groupId;
  final String groupName;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(ArabicStrings.reminderGroupTitle)),
    body: ListView(
      padding: AppSpacing.screen,
      children: [
        BlocProvider<RemindersCubit>(
          create: (_) => serviceLocator<RemindersCubit>(),
          child: GroupReminderSection(
            groupId: groupId,
            groupName: groupName,
            isOwner: true,
          ),
        ),
      ],
    ),
  );
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
