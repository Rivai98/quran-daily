import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/design_system/app_colors.dart';
import 'package:quran_daily/core/design_system/widgets/app_avatar.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/core/quran/portion_unit.dart';
import 'package:quran_daily/core/quran/quran_metadata_repository.dart';
import 'package:quran_daily/features/quran_groups/cubit/group_info/group_info_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';
import 'package:quran_daily/features/quran_groups/services/group_photo_service.dart';
import 'package:quran_daily/features/quran_groups/view/screens/group_info_screen.dart';

import '../../../helpers/quran_metadata_test_asset_bundle.dart';
import '../../../helpers/widget_test_app.dart';

class _MockGroupsRepository extends Mock implements GroupsRepository {}

class _MockGroupPhotoService extends Mock implements GroupPhotoService {}

void main() {
  setUpAll(loadAppFontsForGoldenTests);

  late _MockGroupsRepository repository;
  late _MockGroupPhotoService photoService;
  late QuranMetadataRepository metadataRepository;

  final ownerGroupInfo = GroupInfo(
    groupId: 'g-1',
    name: 'أهل القرآن',
    description: 'مجموعة لتلاوة وتدبر القرآن الكريم',
    photoPath: null,
    status: GroupStatus.active,
    visibility: GroupVisibility.public,
    joinMode: JoinMode.autoAccept,
    portionUnit: PortionUnit.juz,
    timezone: 'Africa/Cairo',
    createdAt: DateTime.parse('2026-01-15T00:00:00Z'),
    myRole: GroupRole.owner,
    memberCount: 20,
    seatCapacity: 30,
    khatmaCount: 5,
    inviteCode: 'JOIN1234',
    members: [
      GroupInfoMember(
        userId: 'u-1',
        membershipId: 'm-1',
        displayName: 'أحمد الإمام',
        role: GroupRole.owner,
        seatNumber: 1,
        joinedAt: DateTime.parse('2026-01-15T00:00:00Z'),
      ),
      GroupInfoMember(
        userId: 'u-2',
        membershipId: 'm-2',
        displayName: 'يوسف الصديق',
        role: GroupRole.member,
        seatNumber: 2,
        joinedAt: DateTime.parse('2026-01-16T00:00:00Z'),
      ),
    ],
  );

  final regularMemberGroupInfo = GroupInfo(
    groupId: 'g-1',
    name: 'أهل القرآن',
    description: 'مجموعة لتلاوة وتدبر القرآن الكريم',
    photoPath: null,
    status: GroupStatus.active,
    visibility: GroupVisibility.public,
    joinMode: JoinMode.autoAccept,
    portionUnit: PortionUnit.juz,
    timezone: 'Africa/Cairo',
    createdAt: DateTime.parse('2026-01-15T00:00:00Z'),
    myRole: GroupRole.member,
    memberCount: 20,
    seatCapacity: 30,
    khatmaCount: 5,
    inviteCode: null,
    members: ownerGroupInfo.members,
  );

  setUp(() async {
    repository = _MockGroupsRepository();
    photoService = _MockGroupPhotoService();
    metadataRepository = QuranMetadataRepository(
      bundle: QuranMetadataTestAssetBundle(),
    );
    await metadataRepository.load();
    when(
      () => repository.getGroupInfo('g-1'),
    ).thenAnswer((_) async => Success(ownerGroupInfo));
  });

  group('GroupInfoScreen (T016, T017, T018, T019, T020)', () {
    testWidgets('golden: group info at 360x800 in light and dark themes', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final dark in [false, true]) {
        final cubit = GroupInfoCubit(repository)
          ..emit(
            GroupInfoState(
              status: GroupInfoStatus.success,
              groupInfo: ownerGroupInfo,
            ),
          );
        addTearDown(cubit.close);
        await tester.pumpWidget(
          buildArabicTestApp(
            BlocProvider.value(
              value: cubit,
              child: GroupInfoScreen(
                groupId: 'g-1',
                photoService: photoService,
                metadataRepository: metadataRepository,
              ),
            ),
            dark: dark,
            size: const Size(360, 800),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(GroupInfoScreen),
          matchesGoldenFile(
            dark
                ? 'goldens/polish_b_group_info_dark.png'
                : 'goldens/polish_b_group_info_light.png',
          ),
        );
      }
    });

    testWidgets('renders details, stats, and member list', (tester) async {
      final cubit = GroupInfoCubit(repository);
      cubit.emit(
        GroupInfoState(
          status: GroupInfoStatus.success,
          groupInfo: ownerGroupInfo,
        ),
      );

      await tester.pumpWidget(
        buildArabicTestApp(
          BlocProvider.value(
            value: cubit,
            child: GroupInfoScreen(
              groupId: 'g-1',
              photoService: photoService,
              metadataRepository: metadataRepository,
            ),
          ),
        ),
      );

      expect(find.text('أهل القرآن'), findsOneWidget);
      expect(find.text('مجموعة لتلاوة وتدبر القرآن الكريم'), findsOneWidget);
      expect(find.byType(GroupAvatar), findsOneWidget);
      expect(find.text(ArabicStrings.groupStats), findsOneWidget);
      expect(find.text(ArabicStrings.createdDate), findsOneWidget);
      expect(find.text(ArabicStrings.completedKhatmas), findsOneWidget);
      expect(find.text('٥'), findsOneWidget); // Arabic numeral 5
      expect(find.text(ArabicStrings.inviteCodeLabel), findsOneWidget);
      expect(find.text('JOIN1234'), findsOneWidget);
      expect(find.text('أحمد الإمام'), findsOneWidget);
      expect(find.text('يوسف الصديق'), findsOneWidget);
      expect(find.byType(UserAvatar), findsNWidgets(2));
    });

    testWidgets('owner sees edit details button and photo change button', (
      tester,
    ) async {
      final cubit = GroupInfoCubit(repository);
      cubit.emit(
        GroupInfoState(
          status: GroupInfoStatus.success,
          groupInfo: ownerGroupInfo,
        ),
      );

      await tester.pumpWidget(
        buildArabicTestApp(
          BlocProvider.value(
            value: cubit,
            child: GroupInfoScreen(
              groupId: 'g-1',
              photoService: photoService,
              metadataRepository: metadataRepository,
            ),
          ),
        ),
      );

      expect(find.byTooltip(ArabicStrings.editGroupDetails), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
    });

    testWidgets(
      'plain member does not see edit details or photo change button or invite code',
      (tester) async {
        final cubit = GroupInfoCubit(repository);
        cubit.emit(
          GroupInfoState(
            status: GroupInfoStatus.success,
            groupInfo: regularMemberGroupInfo,
          ),
        );

        await tester.pumpWidget(
          buildArabicTestApp(
            BlocProvider.value(
              value: cubit,
              child: GroupInfoScreen(
                groupId: 'g-1',
                photoService: photoService,
                metadataRepository: metadataRepository,
              ),
            ),
          ),
        );

        expect(find.byTooltip(ArabicStrings.editGroupDetails), findsNothing);
        expect(find.byIcon(Icons.camera_alt), findsNothing);
        expect(find.text(ArabicStrings.inviteCodeLabel), findsNothing);
      },
    );

    testWidgets(
      'PRIVACY: never renders email addresses in group info or members list',
      (tester) async {
        final cubit = GroupInfoCubit(repository);
        cubit.emit(
          GroupInfoState(
            status: GroupInfoStatus.success,
            groupInfo: ownerGroupInfo,
          ),
        );

        await tester.pumpWidget(
          buildArabicTestApp(
            BlocProvider.value(
              value: cubit,
              child: GroupInfoScreen(
                groupId: 'g-1',
                photoService: photoService,
                metadataRepository: metadataRepository,
              ),
            ),
          ),
        );

        expect(find.textContaining('@'), findsNothing);
        expect(find.textContaining('.com'), findsNothing);
      },
    );

    testWidgets('adapts cleanly to narrow screen 320dp without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320 * 2, 640 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = GroupInfoCubit(repository);
      cubit.emit(
        GroupInfoState(
          status: GroupInfoStatus.success,
          groupInfo: ownerGroupInfo,
        ),
      );

      await tester.pumpWidget(
        buildArabicTestApp(
          BlocProvider.value(
            value: cubit,
            child: GroupInfoScreen(
              groupId: 'g-1',
              photoService: photoService,
              metadataRepository: metadataRepository,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('adapts cleanly to 200% text scale without overflow', (
      tester,
    ) async {
      final cubit = GroupInfoCubit(repository);
      cubit.emit(
        GroupInfoState(
          status: GroupInfoStatus.success,
          groupInfo: ownerGroupInfo,
        ),
      );

      await tester.pumpWidget(
        buildArabicTestApp(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: BlocProvider.value(
              value: cubit,
              child: GroupInfoScreen(
                groupId: 'g-1',
                photoService: photoService,
                metadataRepository: metadataRepository,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly in dark theme', (tester) async {
      final cubit = GroupInfoCubit(repository);
      cubit.emit(
        GroupInfoState(
          status: GroupInfoStatus.success,
          groupInfo: ownerGroupInfo,
        ),
      );

      await tester.pumpWidget(
        buildArabicTestApp(
          Theme(
            data: ThemeData.dark().copyWith(extensions: [AppColors.dark]),
            child: BlocProvider.value(
              value: cubit,
              child: GroupInfoScreen(
                groupId: 'g-1',
                photoService: photoService,
                metadataRepository: metadataRepository,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('أهل القرآن'), findsOneWidget);
    });
  });
}
