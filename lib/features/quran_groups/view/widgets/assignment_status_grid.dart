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

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: assignments.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _columnCountFor(constraints.maxWidth),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 88,
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_iconFor(item.status), color: color, size: 18),
                    const SizedBox(height: 4),
                    _ScaledTileText(
                      '\u062c\u0632\u0621 ${item.part}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    _ScaledTileText(label, style: TextStyle(color: color)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  int _columnCountFor(double width) {
    if (width >= 520) {
      return 6;
    }
    if (width >= 320) {
      return 5;
    }
    return 4;
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

class _ScaledTileText extends StatelessWidget {
  const _ScaledTileText(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(text, maxLines: 1, softWrap: false, style: style),
      ),
    );
  }
}
