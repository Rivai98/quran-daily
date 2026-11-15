import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/core/localization/arabic_formatting.dart';
import 'package:quran_daily/core/design_system/widgets/skeleton.dart';
import 'package:quran_daily/features/quran_groups/cubit/discovery/discovery_cubit.dart';
import 'package:quran_daily/features/quran_groups/cubit/group_list/group_list_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/models/models.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';
import 'package:quran_daily/features/quran_groups/view/screens/discovery_screen.dart';
import '../../../helpers/widget_test_app.dart';
import '../../../helpers/test_fixtures.dart';

class _Repository extends Mock implements GroupsRepository {}

const _group = PublicGroupProfile(
  groupId: 'g1',
  name: 'حلقة الفجر',
  shortDescription: 'ورد يومي',
  status: GroupStatus.active,
  activeMemberCount: 27,
  timezone: 'Africa/Cairo',
  joinMode: JoinMode.autoAccept,
);

Widget _screen(GroupsRepository repository) => MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => DiscoveryCubit(repository: repository)),
    BlocProvider(
      create: (_) => GroupListCubit(repository: repository)..refresh(),
    ),
  ],
  child: const DiscoveryScreen(),
);

void main() {
  setUpAll(loadArabicUiFontsForGoldenTests);
  late _Repository repository;
  setUp(() {
    repository = _Repository();
    when(
      () => repository.getMyGroups(),
    ).thenAnswer((_) async => Success(TestFixtures.overview()));
  });

  testWidgets(
    'discovery content supports RTL, scaling, dark theme, and 320dp',
    (tester) async {
      when(
        () => repository.searchPublicGroups(
          query: any(named: 'query'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => const Success([_group]));

      await pumpAllVariants(tester, _screen(repository), (
        tester,
        variant,
      ) async {
        await tester.pumpAndSettle();
        expect(
          find.text(ArabicStrings.discoveryScreenTitle),
          findsOneWidget,
          reason: variant,
        );
        expect(find.text('حلقة الفجر'), findsOneWidget, reason: variant);
        expect(
          find.byIcon(Icons.people_alt_rounded),
          findsOneWidget,
          reason: variant,
        );
        expect(
          find.byIcon(Icons.menu_book_rounded),
          findsOneWidget,
          reason: variant,
        );
        expect(
          find.byIcon(Icons.location_on_rounded),
          findsOneWidget,
          reason: variant,
        );
        expect(
          find.textContaining(ArabicFormatting.membersProgress(27)),
          findsOneWidget,
          reason: variant,
        );
        expect(
          find.text('القاهرة'),
          findsOneWidget,
          reason: 'timezone should be localized to a city name ($variant)',
        );
        expect(
          find.byWidgetPredicate((widget) => widget is TextButton),
          findsOneWidget,
          reason: 'join action should use a compact text button ($variant)',
        );
        expect(tester.takeException(), isNull, reason: variant);
      });
    },
  );

  testWidgets('golden: S2 discovery at 360x800 in light and dark themes', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    when(
      () => repository.searchPublicGroups(
        query: any(named: 'query'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => const Success([_group]));

    await tester.pumpWidget(
      buildArabicTestApp(_screen(repository), size: const Size(360, 800)),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../../goldens/design_c_s2_light.png'),
    );

    await tester.pumpWidget(
      buildArabicTestApp(
        _screen(repository),
        dark: true,
        size: const Size(360, 800),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../../goldens/design_c_s2_dark.png'),
    );
  });

  testWidgets('discovery shows loading, empty, and offline states', (
    tester,
  ) async {
    final completer = Completer<Result<List<PublicGroupProfile>>>();
    when(
      () => repository.searchPublicGroups(
        query: any(named: 'query'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) => completer.future);
    await tester.pumpWidget(buildArabicTestApp(_screen(repository)));
    await tester.pump();
    expect(find.byType(SkeletonBox), findsWidgets);

    completer.complete(const Success([]));
    await tester.pumpAndSettle();
    expect(find.text(ArabicStrings.noPublicGroups), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    when(
      () => repository.searchPublicGroups(
        query: any(named: 'query'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer(
      (_) async => const FailureResult(
        NetworkFailure(message: 'offline', code: 'network'),
      ),
    );
    await tester.pumpWidget(buildArabicTestApp(_screen(repository)));
    await tester.pumpAndSettle();
    expect(find.text(ArabicStrings.discoveryOffline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping search does not issue another request', (tester) async {
    when(
      () => repository.searchPublicGroups(
        query: any(named: 'query'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => const Success([_group]));

    await tester.pumpWidget(buildArabicTestApp(_screen(repository)));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.pump();

    verify(
      () => repository.searchPublicGroups(query: '', limit: 20, offset: 0),
    ).called(1);
  });

  testWidgets('keyboard submit searches immediately and cancels the debounce', (
    tester,
  ) async {
    when(
      () => repository.searchPublicGroups(
        query: any(named: 'query'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => const Success([_group]));

    await tester.pumpWidget(buildArabicTestApp(_screen(repository)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'الفجر');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.pump(DiscoveryCubit.debounceDuration);

    verify(
      () => repository.searchPublicGroups(query: 'الفجر', limit: 20, offset: 0),
    ).called(1);
  });

  testWidgets('discovery shows non-network failures with a retry action', (
    tester,
  ) async {
    when(
      () => repository.searchPublicGroups(
        query: any(named: 'query'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer(
      (_) async => const FailureResult(
        AuthFailure(message: 'forbidden', code: 'forbidden'),
      ),
    );
    await tester.pumpWidget(buildArabicTestApp(_screen(repository)));
    await tester.pumpAndSettle();
    expect(find.text(ArabicStrings.joinError), findsOneWidget);
    expect(find.text(ArabicStrings.retry), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('membership limit is shown once above the results', (
    tester,
  ) async {
    when(() => repository.getMyGroups()).thenAnswer(
      (_) async => Success(
        TestFixtures.overview(
          groups: [
            TestFixtures.myGroup(groupId: 'g-active-1'),
            TestFixtures.myGroup(groupId: 'g-active-2'),
          ],
        ),
      ),
    );
    when(
      () => repository.searchPublicGroups(
        query: any(named: 'query'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => const Success([_group]));

    await pumpAllVariants(tester, _screen(repository), (tester, variant) async {
      await tester.pumpAndSettle();
      expect(
        find.text(
          '${ArabicStrings.membershipLimitMessage} ${ArabicStrings.membershipLimitNextStep}',
        ),
        findsOneWidget,
        reason: variant,
      );
      expect(find.text(ArabicStrings.groupSelectionTitle), findsOneWidget);
      expect(
        find.text(ArabicStrings.membershipLimitReachedAction),
        findsAtLeastNWidgets(1),
      );
      expect(find.text(ArabicStrings.requestToJoin), findsNothing);
      expect(tester.takeException(), isNull, reason: variant);
    });
  });

  testWidgets('join membership_limit uses mapped Arabic snackbar copy', (
    tester,
  ) async {
    when(
      () => repository.searchPublicGroups(
        query: any(named: 'query'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => const Success([_group]));
    when(() => repository.joinGroup(groupId: 'g1')).thenAnswer(
      (_) async => const FailureResult(
        AuthFailure(message: 'limit', code: 'membership_limit'),
      ),
    );

    await tester.pumpWidget(buildArabicTestApp(_screen(repository)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ArabicStrings.requestToJoin));
    await tester.pumpAndSettle();

    expect(
      find.text(ArabicStrings.authError('membership_limit')),
      findsOneWidget,
    );
    expect(find.text(ArabicStrings.joinError), findsNothing);
  });
}
