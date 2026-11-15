import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/core/design_system/widgets/widgets.dart';
import 'package:quran_daily/features/quran_groups/cubit/create_group/create_group_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';
import 'package:quran_daily/features/quran_groups/view/screens/create_group_screen.dart';
import 'package:quran_daily/core/quran/portion_unit.dart';
import 'package:quran_daily/core/quran/quran_metadata_repository.dart';
import '../../../helpers/quran_metadata_test_asset_bundle.dart';

import '../../../helpers/widget_test_app.dart';

class _MockRepo extends Mock implements GroupsRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadArabicUiFontsForGoldenTests);
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_timezone'),
          (_) async => 'UTC',
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('flutter_timezone'),
            null,
          ),
    );
    registerFallbackValue(
      const CreateGroupInput(
        name: 'x',
        timezone: 'Africa/Cairo',
        visibility: GroupVisibility.private,
        joinMode: JoinMode.approval,
      ),
    );
  });

  Widget pump({QuranMetadataRepository? metadataRepository}) =>
      BlocProvider<CreateGroupCubit>(
        create: (_) => CreateGroupCubit(repository: repo),
        child: CreateGroupScreen(metadataRepository: metadataRepository),
      );

  testWidgets('renders name, description, visibility and join-mode controls', (
    tester,
  ) async {
    await tester.pumpWidget(buildArabicTestApp(pump()));

    expect(find.text(ArabicStrings.createGroup), findsAtLeastNWidgets(1));
    expect(find.byType(AppTextField), findsAtLeastNWidgets(2));
    // Field labels name the field, not the page or a validation message.
    expect(find.text(ArabicStrings.groupNameLabel), findsOneWidget);
    expect(find.text(ArabicStrings.shortDescriptionLabel), findsOneWidget);
    expect(find.text(ArabicStrings.groupSelectionTitle), findsNothing);
  });

  testWidgets('shows metadata-derived unit options and cycle lengths', (
    tester,
  ) async {
    final metadataRepository = QuranMetadataRepository(
      bundle: QuranMetadataTestAssetBundle(),
    );
    await tester.runAsync(metadataRepository.load);
    await tester.pumpWidget(
      buildArabicTestApp(pump(metadataRepository: metadataRepository)),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(ArabicStrings.portionUnitName(PortionUnit.juz)),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text(ArabicStrings.portionUnitName(PortionUnit.juz)),
      findsOneWidget,
    );
    expect(
      find.text(ArabicStrings.portionUnitName(PortionUnit.hizb)),
      findsOneWidget,
    );
    expect(find.text(ArabicStrings.khatmaDays(2)), findsAtLeastNWidgets(1));
    expect(find.text(ArabicStrings.khatmaDays(8)), findsOneWidget);
    expect(find.text(ArabicStrings.khatmaDays(21)), findsOneWidget);
  });

  testWidgets('create group form has light and dark 360x800 goldens', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final metadataRepository = QuranMetadataRepository(
      bundle: QuranMetadataTestAssetBundle(),
    );
    await tester.runAsync(metadataRepository.load);

    for (final dark in [false, true]) {
      await tester.pumpWidget(
        buildArabicTestApp(
          pump(metadataRepository: metadataRepository),
          dark: dark,
          size: const Size(360, 800),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          '../../../goldens/create_group_${dark ? 'dark' : 'light'}_360x800.png',
        ),
      );
    }
  });

  testWidgets('submitting invalid name shows Arabic validation error and '
      'blocks the repository', (tester) async {
    await tester.pumpWidget(buildArabicTestApp(pump()));

    await tester.enterText(find.byType(AppTextField).first, 'ab');
    await tester.ensureVisible(find.text(ArabicStrings.createTheGroup));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ArabicStrings.createTheGroup));
    await tester.pumpAndSettle();

    verifyNever(() => repo.createGroup(any()));
    expect(
      find.text(ArabicStrings.nameLengthError),
      findsAtLeastNWidgets(1),
      reason: 'the field-level Arabic error must be visible (hint shares text)',
    );
  });

  testWidgets('visibility and join modes have clear illustrated choices', (
    tester,
  ) async {
    await tester.pumpWidget(buildArabicTestApp(pump()));

    expect(find.byIcon(Icons.public_rounded), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.group_add_rounded), findsOneWidget);
    expect(find.byIcon(Icons.verified_user_outlined), findsOneWidget);
    expect(find.text(ArabicStrings.publicVisibilityHint), findsOneWidget);
    expect(find.text(ArabicStrings.ownerApprovalJoinModeHint), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('membership limit shows the two-group explanation', (
    tester,
  ) async {
    when(() => repo.createGroup(any())).thenAnswer(
      (_) async => const FailureResult(
        AuthFailure(message: 'membership_limit', code: 'membership_limit'),
      ),
    );

    await tester.pumpWidget(buildArabicTestApp(pump()));

    await tester.enterText(find.byType(AppTextField).first, 'حلقة صالحة');
    await tester.ensureVisible(find.text(ArabicStrings.createTheGroup));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ArabicStrings.createTheGroup));
    await tester.pumpAndSettle();

    expect(find.text(ArabicStrings.membershipLimitMessage), findsOneWidget);
  });

  testWidgets('uses the device timezone when creating a group', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_timezone'), (
          call,
        ) async {
          expect(call.method, 'getLocalTimezone');
          return 'Asia/Riyadh';
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('flutter_timezone'),
            null,
          ),
    );
    when(() => repo.createGroup(any())).thenAnswer(
      (_) async => const FailureResult(
        AuthFailure(message: 'temporary', code: 'network'),
      ),
    );

    await tester.pumpWidget(buildArabicTestApp(pump()));
    await tester.enterText(find.byType(AppTextField).first, 'حلقة الرياض');
    await tester.ensureVisible(find.text(ArabicStrings.createTheGroup));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ArabicStrings.createTheGroup));
    await tester.pumpAndSettle();

    final input =
        verify(() => repo.createGroup(captureAny())).captured.single
            as CreateGroupInput;
    expect(input.timezone, 'Asia/Riyadh');
  });

  testWidgets('renders in all constitution variants without overflow', (
    tester,
  ) async {
    await pumpAllVariants(tester, pump(), (tester, variant) async {
      expect(tester.takeException(), isNull, reason: variant);
    });
  });
}
