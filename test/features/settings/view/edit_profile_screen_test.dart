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
    testWidgets('avatar picker light and dark goldens', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      for (final dark in [false, true]) {
        await tester.pumpWidget(
          buildArabicTestApp(
            EditProfileScreen(
              initialDisplayName: 'قارئ القرآن',
              initialBio: 'أقرأ كل يوم',
              repository: repository,
            ),
            dark: dark,
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(EditProfileScreen),
          matchesGoldenFile(
            'goldens/007_avatar_picker_${dark ? 'dark' : 'light'}.png',
          ),
        );
        await tester.pumpWidget(const SizedBox.shrink());
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('prefills values and disables save until changed', (
      tester,
    ) async {
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
      verifyNever(
        () => repository.updateMyProfile(
          any(),
          bio: any(named: 'bio'),
          avatarKey: any(named: 'avatarKey'),
        ),
      );
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
      verifyNever(
        () => repository.updateMyProfile(
          any(),
          bio: any(named: 'bio'),
          avatarKey: any(named: 'avatarKey'),
        ),
      );
    });

    testWidgets('saves changed values', (tester) async {
      when(
        () => repository.updateMyProfile(
          any(),
          bio: any(named: 'bio'),
          avatarKey: any(named: 'avatarKey'),
        ),
      ).thenAnswer(
        (_) async => Success(
          UserProfile(
            userId: 'u1',
            displayName: 'Changed Name',
            bio: 'Updated bio',
            updatedAt: DateTime.now(),
          ),
        ),
      );

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

      verify(
        () => repository.updateMyProfile(
          'Changed Name',
          bio: 'Updated bio',
          avatarKey: 'ornament',
        ),
      ).called(1);
    });

    testWidgets('avatar picker selects and saves a drawn avatar', (
      tester,
    ) async {
      when(
        () => repository.updateMyProfile(
          any(),
          bio: any(named: 'bio'),
          avatarKey: any(named: 'avatarKey'),
        ),
      ).thenAnswer(
        (_) async => const Success(
          UserProfile(
            userId: 'u1',
            displayName: 'Sample Name',
            avatarKey: 'woman_hijab',
          ),
        ),
      );

      await tester.pumpWidget(
        buildArabicTestApp(
          EditProfileScreen(
            initialDisplayName: 'Sample Name',
            initialBio: 'Sample bio',
            repository: repository,
          ),
        ),
      );

      expect(find.text(ArabicStrings.avatarPickerTitle), findsOneWidget);
      expect(find.text(ArabicStrings.avatarWomanHijab), findsOneWidget);
      await tester.tap(find.text(ArabicStrings.avatarWomanHijab));
      await tester.pump();
      await tester.tap(find.text(ArabicStrings.saveChanges));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(
        () => repository.updateMyProfile(
          'Sample Name',
          bio: 'Sample bio',
          avatarKey: 'woman_hijab',
        ),
      ).called(1);
    });
  });
}
