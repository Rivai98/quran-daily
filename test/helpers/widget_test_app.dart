import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_daily/core/design_system/app_theme.dart';

/// Load the app's bundled Arabic fonts before capturing visual goldens.
Future<void> loadAppFontsForGoldenTests() async {
  for (final family in const {
    'Cairo': 'assets/fonts/cairo/Cairo-Variable.ttf',
    'Amiri': 'assets/fonts/amiri/Amiri-Regular.ttf',
  }.entries) {
    final loader = FontLoader(family.key)
      ..addFont(rootBundle.load(family.value));
    await loader.load();
  }
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await materialIcons.load();
}

/// Pumps [child] inside the real app theme: Arabic locale, RTL, Material 3
/// design-system ThemeData (with the [AppColors] ThemeExtension), optionally
/// dark, at [textScale], and at a logical [size] (devicePixelRatio 1).
///
/// [dark], [textScale] and [size] default to the base variant; [size] is
/// only applied when provided so tests that set `tester.view.physicalSize`
/// themselves keep working.
Widget buildArabicTestApp(
  Widget child, {
  bool dark = false,
  double textScale = 1.0,
  Size? size,
}) {
  var app = MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    builder: (context, builtChild) {
      Widget tree = builtChild ?? const SizedBox.shrink();
      if (textScale != 1.0) {
        tree = MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: tree,
        );
      }
      if (size != null) {
        tree = MediaQuery(
          data: MediaQuery.of(context).copyWith(size: size),
          child: tree,
        );
      }
      return Directionality(textDirection: TextDirection.rtl, child: tree);
    },
    home: Material(child: child),
  );
  return app;
}

/// The four mandatory constitution variants for every screen/widget test:
/// base RTL, 200% text scale, dark theme, and 320dp width.
const testVariants = <({String name, bool dark, double textScale, Size size})>[
  (name: 'rtl', dark: false, textScale: 1.0, size: Size(360, 740)),
  (name: '200% text', dark: false, textScale: 2.0, size: Size(360, 740)),
  (name: 'dark', dark: true, textScale: 1.0, size: Size(360, 740)),
  (name: '320dp', dark: false, textScale: 1.0, size: Size(320, 640)),
];

/// Pumps [child] in every [testVariants] and runs [assertions] after each
/// pump; the tree is cleared between variants.
Future<void> pumpAllVariants(
  WidgetTester tester,
  Widget child,
  Future<void> Function(WidgetTester tester, String variant) assertions,
) async {
  for (final variant in testVariants) {
    await tester.pumpWidget(
      buildArabicTestApp(
        child,
        dark: variant.dark,
        textScale: variant.textScale,
        size: variant.size,
      ),
    );
    await tester.pump();
    await assertions(tester, variant.name);
    await tester.pumpWidget(const SizedBox.shrink());
  }
}
