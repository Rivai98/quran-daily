import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/design_system/widgets/offline_banner.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/core/quran/quran_metadata_repository.dart';
import 'package:quran_daily/core/quran/portion_unit.dart';
import 'package:quran_daily/features/quran_groups/cubit/assignment/assignment_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/khatma_repository.dart';
import 'package:quran_daily/features/quran_groups/view/screens/personal_assignment_screen.dart';

import '../../../helpers/widget_test_app.dart';
import '../../../helpers/quran_metadata_test_asset_bundle.dart';

class _Repository extends Mock implements KhatmaRepository {}

QuranMetadataRepository _metadata() =>
    QuranMetadataRepository(bundle: QuranMetadataTestAssetBundle());

Assignment _assignment(AssignmentStatusEnum status) => Assignment(
  assignmentId: 'a-1',
  juz: 1,
  seatNumber: 1,
  kind: AssignmentKind.seat,
  status: status,
  isMe: true,
);

DashboardSnapshot _snapshot({
  AssignmentStatusEnum status = AssignmentStatusEnum.pending,
  DayState dayState = DayState.open,
  PortionUnit portionUnit = PortionUnit.juz,
}) {
  final assignment = _assignment(status);
  return DashboardSnapshot(
    groupId: 'g1',
    groupName: 'مجموعة',
    myRole: GroupRole.member,
    status: GroupStatus.active,
    serverGeneratedAt: DateTime.parse('2026-11-15T10:00:00Z'),
    today: GroupDayInfo(
      groupDate: '2026-11-15',
      state: dayState,
      completedCount: status == AssignmentStatusEnum.completed ? 1 : 0,
      lateCount: status == AssignmentStatusEnum.late ? 1 : 0,
      missedCount: 0,
      unreadCount: 0,
      pendingCount: status == AssignmentStatusEnum.pending ? 1 : 0,
      availableCount: 29,
      fullKhatma: false,
      endsAt: DateTime.parse('2026-11-15T23:59:00Z'),
    ),
    myAssignments: [assignment],
    assignments: [assignment],
    portionUnit: portionUnit,
  );
}

