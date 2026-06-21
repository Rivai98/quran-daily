import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/localization/arabic_strings.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class QuranDailyApp extends StatelessWidget {
  const QuranDailyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: ArabicStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      initialRoute: AppRoutes.auth,
      routes: AppRoutes.routes,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
