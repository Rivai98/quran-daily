import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/design_system/widgets/state_panel.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/quran_groups/view/screens/group_settings_screen.dart';

import '../../../helpers/widget_test_app.dart';

void main() {
  testWidgets('read-only settings view supports every constitution variant', (
    tester,
  ) async {
    await pumpAllVariants(
      tester,
      const GroupSettingsScreen(
        groupId: 'group',
        isOwner: false,
        onKhatmaStarted: _noop,
      ),
      (tester, variant) async {
        expect(find.byType(StatePanel), findsOneWidget, reason: variant);
        expect(
          find.text(ArabicStrings.roleMember),
          findsOneWidget,
          reason: variant,
        );
        expect(tester.takeException(), isNull, reason: variant);
      },
    );
  });
}

void _noop() {}
