import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/localization/arabic_numerals.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/core/quran/portion_unit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/view/widgets/juz_grid.dart';

import '../../../helpers/widget_test_app.dart';

void main() {
  testWidgets('missed details are hidden from members', (tester) async {
    final assignment = Assignment(
      assignmentId: 'missed-1',
      juz: 1,
      seatNumber: 1,
      kind: AssignmentKind.seat,
      status: AssignmentStatusEnum.missed,
    );

    await tester.pumpWidget(
      buildArabicTestApp(JuzGrid(assignments: [assignment], showMissed: false)),
    );

    expect(
      find.bySemanticsLabel(RegExp('.*${ArabicStrings.unread}.*')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('.*${ArabicStrings.missed}.*')),
      findsNothing,
    );
  });

  testWidgets(
    'partial page cycle labels remaining seats as rest days in every variant',
    (tester) async {
      final assignments = List.generate(
        4,
        (index) => Assignment(
          assignmentId: 'assignment-$index',
          juz: index + 1,
          portionIndex: 601 + index,
          seatNumber: index + 1,
          kind: AssignmentKind.seat,
          status: AssignmentStatusEnum.pending,
        ),
      );

      await pumpAllVariants(
        tester,
        JuzGrid(assignments: assignments, unit: PortionUnit.page),
        (tester, variant) async {
          expect(
            find.text(ArabicStrings.restDay),
            findsAtLeastNWidgets(1),
            reason: variant,
          );
          expect(
            find.text(ArabicNumerals.format(601)),
            findsOneWidget,
            reason: variant,
          );
          expect(tester.takeException(), isNull, reason: variant);
        },
      );
    },
  );
}
