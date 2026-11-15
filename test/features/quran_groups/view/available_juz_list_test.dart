import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/core/quran/quran_metadata_repository.dart';
import 'package:quran_daily/core/quran/juz_info.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/view/widgets/available_juz_list.dart';

import '../../../helpers/widget_test_app.dart';

class _Metadata extends Mock implements QuranMetadataRepository {}

Assignment _assignment({
  required String id,
  required int juz,
  AssignmentStatusEnum status = AssignmentStatusEnum.available,
  AssignmentKind kind = AssignmentKind.unassigned,
  bool isMe = false,
}) => Assignment(
  assignmentId: id,
  juz: juz,
  seatNumber: juz,
  kind: kind,
  status: status,
  isMe: isMe,
);

void main() {
  testWidgets(
    'available juz offers an action and calls its handler in every variant',
    (tester) async {
      final metadata = _Metadata();
      when(metadata.load).thenAnswer((_) async {});
      when(() => metadata.juz(any())).thenReturn(
        const JuzInfo(
          number: 4,
          startSura: 1,
          startAya: 1,
          endSura: 1,
          endAya: 2,
        ),
      );
      when(() => metadata.suraName(any())).thenReturn('metadata-name');
      Assignment? selected;
      await pumpAllVariants(
        tester,
        AvailableJuzList(
          assignments: [_assignment(id: 'a4', juz: 4)],
          metadataRepository: metadata,
          onVolunteer: (a) => selected = a,
        ),
        (tester, _) async {
          final action = find.text(ArabicStrings.volunteerForJuz);
          expect(action, findsOneWidget);
          await tester.tap(action);
          expect(selected?.assignmentId, 'a4');
          expect(tester.takeException(), isNull);
        },
      );
    },
  );

  testWidgets(
    'taken volunteer juz displays explicit taken status and no action',
    (tester) async {
      final metadata = _Metadata();
      when(metadata.load).thenAnswer((_) async {});
      when(() => metadata.juz(any())).thenReturn(
        const JuzInfo(
          number: 8,
          startSura: 1,
          startAya: 1,
          endSura: 1,
          endAya: 2,
        ),
      );
      when(() => metadata.suraName(any())).thenReturn('metadata-name');
      await tester.pumpWidget(
        buildArabicTestApp(
          AvailableJuzList(
            assignments: [
              _assignment(
                id: 'a8',
                juz: 8,
                status: AssignmentStatusEnum.pending,
                kind: AssignmentKind.volunteer,
              ),
            ],
            metadataRepository: metadata,
            onVolunteer: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.text(ArabicStrings.volunteerTaken), findsOneWidget);
      expect(find.text(ArabicStrings.volunteerForJuz), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
