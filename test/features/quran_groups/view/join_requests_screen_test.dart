import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/design_system/app_theme.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/quran_groups/cubit/join_requests/join_requests_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/view/screens/join_requests_screen.dart';

class _Groups extends Mock implements GroupsRepository {}

void main() {
  testWidgets('request view fits narrow RTL at 200% text scale in dark theme', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );
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
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: BlocProvider(
            create: (_) => JoinRequestsCubit(repository),
            child: const JoinRequestsScreen(groupId: 'g'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(ArabicStrings.memberRole), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
