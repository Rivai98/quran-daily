import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/app/router.dart';
import 'package:quran_daily/core/di/service_locator.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/quran_groups/cubit/create_group/create_group_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';

import '../helpers/widget_test_app.dart';

class _Groups extends Mock implements GroupsRepository {}

void main() {
  setUp(() async {
    await serviceLocator.reset();
    serviceLocator.registerFactory<CreateGroupCubit>(
      () => CreateGroupCubit(repository: _Groups()),
    );
  });
  tearDown(serviceLocator.reset);

  testWidgets('/groups/new route provides its cubit and renders the form', (
    tester,
  ) async {
    final builder = AppRoutes.routes['/groups/new']!;
    await tester.pumpWidget(buildArabicTestApp(Builder(builder: builder)));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(ArabicStrings.groupNameLabel), findsOneWidget);
    expect(find.text(ArabicStrings.createTheGroup), findsOneWidget);
  });

  testWidgets('reader entry pushes onto root navigator above tab bar', (
    tester,
  ) async {
    final rootKey = GlobalKey<NavigatorState>();
    var readerIsOnRoot = false;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: rootKey,
        routes: {
          AppRoutes.mushafReader: (context) {
            readerIsOnRoot =
                ModalRoute.of(context)?.navigator == rootKey.currentState;
            return const Scaffold(body: Text('reader route'));
          },
        },
        home: Scaffold(
          body: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (context) => Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () =>
                        AppRoutes.pushReader(context, arguments: {'page': 1}),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: const Text('tab bar'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(readerIsOnRoot, isTrue);
    expect(find.text('reader route'), findsOneWidget);
    expect(find.text('tab bar'), findsNothing);
  });
}
