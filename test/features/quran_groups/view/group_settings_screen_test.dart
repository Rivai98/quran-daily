import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/design_system/widgets/state_panel.dart';
import 'package:quran_daily/core/design_system/widgets/app_text_field.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/core/quran/portion_unit.dart';
import 'package:quran_daily/features/quran_groups/cubit/group_settings/group_settings_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';
import 'package:quran_daily/features/quran_groups/view/screens/group_settings_screen.dart';

import '../../../helpers/widget_test_app.dart';

void main() {
  testWidgets('owner confirms a portion change for the next cycle', (
    tester,
  ) async {
    final repository = _MockGroupsRepository();
    registerFallbackValue(const GroupSettingsPatch());
    final cubit = GroupSettingsCubit(repository: repository)
      ..load(groupId: 'group');
    addTearDown(cubit.close);

    await tester.pumpWidget(
      buildArabicTestApp(
        BlocProvider.value(
          value: cubit,
          child: const GroupSettingsScreen(
            groupId: 'group',
            isOwner: true,
            portionUnit: PortionUnit.juz,
            isActive: true,
            onKhatmaStarted: _noop,
          ),
        ),
      ),
    );
    final unitSelector = find.byType(DropdownButtonFormField<PortionUnit>);
    await tester.scrollUntilVisible(
      unitSelector,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(unitSelector);
    await tester.tap(unitSelector);
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(ArabicStrings.portionUnitName(PortionUnit.hizb)).last,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(ArabicStrings.confirmPortionChange));
    await tester.tap(find.text(ArabicStrings.confirmPortionChange));
    await tester.pumpAndSettle();

    expect(
      find.text(ArabicStrings.portionChangeAppliesNextCycle),
      findsOneWidget,
    );
  });

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

  testWidgets('owner settings use shared fields and separate sections', (
    tester,
  ) async {
    final repository = _MockGroupsRepository();
    registerFallbackValue(const GroupSettingsPatch());
    final cubit = GroupSettingsCubit(repository: repository)
      ..load(groupId: 'group');
    addTearDown(cubit.close);

    await tester.pumpWidget(
      buildArabicTestApp(
        BlocProvider.value(
          value: cubit,
          child: const GroupSettingsScreen(
            groupId: 'group',
            isOwner: true,
            groupName: 'حلقة تجريبية',
            onKhatmaStarted: _noop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byType(DropdownButtonFormField<PortionUnit>),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(AppTextField), findsNWidgets(2));
    expect(find.text(ArabicStrings.inviteCodeLabel), findsOneWidget);
    expect(
      find.text(ArabicStrings.portionSelectorTitle),
      findsAtLeastNWidgets(1),
    );
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}

class _MockGroupsRepository extends Mock implements GroupsRepository {}
