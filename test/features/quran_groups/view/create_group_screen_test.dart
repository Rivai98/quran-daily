import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/core/design_system/widgets/widgets.dart';
import 'package:quran_daily/features/quran_groups/cubit/create_group/create_group_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';
import 'package:quran_daily/features/quran_groups/view/screens/create_group_screen.dart';

import '../../../helpers/widget_test_app.dart';

class _MockRepo extends Mock implements GroupsRepository {}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    registerFallbackValue(const CreateGroupInput(
      name: 'x',
      timezone: 'Africa/Cairo',
      visibility: GroupVisibility.private,
      joinMode: JoinMode.approval,
    ));
  });

  Widget pump() => BlocProvider<CreateGroupCubit>(
        create: (_) => CreateGroupCubit(repository: repo),
        child: const CreateGroupScreen(),
      );

  testWidgets('renders name, description, visibility and join-mode controls',
      (tester) async {
    await tester.pumpWidget(buildArabicTestApp(pump()));

    expect(find.text(ArabicStrings.createGroup), findsAtLeastNWidgets(1));
    expect(find.byType(AppTextField), findsAtLeastNWidgets(2));
    // Field labels name the field, not the page or a validation message.
    expect(find.text(ArabicStrings.groupNameLabel), findsOneWidget);
    expect(find.text(ArabicStrings.shortDescriptionLabel), findsOneWidget);
    expect(find.text(ArabicStrings.groupSelectionTitle), findsNothing);
  });

  testWidgets('submitting invalid name shows Arabic validation error and '
      'blocks the repository', (tester) async {
    await tester.pumpWidget(buildArabicTestApp(pump()));

    await tester.enterText(find.byType(AppTextField).first, 'ab');
    await tester.ensureVisible(find.text(ArabicStrings.createTheGroup));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ArabicStrings.createTheGroup));
    await tester.pumpAndSettle();

    verifyNever(() => repo.createGroup(any()));
    expect(
      find.text(ArabicStrings.nameLengthError),
      findsAtLeastNWidgets(1),
      reason: 'the field-level Arabic error must be visible (hint shares text)',
    );
  });

  testWidgets('limit error surfaces the 3-group cap explanation',
      (tester) async {
    when(() => repo.createGroup(any())).thenAnswer(
        (_) async => const FailureResult(
            AuthFailure(message: 'owner_group_limit', code: 'owner_group_limit')));

    await tester.pumpWidget(buildArabicTestApp(pump()));

    await tester.enterText(find.byType(AppTextField).first, 'حلقة صالحة');
    await tester.ensureVisible(find.text(ArabicStrings.createTheGroup));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ArabicStrings.createTheGroup));
    await tester.pumpAndSettle();

    expect(find.text(ArabicStrings.ownerGroupLimitCopy), findsOneWidget);
  });

  testWidgets('renders in all constitution variants without overflow',
      (tester) async {
    await pumpAllVariants(tester, pump(), (tester, variant) async {
      expect(tester.takeException(), isNull, reason: variant);
    });
  });
}
