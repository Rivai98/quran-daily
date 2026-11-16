import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:quran_daily/features/mushaf/view/widgets/snappy_mushaf_scroll_physics.dart';

FixedScrollMetrics _metrics({
  required double pixels,
  required double viewport,
  double maxExtent = 2000.0,
}) {
  return FixedScrollMetrics(
    minScrollExtent: 0.0,
    maxScrollExtent: maxExtent,
    pixels: pixels,
    viewportDimension: viewport,
    axisDirection: AxisDirection.right,
    devicePixelRatio: 1.0,
  );
}

void main() {
  group('SnappyMushafScrollPhysics unit math', () {
    const viewport = 400.0;
    const tolerance = Tolerance(velocity: 100.0);
    const physics = SnappyMushafScrollPhysics(settledPage: 2.0);

    test('20% drag forward -> next page', () {
      final metrics = _metrics(
        pixels: (2.0 + 0.20) * viewport,
        viewport: viewport,
      );
      final target = physics.getTargetPixels(metrics, tolerance, 0.0);
      expect(target, 3.0 * viewport);
    });

    test('20% drag back -> previous page', () {
      final metrics = _metrics(
        pixels: (2.0 - 0.20) * viewport,
        viewport: viewport,
      );
      final target = physics.getTargetPixels(metrics, tolerance, 0.0);
      expect(target, 1.0 * viewport);
    });

    test('10% drag either way -> stays', () {
      final metricsForward = _metrics(
        pixels: (2.0 + 0.10) * viewport,
        viewport: viewport,
      );
      expect(
        physics.getTargetPixels(metricsForward, tolerance, 0.0),
        2.0 * viewport,
      );

      final metricsBack = _metrics(
        pixels: (2.0 - 0.10) * viewport,
        viewport: viewport,
      );
      expect(
        physics.getTargetPixels(metricsBack, tolerance, 0.0),
        2.0 * viewport,
      );
    });

    test('small fling either way -> turns', () {
      final metricsForward = _metrics(
        pixels: (2.0 + 0.05) * viewport,
        viewport: viewport,
      );
      expect(
        physics.getTargetPixels(metricsForward, tolerance, 50.0),
        3.0 * viewport,
      );

      final metricsBack = _metrics(
        pixels: (2.0 - 0.05) * viewport,
        viewport: viewport,
      );
      expect(
        physics.getTargetPixels(metricsBack, tolerance, -50.0),
        1.0 * viewport,
      );
    });
  });

  group('SnappyMushafScrollPhysics widget interaction', () {
    Widget buildTestApp(PageController controller) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 600,
              child: PageView(
                controller: controller,
                pageSnapping: false,
                physics: SnappyMushafScrollPhysics(
                  settledPageGetter: () => controller.page?.roundToDouble(),
                ),
                children: const [
                  Center(child: Text('Page 0')),
                  Center(child: Text('Page 1')),
                  Center(child: Text('Page 2')),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('20% drag forward -> next page', (tester) async {
      final controller = PageController(initialPage: 1);
      await tester.pumpWidget(buildTestApp(controller));
      await tester.pumpAndSettle();

      // Drag left by 80px (20% of 400px width)
      await tester.drag(find.text('Page 1'), const Offset(-80, 0));
      await tester.pumpAndSettle();

      expect(controller.page, 2.0);
      expect(find.text('Page 2'), findsOneWidget);
    });

    testWidgets('20% drag back -> previous page', (tester) async {
      final controller = PageController(initialPage: 1);
      await tester.pumpWidget(buildTestApp(controller));
      await tester.pumpAndSettle();

      // Drag right by 80px (20% of 400px width)
      await tester.drag(find.text('Page 1'), const Offset(80, 0));
      await tester.pumpAndSettle();

      expect(controller.page, 0.0);
      expect(find.text('Page 0'), findsOneWidget);
    });

    testWidgets('10% drag either way -> stays', (tester) async {
      final controller = PageController(initialPage: 1);
      await tester.pumpWidget(buildTestApp(controller));
      await tester.pumpAndSettle();

      // Drag left by 40px (10% of 400px width)
      await tester.drag(find.text('Page 1'), const Offset(-40, 0));
      await tester.pumpAndSettle();
      expect(controller.page, 1.0);

      // Drag right by 40px (10% of 400px width)
      await tester.drag(find.text('Page 1'), const Offset(40, 0));
      await tester.pumpAndSettle();
      expect(controller.page, 1.0);
    });

    testWidgets('small fling either way -> turns', (tester) async {
      final controller = PageController(initialPage: 1);
      await tester.pumpWidget(buildTestApp(controller));
      await tester.pumpAndSettle();

      // Fling forward with velocity
      await tester.fling(find.byType(PageView), const Offset(-50, 0), 1000);
      await tester.pumpAndSettle();
      expect(controller.page, 2.0);

      // Fling back with velocity
      await tester.fling(find.byType(PageView), const Offset(50, 0), 1000);
      await tester.pumpAndSettle();
      expect(controller.page, 1.0);
    });
  });
}
