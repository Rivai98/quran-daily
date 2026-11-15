import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/app/router.dart';
import 'package:quran_daily/core/design_system/app_theme.dart';
import 'package:quran_daily/core/design_system/widgets/offline_banner.dart';
import 'package:quran_daily/core/design_system/widgets/state_panel.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/profile/cubit/profile_cubit.dart';
import 'package:quran_daily/features/profile/data/entities/profile_entities.dart';
import 'package:quran_daily/features/profile/data/repositories/profile_repository.dart';
import 'package:quran_daily/features/profile/view/profile_screen.dart';

import '../../../helpers/widget_test_app.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  setUpAll(loadDesignSystemFonts);
  late MockProfileRepository repository;

  final sampleProfile = UserProfile(
    displayName: 'عبد الله السعيد',
    memberSince: DateTime(2026, 10, 1),
    streak: 12,
    bestStreak: 20,
    portionsRead: 65,
    portionsLate: 4,
    khatmas: const [
      ProfileKhatma(
        groupId: 'g-1',
        groupName: 'ختمة الفجر المباركة',
        completed: 2,
      ),
    ],
    badges: [
      ProfileBadge(
        code: ProfileBadgeCode.firstKhatma,
        earnedAt: DateTime(2026, 10, 20),
      ),
      ProfileBadge(
        code: ProfileBadgeCode.streak7,
        earnedAt: DateTime(2026, 10, 15),
      ),
      const ProfileBadge(code: ProfileBadgeCode.streak30),
      const ProfileBadge(code: ProfileBadgeCode.streak100),
      const ProfileBadge(code: ProfileBadgeCode.portions100),
    ],
  );

  setUp(() {
    repository = MockProfileRepository();
  });

  Widget buildScreen({ProfileCubit? cubit}) {
    return BlocProvider<ProfileCubit>(
      create: (_) => cubit ?? (ProfileCubit(repository: repository)..load()),
      child: const ProfileScreen(),
    );
  }

  group('ProfileScreen widget tests', () {
    testWidgets('account light and dark goldens', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      when(
        () => repository.getProfile(forceRefresh: any(named: 'forceRefresh')),
      ).thenAnswer((_) async => Success(sampleProfile));
      for (final dark in [false, true]) {
        await tester.pumpWidget(buildArabicTestApp(buildScreen(), dark: dark));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(ProfileScreen),
          matchesGoldenFile(
            'goldens/005_profile_${dark ? 'dark' : 'light'}.png',
          ),
        );
        await tester.pumpWidget(const SizedBox.shrink());
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('all constitution variants render without overflow', (
      tester,
    ) async {
      when(
        () => repository.getProfile(forceRefresh: any(named: 'forceRefresh')),
      ).thenAnswer((_) async => Success(sampleProfile));

      await pumpAllVariants(tester, buildScreen(), (tester, variant) async {
        expect(tester.takeException(), isNull, reason: variant);
      });
    });

    testWidgets('content: shows profile data and sections', (tester) async {
      when(
        () => repository.getProfile(forceRefresh: any(named: 'forceRefresh')),
      ).thenAnswer((_) async => Success(sampleProfile));

      await tester.pumpWidget(buildArabicTestApp(buildScreen()));
      await tester.pumpAndSettle();

      expect(find.text('عبد الله السعيد'), findsOneWidget);
      expect(find.text(ArabicStrings.profileTitle), findsOneWidget);
      expect(find.text(ArabicStrings.profileStreakSection), findsOneWidget);
      expect(find.text(ArabicStrings.profileTotalsSection), findsOneWidget);
      expect(find.text(ArabicStrings.profileKhatmasSection), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text(ArabicStrings.profileBadgesSection),
        100.0,
      );
      expect(find.text(ArabicStrings.profileBadgesSection), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text(ArabicStrings.profileLogNavigation),
        100.0,
      );
      expect(find.text(ArabicStrings.profileLogNavigation), findsOneWidget);
      expect(find.text(ArabicStrings.myProfileTitle), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(ArabicStrings.profileSettingsNavigation),
        100.0,
      );
      expect(
        find.text(ArabicStrings.profileSettingsNavigation),
        findsOneWidget,
      );
    });

    testWidgets('shows loading indicator when state is loading', (
      tester,
    ) async {
      final completer = Completer<Result<UserProfile>>();
      when(
        () => repository.getProfile(forceRefresh: any(named: 'forceRefresh')),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildArabicTestApp(buildScreen()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(Success(sampleProfile));
      await tester.pumpAndSettle();
    });

    testWidgets('shows offline banner when profile is stale', (tester) async {
      final staleProfile = sampleProfile.copyWith(isStale: true);
      when(
        () => repository.getProfile(forceRefresh: any(named: 'forceRefresh')),
      ).thenAnswer((_) async => Success(staleProfile));

      await tester.pumpWidget(buildArabicTestApp(buildScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(OfflineBanner), findsOneWidget);
      expect(find.text('عبد الله السعيد'), findsOneWidget);
    });

    testWidgets('shows error state panel and retries on tap', (tester) async {
      when(
        () => repository.getProfile(forceRefresh: any(named: 'forceRefresh')),
      ).thenAnswer(
        (_) async => const FailureResult(
          NetworkFailure(message: 'Connection failed', code: 'network'),
        ),
      );

      await tester.pumpWidget(buildArabicTestApp(buildScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(StatePanel), findsOneWidget);
      expect(find.text(ArabicStrings.profileLoadError), findsOneWidget);

      when(
        () => repository.getProfile(forceRefresh: any(named: 'forceRefresh')),
      ).thenAnswer((_) async => Success(sampleProfile));

      await tester.tap(find.text(ArabicStrings.retry));
      await tester.pumpAndSettle();

      expect(find.text('عبد الله السعيد'), findsOneWidget);
    });

    testWidgets('tapping navigation rows triggers pushNamed safely', (
      tester,
    ) async {
      when(
        () => repository.getProfile(forceRefresh: any(named: 'forceRefresh')),
      ).thenAnswer((_) async => Success(sampleProfile));

      var pushedRoute = '';
      final app = MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        routes: {
          '/': (_) => buildScreen(),
          AppRoutes.settings: (_) =>
              const Scaffold(body: Text('Settings Target')),
          AppRoutes.log: (_) => const Scaffold(body: Text('Log Target')),
          AppRoutes.editMyProfile: (_) =>
              const Scaffold(body: Text('Edit Profile Target')),
        },
        navigatorObservers: [_RouteObserver((route) => pushedRoute = route)],
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text(ArabicStrings.profileSettingsNavigation),
        100.0,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ArabicStrings.profileSettingsNavigation));
      await tester.pumpAndSettle();

      expect(pushedRoute, AppRoutes.settings);
      expect(find.text('Settings Target'), findsOneWidget);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text(ArabicStrings.myProfileTitle));
      await tester.pumpAndSettle();

      expect(pushedRoute, AppRoutes.editMyProfile);
      expect(find.text('Edit Profile Target'), findsOneWidget);
    });
  });
}

class _RouteObserver extends NavigatorObserver {
  _RouteObserver(this.onPush);
  final void Function(String) onPush;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name != null) {
      onPush(route.settings.name!);
    }
  }
}
