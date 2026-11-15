import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/assignment_status.dart' as design;
import '../../../../core/design_system/widgets/part_tile.dart';
import '../../data/entities/entities.dart';

class JuzGrid extends StatelessWidget {
  const JuzGrid({super.key, required this.assignments});

  final List<Assignment> assignments;

  @override
  Widget build(BuildContext context) {
    final ordered = [...assignments]..sort((a, b) => a.juz.compareTo(b.juz));
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: AppSpacing.xs,
        mainAxisSpacing: AppSpacing.xs,
      ),
      children: [
        for (final assignment in ordered)
          PartTile(
            juz: assignment.juz,
            status: design.AssignmentStatus.values.byName(assignment.status.name),
            isMine: assignment.isMe,
          ),
      ],
    );
  }
}