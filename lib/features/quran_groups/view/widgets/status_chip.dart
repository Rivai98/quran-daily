import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

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
    final color = switch (status) {
      ReadingStatus.completed => AppTheme.completeColor,
      ReadingStatus.pending => AppTheme.pendingColor,
      ReadingStatus.missed => AppTheme.missedColor,
      ReadingStatus.late => AppTheme.lateColor,
    };

    return Chip(
      avatar: Icon(_icon, size: 16, color: color),
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.32)),
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
