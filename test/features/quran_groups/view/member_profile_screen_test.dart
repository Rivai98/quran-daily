import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/design_system/app_colors.dart';
import 'package:quran_daily/core/design_system/widgets/app_avatar.dart';
import 'package:quran_daily/core/design_system/widgets/status_chip.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/quran_groups/cubit/member_profile/member_profile_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';
import 'package:quran_daily/features/quran_groups/view/screens/member_profile_screen.dart';

import '../../../helpers/widget_test_app.dart';

class _MockGroupsRepository extends Mock implements GroupsRepository {}

void main() {
  late _MockGroupsRepository repository;

  final memberProfileData = MemberGroupProfile(
    userId: 'u-123',
    groupId: 'g-abc',
    displayName: 'سلمان الفارسي',
    initials: 'س ف',
    bio: 'حب القرآن حياة القلوب',
    role: 'member',
    seatNumber: 15,
    memberSince: DateTime.parse('2026-02-01T00:00:00Z'),
    isMe: false,
    currentStreak: 7,
    completionRate: 85,
    portionsRead: 30,
    recentDays: const [
      MemberRecentDay(
        groupDate: '2026-11-15',
        portionIndex: 15,
        juz: 15,
        kind: AssignmentKind.seat,
        status: AssignmentStatusEnum.completed,
      ),
      MemberRecentDay(
        groupDate: '2026-11-14',
        portionIndex: 14,
        juz: 14,
        kind: AssignmentKind.volunteer,
        status: AssignmentStatusEnum.late,
      ),
    ],
  );

  setUp(() {
    repository = _MockGroupsRepository();
    when(() => repository.getMemberProfile(any(), any()))
        .thenAnswer((_) async => Success(memberProfileData));
  });

  group('MemberProfileScreen (T012 & T014)', () {
    testWidgets('renders member profile details (name, avatar, role, bio, metrics, recent days)', (tester) async {
      final cubit = MemberProfileCubit(repository);
      cubit.emit(
        MemberProfileState(
          status: MemberProfileStatus.success,
          profile: memberProfileData,
        ),
      );

      await tester.pumpWidget(
        buildArabicTestApp(
          BlocProvider.value(
            value: cubit,
            child: const MemberProfileScreen(
              userId: 'u-123',
              groupId: 'g-abc',
            ),
          ),
        ),
      );

      expect(find.text('سلمان الفارسي'), findsOneWidget);
      expect(find.byType(UserAvatar), findsOneWidget);
      expect(find.text(ArabicStrings.memberRoleMember), findsOneWidget);
      expect(find.text('حب القرآن حياة القلوب'), findsOneWidget);
      expect(find.text(ArabicStrings.currentStreak), findsOneWidget);
      expect(find.text(ArabicStrings.completionRate), findsOneWidget);
      expect(find.text(ArabicStrings.portionsRead), findsOneWidget);
      expect(find.text(ArabicStrings.recentDays), findsOneWidget);
      expect(find.byType(StatusChip), findsNWidgets(2));
      expect(find.text(ArabicStrings.tagVolunteer), findsOneWidget);
    });

    testWidgets('PRIVACY: never shows email under any circumstances', (tester) async {
      final cubit = MemberProfileCubit(repository);
      cubit.emit(
        MemberProfileState(
          status: MemberProfileStatus.success,
          profile: memberProfileData,
        ),
      );

      await tester.pumpWidget(
        buildArabicTestApp(
          BlocProvider.value(
            value: cubit,
            child: const MemberProfileScreen(
              userId: 'u-123',
              groupId: 'g-abc',
            ),
          ),
        ),
      );

      expect(find.textContaining('@'), findsNothing);
      expect(find.textContaining('.com'), findsNothing);
    });

    testWidgets('displays profileNotAccessible when user has no access', (tester) async {
      final cubit = MemberProfileCubit(repository);
      cubit.emit(
        const MemberProfileState(
          status: MemberProfileStatus.notAccessible,
        ),
      );

      await tester.pumpWidget(
        buildArabicTestApp(
          BlocProvider.value(
            value: cubit,
            child: const MemberProfileScreen(
              userId: 'u-stranger',
              groupId: 'g-secret',
            ),
          ),
        ),
      );

      expect(find.text(ArabicStrings.profileNotAccessible), findsAtLeastNWidgets(1));
    });

    testWidgets('shows edit button when profile.isMe is true', (tester) async {
      final myProfile = MemberGroupProfile(
        userId: 'u-me',
        groupId: 'g-abc',
        displayName: 'أنا المستخدم',
        role: 'owner',
        memberSince: DateTime.parse('2026-01-01T00:00:00Z'),
        isMe: true,
      );

      final cubit = MemberProfileCubit(repository);
      cubit.emit(
        MemberProfileState(
          status: MemberProfileStatus.success,
          profile: myProfile,
        ),
      );

      await tester.pumpWidget(
        buildArabicTestApp(
          BlocProvider.value(
            value: cubit,
            child: const MemberProfileScreen(
              userId: 'u-me',
              groupId: 'g-abc',
            ),
          ),
        ),
      );

      expect(find.text(ArabicStrings.editProfile), findsOneWidget);
      expect(find.text(ArabicStrings.memberRoleOwner), findsOneWidget);
    });

    testWidgets('adapts cleanly to narrow screen 320dp without overflow', (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 640 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = MemberProfileCubit(repository);
      cubit.emit(
        MemberProfileState(
          status: MemberProfileStatus.success,
          profile: memberProfileData,
        ),
      );

      await tester.pumpWidget(
        buildArabicTestApp(
          BlocProvider.value(
            value: cubit,
            child: const MemberProfileScreen(
              userId: 'u-123',
              groupId: 'g-abc',
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('adapts cleanly to 200% text scale without overflow', (tester) async {
      final cubit = MemberProfileCubit(repository);
      cubit.emit(
        MemberProfileState(
          status: MemberProfileStatus.success,
          profile: memberProfileData,
        ),
      );

      await tester.pumpWidget(
        buildArabicTestApp(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: BlocProvider.value(
              value: cubit,
              child: const MemberProfileScreen(
                userId: 'u-123',
                groupId: 'g-abc',
              ),
            ),
          ),
        ),
      );

      final err = tester.takeException();
      if (err is FlutterError) {
        // ignore: avoid_print
        for (final node in err.diagnostics) {
          // ignore: avoid_print
          print('${node.name}: ${node.toDescription()}');
        }
      }
      expect(err, isNull);
    });

    testWidgets('renders cleanly in dark theme', (tester) async {
      final cubit = MemberProfileCubit(repository);
      cubit.emit(
        MemberProfileState(
          status: MemberProfileStatus.success,
          profile: memberProfileData,
        ),
      );

      await tester.pumpWidget(
        buildArabicTestApp(
          Theme(
            data: ThemeData.dark().copyWith(
              extensions: [AppColors.dark],
            ),
            child: BlocProvider.value(
              value: cubit,
              child: const MemberProfileScreen(
                userId: 'u-123',
                groupId: 'g-abc',
              ),
            ),
          ),
        ),
      );

      final err = tester.takeException();
      if (err is FlutterError) {
        // ignore: avoid_print
        for (final node in err.diagnostics) {
          // ignore: avoid_print
          print('${node.name}: ${node.toDescription()}');
        }
      }
      expect(err, isNull);
      expect(find.text('سلمان الفارسي'), findsOneWidget);
    });
  });
}
