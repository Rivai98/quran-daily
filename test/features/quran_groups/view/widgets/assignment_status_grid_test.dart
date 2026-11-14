import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/features/quran_groups/view/widgets/assignment_status_grid.dart';

import '../../../../helpers/widget_test_app.dart';

void main() {
  testWidgets('lays out all assignment statuses on narrow phones without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      buildArabicTestApp(
        Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: const [AssignmentStatusGrid()],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('\u062c\u0632\u0621 30'), findsOneWidget);
  });
}
