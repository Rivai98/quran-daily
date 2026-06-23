import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/quran_groups/view/screens/group_dashboard_screen.dart';

import '../../../helpers/widget_test_app.dart';

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets('dashboard is stable at ${width.toInt()}px width',
        (tester) async {
      tester.view.physicalSize = Size(width, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildArabicTestApp(const GroupDashboardScreen()),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text(ArabicStrings.dashboardTitle), findsOneWidget);
      expect(find.text(ArabicStrings.partsStatusTitle), findsOneWidget);
      expect(find.text(ArabicStrings.organizerActionsTitle), findsOneWidget);
    });
  }

  testWidgets('dashboard tolerates enlarged Arabic text', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      buildArabicTestApp(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.25)),
          child: const GroupDashboardScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
