import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/design_system/app_theme.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/quran_groups/cubit/members/members_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';
import 'package:quran_daily/features/quran_groups/view/screens/members_screen.dart';

class _Groups extends Mock implements GroupsRepository {}

void main() {
  for (final role in ['owner', 'supervisor', 'member']) {
    testWidgets('$role view fits 320dp, RTL, large text and dark theme', (
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
      when(() => repository.getMembers('g')).thenAnswer(
        (_) async => const Success(
          SeatMap(
            groupId: 'g',
            members: [
              SeatMember(
                membershipId: 'm',
                displayName: ArabicStrings.memberRole,
                role: GroupRole.member,
                seatNumber: 2,
              ),
            ],
            activeMemberCount: 1,
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: BlocProvider(
              create: (_) => MembersCubit(repository),
              child: MembersScreen(
                groupId: 'g',
                isOwner: role == 'owner',
                isSupervisor: role == 'supervisor',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(ArabicStrings.memberRole), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
