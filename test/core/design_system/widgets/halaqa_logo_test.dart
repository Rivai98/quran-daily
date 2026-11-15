import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/design_system/app_colors.dart';
import 'package:quran_daily/core/design_system/widgets/halaqa_logo.dart';

import '../../../helpers/widget_test_app.dart';

void main() {
  testWidgets('renders HalaqaLogo in small (48) and large (96) sizes', (tester) async {
    await tester.pumpWidget(
      buildArabicTestApp(
        const Column(
          children: [
            HalaqaLogo(size: HalaqaLogo.small),
            HalaqaLogo(size: HalaqaLogo.large),
          ],
        ),
      ),
    );

    final smallLogo = tester.getSize(find.byType(HalaqaLogo).first);
    expect(smallLogo.width, 48);
    expect(smallLogo.height, 48);

    final largeLogo = tester.getSize(find.byType(HalaqaLogo).last);
    expect(largeLogo.width, 96);
    expect(largeLogo.height, 96);

    final paints = find.descendant(
      of: find.byType(HalaqaLogo),
      matching: find.byType(CustomPaint),
    );
    expect(paints, findsNWidgets(2));
  });

  testWidgets('renders HalaqaLogo across light and dark variants', (tester) async {
    for (final isDark in [false, true]) {
      await tester.pumpWidget(
        buildArabicTestApp(
          HalaqaLogo(size: 48, isDark: isDark),
          dark: isDark,
        ),
      );

      final customPaintFinder = find.descendant(
        of: find.byType(HalaqaLogo),
        matching: find.byType(CustomPaint),
      );
      final customPaint = tester.widget<CustomPaint>(customPaintFinder);
      final painter = customPaint.painter as HalaqaLogoPainter;

      if (isDark) {
        expect(painter.color, AppColors.dark.primary);
        expect(painter.goldColor, AppColors.dark.accent);
      } else {
        expect(painter.color, AppColors.light.primary);
        expect(painter.goldColor, AppColors.light.accent);
      }
    }
  });

  testWidgets('respects explicit custom color and goldColor', (tester) async {
    const customColor = Colors.teal;
    const customGold = Colors.amber;

    await tester.pumpWidget(
      buildArabicTestApp(
        const HalaqaLogo(
          size: 48,
          color: customColor,
          goldColor: customGold,
        ),
      ),
    );

    final customPaintFinder = find.descendant(
      of: find.byType(HalaqaLogo),
      matching: find.byType(CustomPaint),
    );
    final customPaint = tester.widget<CustomPaint>(customPaintFinder);
    final painter = customPaint.painter as HalaqaLogoPainter;
    expect(painter.color, customColor);
    expect(painter.goldColor, customGold);
  });

  testWidgets('golden: HalaqaLogo sizes in light and dark', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 360);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Widget buildLogoShowcase({required bool dark}) => buildArabicTestApp(
          const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HalaqaLogo(size: HalaqaLogo.small),
                SizedBox(width: 24),
                HalaqaLogo(size: HalaqaLogo.large),
              ],
            ),
          ),
          dark: dark,
          size: const Size(360, 360),
        );

    await tester.pumpWidget(buildLogoShowcase(dark: false));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../../goldens/halaqa_logo_light.png'),
    );

    await tester.pumpWidget(buildLogoShowcase(dark: true));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../../goldens/halaqa_logo_dark.png'),
    );
  });
}
