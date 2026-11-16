import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/quran_groups/view/widgets/invite_code_row.dart';

import '../../../helpers/widget_test_app.dart';

void main() {
  setUpAll(loadDesignSystemFonts);

  testWidgets('shows the code with Latin digits, never Arabic-Indic', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildArabicTestApp(
        const Scaffold(
          body: InviteCodeRow(code: 'DZAC2NAR', groupName: 'حلقة الفجر'),
        ),
      ),
    );
    expect(find.text('DZAC2NAR'), findsOneWidget);
    expect(find.textContaining('٢'), findsNothing);
  });

  testWidgets('tapping the code copies it and confirms', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      buildArabicTestApp(
        const Scaffold(
          body: InviteCodeRow(code: 'DZAC2NAR', groupName: 'حلقة الفجر'),
        ),
      ),
    );

    await tester.tap(find.text('DZAC2NAR'));
    await tester.pump();

    expect(copied, 'DZAC2NAR');
    expect(find.text(ArabicStrings.inviteCodeCopied), findsOneWidget);
  });

  test('share text carries the group name and the exact code', () {
    final text = ArabicStrings.inviteShareText(
      groupName: 'حلقة الفجر',
      code: 'DZAC2NAR',
    );
    expect(text, contains('«حلقة الفجر»'));
    expect(text, contains('DZAC2NAR'));
  });
}
