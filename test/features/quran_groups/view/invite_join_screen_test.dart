import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/quran_groups/cubit/join/join_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/models/models.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';
import 'package:quran_daily/features/quran_groups/view/screens/invite_join_screen.dart';
import '../../../helpers/widget_test_app.dart';

class _Repository extends Mock implements GroupsRepository {}

const _profile = PublicGroupProfile(
  groupId: 'g1',
  name: 'حلقة الفجر',
  shortDescription: 'ورد يومي',
  status: GroupStatus.forming,
  activeMemberCount: 1,
  timezone: 'Africa/Cairo',
  joinMode: JoinMode.approval,
);

Widget _screen(GroupsRepository repository) => BlocProvider(
  create: (_) => JoinCubit(repository: repository),
  child: const InviteJoinScreen(initialCode: 'AB234567'),
);

void main() {
  setUpAll(loadArabicUiFontsForGoldenTests);
  late _Repository repository;
  setUp(() => repository = _Repository());

  testWidgets('invite preview is readable across required layout variants', (
    tester,
  ) async {
    when(
      () => repository.getInvitePreview('AB234567'),
    ).thenAnswer((_) async => const Success(_profile));
    await pumpAllVariants(tester, _screen(repository), (tester, variant) async {
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(ArabicStrings.joinGroupAction),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text(ArabicStrings.joinByInviteTitle),
        findsOneWidget,
        reason: variant,
      );
      expect(find.text('حلقة الفجر'), findsOneWidget, reason: variant);
      expect(
        find.text(ArabicStrings.joinGroupAction),
        findsOneWidget,
        reason: variant,
      );
      expect(tester.takeException(), isNull, reason: variant);
    });
  });

  testWidgets('invite form has a title that describes joining by invite code', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildArabicTestApp(
        BlocProvider(
          create: (_) => JoinCubit(repository: repository),
          child: const InviteJoinScreen(),
        ),
      ),
    );

    expect(find.text(ArabicStrings.joinByInviteTitle), findsOneWidget);
    expect(find.text(ArabicStrings.inviteJoinScreenTitle), findsNothing);
  });

  testWidgets('invite preview has light and dark 360x800 goldens', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    when(
      () => repository.getInvitePreview('AB234567'),
    ).thenAnswer((_) async => const Success(_profile));

    await tester.pumpWidget(
      buildArabicTestApp(_screen(repository), size: const Size(360, 800)),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../../goldens/join_invite_light_360x800.png'),
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
      matchesGoldenFile('../../../goldens/join_invite_dark_360x800.png'),
    );
  });

  testWidgets('invite screen presents full and invalid-link explanations', (
    tester,
  ) async {
    when(() => repository.getInvitePreview('AB234567')).thenAnswer(
      (_) async => const Success(
        PublicGroupProfile(
          groupId: 'g1',
          name: 'حلقة ممتلئة',
          status: GroupStatus.active,
          activeMemberCount: 30,
          timezone: 'Africa/Cairo',
          joinMode: JoinMode.approval,
        ),
      ),
    );
    await tester.pumpWidget(buildArabicTestApp(_screen(repository)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(ArabicStrings.inviteUnavailable),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(ArabicStrings.groupFull), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    when(() => repository.getInvitePreview('ZZ234567')).thenAnswer(
      (_) async => const FailureResult(
        AuthFailure(message: 'invite_invalid', code: 'invite_invalid'),
      ),
    );
    await tester.pumpWidget(
      buildArabicTestApp(
        BlocProvider(
          create: (_) => JoinCubit(repository: repository),
          child: const InviteJoinScreen(initialCode: 'ZZ234567'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(ArabicStrings.inviteUnavailable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'invite form covers empty, loading, offline, and pending states',
    (tester) async {
      final completer = Completer<Result<PublicGroupProfile>>();
      when(
        () => repository.getInvitePreview('AB234567'),
      ).thenAnswer((_) => completer.future);
      when(
        () => repository.joinGroup(
          inviteCode: 'AB234567',
          source: JoinSource.invite,
        ),
      ).thenAnswer(
        (_) async =>
            const Success(JoinOutcome(joined: false, joinRequestId: 'r1')),
      );
      final cubit = JoinCubit(repository: repository);
      await tester.pumpWidget(
        buildArabicTestApp(
          BlocProvider.value(value: cubit, child: const InviteJoinScreen()),
        ),
      );
      expect(find.text(ArabicStrings.inviteCodeLabel), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'AB234567');
      await tester.tap(find.text(ArabicStrings.previewInviteAction));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete(
        const FailureResult(
          NetworkFailure(message: 'offline', code: 'network'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(ArabicStrings.joinError), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      when(
        () => repository.getInvitePreview('AB234567'),
      ).thenAnswer((_) async => const Success(_profile));
      final pendingCubit = JoinCubit(repository: repository);
      await tester.pumpWidget(
        buildArabicTestApp(
          BlocProvider.value(
            value: pendingCubit,
            child: const InviteJoinScreen(initialCode: 'AB234567'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(ArabicStrings.joinGroupAction),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(ArabicStrings.joinGroupAction));
      await tester.pumpAndSettle();
      expect(find.text(ArabicStrings.pendingApproval), findsWidgets);
      expect(tester.takeException(), isNull);
      await cubit.close();
      await pendingCubit.close();
    },
  );
}
