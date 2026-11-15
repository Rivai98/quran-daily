import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/design_system/app_theme.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/view/widgets/override_assignment_sheet.dart';

void main() {
  testWidgets(
    'owner can choose a member and submit at narrow width in RTL dark mode',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var submitted = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => OverrideAssignmentSheet.show(
                    context,
                    members: const [
                      SeatMember(
                        membershipId: 'm1',
                        displayName: ArabicStrings.memberRole,
                        role: GroupRole.member,
                        seatNumber: 2,
                      ),
                    ],
                    onSubmit: (id) async {
                      submitted = id == 'm1';
                      return Success<DashboardSnapshot>(
                        DashboardSnapshot(
                          groupId: 'g',
                          groupName: ArabicStrings.memberRole,
                          myRole: GroupRole.owner,
                          status: GroupStatus.active,
                          serverGeneratedAt: DateTime.utc(2026),
                        ),
                      );
                    },
                  ),
                  child: const Text(''),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(TextButton).first);
      await tester.pumpAndSettle();
      tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
      );
      await tester.tap(find.text(ArabicStrings.memberRole));
      await tester.pump();
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();
      expect(submitted, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
