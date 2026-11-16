import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/assignment_status.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/status_chip.dart';
import '../../../../core/localization/arabic_numerals.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../data/entities/log_entities.dart';

class LogDayTile extends StatelessWidget {
  const LogDayTile({super.key, required this.day, this.onTap});
  final LogDay day;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEEE d MMMM yyyy', 'ar').format(day.date);
    final colors = Theme.of(context).extension<AppColors>()!;
    final statusLabel = day.complete
        ? ArabicStrings.logDayComplete
        : ArabicStrings.logDayPartial;
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgBR,
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ArabicNumerals.format(date),
                      style: AppTypography.title,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: day.complete
                          ? colors.completedBg
                          : colors.pendingBg,
                      borderRadius: AppRadius.pillBR,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          day.complete
                              ? Icons.check_circle_rounded
                              : Icons.history_rounded,
                          size: 18,
                          color: day.complete
                              ? colors.completedFg
                              : colors.pendingFg,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          statusLabel,
                          style: AppTypography.caption.copyWith(
                            color: day.complete
                                ? colors.completedFg
                                : colors.pendingFg,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (day.items.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Column(
                  children: [
                    for (final entry in day.items.indexed) ...[
                      _LogStatusChip(item: entry.$2),
                      if (entry.$1 < day.items.length - 1)
                        const SizedBox(height: AppSpacing.xs),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LogStatusChip extends StatelessWidget {
  const _LogStatusChip({required this.item});
  final LogItem item;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final AssignmentStatus status = switch (item.status) {
      LogItemStatus.completed => AssignmentStatus.completed,
      LogItemStatus.late => AssignmentStatus.late,
      LogItemStatus.missed => AssignmentStatus.missed,
      LogItemStatus.pending => AssignmentStatus.pending,
      LogItemStatus.unread => AssignmentStatus.unread,
    };
    final isVolunteer = item.kind == LogItemKind.volunteer;
    final fg = colors.statusFg(
      isVolunteer ? AssignmentStatus.available : status,
    );
    final bg = colors.statusBg(
      isVolunteer ? AssignmentStatus.available : status,
    );
    final label = isVolunteer ? ArabicStrings.logVolunteered : status.label;
    final icon = isVolunteer
        ? Icons.volunteer_activism_rounded
        : switch (status) {
            AssignmentStatus.completed => Icons.check_circle_rounded,
            AssignmentStatus.pending => Icons.schedule_rounded,
            AssignmentStatus.missed => Icons.cancel_rounded,
            AssignmentStatus.late => Icons.history_rounded,
            AssignmentStatus.available => Icons.volunteer_activism_rounded,
            AssignmentStatus.unread => Icons.remove_circle_rounded,
          };
    return Row(
      children: [
        Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pillBR),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: AppSpacing.xxs),
              Text(label, style: AppTypography.caption.copyWith(color: fg)),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            item.groupName,
            style: AppTypography.caption.copyWith(color: colors.inkMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
