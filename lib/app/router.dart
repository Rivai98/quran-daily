import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_daily/features/quran_groups/cubit/discovery/discovery_cubit.dart';
import 'package:quran_daily/features/quran_groups/cubit/join/join_cubit.dart';

import '../core/di/service_locator.dart';
import '../core/errors/failures.dart';
import '../core/auth/session_gateway.dart';
import '../core/localization/arabic_strings.dart';
import '../core/quran/quran_metadata_repository.dart';
import '../core/storage/local_database.dart';
import '../core/quran/portion_unit.dart';
import '../core/settings/settings_repository.dart';
import '../core/quran/mushaf/mushaf_repository.dart';
import '../core/quran/mushaf/qpc_v2_repository.dart';
import '../core/design_system/widgets/state_panel.dart';
import '../features/quran_groups/cubit/dashboard/dashboard_cubit.dart';
import '../features/quran_groups/cubit/assignment/assignment_cubit.dart';
import '../features/quran_groups/data/entities/entities.dart';
import '../features/quran_groups/data/repositories/khatma_repository.dart';
import '../features/quran_groups/view/screens/history_screen.dart';
import '../features/quran_groups/view/screens/group_dashboard_screen.dart';
import '../features/quran_groups/view/screens/create_group_screen.dart';
import '../features/quran_groups/cubit/create_group/create_group_cubit.dart';
import '../features/quran_groups/view/screens/group_selection_screen.dart';
import '../features/quran_groups/cubit/join_requests/join_requests_cubit.dart';
import '../features/quran_groups/cubit/members/members_cubit.dart';
import '../features/quran_groups/view/screens/join_requests_screen.dart';
import '../features/quran_groups/view/screens/members_screen.dart';
import '../features/quran_groups/view/screens/group_settings_screen.dart';
import '../features/quran_groups/cubit/group_settings/group_settings_cubit.dart';
import '../features/quran_groups/view/screens/discovery_screen.dart';
import '../features/quran_groups/view/screens/invite_join_screen.dart';
import '../features/quran_groups/view/screens/personal_assignment_screen.dart';
import '../features/settings/view/settings_screen.dart';
import '../features/mushaf/cubit/reader_cubit.dart';
import '../features/mushaf/data/reader_storage.dart';
import '../features/mushaf/view/bookmarks_screen.dart';
import '../features/mushaf/view/mushaf_index_screen.dart';
import '../features/mushaf/view/reader_screen.dart';
import '../features/admin/view/admin_screens.dart';
import '../features/quran_groups/cubit/member_profile/member_profile_cubit.dart';
import '../features/quran_groups/view/screens/member_profile_screen.dart';
import '../features/quran_groups/cubit/group_info/group_info_cubit.dart';
import '../features/quran_groups/view/screens/group_info_screen.dart';
import '../features/settings/view/edit_profile_screen.dart';
import '../features/profile/cubit/profile_cubit.dart';
import '../features/profile/view/profile_screen.dart';
import '../features/log/cubit/log_cubit.dart';
import '../features/log/data/repositories/log_repository.dart';
import '../features/log/view/log_screen.dart';

String? inviteCodeFromDeepLink(Uri uri) {
  if (uri.scheme != 'qurandaily' ||
      uri.host != 'join' ||
      uri.pathSegments.length != 1) {
    return null;
  }
  final code = uri.pathSegments.single.toUpperCase();
  return RegExp(r'^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{8}$').hasMatch(code)
      ? code
      : null;
}

/// Global navigator key so the auth gate can clear any pushed private
/// routes when the session ends (sign-out/expiry): back navigation and
/// deep links must never rebuild private content while unauthenticated.
final navigatorKey = GlobalKey<NavigatorState>();

QuranMetadataRepository _metadataRepository() =>
    serviceLocator.isRegistered<QuranMetadataRepository>()
    ? serviceLocator<QuranMetadataRepository>()
    : QuranMetadataRepository();

class AppRoutes {
  const AppRoutes._();

