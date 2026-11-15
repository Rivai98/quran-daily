import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/quran_groups/cubit/members/members_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';
import 'package:quran_daily/features/quran_groups/view/screens/members_screen.dart';

import '../../../helpers/widget_test_app.dart';

class _Groups extends Mock implements GroupsRepository {}

void main() {
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
          expect(tester.takeException(), isNull, reason: variant);
        },
      );
    });
  }
}
