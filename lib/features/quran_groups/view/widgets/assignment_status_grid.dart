import 'package:flutter/material.dart';

import '../../../../core/localization/arabic_strings.dart';
import 'status_chip.dart';

class AssignmentStatusGrid extends StatelessWidget {
  const AssignmentStatusGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final assignments = List.generate(30, (index) {
      final part = index + 1;
      final status = switch (part % 10) {
        0 => ReadingStatus.missed,
        1 || 2 || 3 || 4 => ReadingStatus.completed,
        5 => ReadingStatus.late,
        _ => ReadingStatus.pending,
      };
      return _AssignmentPreview(part: part, status: status);
    });

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: assignments.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, index) {
        final item = assignments[index];
        final color = switch (item.status) {
          ReadingStatus.completed => const Color(0xFF167A4A),
          ReadingStatus.pending => const Color(0xFF8A6D1F),
          ReadingStatus.missed => const Color(0xFFB3261E),
          ReadingStatus.late => const Color(0xFF6750A4),
        };
        final label = switch (item.status) {
          ReadingStatus.completed => ArabicStrings.completed,
          ReadingStatus.pending => ArabicStrings.pending,
          ReadingStatus.missed => ArabicStrings.missed,
          ReadingStatus.late => ArabicStrings.late,
        };
        return DecoratedBox(
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            border: Border.all(color: color.withOpacity(0.28)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_iconFor(item.status), color: color, size: 18),
                const SizedBox(height: 4),
                Text('جزء ${item.part}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                FittedBox(child: Text(label, style: TextStyle(color: color))),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _iconFor(ReadingStatus status) {
    return switch (status) {
      ReadingStatus.completed => Icons.check_circle,
      ReadingStatus.pending => Icons.schedule,
      ReadingStatus.missed => Icons.error_outline,
      ReadingStatus.late => Icons.history_toggle_off,
    };
  }
}

class _AssignmentPreview {
  const _AssignmentPreview({required this.part, required this.status});

  final int part;
  final ReadingStatus status;
}
