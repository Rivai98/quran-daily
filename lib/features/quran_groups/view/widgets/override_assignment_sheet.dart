import 'package:flutter/material.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/localization/arabic_numerals.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../data/entities/entities.dart';
import '../../../../core/errors/result.dart';

/// Owner-only assignment change sheet; mutations are routed through the Cubit.
class OverrideAssignmentSheet extends StatefulWidget {
  const OverrideAssignmentSheet({
    super.key,
    required this.members,
    required this.onSubmit,
  });
  final List<SeatMember> members;
  final Future<Result<DashboardSnapshot>> Function(String membershipId)
  onSubmit;

  static Future<void> show(
    BuildContext context, {
    required List<SeatMember> members,
    required Future<Result<DashboardSnapshot>> Function(String membershipId)
    onSubmit,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        OverrideAssignmentSheet(members: members, onSubmit: onSubmit),
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
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ArabicStrings.overrideAssignmentTitle,
              style: AppTypography.title,
            ),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.members.length,
                itemBuilder: (context, index) {
                  final member = widget.members[index];
                  return ListTile(
                    selected: selected == member.membershipId,
                    onTap: submitting
                        ? null
                        : () => setState(() => selected = member.membershipId),
                    leading: Icon(
                      selected == member.membershipId
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                    ),
                    title: Text(
                      member.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${ArabicStrings.seatLabel} ${ArabicNumerals.format(member.seatNumber)}',
                    ),
                  );
                },
              ),
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
    ),
  );

  Future<void> _submit() async {
    setState(() {
      submitting = true;
      error = null;
    });
    final result = await widget.onSubmit(selected!);
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
