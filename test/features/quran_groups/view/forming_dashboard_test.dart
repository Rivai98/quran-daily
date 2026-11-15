import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/design_system/app_button.dart';
import 'package:quran_daily/core/design_system/widgets/skeleton.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/core/localization/arabic_numerals.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';
import 'package:quran_daily/features/quran_groups/view/widgets/forming_group_view.dart';

import '../../../helpers/test_fixtures.dart';
import '../../../helpers/widget_test_app.dart';

class _MockRepo extends Mock implements GroupsRepository {}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    when(() => repo.getMembers(any())).thenAnswer((_) async => Success(
          TestFixtures.seatMap(members: [
            TestFixtures.member(1, role: GroupRole.owner, name: 'سارة'),
            TestFixtures.member(2, name: 'أحمد'),
          ]),
        ));
  });

  testWidgets('forming view shows N/30, ناقص X, seats and invite share',
      (tester) async {
    await tester.pumpWidget(buildArabicTestApp(
      FormingGroupView(
        groupId: 'g1',
        groupName: TestFixtures.groupName,
        inviteCode: 'AB23CD45',
        activeMemberCount: 28,
        isOwner: true,
        onStartKhatma: (_) {},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text(ArabicStrings.groupMembersRatio(28, 30)), findsOneWidget);
    expect(
      find.text('${ArabicStrings.missingX} ${ArabicNumerals.format(2)}'),
      findsOneWidget,
    );
    expect(find.byType(AppButton), findsAtLeastNWidgets(1));
    expect(find.text(ArabicStrings.shareInviteAction), findsOneWidget);
    expect(find.byType(SkeletonBox), findsNothing);
  });

  testWidgets('owner sees the start-khatma primary action', (tester) async {
    await tester.pumpWidget(buildArabicTestApp(
      FormingGroupView(
        groupId: 'g1',
        groupName: TestFixtures.groupName,
        inviteCode: 'AB23CD45',
        activeMemberCount: 1,
        isOwner: true,
        onStartKhatma: (_) {},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text(ArabicStrings.startKhatmaAction), findsOneWidget);
  });

  testWidgets('non-owner does not see the start action', (tester) async {
    await tester.pumpWidget(buildArabicTestApp(
      FormingGroupView(
        groupId: 'g1',
        groupName: TestFixtures.groupName,
        inviteCode: 'AB23CD45',
        activeMemberCount: 3,
        isOwner: false,
        onStartKhatma: (_) {},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text(ArabicStrings.startKhatmaAction), findsNothing);
  });

  testWidgets('loading state renders skeleton placeholders', (tester) async {
    await tester.pumpWidget(buildArabicTestApp(
      FormingGroupView(
        groupId: 'g1',
        groupName: TestFixtures.groupName,
        inviteCode: 'AB23CD45',
        activeMemberCount: 5,
        isOwner: true,
        loading: true,
        onStartKhatma: (_) {},
      ),
    ));
    await tester.pump();
    expect(find.byType(SkeletonBox), findsWidgets,
        reason: 'skeleton placeholders while loading the seat map');
  });

  testWidgets('renders in all constitution variants without overflow',
      (tester) async {
    await pumpAllVariants(
      tester,
      FormingGroupView(
        groupId: 'g1',
        groupName: TestFixtures.groupName,
        inviteCode: 'AB23CD45',
        activeMemberCount: 12,
        isOwner: true,
        onStartKhatma: (_) {},
      ),
      (tester, variant) async {
        expect(tester.takeException(), isNull, reason: variant);
      },
    );
  });
}