  static const auth = '/';
  static const groups = '/groups';
  static const discovery = '/discover';
  static const dashboard = '/groups/dashboard';
  static const assignment = '/groups/dashboard/assignment';
  static const organizerReview = '/groups/organizer/review';
  static const joinRequests = '/groups/organizer/join-requests';
  static const members = '/groups/organizer/members';
  static const history = '/groups/history';
  static const groupSettings = '/groups/settings';
  static const settings = '/settings';
  static const mushaf = '/mushaf';
  static const mushafReader = '/mushaf/reader';
  static const mushafIndex = '/mushaf/index';
  static const mushafBookmarks = '/mushaf/bookmarks';
  static const mushafLicenses = '/mushaf/licenses';

  static Future<T?> pushReader<T>(BuildContext context, {Object? arguments}) =>
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamed<T>(mushafReader, arguments: arguments);

  // --- 007 profiles ---
  static const memberProfile = '/groups/member/profile';
  static const groupInfo = '/groups/info';
  static const editMyProfile = '/profile/edit';
  static const log = '/log';
  static const profile = '/profile';

  /// Root of the المصحف tab in the HomeShell: the Mushaf index (spec 003).
  /// Pages open on top of the index so back returns to it.
  static Widget mushafTab(BuildContext context) {
    final dependencies = _mushafDependencies();
    if (dependencies == null) return _mushafUnavailable();
    final (repository, _) = dependencies;
    return MushafIndexScreen(
      repository: repository,
      onOpenPage: (page) => pushReader(context, arguments: {'page': page}),
    );
  }

