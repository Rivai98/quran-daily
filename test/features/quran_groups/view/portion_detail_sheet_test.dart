import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/design_system/widgets/app_avatar.dart';
import 'package:quran_daily/core/design_system/widgets/status_chip.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/core/quran/portion_unit.dart';
import 'package:quran_daily/core/quran/quran_metadata_repository.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/view/widgets/portion_detail_sheet.dart';

import '../../../helpers/quran_metadata_test_asset_bundle.dart';
import '../../../helpers/widget_test_app.dart';

void main() {
  late QuranMetadataRepository metadataRepository;

  setUpAll(() async {
    metadataRepository = QuranMetadataRepository(
      bundle: QuranMetadataTestAssetBundle(),
    );
    await metadataRepository.load();
  });

  group('PortionDetailSheet (T010 & T011)', () {
    testWidgets('renders reader details, status, kind, time and profile action', (tester) async {
      final assignment = Assignment(
        assignmentId: 'a-10',
        juz: 10,
        portionIndex: 10,
        seatNumber: 10,
        kind: AssignmentKind.volunteer,
        status: AssignmentStatusEnum.completed,
        readerDisplayName: 'عمر الفاروق',
        reader: const ReaderInfo(
          userId: 'u-omar',
          displayName: 'عمر الفاروق',
          initials: 'ع ف',
        ),
        isMe: false,
        completedAt: DateTime.parse('2026-11-15T09:30:00.000Z'),
      );

      var profileOpened = false;

      await tester.pumpWidget(
        buildArabicTestApp(
          Scaffold(
            body: PortionDetailSheet(
              assignment: assignment,
              unit: PortionUnit.juz,
              groupId: 'g-1',
              metadataRepository: metadataRepository,
              onOpenProfile: (userId) {
                expect(userId, 'u-omar');
                profileOpened = true;
              },
            ),
          ),
        ),
      );

      expect(find.text(ArabicStrings.portionName(PortionUnit.juz, 10)), findsOneWidget);
      expect(find.text('عمر الفاروق'), findsOneWidget);
      expect(find.byType(UserAvatar), findsOneWidget);
      expect(find.byType(StatusChip), findsOneWidget);
      expect(find.textContaining(ArabicStrings.kindVolunteer), findsOneWidget);
      expect(find.text(ArabicStrings.openProfile), findsOneWidget);

      await tester.tap(find.text(ArabicStrings.openProfile));
      await tester.pump();
      expect(profileOpened, isTrue);
    });

    testWidgets('vacant portion displays available status and volunteer action', (tester) async {
      final assignment = const Assignment(
        assignmentId: 'a-vacant',
        juz: 3,
        portionIndex: 3,
        seatNumber: 3,
        kind: AssignmentKind.unassigned,
        status: AssignmentStatusEnum.available,
        isMe: false,
      );

      var volunteered = false;

      await tester.pumpWidget(
        buildArabicTestApp(
          Scaffold(
            body: PortionDetailSheet(
              assignment: assignment,
              unit: PortionUnit.juz,
              groupId: 'g-1',
              metadataRepository: metadataRepository,
              onVolunteer: () {
                volunteered = true;
              },
            ),
          ),
        ),
      );

      expect(find.text(ArabicStrings.portionVacant), findsOneWidget);
      expect(find.text(ArabicStrings.volunteerForPortion), findsOneWidget);
      expect(find.text(ArabicStrings.openProfile), findsNothing);

      await tester.tap(find.text(ArabicStrings.volunteerForPortion));
      await tester.pump();
      expect(volunteered, isTrue);
    });

    testWidgets('hidden reader displays unread without name (privacy rule)', (tester) async {
      final assignment = const Assignment(
        assignmentId: 'a-hidden',
        juz: 4,
        portionIndex: 4,
        seatNumber: 4,
        kind: AssignmentKind.seat,
        status: AssignmentStatusEnum.unread,
        readerDisplayName: null,
        reader: null,
        isMe: false,
      );

      await tester.pumpWidget(
        buildArabicTestApp(
          Scaffold(
            body: PortionDetailSheet(
              assignment: assignment,
              unit: PortionUnit.juz,
              groupId: 'g-1',
              metadataRepository: metadataRepository,
            ),
          ),
        ),
      );

      expect(find.text(ArabicStrings.unread), findsAtLeastNWidgets(1));
      expect(find.text(ArabicStrings.openProfile), findsNothing);
    });
  });
}
