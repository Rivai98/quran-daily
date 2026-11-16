import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/di/service_locator.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/features/admin/cubit/admin_cubit.dart';
import 'package:quran_daily/features/admin/data/admin_repository.dart';
import 'package:quran_daily/features/admin/view/admin_screens.dart';

import '../../../helpers/widget_test_app.dart';

class _AdminRepository extends Mock implements AdminRepository {}

void main() {
  setUpAll(loadDesignSystemFonts);
  late _AdminRepository repository;

  setUp(() async {
    await serviceLocator.reset();
    repository = _AdminRepository();
    when(() => repository.overview()).thenAnswer(
      (_) async => const Success({
        'users': {'total': 12, 'new_7d': 2, 'active_today': 4},
        'groups': {'total': 3},
        'today': {'rate_percent': 75},
        'khatmas': {'last_30d': 5},
        'series': [
          {'completed': 2},
          {'completed': 5},
        ],
      }),
    );
    when(
      () => repository.groups(
        query: any(named: 'query'),
        status: any(named: 'status'),
      ),
    ).thenAnswer(
      (_) async => const Success({
        'total': 1,
        'items': [
          {
            'id': 'g1',
            'name': 'مجموعة النور',
            'owner_name': 'أحمد',
            'member_count': 4,
          },
        ],
      }),
    );
    when(
      () => repository.users(
        query: any(named: 'query'),
        status: any(named: 'status'),
      ),
    ).thenAnswer(
      (_) async => const Success({
        'total': 1,
        'items': [
          {
            'id': 'u1',
            'display_name': 'مريم',
            'email': 'm@example.test',
            'status': 'active',
          },
        ],
      }),
    );
    when(() => repository.groupDetail(any())).thenAnswer(
      (_) async => const Success({
        'group': {
          'name': 'مجموعة النور',
          'status': 'active',
          'owner_name': 'أحمد',
          'portion_unit': 'juz',
        },
        'members': [],
        'today': {'rate_percent': 75},
      }),
    );
    when(() => repository.userDetail(any())).thenAnswer(
      (_) async => const Success({
        'user': {
          'display_name': 'مريم',
          'email': 'm@example.test',
          'status': 'active',
        },
        'groups': [],
      }),
    );
    when(() => repository.audit(action: any(named: 'action'))).thenAnswer(
      (_) async => const Success({
        'total': 1,
        'items': [
          {
            'action': 'create_user',
            'actor_name': 'أحمد',
            'target_name': 'مريم',
            'result': 'succeeded',
            'created_at': '2026-11-15',
          },
        ],
      }),
    );
    serviceLocator.registerFactory<AdminCubit>(() => AdminCubit(repository));
  });

  tearDown(() async => serviceLocator.reset());

  testWidgets(
    'overview remains usable in RTL, dark mode, 200% text and 320dp',
    (tester) async {
      await pumpAllVariants(tester, const AdminOverviewScreen(), (
        tester,
        variant,
      ) async {
        await tester.pumpAndSettle();
        expect(
          find.byType(AdminOverviewScreen),
          findsOneWidget,
          reason: variant,
        );
        expect(tester.takeException(), isNull, reason: variant);
      });
    },
  );

  testWidgets('admin console renders at 360x800 in both themes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final screens = <(String, Widget)>[
      ('overview', const AdminOverviewScreen()),
      ('groups', const AdminGroupsScreen()),
      ('users', const AdminUsersScreen()),
      ('audit', const AdminAuditScreen()),
    ];
    for (final (name, screen) in screens) {
      for (final dark in [false, true]) {
        await tester.pumpWidget(
          buildArabicTestApp(screen, dark: dark, size: const Size(360, 800)),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(screen.runtimeType),
          matchesGoldenFile(
            'goldens/admin_${name}_${dark ? 'dark' : 'light'}.png',
          ),
        );
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
  });

  testWidgets('admin search is debounced and keeps current rows visible', (
    tester,
  ) async {
    await tester.pumpWidget(buildArabicTestApp(const AdminGroupsScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsOneWidget);

    const query = '\u0627\u0644\u0646\u0648\u0631';
    await tester.enterText(find.byType(TextField), query);
    await tester.pump();
    expect(find.byType(ListTile), findsOneWidget);
    verifyNever(
      () => repository.groups(
        query: query,
        status: any(named: 'status'),
      ),
    );

    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    verify(
      () => repository.groups(
        query: query,
        status: any(named: 'status'),
      ),
    ).called(1);
  });

  testWidgets(
    'groups, users, details and audit render across required variants',
    (tester) async {
      final screens = <Widget>[
        const AdminGroupsScreen(),
        const AdminUsersScreen(),
        const AdminGroupDetailScreen(groupId: 'g1'),
        const AdminUserDetailScreen(userId: 'u1'),
        const AdminAuditScreen(),
      ];
      for (final screen in screens) {
        await pumpAllVariants(tester, screen, (tester, variant) async {
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${screen.runtimeType}: $variant',
          );
        });
      }
    },
  );
}
