import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app_links/app_links.dart';

import '../core/di/service_locator.dart';
import '../core/auth/session_gateway.dart';
import '../core/localization/arabic_strings.dart';
import '../core/design_system/app_theme.dart';
import '../core/quran/quran_metadata_repository.dart';
import '../features/auth/cubit/auth_cubit.dart';
import '../features/auth/view/auth_entry_screen.dart';
import '../features/mushaf/data/mushaf_sync_repository.dart';
import '../features/quran_groups/cubit/group_list/group_list_cubit.dart';
import '../features/quran_groups/data/repositories/khatma_repository.dart';
import '../features/reminders/data/notification_scheduler.dart';
import '../features/reminders/data/reminder_planning_service.dart';
import '../features/shell/home_shell.dart';
import '../features/home/view/home_screen.dart';
import '../features/home/cubit/home_cubit.dart';
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
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  String? _pendingInviteCode;
  bool _openingInvite = false;

  AuthCubit get _authCubit => widget._authCubit ?? serviceLocator<AuthCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _linkSubscription = _appLinks.uriLinkStream.listen(_handleUri);
    _appLinks
        .getInitialLink()
        .then((uri) {
          if (uri != null) _handleUri(uri);
        })
        .catchError((_) {});
    if (serviceLocator.isRegistered<NotificationScheduler>()) {
      unawaited(
        serviceLocator<NotificationScheduler>()
            .initialize(
              onTap: (_) =>
                  navigatorKey.currentState?.pushNamed(AppRoutes.groups),
            )
            .then((_) async {
              if (serviceLocator.isRegistered<ReminderPlanningService>()) {
                await serviceLocator<ReminderPlanningService>().refresh();
              }
            })
            .catchError((_) {}),
      );
    }
  }

  void _handleUri(Uri uri) {
    final code = inviteCodeFromDeepLink(uri);
    if (code == null) return;
    if (_authCubit.state.status == AuthStatus.authenticated) {
      _openInvite(code);
    } else {
      _pendingInviteCode = code;
    }
  }

  void _openPendingInvite() {
    final code = _pendingInviteCode;
    if (code == null) return;
    _pendingInviteCode = null;
    _openInvite(code);
  }

  void _openInvite(String code) {
    if (_openingInvite) return;
    _openingInvite = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      navigatorKey.currentState?.pushNamed('/join/$code').whenComplete(() {
        _openingInvite = false;
      });
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
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
      unawaited(_syncMushafSafely());
    }
  }

  /// Pushes queued last-position/bookmark writes, then pulls the account's
  /// copy (sign-in, app start with a saved session, and resume).
  Future<void> _syncMushafSafely() async {
    if (!serviceLocator.isRegistered<MushafSyncRepository>()) return;
    try {
      await serviceLocator<MushafSyncRepository>().sync();
    } catch (_) {
      // Reading stays local-first; the queue is retried on the next trigger.
    }
  }

  Future<void> _syncPendingSafely() async {
    try {
      await serviceLocator<KhatmaRepository>().syncPending();
      if (serviceLocator.isRegistered<ReminderPlanningService>()) {
        await serviceLocator<ReminderPlanningService>().refresh();
      }
    } catch (_) {
      // The dashboard remains available if background sync cannot reach the server.
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (_) =>
          widget._authCubit ?? (serviceLocator<AuthCubit>()..bootstrap()),
      child: BlocProvider<GroupListCubit>(
        create: (_) => serviceLocator<GroupListCubit>(),
        child: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            // Sign-out/expiry must clear any pushed private route.
            if (state.status == AuthStatus.unauthenticated) {
              resetToGate();
            }
            if (state.status == AuthStatus.authenticated) {
              _openPendingInvite();
              unawaited(_syncMushafSafely());
              if (serviceLocator.isRegistered<ReminderPlanningService>()) {
                unawaited(
                  serviceLocator<ReminderPlanningService>()
                      .refresh()
                      .catchError((_) {}),
                );
              }
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
            onGenerateRoute: AppRoutes.onGenerateRoute,
            builder: (context, child) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const _AuthGate(),
          ),
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
            return BlocProvider(
              create: (_) => serviceLocator<HomeCubit>(),
              child: Builder(
                builder: (context) => HomeShell(
                  onHomeSelected: context.read<HomeCubit>().refreshIfStale,
                  homeBuilder: (_) => HomeScreen(
                    displayName: state.profile?.displayName,
                    metadataRepository:
                        serviceLocator.isRegistered<QuranMetadataRepository>()
                        ? serviceLocator<QuranMetadataRepository>()
                        : QuranMetadataRepository(),
                  ),
                  groupsBuilder: (context) =>
                      AppRoutes.routes[AppRoutes.groups]!(context),
                ),
              ),
            );
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
