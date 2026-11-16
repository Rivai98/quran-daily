import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/quran_groups/cubit/members/members_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';
import 'package:quran_daily/core/design_system/widgets/app_avatar.dart';
import 'package:quran_daily/features/quran_groups/view/screens/members_screen.dart';

import '../../../helpers/widget_test_app.dart';

class _Groups extends Mock implements GroupsRepository {}

void main() {
  setUpAll(loadAppFontsForGoldenTests);

  testWidgets('golden: members at 360x800 in light and dark themes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Groups();
    when(() => repository.getMembers('g')).thenAnswer(
      (_) async => const Success(
        SeatMap(
          groupId: 'g',
          members: [
            SeatMember(
              membershipId: 'm1',
              displayName: 'أحمد سالم',
              role: GroupRole.owner,
              seatNumber: 1,
            ),
            SeatMember(
              membershipId: 'm2',
              displayName: 'سارة محمود',
              role: GroupRole.member,
              seatNumber: 2,
            ),
          ],
          activeMemberCount: 2,
        ),
      ),
    );
    when(() => repository.getGroupInfo('g')).thenAnswer(
      (_) async => const FailureResult(UnknownFailure(message: '', code: '')),
    );
    for (final dark in [false, true]) {
      await tester.pumpWidget(
        buildArabicTestApp(
          BlocProvider(
            create: (_) => MembersCubit(repository),
            child: const MembersScreen(
              groupId: 'g',
              isOwner: true,
              isSupervisor: false,
            ),
          ),
          dark: dark,
          size: const Size(360, 800),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MembersScreen),
        matchesGoldenFile(
          dark
              ? 'goldens/polish_b_members_dark.png'
              : 'goldens/polish_b_members_light.png',
        ),
      );
    }
  });

  for (final role in ['owner', 'supervisor', 'member']) {
    testWidgets('$role view fits every constitution variant', (tester) async {
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
      when(() => repository.getGroupInfo('g')).thenAnswer(
        (_) async => Success(
          GroupInfo(
            groupId: 'g',
            name: 'Group',
            status: GroupStatus.active,
            visibility: GroupVisibility.public,
            joinMode: JoinMode.approval,
            timezone: 'UTC',
            createdAt: DateTime(2026),
            myRole: GroupRole.owner,
            memberCount: 1,
            members: [
              GroupInfoMember(
                userId: 'u',
                membershipId: 'm',
                displayName: ArabicStrings.memberRole,
                role: GroupRole.member,
                joinedAt: DateTime(2026),
              ),
            ],
          ),
        ),
      );
      await pumpAllVariants(
        tester,
        BlocProvider(
          create: (_) => MembersCubit(repository),
          child: MembersScreen(
            groupId: 'g',
            isOwner: role == 'owner',
            isSupervisor: role == 'supervisor',
          ),
        ),
        (tester, variant) async {
          expect(
            find.text(ArabicStrings.memberRole),
            findsWidgets,
            reason: variant,
          );
          expect(find.byType(UserAvatar), findsOneWidget, reason: variant);
          // 005 T031: role badge icon next to the member.
          expect(
            find.byIcon(Icons.shield_rounded),
            findsOneWidget,
            reason: variant,
          );
          expect(
            find.byIcon(Icons.event_seat_rounded),
            findsOneWidget,
            reason: variant,
          );
          expect(tester.takeException(), isNull, reason: variant);
        },
      );
    });
  }
}
