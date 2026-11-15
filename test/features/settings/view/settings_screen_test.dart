import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/auth/session_gateway.dart';
import 'package:quran_daily/core/design_system/app_button.dart';
import 'package:quran_daily/core/design_system/app_typography.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/core/settings/settings_repository.dart';
import 'package:quran_daily/features/settings/cubit/settings_cubit.dart';
import 'package:quran_daily/features/settings/view/settings_screen.dart';

import '../../../helpers/widget_test_app.dart';

class _MockSettingsRepo extends Mock implements SettingsRepository {}

class _MockSessionGateway extends Mock implements SessionGateway {}

void main() {
  setUpAll(loadDesignSystemFonts);
  late _MockSettingsRepo settingsRepo;
  late _MockSessionGateway sessionGateway;

  setUp(() {
    settingsRepo = _MockSettingsRepo();
    sessionGateway = _MockSessionGateway();
    when(
      () => settingsRepo.getQuranTextScale(),
    ).thenAnswer((_) async => const Success(1.0));
    when(
      () => settingsRepo.setQuranTextScale(any()),
    ).thenAnswer((_) async => const Success(null));
  });

  SettingsCubit buildCubit() => SettingsCubit(
    settingsRepository: settingsRepo,
    sessionGateway: sessionGateway,
  );

  testWidgets('settings renders at 360x800 in both themes', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final dark in [false, true]) {
      await tester.pumpWidget(
        buildArabicTestApp(
          SettingsScreen(cubit: buildCubit()),
          dark: dark,
          size: const Size(360, 800),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(SettingsScreen),
        matchesGoldenFile('goldens/settings_${dark ? 'dark' : 'light'}.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  Widget pump(Widget child, {SettingsCubit? cubit}) {
    return buildArabicTestApp(SettingsScreen(cubit: cubit ?? buildCubit()));
  }

  testWidgets(
    'renders settings screen with title, slider, preview, and sign-out button',
    (tester) async {
      final cubit = buildCubit();
      await tester.pumpWidget(pump(const SettingsScreen(), cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.text(ArabicStrings.settingsTitle), findsOneWidget);
      expect(find.text(ArabicStrings.quranTextSizeTitle), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text(ArabicStrings.quranPreviewText), findsOneWidget);
      expect(find.text(ArabicStrings.signOut), findsOneWidget);
      expect(find.text(ArabicStrings.settingsReadingSection), findsOneWidget);
      expect(find.text(ArabicStrings.settingsAccountSection), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(ArabicStrings.settingsLicensesEntry),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(ArabicStrings.settingsAboutSection), findsOneWidget);
      expect(find.text(ArabicStrings.settingsLicensesEntry), findsOneWidget);
    },
  );

  testWidgets('slider changes update quran text scale on cubit', (
    tester,
  ) async {
    final cubit = buildCubit();
    await tester.pumpWidget(pump(const SettingsScreen(), cubit: cubit));
    await tester.pumpAndSettle();

    final slider = find.byType(Slider);
    expect(slider, findsOneWidget);

    await tester.tap(slider);
    await tester.pumpAndSettle();

    verify(
      () => settingsRepo.setQuranTextScale(any()),
    ).called(greaterThanOrEqualTo(1));
  });

  testWidgets('preview text is styled with quranLabel', (tester) async {
    final cubit = buildCubit();
    await tester.pumpWidget(pump(const SettingsScreen(), cubit: cubit));
    await tester.pumpAndSettle();

    final textWidget = tester.widget<Text>(
      find.text(ArabicStrings.quranPreviewText),
    );
    expect(textWidget.style?.fontFamily, AppTypography.quranLabel.fontFamily);
  });

  testWidgets('sign out button opens confirm sheet', (tester) async {
    final cubit = buildCubit();
    await tester.pumpWidget(pump(const SettingsScreen(), cubit: cubit));
    await tester.pumpAndSettle();

    final signOutBtn = find.widgetWithText(AppButton, ArabicStrings.signOut);
    expect(signOutBtn, findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -320));
    await tester.pumpAndSettle();
    await tester.tap(signOutBtn);
    await tester.pumpAndSettle();

    expect(find.text(ArabicStrings.signOutConfirmTitle), findsOneWidget);
    expect(find.text(ArabicStrings.signOutConfirmMessage), findsOneWidget);
  });

  testWidgets('confirming sign out calls cubit.signOut()', (tester) async {
    when(
      () => sessionGateway.signOut(),
    ).thenAnswer((_) async => const Success(null));

    final cubit = buildCubit();
    await tester.pumpWidget(pump(const SettingsScreen(), cubit: cubit));
    await tester.pumpAndSettle();

    final signOutButton = find.widgetWithText(AppButton, ArabicStrings.signOut);
    await tester.drag(find.byType(ListView).first, const Offset(0, -320));
    await tester.pumpAndSettle();
    await tester.tap(signOutButton);
    await tester.pumpAndSettle();

    final confirmButtons = find.widgetWithText(
      AppButton,
      ArabicStrings.signOut,
    );
    await tester.tap(confirmButtons.last);
    await tester.pumpAndSettle();

    verify(() => sessionGateway.signOut()).called(1);
  });

  testWidgets('renders properly across all variants without overflow', (
    tester,
  ) async {
    final cubit = buildCubit();
    await pumpAllVariants(tester, SettingsScreen(cubit: cubit), (
      tester,
      variant,
    ) async {
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
