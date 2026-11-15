import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/design_system/app_colors.dart';
import 'package:quran_daily/core/design_system/assignment_status.dart';
import 'package:quran_daily/core/design_system/widgets/part_tile.dart';
import 'package:quran_daily/core/design_system/widgets/status_chip.dart';

import '../../../helpers/widget_test_app.dart';

void main() {
  const expected = {
    AssignmentStatus.completed: (
      label: 'تمت القراءة',
      icon: Icons.check_circle,
    ),
    AssignmentStatus.pending: (
      label: 'لم يُقرأ بعد',
      icon: Icons.schedule,
    ),
    AssignmentStatus.missed: (
      label: 'فائت',
      icon: Icons.cancel,
    ),
    AssignmentStatus.late: (
      label: 'قُرئ متأخرًا',
      icon: Icons.history,
    ),
    AssignmentStatus.available: (
      label: 'متاح',
      icon: Icons.volunteer_activism,
    ),
    AssignmentStatus.unread: (
      label: 'لم يقرأه أحد',
      icon: Icons.remove_circle,
    ),
  };

  for (final entry in expected.entries) {
    testWidgets('StatusChip renders ${entry.key.name} as color+icon+label',
        (tester) async {
      await tester.pumpWidget(
        buildArabicTestApp(
          Scaffold(body: Center(child: StatusChip(status: entry.key))),
        ),
      );

      expect(find.text(entry.value.label), findsOneWidget);
      final icon = tester.widget<Icon>(find.byType(Icon).first);
      expect(icon.icon, entry.value.icon);

      // The chip background must be the status background token.
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(StatusChip),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration;
      final Color? bg = decoration is ShapeDecoration
          ? decoration.color
          : (decoration is BoxDecoration ? decoration.color : null);
      expect(bg, AppColors.light.statusBg(entry.key));
      expect(icon.color, AppColors.light.statusFg(entry.key));
    });
  }

  for (final entry in expected.entries) {
    testWidgets('PartTile renders ${entry.key.name} juz number + icon',
        (tester) async {
      await tester.pumpWidget(
        buildArabicTestApp(
          const Scaffold(body: Center(child: PartTile(juz: 5, status: AssignmentStatus.pending))),
        ),
      );

      expect(find.text('٥'), findsOneWidget);
      final icon = tester.widget<Icon>(find.byType(Icon).first);
      expect(icon.icon, Icons.schedule);
    });
  }

  testWidgets('PartTile semantics read "الجزء ٥، <status>، جزؤك" when mine',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      buildArabicTestApp(
        const Scaffold(
          body: Center(
            child: PartTile(
              juz: 5,
              status: AssignmentStatus.pending,
              isMine: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('الجزء ٥، لم يُقرأ بعد، جزؤك'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('PartTile semantics without mine flag omit the marker',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      buildArabicTestApp(
        const Scaffold(
          body: Center(
            child: PartTile(juz: 7, status: AssignmentStatus.completed),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('الجزء ٧، تمت القراءة'), findsOneWidget);
    semantics.dispose();
  });
}
