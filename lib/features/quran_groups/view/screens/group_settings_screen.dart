import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/app_section_header.dart';
import '../../../../core/design_system/widgets/confirm_sheet.dart';
import '../../../../core/design_system/widgets/state_panel.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/localization/arabic_numerals.dart';
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
    required this.onKhatmaStarted,
  });

  final String groupId;
  final bool isOwner;
  final String? inviteCode;
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
  });

  final String groupId;
  final String? inviteCode;
  final bool submitting;
  final AppFailure? failure;

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
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: ShapeDecoration(
              color: colors.missedBg,
              shape: RoundedRectangleBorder(
                borderRadius:
                    const BorderRadius.all(Radius.circular(12)),
                side: BorderSide(
                    color: colors.danger.withValues(alpha: 0.3)),
              ),
            ),
            child: Text(
              ArabicStrings.authError(failure!.code),
              style:
                  AppTypography.caption.copyWith(color: colors.danger),
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
                          text: 'انضم إلى مجموعتي في ختمة يومية! رمز الدعوة: $inviteCode'
                              ' — qurandaily://join/$inviteCode',
                        ),
                      ),
                      icon: const Icon(Icons.share),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'توليد رمز جديد',
                  variant: AppButtonVariant.secondary,
                  onPressed: submitting
                      ? null
                      : () => ConfirmSheet.show(
                            context,
                            title: 'توليد رمز دعوة جديد؟',
                            message:
                                'سيتوقف عمل رمز الدعوة القديم ولن يعود رابط الدعوة السابق.',
                            confirmLabel: 'نعم، ولّد رمزًا جديدًا',
                            onConfirm: () => cubit.regenerateInvite(),
                          ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppSectionHeader(title: ArabicStrings.settingsTitle),
        TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'اسم المجموعة'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: descriptionController,
          decoration: const InputDecoration(labelText: 'وصف مختصر'),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(ArabicStrings.settingsApplyTomorrowNote,
            style: AppTypography.caption),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: ArabicStrings.save,
          variant: AppButtonVariant.tonal,
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
                    title: 'أرشف المجموعة؟',
                    message:
                        'لن تُقبل انضمامات جديدة ولن تتولد أيام جديدة للمجموعة.',
                    confirmLabel: 'نعم، أرشف',
                    onConfirm: () => cubit.archiveGroup(),
                  ),
          icon: const Icon(Icons.archive_outlined),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
