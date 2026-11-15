import 'package:flutter/material.dart';
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
    return InkWell(
      onTap: onTap,
      child: AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [Expanded(child: Text(ArabicNumerals.format(date), style: AppTypography.title)), Icon(day.complete ? Icons.check_circle_outline : Icons.history, semanticLabel: day.complete ? ArabicStrings.logDayComplete : ArabicStrings.logDayPartial)]),
        const SizedBox(height: AppSpacing.sm),
        Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: day.items.map((item) => _LogStatusChip(item: item)).toList()),
      ])),
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
    final fg = colors.statusFg(isVolunteer ? AssignmentStatus.available : status);
    final bg = colors.statusBg(isVolunteer ? AssignmentStatus.available : status);
    final label = isVolunteer ? ArabicStrings.logVolunteered : status.label;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pillBR),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isVolunteer ? Icons.volunteer_activism : status.icon, size: 18, color: fg),
        const SizedBox(width: AppSpacing.xxs),
        Text('$label · ${item.groupName}', style: AppTypography.caption.copyWith(color: fg)),
      ]),
    );
  }
}
