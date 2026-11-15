import 'package:flutter/material.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../data/entities/entities.dart';
import '../../data/repositories/khatma_repository.dart';

/// Standalone owner tool. Dashboard wiring is intentionally left to the shell.
class OverrideAssignmentSheet extends StatefulWidget {
  const OverrideAssignmentSheet({
    super.key,
    required this.assignmentId,
    required this.members,
    required this.repository,
  });
  final String assignmentId;
  final List<SeatMember> members;
  final KhatmaRepository repository;

  static Future<void> show(
    BuildContext context, {
    required String assignmentId,
    required List<SeatMember> members,
    required KhatmaRepository repository,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => OverrideAssignmentSheet(
      assignmentId: assignmentId,
      members: members,
      repository: repository,
    ),
  );

  @override
  State<OverrideAssignmentSheet> createState() =>
      _OverrideAssignmentSheetState();
}

class _OverrideAssignmentSheetState extends State<OverrideAssignmentSheet> {
  String? selected;
  bool submitting = false;
  String? error;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: AppSpacing.screen,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ArabicStrings.overrideAssignmentTitle,
            style: AppTypography.title,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final member in widget.members)
            ListTile(
              selected: selected == member.membershipId,
              onTap: submitting
                  ? null
                  : () => setState(() => selected = member.membershipId),
              leading: Icon(
                selected == member.membershipId
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: Text(member.displayName),
              subtitle: Text('${ArabicStrings.seatLabel} ${member.seatNumber}'),
            ),
          if (error != null)
            Text(ArabicStrings.operationFailed, style: AppTypography.body),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: ArabicStrings.overrideAssignmentAction,
            loading: submitting,
            onPressed: selected == null || submitting ? null : _submit,
          ),
        ],
      ),
    ),
  );

  Future<void> _submit() async {
    setState(() {
      submitting = true;
      error = null;
    });
    final result = await widget.repository.overrideAssignment(
      widget.assignmentId,
      selected!,
    );
    if (!mounted) return;
    result.when(
      success: (_) => Navigator.pop(context),
      failure: (_) => setState(() {
        submitting = false;
        error = 'failed';
      }),
    );
  }
}
