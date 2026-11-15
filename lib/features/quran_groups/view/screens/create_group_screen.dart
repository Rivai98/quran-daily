import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/app_section_header.dart';
import '../../../../core/design_system/widgets/app_text_field.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/quran/portion_unit.dart';
import '../../../../core/quran/quran_metadata_repository.dart';
import '../../data/entities/entities.dart';
import '../../cubit/create_group/create_group_cubit.dart';

/// S4 create group (ui-contract): name, description, timezone, day start
/// time, visibility and join-mode segmented controls; one primary button.
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key, this.metadataRepository});
  final QuranMetadataRepository? metadataRepository;

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
  final _fallbackMetadata = QuranMetadataRepository();
  QuranMetadataRepository get _metadataRepository =>
      widget.metadataRepository ?? _fallbackMetadata;
  late final Future<void> _metadata = _metadataRepository.load();

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
          final limitError =
              state.status == CreateGroupStatus.failure &&
              state.failure?.kind == FailureKind.limitReached;

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: AppSpacing.screenContent,
                    children: [
                      AppTextField(
                        label: ArabicStrings.groupNameLabel,
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
                        label: ArabicStrings.shortDescriptionLabel,
                        hint: ArabicStrings.descriptionLengthError,
                        controller: _description,
                        errorText: _descriptionError,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppSectionHeader(title: ArabicStrings.groupVisibilityTitle),
                      _SegmentedRow<GroupVisibility>(
                        values: const [
                          GroupVisibility.public,
                          GroupVisibility.private,
                        ],
                        labelOf: (v) => v == GroupVisibility.public
                            ? ArabicStrings.publicVisibility
                            : ArabicStrings.privateVisibility,
                        hintOf: (v) => v == GroupVisibility.public
                            ? ArabicStrings.publicVisibilityHint
                            : ArabicStrings.privateVisibilityHint,
                        selected: _visibility,
                        onChanged: (v) => setState(() => _visibility = v),
                        enabled: !submitting,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppSectionHeader(title: ArabicStrings.joinModeTitle),
                      _SegmentedRow<JoinMode>(
                        values: const [JoinMode.autoAccept, JoinMode.approval],
                        labelOf: (m) => m == JoinMode.autoAccept
                            ? ArabicStrings.autoAcceptJoinMode
                            : ArabicStrings.ownerApprovalJoinMode,
                        hintOf: (v) => v == JoinMode.autoAccept
                            ? ArabicStrings.autoAcceptJoinModeHint
                            : ArabicStrings.ownerApprovalJoinModeHint,
                        selected: _joinMode,
                        onChanged: (m) => setState(() => _joinMode = m),
                        enabled: !submitting,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppSectionHeader(
                        title: ArabicStrings.portionSelectorTitle,
                      ),
                      FutureBuilder<void>(
                        future: _metadata,
                        builder: (context, metadataState) {
                          if (metadataState.hasError ||
                              metadataState.connectionState !=
                                  ConnectionState.done) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            children: [
                              for (final unit in PortionUnit.values)
                                _PortionChoice(
                                  unit: unit,
                                  selected: state.portionUnit == unit,
                                  count: _metadataRepository
                                      .portions(unit)
                                      .length,
                                  enabled: !submitting,
                                  onTap: () => context
                                      .read<CreateGroupCubit>()
                                      .selectPortionUnit(unit),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
                if (limitError) ...[
                  Padding(
                    padding: AppSpacing.screenH,
                    child: _LimitBanner(colors: colors),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                Padding(
                  padding: AppSpacing.screenH,
                  child: AppButton(
                    label: ArabicStrings.createTheGroup,
                    loading: submitting,
                    expanded: true,
                    onPressed: submitting ? null : _submit,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
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
    required this.hintOf,
    required this.selected,
    required this.onChanged,
    required this.enabled,
  });

  final List<T> values;
  final String Function(T) labelOf;
  final String Function(T) hintOf;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Column(
      children: [
        for (final value in values) ...[
          Material(
            color: selected == value ? colors.primaryContainer : colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.mdBR,
              side: BorderSide(
                color: selected == value ? colors.primary : colors.border,
              ),
            ),
            child: InkWell(
              borderRadius: AppRadius.mdBR,
              onTap: enabled ? () => onChanged(value) : null,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      selected == value
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selected == value
                          ? colors.primary
                          : colors.inkMuted,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(labelOf(value), style: AppTypography.label),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            hintOf(value),
                            style: AppTypography.caption.copyWith(
                              color: colors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (value != values.last) const SizedBox(height: AppSpacing.xs),
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
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: ShapeDecoration(
        color: colors.pendingBg,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdBR,
          side: BorderSide(color: colors.pendingFg.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.block, size: 20, color: colors.pendingFg),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              ArabicStrings.membershipLimitMessage,
              style: AppTypography.caption.copyWith(color: colors.pendingFg),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed('/groups'),
            child: Text(ArabicStrings.groupSelectionTitle),
          ),
        ],
      ),
    );
  }
}

class _PortionChoice extends StatelessWidget {
  const _PortionChoice({
    required this.unit,
    required this.selected,
    required this.count,
    required this.enabled,
    required this.onTap,
  });
  final PortionUnit unit;
  final bool selected;
  final int count;
  final bool enabled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final days = (count + 29) ~/ 30;
    return Semantics(
      selected: selected,
      button: true,
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBR),
          side: BorderSide(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
          ),
          padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ArabicStrings.portionUnitName(unit),
                    style: AppTypography.label,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    ArabicStrings.khatmaDays(days),
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
