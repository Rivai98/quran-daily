import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/quran_groups/cubit/join_requests/join_requests_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/view/screens/join_requests_screen.dart';

import '../../../helpers/widget_test_app.dart';

class _Groups extends Mock implements GroupsRepository {}

void main() {
  setUpAll(loadAppFontsForGoldenTests);

  testWidgets('golden: join requests at 360x800 in light and dark themes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Groups();
    when(() => repository.listJoinRequests('g')).thenAnswer(
      (_) async => Success([
        PublicJoinRequestInfo(
          joinRequestId: 'r1',
          userDisplayName: 'أحمد سالم',
          requestedAt: DateTime.utc(2026),
          source: JoinSource.invite,
        ),
        PublicJoinRequestInfo(
          joinRequestId: 'r2',
          userDisplayName: 'سارة محمود',
          requestedAt: DateTime.utc(2026),
          source: JoinSource.discovery,
        ),
      ]),
    );
    for (final dark in [false, true]) {
      await tester.pumpWidget(
        buildArabicTestApp(
          BlocProvider(
            create: (_) => JoinRequestsCubit(repository),
            child: const JoinRequestsScreen(groupId: 'g'),
          ),
          dark: dark,
          size: const Size(360, 800),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(JoinRequestsScreen),
        matchesGoldenFile(
          dark
              ? 'goldens/polish_b_join_requests_dark.png'
              : 'goldens/polish_b_join_requests_light.png',
        ),
      );
    }
  });

  testWidgets('request view fits every constitution variant', (tester) async {
    final repository = _Groups();
    when(() => repository.listJoinRequests('g')).thenAnswer(
      (_) async => Success([
        PublicJoinRequestInfo(
          joinRequestId: 'r',
          userDisplayName: ArabicStrings.memberRole,
          requestedAt: DateTime.utc(2026),
          source: JoinSource.invite,
        ),
      ]),
    );
    await pumpAllVariants(
      tester,
      BlocProvider(
        create: (_) => JoinRequestsCubit(repository),
        child: const JoinRequestsScreen(groupId: 'g'),
      ),
      (tester, variant) async {
        expect(
          find.text(ArabicStrings.memberRole),
          findsOneWidget,
          reason: variant,
        );
        expect(tester.takeException(), isNull, reason: variant);
      },
    );
  });
}
