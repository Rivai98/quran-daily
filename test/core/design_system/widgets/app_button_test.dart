import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/design_system/app_button.dart';

import '../../../helpers/widget_test_app.dart';

void main() {
  testWidgets('primary variant is 52 tall, tonal/secondary/text are 48',
      (tester) async {
    await tester.pumpWidget(buildArabicTestApp(
      Column(
        children: [
          AppButton(
            label: 'سجّل إتمام الجزء',
            onPressed: () {},
            expanded: true,
          ),
          AppButton(
            label: 'راجع الطلبات',
            variant: AppButtonVariant.tonal,
            onPressed: () {},
          ),
          AppButton(
            label: 'إلغاء',
            variant: AppButtonVariant.secondary,
            onPressed: () {},
          ),
          AppButton(
            label: 'عرض الكل',
            variant: AppButtonVariant.text,
            onPressed: () {},
          ),
          AppButton(
            label: 'نعم، تراجع',
            variant: AppButtonVariant.destructive,
            onPressed: () {},
          ),
        ],
      ),
    ));

    double heightOf(int index) =>
        tester.getSize(find.byType(AppButton).at(index)).height;

    expect(heightOf(0), 52);
    expect(heightOf(1), 48);
    expect(heightOf(2), 48);
    expect(heightOf(3), 48);
    expect(heightOf(4), 48);
  });

  testWidgets('all six variants render their Arabic label', (tester) async {
    await tester.pumpWidget(buildArabicTestApp(
      Column(
        children: [
          AppButton(label: 'ابدأ الختمة', onPressed: () {}),
          AppButton(
              label: 'شارك الدعوة',
              variant: AppButtonVariant.tonal,
              onPressed: () {}),
          AppButton(
              label: 'إلغاء',
              variant: AppButtonVariant.secondary,
              onPressed: () {}),
          AppButton(
              label: 'عرض الكل',
              variant: AppButtonVariant.text,
              onPressed: () {}),
          AppButton(
              label: 'نعم، ارفض الطلب',
              variant: AppButtonVariant.destructive,
              onPressed: () {}),
          AppIconButton(
              icon: Icons.settings,
              semanticLabel: 'الإعدادات',
              onPressed: () {}),
        ],
      ),
    ));

    expect(find.text('ابدأ الختمة'), findsOneWidget);
    expect(find.text('شارك الدعوة'), findsOneWidget);
    expect(find.text('إلغاء'), findsOneWidget);
    expect(find.text('عرض الكل'), findsOneWidget);
    expect(find.text('نعم، ارفض الطلب'), findsOneWidget);

    final iconButton = find.byType(AppIconButton);
    expect(tester.getSize(iconButton), const Size(48, 48));
    expect(find.byTooltip('الإعدادات'), findsOneWidget);
  });

  testWidgets('icon sits at the start (right in RTL)', (tester) async {
    await tester.pumpWidget(buildArabicTestApp(
      const AppButton(
        label: 'سجّل إتمام الجزء',
        icon: Icon(Icons.check),
      ),
    ));

    final iconCenter = tester.getCenter(find.byType(Icon).first);
    final labelCenter = tester.getCenter(find.text('سجّل إتمام الجزء'));
    expect(iconCenter.dx, greaterThan(labelCenter.dx),
        reason: 'in RTL the leading icon must render to the right of the label');
  });

  testWidgets('loading keeps width, shows a 20dp spinner and ignores taps',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(buildArabicTestApp(
      AppButton(
        label: 'سجّل إتمام الجزء',
        onPressed: () => taps++,
        expanded: true,
      ),
    ));
    await tester.pump();
    final idleWidth = tester.getSize(find.byType(AppButton)).width;

    await tester.pumpWidget(buildArabicTestApp(
      AppButton(
        label: 'سجّل إتمام الجزء',
        onPressed: () => taps++,
        loading: true,
        expanded: true,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.getSize(find.byType(AppButton)).width, idleWidth);
    expect(
      tester.getSize(find.byType(CircularProgressIndicator).first),
      const Size(20, 20),
    );

    await tester.tap(find.byType(AppButton), warnIfMissed: false);
    await tester.pump();
    expect(taps, 0, reason: 'repeated taps while loading must be ignored');
  });

  testWidgets('disabled renders at 38% opacity', (tester) async {
    await tester.pumpWidget(buildArabicTestApp(
      const AppButton(label: 'انضم'),
    ));

    final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
    expect(opacity.opacity, closeTo(0.38, 0.001));
  });

  testWidgets('long labels stay on one line at phone width', (tester) async {
    await tester.pumpWidget(buildArabicTestApp(
      AppButton(
        label: 'بانتظار موافقة مالك المجموعة على طلب الانضمام',
        icon: const Icon(Icons.check),
        expanded: true,
        onPressed: () {},
      ),
      size: const Size(360, 640),
    ));

    final label = tester.widget<Text>(find.text(
      'بانتظار موافقة مالك المجموعة على طلب الانضمام',
    ));
    expect(label.maxLines, 1);
    expect(label.softWrap, isFalse);
    expect(label.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });
}
