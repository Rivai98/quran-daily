import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/di/service_locator.dart';
import '../core/localization/arabic_strings.dart';
import '../core/design_system/app_theme.dart';
import '../features/auth/cubit/auth_cubit.dart';
import '../features/auth/view/auth_entry_screen.dart';
import '../features/quran_groups/view/screens/group_selection_screen.dart';
import 'router.dart';

class QuranDailyApp extends StatelessWidget {
  const QuranDailyApp({super.key, AuthCubit? authCubit})
      : _authCubit = authCubit;

  final AuthCubit? _authCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (_) => _authCubit ?? (serviceLocator<AuthCubit>()..bootstrap()),
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          // Sign-out/expiry must clear any pushed private route.
          if (state.status == AuthStatus.unauthenticated) {
            resetToGate();
          }
        },
        child: MaterialApp(
          title: ArabicStrings.appName,
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          routes: AppRoutes.routes,
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const _AuthGate(),
        ),
      ),
    );
  }
}

/// Startup gate (spec 002): neutral checking state until bootstrap
/// resolves; private content never flashes before the decision finishes.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.checkingSession:
            return Scaffold(
              body: Semantics(
                label: ArabicStrings.checkingSession,
                child: const Center(child: CircularProgressIndicator()),
              ),
            );
          case AuthStatus.authenticated:
            return const GroupSelectionScreen();
          case AuthStatus.profileFailure:
          case AuthStatus.unauthenticated:
          case AuthStatus.failure:
          case AuthStatus.submitting:
          case AuthStatus.loadingProfile:
          case AuthStatus.signingOut:
            return const AuthEntryScreen();
        }
      },
    );
  }
}
