import 'package:material_ui/material_ui.dart';

import '../../localization/arabic_strings.dart';
import '../app_colors.dart';
import '../app_typography.dart';
import '../assignment_status.dart';

/// UI mapping for [AssignmentStatus]: always color + icon + Arabic label
/// together (constitution Principle VI; color alone is prohibited).
extension AssignmentStatusUI on AssignmentStatus {
  /// Canonical Arabic label from [ArabicStrings].
  String get label {
    switch (this) {
      case AssignmentStatus.completed:
        return ArabicStrings.completed;
      case AssignmentStatus.pending:
        return ArabicStrings.pending;
      case AssignmentStatus.missed:
        return ArabicStrings.missed;
      case AssignmentStatus.late:
        return ArabicStrings.late;
      case AssignmentStatus.available:
        return ArabicStrings.available;
      case AssignmentStatus.unread:
        return ArabicStrings.unread;
    }
  }

  /// Material Symbols Rounded icon name (Flutter Icons equivalent).
  IconData get icon {
    switch (this) {
      case AssignmentStatus.completed:
        return Icons.check_circle;
      case AssignmentStatus.pending:
        return Icons.schedule;
      case AssignmentStatus.missed:
        return Icons.cancel;
      case AssignmentStatus.late:
        return Icons.history;
      case AssignmentStatus.available:
        return Icons.volunteer_activism;
      case AssignmentStatus.unread:
        return Icons.remove_circle;
    }
  }
}

/// Status chip: pill background + status icon + Arabic label.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.filledIcon = false});

  final AssignmentStatus status;
  final bool filledIcon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final fg = colors.statusFg(status);

    return Container(
      decoration: ShapeDecoration(
        color: colors.statusBg(status),
        shape: StadiumBorder(
          side: BorderSide(color: fg.withValues(alpha: 0.32)),
        ),
      ),
      padding: const EdgeInsetsDirectional.only(
        start: 8,
        end: 12,
        top: 2,
        bottom: 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 18, color: fg, fill: filledIcon ? 1.0 : 0.0),
          const SizedBox(width: 4),
          Text(status.label, style: AppTypography.label.copyWith(color: fg)),
        ],
      ),
    );
  }
}