void main() {
  testWidgets(
    'portion assignment shows metadata name and reading range in every variant',
    (tester) async {
      final metadata = _metadata();
      await tester.runAsync(metadata.load);
      const unit = PortionUnit.hizb;
      final snapshot = _snapshot(portionUnit: unit);
      final cubit = AssignmentCubit(
        repository: _Repository(),
        assignment: snapshot.myAssignments.single,
      );
      addTearDown(cubit.close);
      final portion = metadata.portion(
        unit,
        snapshot.myAssignments.single.portionIndex,
      );
      final range = ArabicStrings.portionRange(
        metadata.suraName(portion.startSura),
        portion.startAya,
        metadata.suraName(portion.endSura),
        portion.endAya,
      );
      await pumpAllVariants(
        tester,
        BlocProvider.value(
          value: cubit,
          child: PersonalAssignmentScreen(
            snapshot: snapshot,
            metadataRepository: metadata,
          ),
        ),
        (tester, variant) async {
          expect(
            find.text(ArabicStrings.portionName(unit, 1)),
            findsOneWidget,
            reason: variant,
          );
          expect(find.text(range), findsOneWidget, reason: variant);
          expect(tester.takeException(), isNull, reason: variant);
        },
      );
    },
  );

  testWidgets(
    'pending assignment offers one completion action and hides reader slot',
    (tester) async {
      final repository = _Repository();
      final snapshot = _snapshot();
      final metadata = _metadata();
      final cubit = AssignmentCubit(
        repository: repository,
        assignment: snapshot.myAssignments.single,
      );
      addTearDown(cubit.close);
      await tester.pumpWidget(
        buildArabicTestApp(
          BlocProvider.value(
            value: cubit,
            child: PersonalAssignmentScreen(
              snapshot: snapshot,
              metadataRepository: metadata,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(ArabicStrings.completeAction), findsOneWidget);
      expect(find.text(ArabicStrings.noQuranReader), findsNothing);
      expect(find.text(ArabicStrings.readNowAction), findsOneWidget);
      expect(find.text(ArabicStrings.undoAction), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('completion button names the group portion unit', (
    tester,
  ) async {
    for (final unit in PortionUnit.values) {
      final snapshot = _snapshot(portionUnit: unit);
      final cubit = AssignmentCubit(
        repository: _Repository(),
        assignment: snapshot.myAssignments.single,
      );
      await tester.pumpWidget(
        buildArabicTestApp(
          BlocProvider.value(
            value: cubit,
            child: PersonalAssignmentScreen(
              snapshot: snapshot,
              metadataRepository: _metadata(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(ArabicStrings.completeActionFor(unit)),
        findsOneWidget,
        reason: unit.name,
      );
      expect(
        ArabicStrings.completeActionFor(unit),
        contains(ArabicStrings.portionUnitName(unit)),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await cubit.close();
    }
  });

  testWidgets('undo waits for confirmation before reverting completion', (
    tester,
  ) async {
    final repository = _Repository();
    final snapshot = _snapshot(status: AssignmentStatusEnum.pending);
    final metadata = _metadata();
    final cubit = AssignmentCubit(
      repository: repository,
      assignment: snapshot.myAssignments.single,
    );
    when(() => repository.markComplete('a-1', any())).thenAnswer(
      (_) async => Success(_snapshot(status: AssignmentStatusEnum.completed)),
    );
    when(
      () => repository.undoCompletion('a-1'),
    ).thenAnswer((_) async => Success(_snapshot()));
    addTearDown(cubit.close);
    await tester.pumpWidget(
      buildArabicTestApp(
        BlocProvider.value(
          value: cubit,
          child: PersonalAssignmentScreen(
            snapshot: snapshot,
            metadataRepository: metadata,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(ArabicStrings.completeAction));
    await tester.pumpAndSettle();
    expect(find.text(ArabicStrings.completed), findsOneWidget);
    await tester.tap(find.text(ArabicStrings.undoAction));
    await tester.pumpAndSettle();
    verifyNever(() => repository.undoCompletion('a-1'));
    await tester.tap(find.text(ArabicStrings.confirmUndoAction));
    await tester.pumpAndSettle();
    verify(() => repository.undoCompletion('a-1')).called(1);
    expect(find.text(ArabicStrings.pending), findsOneWidget);
  });

  testWidgets('queued and grace states render in all required variants', (
    tester,
  ) async {
    final repository = _Repository();
    final pending = _snapshot(dayState: DayState.grace);
    final assignment = _assignment(AssignmentStatusEnum.pending);
    final snapshot = DashboardSnapshot(
      groupId: pending.groupId,
      groupName: pending.groupName,
      myRole: pending.myRole,
      status: pending.status,
      serverGeneratedAt: pending.serverGeneratedAt,
      today: pending.today,
      assignments: pending.assignments,
      myAssignments: [assignment],
    );
    final metadata = _metadata();
    final cubit = AssignmentCubit(
      repository: repository,
      dayState: DayState.grace,
      assignment: assignment,
    );
    when(() => repository.markComplete('a-1', any())).thenAnswer(
      (_) async => const FailureResult<DashboardSnapshot>(
        OfflineQueuedFailure(message: 'queued', code: 'offline_queued'),
      ),
    );
    await cubit.complete(DateTime.parse('2026-11-15T12:00:00Z'));
    addTearDown(cubit.close);
    await pumpAllVariants(
      tester,
      BlocProvider.value(
        value: cubit,
        child: PersonalAssignmentScreen(
          snapshot: snapshot,
          metadataRepository: metadata,
        ),
      ),
      (tester, _) async {
        await tester.pumpAndSettle();
        expect(find.text(ArabicStrings.gracePeriodNotice), findsOneWidget);
        expect(find.byType(OfflineBanner), findsNWidgets(2));
        expect(find.text(ArabicStrings.late), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  testWidgets('network failure displays the retry action', (tester) async {
    final repository = _Repository();
    final snapshot = _snapshot();
    final cubit = AssignmentCubit(
      repository: repository,
      assignment: snapshot.myAssignments.single,
    );
    when(() => repository.markComplete('a-1', any())).thenAnswer(
      (_) async => const FailureResult<DashboardSnapshot>(
        NetworkFailure(message: 'offline', code: 'network'),
      ),
    );
    addTearDown(cubit.close);
    await cubit.complete(DateTime.parse('2026-11-15T12:00:00Z'));
    await tester.pumpWidget(
      buildArabicTestApp(
        BlocProvider.value(
          value: cubit,
          child: PersonalAssignmentScreen(
            snapshot: snapshot,
            metadataRepository: _metadata(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(ArabicStrings.networkFailure), findsOneWidget);
    expect(find.text(ArabicStrings.retry), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
