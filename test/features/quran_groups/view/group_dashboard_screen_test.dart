import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/core/design_system/app_colors.dart';
import 'package:quran_daily/core/design_system/app_spacing.dart';
import 'package:quran_daily/core/quran/quran_metadata_repository.dart';
import 'package:quran_daily/core/quran/portion_unit.dart';

import '../../../helpers/quran_metadata_test_asset_bundle.dart';

import 'package:quran_daily/features/quran_groups/cubit/dashboard/dashboard_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/khatma_repository.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/design_system/widgets/part_tile.dart';
import 'package:quran_daily/core/design_system/widgets/skeleton.dart';
import 'package:quran_daily/features/quran_groups/view/widgets/override_assignment_sheet.dart';
import 'package:quran_daily/features/quran_groups/view/screens/group_dashboard_screen.dart';
import 'package:quran_daily/features/quran_groups/view/widgets/forming_group_view.dart';

import '../../../helpers/widget_test_app.dart';

class _Repository extends Mock implements KhatmaRepository {}

class _GroupsRepository extends Mock implements GroupsRepository {}

DashboardSnapshot _snapshot({
  bool full = false,
  bool stale = false,
  GroupRole role = GroupRole.member,
  DayState dayState = DayState.open,
  PortionUnit? pendingPortionUnit,
  PortionUnit portionUnit = PortionUnit.juz,
  CycleInfo? cycle,
}) {
  final assignments = List.generate(
    30,
    (i) => Assignment(
      assignmentId: 'a$i',
      juz: i + 1,
      seatNumber: i + 1,
      kind: AssignmentKind.seat,
      status: i == 0
          ? AssignmentStatusEnum.pending
          : (full && i == 29
                ? AssignmentStatusEnum.completed
                : AssignmentStatusEnum.available),
      isMe: i == 0,
    ),
  );
  return DashboardSnapshot(
    groupId: 'g1',
    groupName: 'مجموعة',
    myRole: role,
    status: GroupStatus.active,
    serverGeneratedAt: DateTime.parse('2026-11-15T10:00:00Z'),
    today: GroupDayInfo(
      groupDate: '2026-11-15',
      state: dayState,
      completedCount: 0,
      lateCount: 0,
      missedCount: 0,
      unreadCount: 0,
      pendingCount: 1,
      availableCount: 29,
      fullKhatma: full,
      endsAt: DateTime.parse('2026-11-15T23:59:00Z'),
    ),
    assignments: assignments,
    myAssignments: [assignments.first],
    activeMemberCount: 1,
    isStale: stale,
    pendingPortionUnit: pendingPortionUnit,
    portionUnit: portionUnit,
    cycle: cycle,
  );
}

