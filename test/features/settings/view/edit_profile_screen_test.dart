import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';
import 'package:quran_daily/features/settings/view/edit_profile_screen.dart';

import '../../../helpers/widget_test_app.dart';

class _MockGroupsRepository extends Mock implements GroupsRepository {}

void main() {
  late _MockGroupsRepository repository;

  setUp(() {
    repository = _MockGroupsRepository();
  });

  group('EditProfileScreen (T013)', () {
    testWidgets('prefills values and disables save until changed', (tester) async {
      await tester.pumpWidget(
        buildArabicTestApp(
          EditProfileScreen(
            initialDisplayName: 'Sample Name',
            initialBio: 'Sample bio',
            repository: repository,
          ),
        ),
      );

      expect(find.text(ArabicStrings.editProfile), findsOneWidget);
      expect(find.text('Sample Name'), findsOneWidget);
      expect(find.text('Sample bio'), findsOneWidget);
      final save = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, ArabicStrings.saveChanges),
      );
      expect(save.onPressed, isNull);
    });

    testWidgets('validates short display name (< 2 chars)', (tester) async {
      await tester.pumpWidget(
        buildArabicTestApp(
          EditProfileScreen(initialDisplayName: 'Name', repository: repository),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'x');
      await tester.pump();
      await tester.tap(find.text(ArabicStrings.saveChanges));
      await tester.pump();

      expect(find.text(ArabicStrings.invalidDisplayName), findsOneWidget);
      verifyNever(() => repository.updateMyProfile(any(), bio: any(named: 'bio')));
    });

    testWidgets('validates long bio (> 120 chars)', (tester) async {
      final longBio = 'b' * 125;
      await tester.pumpWidget(
        buildArabicTestApp(
          EditProfileScreen(
            initialDisplayName: 'Sample Name',
            initialBio: longBio,
            repository: repository,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField).last, '${longBio}x');
      await tester.pump();
      await tester.tap(find.text(ArabicStrings.saveChanges));
      await tester.pump();

      expect(find.text(ArabicStrings.invalidBio), findsOneWidget);
      verifyNever(() => repository.updateMyProfile(any(), bio: any(named: 'bio')));
    });

    testWidgets('saves changed values', (tester) async {
      when(() => repository.updateMyProfile(any(), bio: any(named: 'bio')))
          .thenAnswer((_) async => Success(
                UserProfile(
                  userId: 'u1',
                  displayName: 'Changed Name',
                  bio: 'Updated bio',
                  updatedAt: DateTime.now(),
                ),
              ));

      await tester.pumpWidget(
        buildArabicTestApp(
          EditProfileScreen(
            initialDisplayName: 'Sample Name',
            initialBio: 'Sample bio',
            repository: repository,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'Changed Name');
      await tester.enterText(find.byType(TextField).last, 'Updated bio');
      await tester.pump();
      await tester.tap(find.text(ArabicStrings.saveChanges));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => repository.updateMyProfile('Changed Name', bio: 'Updated bio')).called(1);
    });
  });
}
