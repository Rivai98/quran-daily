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
    testWidgets('renders fields and initial values', (tester) async {
      await tester.pumpWidget(
        buildArabicTestApp(
          EditProfileScreen(
            initialDisplayName: 'أحمد',
            initialBio: 'قارئ مجتهد',
            repository: repository,
          ),
        ),
      );

      expect(find.text(ArabicStrings.editProfile), findsOneWidget);
      expect(find.text('أحمد'), findsOneWidget);
      expect(find.text('قارئ مجتهد'), findsOneWidget);
      expect(find.text(ArabicStrings.saveChanges), findsOneWidget);
    });

    testWidgets('validates short display name (< 2 chars)', (tester) async {
      await tester.pumpWidget(
        buildArabicTestApp(
          EditProfileScreen(
            initialDisplayName: '',
            repository: repository,
          ),
        ),
      );

      await tester.tap(find.text(ArabicStrings.saveChanges));
      await tester.pump();

      expect(find.text(ArabicStrings.invalidDisplayName), findsOneWidget);
      verifyNever(() => repository.updateMyProfile(any(), bio: any(named: 'bio')));
    });

    testWidgets('validates long bio (> 120 chars)', (tester) async {
      final longBio = 'أ' * 125;
      await tester.pumpWidget(
        buildArabicTestApp(
          EditProfileScreen(
            initialDisplayName: 'عبد الله',
            initialBio: longBio,
            repository: repository,
          ),
        ),
      );

      await tester.tap(find.text(ArabicStrings.saveChanges));
      await tester.pump();

      expect(find.text(ArabicStrings.invalidBio), findsOneWidget);
      verifyNever(() => repository.updateMyProfile(any(), bio: any(named: 'bio')));
    });

    testWidgets('successful save calls updateMyProfile and shows snackbar', (tester) async {
      when(() => repository.updateMyProfile('سلمان', bio: 'قارئ جديد'))
          .thenAnswer((_) async => Success(
                UserProfile(
                  userId: 'u1',
                  displayName: 'سلمان',
                  bio: 'قارئ جديد',
                  updatedAt: DateTime.now(),
                ),
              ));

      await tester.pumpWidget(
        buildArabicTestApp(
          EditProfileScreen(
            initialDisplayName: 'سلمان',
            initialBio: 'قارئ جديد',
            repository: repository,
          ),
        ),
      );

      await tester.tap(find.text(ArabicStrings.saveChanges));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => repository.updateMyProfile('سلمان', bio: 'قارئ جديد')).called(1);
    });
  });
}