void main() {
  setUpAll(loadAppFontsForGoldenTests);

  testWidgets('golden: active dashboard at 360x800 in light and dark themes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cubit = DashboardCubit(
      repository: _Repository(),
      groupId: 'g1',
      initialState: DashboardState(
        status: DashboardStatus.success,
        snapshot: _snapshot(),
      ),
    );
    addTearDown(cubit.close);
    final metadataRepository = QuranMetadataRepository(
      bundle: QuranMetadataTestAssetBundle(),
    );
    await tester.runAsync(metadataRepository.load);

    for (final dark in [false, true]) {
      await tester.pumpWidget(
        buildArabicTestApp(
          BlocProvider.value(
            value: cubit,
            child: GroupDashboardScreen(metadataRepository: metadataRepository),
          ),
          dark: dark,
          size: const Size(360, 800),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(GroupDashboardScreen),
        matchesGoldenFile(
          dark
              ? 'goldens/polish_b_dashboard_dark.png'
              : 'goldens/polish_b_dashboard_light.png',
        ),
      );
    }
  });

  testWidgets('non-owner juz tiles do not open the override flow', (
    tester,
  ) async {
    final groups = _GroupsRepository();
    final cubit = DashboardCubit(
      repository: _Repository(),
      groupsRepository: groups,
      groupId: 'g1',
      initialState: DashboardState(
        status: DashboardStatus.success,
        snapshot: _snapshot(role: GroupRole.member),
      ),
    );
    addTearDown(cubit.close);
    final metadataRepository = QuranMetadataRepository(
      bundle: QuranMetadataTestAssetBundle(),
    );
    await tester.runAsync(metadataRepository.load);
    await tester.pumpWidget(
      buildArabicTestApp(
        BlocProvider.value(
          value: cubit,
          child: GroupDashboardScreen(metadataRepository: metadataRepository),
        ),
      ),
    );

    await tester.ensureVisible(find.byType(PartTile).first);
    await tester.tap(find.byType(PartTile).first);
    await tester.pumpAndSettle();

    expect(find.byType(OverrideAssignmentSheet), findsNothing);
    verifyNever(() => groups.getMembers('g1'));
  });

  testWidgets('owner opens override sheet from a juz tile and submits', (
    tester,
  ) async {
    final repository = _Repository();
    final groups = _GroupsRepository();
    when(() => groups.getMembers('g1')).thenAnswer(
      (_) async => Success(
        const SeatMap(
          groupId: 'g1',
          activeMemberCount: 2,
          members: [
            SeatMember(
              membershipId: 'm1',
              displayName: ArabicStrings.memberRole,
              role: GroupRole.member,
              seatNumber: 2,
            ),
          ],
        ),
      ),
    );
    when(() => repository.overrideAssignment('a0', 'm1'))
        .thenAnswer((_) async => Success(_snapshot(role: GroupRole.owner)));
    final cubit = DashboardCubit(
      repository: repository,
      groupsRepository: groups,
      groupId: 'g1',
      initialState: DashboardState(
        status: DashboardStatus.success,
        snapshot: _snapshot(role: GroupRole.owner),
      ),
    );
    addTearDown(cubit.close);
    final metadataRepository = QuranMetadataRepository(
      bundle: QuranMetadataTestAssetBundle(),
    );
    await tester.runAsync(metadataRepository.load);
    await tester.pumpWidget(
      buildArabicTestApp(
        BlocProvider.value(
          value: cubit,
          child: GroupDashboardScreen(metadataRepository: metadataRepository),
        ),
      ),
    );
    await tester.ensureVisible(find.byType(PartTile).first);
    await tester.tap(find.byType(PartTile).first);
    await tester.pumpAndSettle();
    expect(find.byType(OverrideAssignmentSheet), findsOneWidget);
    await tester.tap(find.text(ArabicStrings.memberRole));
    await tester.pump();
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();
    verify(() => repository.overrideAssignment('a0', 'm1')).called(1);
    expect(find.byType(OverrideAssignmentSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('grace day banner is visible on dashboard', (tester) async {
    final snapshot = _snapshot(dayState: DayState.grace);
    final cubit = DashboardCubit(
      repository: _Repository(),
      groupId: 'g1',
      initialState: DashboardState(
        status: DashboardStatus.success,
        snapshot: snapshot,
      ),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      buildArabicTestApp(
        BlocProvider.value(
          value: cubit,
          child: GroupDashboardScreen(
            metadataRepository: QuranMetadataRepository(),
          ),
        ),
      ),
    );
    expect(find.text(ArabicStrings.gracePeriodNotice), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading state announces progress', (tester) async {
    final cubit = DashboardCubit(
      repository: _Repository(),
      groupId: 'g1',
      initialState: const DashboardState(status: DashboardStatus.loading),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      buildArabicTestApp(
        BlocProvider.value(
          value: cubit,
          child: GroupDashboardScreen(
            metadataRepository: QuranMetadataRepository(),
          ),
        ),
      ),
    );
    expect(find.byType(SkeletonBox), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failure state offers a retry action', (tester) async {
    final cubit = DashboardCubit(
      repository: _Repository(),
      groupId: 'g1',
      initialState: const DashboardState(status: DashboardStatus.failure),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      buildArabicTestApp(
        BlocProvider.value(
          value: cubit,
          child: GroupDashboardScreen(
            metadataRepository: QuranMetadataRepository(),
          ),
        ),
      ),
    );
    expect(find.text(ArabicStrings.dashboardLoadError), findsOneWidget);
    expect(find.text(ArabicStrings.retry), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'active dashboard keeps my assignment first and renders 30 semantic tiles',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final repository = _Repository();
      final cubit = DashboardCubit(
        repository: repository,
        groupId: 'g1',
        initialState: DashboardState(
          status: DashboardStatus.success,
          snapshot: _snapshot(),
        ),
      );
      addTearDown(cubit.close);
      await tester.pumpWidget(
        buildArabicTestApp(
          BlocProvider.value(
            value: cubit,
            child: GroupDashboardScreen(
              metadataRepository: QuranMetadataRepository(),
            ),
          ),
        ),
      );
      expect(find.byType(PartTile), findsNWidgets(30));
      expect(find.text('مجموعة'), findsOneWidget);
      expect(find.text(ArabicStrings.myWirdToday), findsOneWidget);
      expect(find.text(ArabicStrings.readNowAction), findsOneWidget);
      expect(find.byTooltip(ArabicStrings.mushafTitle), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(IconButton),
        ),
        findsNWidgets(2),
      );
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(PopupMenuButton<String>),
        ),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.text(ArabicStrings.myWirdToday)).dy,
        lessThan(640),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shows completion and stale banners and adapts to all required variants',
    (tester) async {
      final repository = _Repository();
      final cubit = DashboardCubit(
        repository: repository,
        groupId: 'g1',
        initialState: DashboardState(
          status: DashboardStatus.offline,
          snapshot: _snapshot(full: true, stale: true),
        ),
      );
      addTearDown(cubit.close);
      await pumpAllVariants(
        tester,
        BlocProvider.value(
          value: cubit,
          child: GroupDashboardScreen(
            metadataRepository: QuranMetadataRepository(),
          ),
        ),
        (tester, variant) async {
          expect(find.byType(PartTile), findsNWidgets(30));
          expect(find.text(ArabicStrings.offlineStale), findsOneWidget);
          expect(find.text(ArabicStrings.fullKhatmaBanner), findsOneWidget);
          expect(find.text(ArabicStrings.khatmaDuaNote), findsOneWidget);
          expect(find.text(ArabicStrings.availableJuzTitle), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    },
  );

  testWidgets('forming group presents seat map and empty state', (
    tester,
  ) async {
    final snapshot = DashboardSnapshot(
      groupId: 'g1',
      groupName: 'مجموعة',
      myRole: GroupRole.owner,
      status: GroupStatus.forming,
      serverGeneratedAt: DateTime.parse('2026-11-15T10:00:00Z'),
      activeMemberCount: 1,
      seats: const SeatMap(groupId: 'g1', activeMemberCount: 1, members: []),
    );
    final cubit = DashboardCubit(
      repository: _Repository(),
      groupId: 'g1',
      initialState: DashboardState(
        status: DashboardStatus.empty,
        snapshot: snapshot,
      ),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      buildArabicTestApp(
        BlocProvider.value(
          value: cubit,
          child: GroupDashboardScreen(
            metadataRepository: QuranMetadataRepository(),
          ),
        ),
      ),
    );
    expect(find.text('مجموعة'), findsOneWidget);
    expect(find.byType(PartTile), findsNothing);
  });

  Future<_GroupsRepository> pumpWithRole(
    WidgetTester tester, {
    required GroupRole role,
    GroupStatus status = GroupStatus.active,
    PortionUnit? pendingPortionUnit,
    PortionUnit portionUnit = PortionUnit.juz,
  }) async {
    final groups = _GroupsRepository();
    final khatma = _Repository();
    when(() => khatma.getDashboard('g1'))
        .thenAnswer((_) async => Success(_snapshot(role: role)));
    final snapshot = status == GroupStatus.forming
        ? DashboardSnapshot(
            groupId: 'g1',
            groupName: 'مجموعة',
            myRole: role,
            status: GroupStatus.forming,
            serverGeneratedAt: DateTime.parse('2026-11-15T10:00:00Z'),
            activeMemberCount: 1,
            seats: const SeatMap(
              groupId: 'g1',
              activeMemberCount: 1,
              members: [],
              inviteCode: 'ABC123',
            ),
          )
        : _snapshot(
            role: role,
            pendingPortionUnit: pendingPortionUnit,
            portionUnit: portionUnit,
            cycle: portionUnit == PortionUnit.juz
                ? null
                : const CycleInfo(
                    number: 1,
                    day: 1,
                    length: 2,
                    completed: 1,
                    total: 60,
                  ),
          );
    final cubit = DashboardCubit(
      repository: khatma,
      groupsRepository: groups,
      groupId: 'g1',
      initialState: DashboardState(
        status: status == GroupStatus.forming
            ? DashboardStatus.empty
            : DashboardStatus.success,
        snapshot: snapshot,
      ),
    );
    addTearDown(cubit.close);
    final metadataRepository = QuranMetadataRepository(
      bundle: QuranMetadataTestAssetBundle(),
    );
    await tester.runAsync(metadataRepository.load);
    await tester.pumpWidget(
      buildArabicTestApp(
        BlocProvider.value(
          value: cubit,
          child: GroupDashboardScreen(metadataRepository: metadataRepository),
        ),
      ),
    );
    await tester.pump();
    return groups;
  }

  testWidgets('forming owner can share the invite and start the khatma', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final groups = await pumpWithRole(
      tester,
      role: GroupRole.owner,
      status: GroupStatus.forming,
    );
    when(() => groups.startKhatma('g1', any()))
        .thenAnswer((_) async => Success(_snapshot(role: GroupRole.owner)));

    expect(find.byType(FormingGroupView), findsOneWidget);
    expect(find.text(ArabicStrings.shareInviteAction), findsOneWidget);

    await tester.ensureVisible(
      find.text(ArabicStrings.startKhatmaAction).first,
    );
    await tester.tap(find.text(ArabicStrings.startKhatmaAction).first);
    await tester.pumpAndSettle();
    expect(find.byType(ChoiceChip), findsNWidgets(30));
    expect(
      tester.getSize(find.byType(ChoiceChip).first),
      const Size(AppSpacing.xxl, AppSpacing.xxl),
    );
    expect(
      tester.widget<ChoiceChip>(find.byType(ChoiceChip).first).selectedColor,
      Theme.of(tester.element(find.byType(ChoiceChip).first))
          .extension<AppColors>()!
          .primaryContainer,
    );
    await tester.tap(find.text(ArabicStrings.startKhatmaAction).last);
    await tester.pumpAndSettle();

    verify(() => groups.startKhatma('g1', any())).called(1);
    expect(find.byType(FormingGroupView), findsNothing);
  });

  testWidgets('forming member sees the forming view without a start action', (
    tester,
  ) async {
    await pumpWithRole(
      tester,
      role: GroupRole.member,
      status: GroupStatus.forming,
    );
    expect(find.byType(FormingGroupView), findsOneWidget);
    expect(find.text(ArabicStrings.startKhatmaAction), findsNothing);
  });

  testWidgets('dashboard announces a pending portion unit change', (
    tester,
  ) async {
    await pumpWithRole(
      tester,
      role: GroupRole.member,
      pendingPortionUnit: PortionUnit.hizb,
      portionUnit: PortionUnit.hizb,
    );
    expect(
      find.text(ArabicStrings.pendingPortionChange(PortionUnit.hizb)),
      findsOneWidget,
    );
    expect(
      find.text(ArabicStrings.portionName(PortionUnit.hizb, 1)),
      findsOneWidget,
    );
    expect(find.text(ArabicStrings.cycleDayProgress(1, 2)), findsOneWidget);
    expect(find.text(ArabicStrings.groupProgressLabel(0, 1)), findsOneWidget);
    expect(
      find.text(ArabicStrings.groupDashboardMeta(1, PortionUnit.hizb)),
      findsOneWidget,
    );
  });

  testWidgets('owner reaches history, members, requests and group settings', (
    tester,
  ) async {
    await pumpWithRole(tester, role: GroupRole.owner);

    await tester.tap(find.byTooltip(ArabicStrings.groupMenuTooltip));
    await tester.pumpAndSettle();

    expect(find.text(ArabicStrings.openHistoryAction), findsOneWidget);
    expect(find.text(ArabicStrings.manageMembersAction), findsOneWidget);
    expect(find.text(ArabicStrings.reviewJoinRequestsAction), findsOneWidget);
    expect(find.text(ArabicStrings.groupSettingsAction), findsOneWidget);

    // Every item leads with an icon in the item's text color (ui-craft).
    const expected = {
      ArabicStrings.setMainGroupAction: Icons.push_pin_rounded,
      ArabicStrings.openHistoryAction: Icons.history_rounded,
      ArabicStrings.manageMembersAction: Icons.people_alt_rounded,
      ArabicStrings.reviewJoinRequestsAction: Icons.person_add_alt_1_rounded,
      ArabicStrings.groupSettingsAction: Icons.tune_rounded,
    };
    for (final entry in expected.entries) {
      final item = find.ancestor(
        of: find.text(entry.key),
        matching: find.byType(PopupMenuItem<String>),
      );
      final icon = find.descendant(
        of: item,
        matching: find.byIcon(entry.value),
      );
      expect(icon, findsOneWidget, reason: entry.key);
      final label = tester.widget<Text>(
        find.descendant(of: item, matching: find.text(entry.key)),
      );
      final labelColor =
          label.style?.color ??
          DefaultTextStyle.of(tester.element(find.text(entry.key))).style.color;
      expect(tester.widget<Icon>(icon).color, labelColor, reason: entry.key);
    }
  });

  testWidgets('supervisor manages members and requests but not settings', (
    tester,
  ) async {
    await pumpWithRole(tester, role: GroupRole.supervisor);
    await tester.tap(find.byTooltip(ArabicStrings.groupMenuTooltip));
    await tester.pumpAndSettle();

    expect(find.text(ArabicStrings.manageMembersAction), findsOneWidget);
    expect(find.text(ArabicStrings.reviewJoinRequestsAction), findsOneWidget);
    expect(find.text(ArabicStrings.groupSettingsAction), findsNothing);
  });

  testWidgets('member can pin main group but cannot manage members', (
    tester,
  ) async {
    await pumpWithRole(tester, role: GroupRole.member);

    await tester.tap(find.byTooltip(ArabicStrings.groupMenuTooltip));
    await tester.pumpAndSettle();
    expect(find.text(ArabicStrings.openHistoryAction), findsOneWidget);
    expect(find.text(ArabicStrings.setMainGroupAction), findsOneWidget);
    expect(find.text(ArabicStrings.manageMembersAction), findsNothing);
  });
}
