import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/features/quran_groups/view/screens/public_group_discovery_screen.dart';
import 'package:quran_daily/features/quran_groups/view/screens/settings_screen.dart';
import 'package:quran_daily/features/quran_groups/view/widgets/state_panel.dart';

import '../../../helpers/widget_test_app.dart';

void main() {
  testWidgets('shared state panels appear on utility screens', (tester) async {
    // GroupSelectionScreen is covered by its dedicated test file
    // (group_selection_screen_test.dart) since its rebuild.
    final screens = <Widget>[
      const PublicGroupDiscoveryScreen(),
      const SettingsScreen(),
    ];

    for (final screen in screens) {
      await tester.pumpWidget(buildArabicTestApp(screen));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(StatePanel), findsWidgets);
    }
  });
}
