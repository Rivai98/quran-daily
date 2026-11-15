import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/assignment_status.dart' as design;
import '../../../../core/design_system/widgets/part_tile.dart';
import '../../data/entities/entities.dart';

class JuzGrid extends StatelessWidget {
  const JuzGrid({super.key, required this.assignments, this.onAssignmentTap});

  final List<Assignment> assignments;
  final ValueChanged<Assignment>? onAssignmentTap;

  @override
  Widget build(BuildContext context) {
    final ordered = [...assignments]..sort((a, b) => a.juz.compareTo(b.juz));
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        // Six columns follow the design reference while preserving room for
        // Arabic-Indic numbers at narrow phone widths.
        crossAxisCount: MediaQuery.sizeOf(context).width < 360 ? 5 : 6,
        crossAxisSpacing: AppSpacing.xxs,
        mainAxisSpacing: AppSpacing.xxs,
      ),
      children: [
        for (final assignment in ordered)
          PartTile(
            juz: assignment.juz,
            status: design.AssignmentStatus.values.byName(
              assignment.status.name,
            ),
            isMine: assignment.isMe,
            onTap: onAssignmentTap == null
                ? null
                : () => onAssignmentTap!(assignment),
          ),
      ],
    );
  }
}
