import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/features/quran_groups/view/screens/history_screen.dart';
import 'package:quran_daily/features/quran_groups/view/screens/member_management_screen.dart';
import 'package:quran_daily/features/quran_groups/view/screens/organizer_assignment_review_screen.dart';

import '../../../helpers/widget_test_app.dart';

void main() {
  testWidgets('dense list screens fit narrow phones', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final screens = [
      const MemberManagementScreen(),
      const OrganizerAssignmentReviewScreen(),
      const HistoryScreen(),
    ];

    for (final screen in screens) {
      await tester.pumpWidget(buildArabicTestApp(screen));
      await tester.pump();

      expect(tester.takeException(), isNull);
    }
  });
}
