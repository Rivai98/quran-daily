import 'package:flutter/material.dart';

import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_colors.dart';
import 'dense_info_row.dart';
import 'status_chip.dart';

class AssignmentList extends StatelessWidget {
  const AssignmentList({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final rows = [
      const _AssignmentRow(1, ReadingStatus.completed),
      const _AssignmentRow(2, ReadingStatus.pending),
      const _AssignmentRow(3, ReadingStatus.late),
      const _AssignmentRow(10, ReadingStatus.missed),
      const _AssignmentRow(12, ReadingStatus.completed),
    ];

    return Column(
      children: [
        for (final row in rows) ...[
          DenseInfoRow(
            icon: Icons.person,
            title: row.memberLabel,
            subtitle: row.partLabel,
            accentColor: _colorFor(appColors, row.status),
            trailing: StatusChip(
              label: _labelFor(row.status),
              status: row.status,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }

  Color _colorFor(AppColors colors, ReadingStatus status) {
    return switch (status) {
      ReadingStatus.completed => colors.completedFg,
      ReadingStatus.pending => colors.pendingFg,
      ReadingStatus.missed => colors.missedFg,
      ReadingStatus.late => colors.lateFg,
    };
  }

  String _labelFor(ReadingStatus status) {
    return switch (status) {
      ReadingStatus.completed => ArabicStrings.completed,
      ReadingStatus.pending => ArabicStrings.pending,
      ReadingStatus.missed => ArabicStrings.missed,
      ReadingStatus.late => ArabicStrings.late,
    };
  }
}

class _AssignmentRow {
  const _AssignmentRow(this.part, this.status);

  final int part;
  final ReadingStatus status;

  String get memberLabel => '${ArabicStrings.memberRole} $part';

  String get partLabel => '\u{62c}\u{632}\u{621} $part - ${ArabicStrings.readyToPublish}';
}
