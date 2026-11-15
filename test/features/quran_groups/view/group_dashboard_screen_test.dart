import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/design_system/widgets/part_tile.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/core/quran/quran_metadata_repository.dart';
import 'package:quran_daily/features/quran_groups/cubit/dashboard/dashboard_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/khatma_repository.dart';
import 'package:quran_daily/features/quran_groups/view/screens/group_dashboard_screen.dart';

import '../../../helpers/widget_test_app.dart';

class _Repository extends Mock implements KhatmaRepository {}

DashboardSnapshot _snapshot({
  bool full = false,
  bool stale = false,
  DayState dayState = DayState.open,
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
    myRole: GroupRole.member,
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
    isStale: stale,
  );
}

void main() {
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
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
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
}
