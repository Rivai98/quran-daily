import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/quran_groups/view/screens/group_selection_screen.dart';
import 'package:quran_daily/features/quran_groups/view/screens/organizer_assignment_review_screen.dart';
import 'package:quran_daily/features/quran_groups/view/screens/organizer_join_requests_screen.dart';
import 'package:quran_daily/features/quran_groups/view/screens/public_group_discovery_screen.dart';
import 'package:quran_daily/features/quran_groups/view/screens/settings_screen.dart';
import 'package:quran_daily/features/quran_groups/view/widgets/state_panel.dart';
import 'package:quran_daily/features/quran_groups/view/widgets/validation_banner.dart';

import '../../../helpers/widget_test_app.dart';

void main() {
  testWidgets('shared state panels appear on utility screens', (tester) async {
    final screens = <Widget>[
      const GroupSelectionScreen(),
      const PublicGroupDiscoveryScreen(),
      const OrganizerJoinRequestsScreen(),
      const SettingsScreen(),
    ];

    for (final screen in screens) {
      await tester.pumpWidget(buildArabicTestApp(screen));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(StatePanel), findsWidgets);
    }
  });

  testWidgets('validation banners communicate blocked organizer states',
      (tester) async {
    await tester.pumpWidget(
      buildArabicTestApp(const OrganizerAssignmentReviewScreen()),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(ValidationBanner), findsOneWidget);
    expect(find.text(ArabicStrings.publishBlocked), findsOneWidget);
  });
}
