import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';

enum ReadingStatus { pending, completed, missed, late }

class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    required this.status,
    super.key,
  });

  final String label;
  final ReadingStatus status;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final color = switch (status) {
      ReadingStatus.completed => appColors.completedFg,
      ReadingStatus.pending => appColors.pendingFg,
      ReadingStatus.missed => appColors.missedFg,
      ReadingStatus.late => appColors.lateFg,
    };

    return Chip(
      avatar: Icon(_icon, size: 16, color: color),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.32)),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.smBR),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
      visualDensity: VisualDensity.compact,
    );
  }

  IconData get _icon {
    return switch (status) {
      ReadingStatus.completed => Icons.check_circle,
      ReadingStatus.pending => Icons.schedule,
      ReadingStatus.missed => Icons.error_outline,
      ReadingStatus.late => Icons.history_toggle_off,
    };
  }
}
