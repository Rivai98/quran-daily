import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/core/localization/arabic_formatting.dart';
import 'package:quran_daily/core/design_system/widgets/app_avatar.dart';
import 'package:quran_daily/core/design_system/widgets/app_card.dart';
import 'package:quran_daily/core/design_system/widgets/halaqa_logo.dart';
import 'package:quran_daily/core/design_system/widgets/app_section_header.dart';
import 'package:quran_daily/features/quran_groups/cubit/group_list/group_list_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';
import 'package:quran_daily/features/quran_groups/view/screens/group_selection_screen.dart';

import '../../../helpers/widget_test_app.dart';
import '../../../helpers/test_fixtures.dart';

class _MockRepo extends Mock implements GroupsRepository {}

void main() {
  setUpAll(loadArabicUiFontsForGoldenTests);
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  Widget pump(Widget child) => BlocProvider<GroupListCubit>(
    create: (_) => GroupListCubit(repository: repo),
    child: child,
  );

  testWidgets('content: lists my groups with name and role marker', (
    tester,
  ) async {
    when(() => repo.getMyGroups()).thenAnswer(
      (_) async => Success(
        TestFixtures.overview(
          groups: [
            TestFixtures.myGroup(
              status: GroupStatus.active,
              role: GroupRole.owner,
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(
      buildArabicTestApp(pump(const GroupSelectionScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text(TestFixtures.groupName), findsOneWidget);
    expect(find.textContaining(ArabicStrings.roleOwner), findsOneWidget);
    expect(find.text(ArabicFormatting.membersProgress(12)), findsOneWidget);
    expect(find.byIcon(Icons.people_alt_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
    expect(find.byIcon(Icons.play_circle_outline_rounded), findsOneWidget);
  });

  testWidgets('golden: S1 at 360x800 light and dark', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    when(() => repo.getMyGroups()).thenAnswer(
      (_) async => Success(
        TestFixtures.overview(
          groups: [TestFixtures.myGroup(status: GroupStatus.forming)],
        ),
      ),
    );
    await tester.pumpWidget(
      buildArabicTestApp(
        pump(const GroupSelectionScreen()),
        size: const Size(360, 800),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../../goldens/design_c_s1_light.png'),
    );
    await tester.pumpWidget(
      buildArabicTestApp(
        pump(const GroupSelectionScreen()),
        dark: true,
        size: const Size(360, 800),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../../goldens/design_c_s1_dark.png'),
    );
  });

  testWidgets('empty: branded panel with one helpful action', (tester) async {
    when(
      () => repo.getMyGroups(),
    ).thenAnswer((_) async => Success(TestFixtures.overview()));

    await tester.pumpWidget(
      buildArabicTestApp(pump(const GroupSelectionScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text(ArabicStrings.noApprovedGroups), findsOneWidget);
    expect(find.byType(HalaqaLogo), findsOneWidget);
    expect(find.text(ArabicStrings.groupSelectionEmptyMessage), findsOneWidget);
    expect(find.text(ArabicStrings.searchGroupAction), findsOneWidget);
    expect(find.text(ArabicStrings.createGroup), findsOneWidget);
    expect(find.text(ArabicStrings.iHaveInviteLink), findsOneWidget);
  });

  testWidgets('My Groups uses the standard section header', (tester) async {
    when(
      () => repo.getMyGroups(),
    ).thenAnswer((_) async => Success(TestFixtures.overview()));

    await tester.pumpWidget(
      buildArabicTestApp(pump(const GroupSelectionScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppSectionHeader), findsOneWidget);
    expect(find.text(ArabicStrings.groupSelectionTitle), findsOneWidget);
  });

  testWidgets('pending rows show the pending chip and cancel action', (
    tester,
  ) async {
    when(() => repo.getMyGroups()).thenAnswer(
      (_) async => Success(
        TestFixtures.overview(
          pending: [
            PendingJoinRequest(
              joinRequestId: 'jr1',
              groupId: 'g9',
              groupName: 'مجموعة الانتظار',
              requestedAt: DateTime.parse('2026-11-14T10:00:00Z'),
              source: JoinSource.invite,
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(
      buildArabicTestApp(pump(const GroupSelectionScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('مجموعة الانتظار'), findsOneWidget);
    expect(find.text(ArabicStrings.pendingShortLabel), findsOneWidget);
    expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    expect(find.text(ArabicStrings.pendingRequestHint), findsOneWidget);
    // Compact row: group emblem, quiet text action, no big outlined button.
    final card = find.ancestor(
      of: find.text('مجموعة الانتظار'),
      matching: find.byType(AppCard),
    );
    expect(
      find.descendant(of: card, matching: find.byType(GroupAvatar)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.byType(OutlinedButton)),
      findsNothing,
    );
    expect(
      find.widgetWithText(TextButton, ArabicStrings.cancelJoinRequestAction),
      findsOneWidget,
    );

    when(
      () => repo.cancelJoinRequest('jr1'),
    ).thenAnswer((_) async => const Success<void>(null));
    await tester.tap(find.text(ArabicStrings.cancelJoinRequestAction));
    await tester.pumpAndSettle();
    verify(() => repo.cancelJoinRequest('jr1')).called(1);
    expect(find.text('مجموعة الانتظار'), findsNothing);
  });

  testWidgets('long pending group names take two lines, then ellipsize', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const longName =
        'حلقة الفجر للمراجعة اليومية مع الأهل والأصدقاء في الحي القديم والجديد';
    when(() => repo.getMyGroups()).thenAnswer(
      (_) async => Success(
        TestFixtures.overview(
          pending: [
            PendingJoinRequest(
              joinRequestId: 'jr1',
              groupId: 'g9',
              groupName: longName,
              requestedAt: DateTime.parse('2026-11-14T10:00:00Z'),
              source: JoinSource.invite,
            ),
          ],
        ),
      ),
    );
    for (final dark in [false, true]) {
      await tester.pumpWidget(
        buildArabicTestApp(
          pump(const GroupSelectionScreen()),
          dark: dark,
          size: const Size(360, 800),
        ),
      );
      await tester.pumpAndSettle();
      final title = tester.widget<Text>(find.text(longName));
      expect(title.maxLines, 2);
      expect(title.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/pending_request_${dark ? 'dark' : 'light'}.png',
        ),
      );
    }
  });

  testWidgets('offline: stale overview shows the offline banner', (
    tester,
  ) async {
    when(() => repo.getMyGroups()).thenAnswer(
      (_) async => Success(
        TestFixtures.overview(groups: [TestFixtures.myGroup()], stale: true),
      ),
    );

    await tester.pumpWidget(
      buildArabicTestApp(pump(const GroupSelectionScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text(ArabicStrings.offlineStale), findsOneWidget);
  });

  testWidgets('failure: StatePanel with retry', (tester) async {
    when(() => repo.getMyGroups()).thenAnswer(
      (_) async =>
          const FailureResult(NetworkFailure(message: 'n', code: 'network')),
    );

    await tester.pumpWidget(
      buildArabicTestApp(pump(const GroupSelectionScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text(ArabicStrings.retry), findsOneWidget);
  });

  testWidgets('all constitution variants render without overflow', (
    tester,
  ) async {
    when(() => repo.getMyGroups()).thenAnswer(
      (_) async => Success(
        TestFixtures.overview(
          groups: [
            TestFixtures.myGroup(),
            TestFixtures.myGroup(groupId: 'g2'),
          ],
          pending: [
            PendingJoinRequest(
              joinRequestId: 'jr1',
              groupId: 'g9',
              groupName: 'مجموعة طويلة الاسم للتمييز',
              requestedAt: DateTime.parse('2026-11-14T10:00:00Z'),
              source: JoinSource.invite,
            ),
          ],
        ),
      ),
    );

    await pumpAllVariants(tester, pump(const GroupSelectionScreen()), (
      tester,
      variant,
    ) async {
      expect(tester.takeException(), isNull, reason: variant);
    });
  });
}