  static Map<String, WidgetBuilder> get routes {
    // The root "/" is owned by the auth gate in app.dart (home), so it is
    // deliberately absent from this table.
    return {
      groups: (_) =>
          GroupSelectionScreen(metadataRepository: _metadataRepository()),
      '/groups/new': (_) => BlocProvider(
        create: (_) => serviceLocator<CreateGroupCubit>(),
        child: CreateGroupScreen(metadataRepository: _metadataRepository()),
      ),
      discovery: (_) => BlocProvider(
        create: (_) => serviceLocator<DiscoveryCubit>()..load(),
        child: const DiscoveryScreen(),
      ),
      '/groups/discovery': (_) => BlocProvider(
        create: (_) => serviceLocator<DiscoveryCubit>()..load(),
        child: const DiscoveryScreen(),
      ),
      '/join': (_) => BlocProvider(
        create: (_) => serviceLocator<JoinCubit>(),
        child: InviteJoinScreen(metadataRepository: _metadataRepository()),
      ),
      '/join-any': (_) => BlocProvider(
        create: (_) => serviceLocator<JoinCubit>(),
        child: const InviteJoinScreen(joinAnyMode: true),
      ),
      dashboard: (context) {
        final groupId = ModalRoute.of(context)?.settings.arguments as String?;
        if (groupId == null || groupId.isEmpty) {
          return Scaffold(
            body: StatePanel(
              icon: Icons.groups,
              title: ArabicStrings.dashboardLoadError,
              message: ArabicStrings.networkFailure,
            ),
          );
        }
        return BlocProvider(
          create: (_) =>
              serviceLocator<DashboardCubit>(param1: groupId)..refresh(),
          child: GroupDashboardScreen(
            metadataRepository: _metadataRepository(),
          ),
        );
      },
      assignment: (context) {
        final snapshot = ModalRoute.of(context)?.settings.arguments;
        if (snapshot is! DashboardSnapshot || snapshot.myAssignments.isEmpty) {
          return Scaffold(
            body: StatePanel(
              icon: Icons.menu_book,
              title: ArabicStrings.noAssignmentToday,
              message: ArabicStrings.noAssignmentToday,
            ),
          );
        }
        final assignment = snapshot.myAssignments.firstWhere(
          (item) => item.isMe,
          orElse: () => snapshot.myAssignments.first,
        );
        return BlocProvider(
          create: (_) => AssignmentCubit(
            repository: serviceLocator<KhatmaRepository>(),
            assignment: assignment,
            groupId: snapshot.groupId,
            dayState: snapshot.today?.state ?? DayState.open,
          ),
          child: PersonalAssignmentScreen(
            snapshot: snapshot,
            metadataRepository: _metadataRepository(),
          ),
        );
      },
      joinRequests: (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments! as Map<String, Object?>;
        final groupId = args['groupId']! as String;
        final given = args['cubit'] as JoinRequestsCubit?;
        final screen = JoinRequestsScreen(groupId: groupId);
        return given != null
            ? BlocProvider.value(value: given, child: screen)
            : BlocProvider(
                create: (_) =>
                    serviceLocator<JoinRequestsCubit>()..load(groupId),
                child: screen,
              );
      },
      members: (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments! as Map<String, Object?>;
        final groupId = args['groupId']! as String;
        final given = args['cubit'] as MembersCubit?;
        final screen = MembersScreen(
          groupId: groupId,
          isOwner: args['isOwner'] == true,
          isSupervisor: args['isSupervisor'] == true,
        );
        return given != null
            ? BlocProvider.value(value: given, child: screen)
            : BlocProvider(
                create: (_) => serviceLocator<MembersCubit>()..load(groupId),
                child: screen,
              );
      },
      groupSettings: (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments! as Map<String, Object?>;
        final groupId = args['groupId']! as String;
        final inviteCode = args['inviteCode'] as String?;
        return BlocProvider(
          create: (_) =>
              serviceLocator<GroupSettingsCubit>()
                ..load(groupId: groupId, inviteCode: inviteCode),
          child: GroupSettingsScreen(
            groupId: groupId,
            isOwner: args['isOwner'] == true,
            inviteCode: inviteCode,
            portionUnit: args['portionUnit'] as PortionUnit? ?? PortionUnit.juz,
            isActive: args['isActive'] == true,
            groupName: args['groupName'] as String?,
            onKhatmaStarted: () => Navigator.of(context).pop(),
          ),
        );
      },
      history: (context) {
        final arguments = ModalRoute.of(context)?.settings.arguments;
        if (arguments is Map<String, Object?>) {
          return HistoryScreen(
            groupId: arguments['groupId'] as String?,
            initialDate: arguments['date'] as String?,
          );
        }
        return HistoryScreen(groupId: arguments as String?);
      },
      settings: (_) => const SettingsScreen(),
      mushaf: (context) {
        final dependencies = _mushafDependencies();
        if (dependencies == null) return _mushafUnavailable();
        final (repository, storage) = dependencies;
        return BlocProvider(
          create: (_) => ReaderCubit(
            repository: repository,
            storage: storage,
            settings: serviceLocator<SettingsRepository>(),
            qpcLayout: serviceLocator<QpcV2Repository>(),
            qpcFonts: serviceLocator<QpcFontManager>(),
          )..openLastPosition(),
          child: ReaderScreen(
            repository: repository,
            storage: storage,
            metadata: _metadataRepository(),
            qpcLayout: serviceLocator<QpcV2Repository>(),
          ),
        );
      },
      mushafReader: (context) {
        final dependencies = _mushafDependencies();
        if (dependencies == null) return _mushafUnavailable();
        final (repository, storage) = dependencies;
        final args = ModalRoute.of(context)?.settings.arguments;
        final params = args is Map<String, Object?>
            ? args
            : const <String, Object?>{};
        final page = params['page'] as int?;
        final unit = params['unit'] as PortionUnit?;
        final index = params['index'] as int?;
        final assignmentId = params['assignmentId'] as String?;
        final completed = params['alreadyCompleted'] == true;
        return BlocProvider(
          create: (_) {
            final cubit = ReaderCubit(
              repository: repository,
              storage: storage,
              settings: serviceLocator<SettingsRepository>(),
              qpcLayout: serviceLocator<QpcV2Repository>(),
              qpcFonts: serviceLocator<QpcFontManager>(),
              onComplete: assignmentId == null
                  ? null
                  : () async {
                      final result = await serviceLocator<KhatmaRepository>()
                          .markComplete(assignmentId, DateTime.now());
                      final failure = result.failureOrNull;
                      if (failure?.category == FailureCategory.offlineQueued) {
                        return true;
                      }
                      if (failure != null) throw StateError(failure.code);
                      return false;
                    },
            );
            if (unit != null && index != null && assignmentId != null) {
              cubit.openPortion(
                unit,
                index,
                assignmentId: assignmentId,
                alreadyCompleted: completed,
              );
            } else {
              cubit.openPage(page ?? 1);
            }
            return cubit;
          },
          child: ReaderScreen(
            repository: repository,
            storage: storage,
            metadata: _metadataRepository(),
            qpcLayout: serviceLocator<QpcV2Repository>(),
          ),
        );
      },
      mushafIndex: (context) {
        final dependencies = _mushafDependencies();
        if (dependencies == null) return _mushafUnavailable();
        final (repository, _) = dependencies;
        return MushafIndexScreen(
          repository: repository,
          onOpenPage: (page) => pushReader(context, arguments: {'page': page}),
        );
      },
      mushafBookmarks: (context) {
        final dependencies = _mushafDependencies();
        if (dependencies == null) return _mushafUnavailable();
        final storage = dependencies.$2;
        return BookmarksScreen(
          storage: storage,
          onOpenPage: (page) => pushReader(context, arguments: {'page': page}),
        );
      },
      mushafLicenses: (_) => const MushafLicensesScreen(),
      '/admin': (_) => const AdminOverviewScreen(),
      '/admin/groups': (_) => const AdminGroupsScreen(),
      '/admin/users': (_) => const AdminUsersScreen(),
      '/admin/audit': (_) => const AdminAuditScreen(),
      '/admin/group': (context) => AdminGroupDetailScreen(
        groupId: ModalRoute.of(context)?.settings.arguments as String? ?? '',
      ),
      '/admin/user': (context) => AdminUserDetailScreen(
        userId: ModalRoute.of(context)?.settings.arguments as String? ?? '',
      ),
      memberProfile: (context) {
        final args = MemberProfileArgs.fromDynamic(
          ModalRoute.of(context)?.settings.arguments,
        );
        return BlocProvider(
          create: (_) => serviceLocator<MemberProfileCubit>(),
          child: MemberProfileScreen(
            userId: args.userId,
            groupId: args.groupId,
          ),
        );
      },
      groupInfo: (context) {
        final groupId =
            ModalRoute.of(context)?.settings.arguments as String? ?? '';
        return BlocProvider(
          create: (_) => serviceLocator<GroupInfoCubit>(),
          child: GroupInfoScreen(groupId: groupId),
        );
      },
      editMyProfile: (_) => const EditProfileScreen(),
      profile: (_) => BlocProvider(
        create: (_) => serviceLocator<ProfileCubit>()..load(),
        child: const ProfileScreen(),
      ),
      log: (_) => BlocProvider(
        create: (_) => serviceLocator<LogCubit>()..load(),
        child: LogScreen(repository: serviceLocator<LogRepository>()),
      ),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final uri = Uri.tryParse(settings.name ?? '');
    if (uri == null ||
        uri.pathSegments.length != 2 ||
        uri.pathSegments.first != 'join') {
      return null;
    }
    final code = uri.pathSegments.last.toUpperCase();
    if (!RegExp(r'^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{8}$').hasMatch(code)) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => BlocProvider(
          create: (_) => serviceLocator<JoinCubit>(),
          child: const InviteJoinScreen(initialCode: 'INVALID'),
        ),
      );
    }
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => BlocProvider(
        create: (_) => serviceLocator<JoinCubit>(),
        child: InviteJoinScreen(initialCode: code),
      ),
    );
  }
}

(MushafRepository, ReaderStorage)? _mushafDependencies() {
  if (!serviceLocator.isRegistered<MushafRepository>() ||
      !serviceLocator.isRegistered<ReaderStorage>() ||
      !serviceLocator.isRegistered<SessionGateway>() ||
      !serviceLocator.isRegistered<LocalDatabase>()) {
    return null;
  }
  final userId = serviceLocator<SessionGateway>().currentUserId;
  if (userId == null) return null;
  return (serviceLocator<MushafRepository>(), serviceLocator<ReaderStorage>());
}

Widget _mushafUnavailable() => Scaffold(
  body: StatePanel(
    icon: Icons.menu_book,
    title: ArabicStrings.mushafLoadError,
    message: ArabicStrings.mushafIntegrityError,
    isError: true,
  ),
);

/// Clears every route above the gate (which re-decides auth vs private).
void resetToGate() {
  navigatorKey.currentState?.popUntil((route) => route.isFirst);
}
