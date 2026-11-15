import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/assignment_status.dart' as design;
import '../../../../core/design_system/widgets/part_tile.dart';
import '../../../../core/quran/portion_unit.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/localization/arabic_numerals.dart';
import '../../data/entities/entities.dart';

class JuzGrid extends StatelessWidget {
  const JuzGrid({
    super.key,
    required this.assignments,
    this.onAssignmentTap,
    this.unit = PortionUnit.juz,
  });

  final List<Assignment> assignments;
  final ValueChanged<Assignment>? onAssignmentTap;
  final PortionUnit unit;

  @override
  Widget build(BuildContext context) {
    final bySeat = {for (final item in assignments) item.seatNumber: item};
    final ordered = [...assignments]
      ..sort(
        unit == PortionUnit.juz
            ? (a, b) => a.juz.compareTo(b.juz)
            : (a, b) => a.seatNumber.compareTo(b.seatNumber),
      );
    final seatNumbers = unit == PortionUnit.juz
        ? ordered.map((item) => item.seatNumber).toList()
        : List<int>.generate(30, (index) => index + 1);
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: unit == PortionUnit.juz
            ? (MediaQuery.sizeOf(context).width < 360 ? 5 : 6)
            : 3,
        childAspectRatio: unit == PortionUnit.juz ? 1 : 0.72,
        crossAxisSpacing: unit == PortionUnit.juz
            ? AppSpacing.xxs
            : AppSpacing.xs,
        mainAxisSpacing: unit == PortionUnit.juz
            ? AppSpacing.xxs
            : AppSpacing.xs,
      ),
      children: [
        for (final seat in seatNumbers)
          if (bySeat[seat] case final assignment?)
            PartTile(
              juz: assignment.juz,
              unit: unit,
              portionIndex: assignment.portionIndex,
              readerInitials: assignment.reader?.initials,
              readerDisplayName: assignment.reader?.displayName ??
                  assignment.readerDisplayName,
              status: design.AssignmentStatus.values.byName(
                assignment.status.name,
              ),
              isMine: assignment.isMe,
              onTap: onAssignmentTap == null
                  ? null
                  : () => onAssignmentTap!(assignment),
            )
          else
            _RestDayTile(seat: seat),
      ],
    );
  }
}

class _RestDayTile extends StatelessWidget {
  const _RestDayTile({required this.seat});
  final int seat;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Semantics(
      label:
          ArabicStrings.restDaySeatLabel(ArabicNumerals.format(seat)),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsetsDirectional.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          borderRadius: AppRadius.smBR,
          border: Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, color: colors.inkMuted, size: 20),
            Text(
              ArabicStrings.restDay,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: colors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
