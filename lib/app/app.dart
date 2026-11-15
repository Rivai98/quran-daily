import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/di/service_locator.dart';
import '../core/auth/session_gateway.dart';
import '../core/localization/arabic_strings.dart';
import '../core/design_system/app_theme.dart';
import '../features/auth/cubit/auth_cubit.dart';
import '../features/auth/view/auth_entry_screen.dart';
import '../features/quran_groups/view/screens/group_selection_screen.dart';
import '../features/quran_groups/data/repositories/khatma_repository.dart';
import 'router.dart';

class QuranDailyApp extends StatefulWidget {
  const QuranDailyApp({super.key, AuthCubit? authCubit})
    : _authCubit = authCubit;

  final AuthCubit? _authCubit;

  @override
  State<QuranDailyApp> createState() => _QuranDailyAppState();
}

class _QuranDailyAppState extends State<QuranDailyApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        serviceLocator.isRegistered<KhatmaRepository>() &&
        serviceLocator.isRegistered<SessionGateway>() &&
        serviceLocator<SessionGateway>().currentUserId != null) {
      unawaited(_syncPendingSafely());
    }
  }

  Future<void> _syncPendingSafely() async {
    try {
      await serviceLocator<KhatmaRepository>().syncPending();
    } catch (_) {
      // The dashboard remains available if background sync cannot reach the server.
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (_) =>
          widget._authCubit ?? (serviceLocator<AuthCubit>()..bootstrap()),
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
