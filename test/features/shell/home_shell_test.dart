import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/shell/home_shell.dart';
import '../../helpers/widget_test_app.dart';

void main() {
  setUpAll(loadArabicUiFontsForGoldenTests);

  testWidgets('refreshes Home when returning to its tab', (tester) async {
    var homeSelected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          homeBuilder: _home,
          groupsBuilder: _groups,
          mushafBuilder: _mushaf,
          profileBuilder: _profile,
          onHomeSelected: () => homeSelected++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(ArabicStrings.groupsTab));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ArabicStrings.homeTab));
    await tester.pumpAndSettle();

    expect(homeSelected, 1);
  });

  testWidgets(
    'shows four labelled tabs, Home selected, and retains tab stacks',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeShell(
            homeBuilder: _home,
            groupsBuilder: _groups,
            mushafBuilder: _mushaf,
            profileBuilder: _profile,
          ),
        ),
      );

      expect(find.text('الرئيسية'), findsOneWidget);
      expect(find.text('مجموعاتي'), findsOneWidget);
      expect(find.text('المصحف'), findsOneWidget);
      expect(find.text('حسابي'), findsOneWidget);
      expect(find.text('HOME CONTENT'), findsOneWidget);
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);

      await tester.tap(find.text('مجموعاتي'));
      await tester.pumpAndSettle();
      expect(find.text('GROUPS CONTENT'), findsOneWidget);
      await tester.tap(find.text('OPEN GROUP DETAIL'));
      await tester.pumpAndSettle();
      expect(find.text('GROUP DETAIL'), findsOneWidget);
      await tester.tap(find.text('المصحف'));
      await tester.pumpAndSettle();
      expect(find.text('MUSHAF CONTENT'), findsOneWidget);
      await tester.tap(find.text('مجموعاتي'));
      await tester.pumpAndSettle();
      expect(find.text('GROUP DETAIL'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('GROUPS CONTENT'), findsOneWidget);
    },
  );

  testWidgets('shell tabs render light and dark at 360x800', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final dark in [false, true]) {
      await tester.pumpWidget(
        buildArabicTestApp(
          HomeShell(
            homeBuilder: _home,
            groupsBuilder: _groups,
            mushafBuilder: _mushaf,
            profileBuilder: _profile,
          ),
          dark: dark,
          size: const Size(360, 800),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/shell_tabs_${dark ? 'dark' : 'light'}_360x800.png',
        ),
      );
    }
  });

  testWidgets(
    'renders in RTL at 200% text scale and offers settings from profile',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2)),
              child: HomeShell(
                homeBuilder: _home,
                groupsBuilder: _groups,
                mushafBuilder: _mushaf,
                profileBuilder: _profile,
              ),
            ),
          ),
        ),
      );
      expect(
        Directionality.of(tester.element(find.text('الرئيسية'))),
        TextDirection.rtl,
      );
      await tester.tap(find.text('حسابي'));
      await tester.pumpAndSettle();
      expect(find.text('الإعدادات'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _home(BuildContext context) =>
    const Scaffold(body: Center(child: Text('HOME CONTENT')));
Widget _groups(BuildContext context) => Scaffold(
  body: Center(
    child: Column(
      children: [
        const Text('GROUPS CONTENT'),
        TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  const Scaffold(body: Center(child: Text('GROUP DETAIL'))),
            ),
          ),
          child: const Text('OPEN GROUP DETAIL'),
        ),
      ],
    ),
  ),
);
Widget _mushaf(BuildContext context) =>
    const Scaffold(body: Center(child: Text('MUSHAF CONTENT')));
Widget _profile(BuildContext context) => const ProfileTabPlaceholder();
