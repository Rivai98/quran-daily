import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/app_section_header.dart';
import '../../../../core/design_system/widgets/app_text_field.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../data/entities/entities.dart';
import '../../cubit/create_group/create_group_cubit.dart';

/// S4 create group (ui-contract): name, description, timezone, day start
/// time, visibility and join-mode segmented controls; one primary button
/// "أنشئ المجموعة".
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();

  String? _nameError;
  String? _descriptionError;
  GroupVisibility _visibility = GroupVisibility.public;
  JoinMode _joinMode = JoinMode.approval;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    final cubit = context.read<CreateGroupCubit>();
    cubit.submit(
      name: _name.text,
      shortDescription: _description.text,
      timezone: 'Africa/Cairo', // device default via flutter_timezone (T062)
      visibility: _visibility,
      joinMode: _joinMode,
    );
    setState(() {
      _nameError = _name.text.trim().length < 3
          ? ArabicStrings.nameLengthError
          : null;
      _descriptionError = _description.text.trim().length > 200
          ? ArabicStrings.descriptionLengthError
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.createGroup)),
      body: BlocConsumer<CreateGroupCubit, CreateGroupState>(
        listener: (context, state) {
          if (state.status == CreateGroupStatus.success) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        builder: (context, state) {
          final submitting = state.status == CreateGroupStatus.submitting;
          final limitError = state.status == CreateGroupStatus.failure &&
              state.failure?.kind == FailureKind.limitReached;

          return SafeArea(
            child: ListView(
              padding: AppSpacing.screen,
              children: [
                AppTextField(
                  label: ArabicStrings.groupSelectionTitle,
                  hint: ArabicStrings.nameLengthError,
                  controller: _name,
                  errorText:
                      (state.failure?.code == 'validation_failed' &&
                              _nameError == null)
                          ? ArabicStrings.nameLengthError
                          : _nameError,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  label: ArabicStrings.descriptionLengthError,
                  controller: _description,
                  errorText: _descriptionError,
                ),
                const SizedBox(height: AppSpacing.md),
                AppSectionHeader(title: ArabicStrings.settingsTitle),
                _SegmentedRow<GroupVisibility>(
                  values: const [GroupVisibility.public, GroupVisibility.private],
                  labelOf: (v) =>
                      v == GroupVisibility.public ? 'عامة' : 'خاصة',
                  selected: _visibility,
                  onChanged: (v) => setState(() => _visibility = v),
                  enabled: !submitting,
                ),
                const SizedBox(height: AppSpacing.sm),
                _SegmentedRow<JoinMode>(
                  values: const [JoinMode.autoAccept, JoinMode.approval],
                  labelOf: (m) =>
                      m == JoinMode.autoAccept ? 'قبول تلقائي' : 'بموافقة المالك',
                  selected: _joinMode,
                  onChanged: (m) => setState(() => _joinMode = m),
                  enabled: !submitting,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (limitError) ...[
                  _LimitBanner(colors: colors),
                  const SizedBox(height: AppSpacing.md),
                ],
                AppButton(
                  label: ArabicStrings.createTheGroup,
                  loading: submitting,
                  expanded: true,
                  onPressed: submitting ? null : _submit,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SegmentedRow<T> extends StatelessWidget {
  const _SegmentedRow({
    required this.values,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
    required this.enabled,
  });

  final List<T> values;
  final String Function(T) labelOf;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Row(
      children: [
        for (final value in values) ...[
          Expanded(
            child: TextButton(
              onPressed: enabled ? () => onChanged(value) : null,
              style: TextButton.styleFrom(
                backgroundColor: selected == value
                    ? colors.primaryContainer
                    : colors.surface,
                foregroundColor: selected == value
                    ? colors.onPrimaryContainer
                    : colors.inkMuted,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.all(Radius.circular(12)),
                ),
                side: BorderSide(color: colors.border),
              ),
              child: Text(labelOf(value)),
            ),
          ),
          if (value != values.last) const SizedBox(width: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _LimitBanner extends StatelessWidget {
  const _LimitBanner({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: ShapeDecoration(
        color: colors.pendingBg,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          side:
              BorderSide(color: colors.pendingFg.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.block, size: 20, color: colors.pendingFg),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(ArabicStrings.ownerGroupLimitCopy,
                style: AppTypography.caption
                    .copyWith(color: colors.pendingFg)),
          ),
        ],
      ),
    );
  }
}
