import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_daily/features/quran_groups/cubit/discovery/discovery_cubit.dart';
import 'package:quran_daily/features/quran_groups/cubit/join/join_cubit.dart';

import '../core/di/service_locator.dart';
import '../core/localization/arabic_strings.dart';
import '../core/quran/quran_metadata_repository.dart';
import '../core/design_system/widgets/state_panel.dart';
import '../features/quran_groups/cubit/dashboard/dashboard_cubit.dart';
import '../features/quran_groups/cubit/assignment/assignment_cubit.dart';
import '../features/quran_groups/data/entities/entities.dart';
import '../features/quran_groups/data/repositories/khatma_repository.dart';
import '../features/quran_groups/view/screens/daily_history_screen.dart';
import '../features/quran_groups/view/screens/group_dashboard_screen.dart';
import '../features/quran_groups/view/screens/create_group_screen.dart';
import '../features/quran_groups/view/screens/group_selection_screen.dart';
import '../features/quran_groups/cubit/join_requests/join_requests_cubit.dart';
import '../features/quran_groups/cubit/members/members_cubit.dart';
import '../features/quran_groups/view/screens/join_requests_screen.dart';
import '../features/quran_groups/view/screens/members_screen.dart';
import '../features/quran_groups/view/screens/discovery_screen.dart';
import '../features/quran_groups/view/screens/invite_join_screen.dart';
import '../features/quran_groups/view/screens/personal_assignment_screen.dart';
import '../features/quran_groups/view/screens/settings_screen.dart';

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
  static const settings = '/settings';

  static Map<String, WidgetBuilder> get routes {
    // The root "/" is owned by the auth gate in app.dart (home), so it is
    // deliberately absent from this table.
    return {
      groups: (_) => const GroupSelectionScreen(),
      '/groups/new': (_) => const CreateGroupScreen(),
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
        child: const InviteJoinScreen(),
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
            metadataRepository: serviceLocator<QuranMetadataRepository>(),
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
            metadataRepository: serviceLocator<QuranMetadataRepository>(),
          ),
        );
      },
      joinRequests: (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments! as Map<String, Object?>;
        return BlocProvider.value(
          value: args['cubit']! as JoinRequestsCubit,
          child: JoinRequestsScreen(groupId: args['groupId']! as String),
        );
      },
      members: (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments! as Map<String, Object?>;
        return BlocProvider.value(
          value: args['cubit']! as MembersCubit,
          child: MembersScreen(
            groupId: args['groupId']! as String,
            isOwner: args['isOwner'] == true,
            isSupervisor: args['isSupervisor'] == true,
          ),
        );
      },
      history: (_) => const DailyHistoryScreen(),
      settings: (_) => const SettingsScreen(),
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

/// Clears every route above the gate (which re-decides auth vs private).
void resetToGate() {
  navigatorKey.currentState?.popUntil((route) => route.isFirst);
}
