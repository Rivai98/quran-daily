import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/quran_groups/cubit/discovery/discovery_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/models/models.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';
import 'package:quran_daily/features/quran_groups/view/screens/discovery_screen.dart';
import '../../../helpers/widget_test_app.dart';

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

Widget _screen(GroupsRepository repository) => BlocProvider(
  create: (_) => DiscoveryCubit(repository: repository),
  child: const DiscoveryScreen(),
);

void main() {
  late _Repository repository;
  setUp(() => repository = _Repository());

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
        expect(find.text('٢٧ / ٣٠ عضو نشط'), findsOneWidget, reason: variant);
        expect(tester.takeException(), isNull, reason: variant);
      });
    },
  );

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
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

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
}
