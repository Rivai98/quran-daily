import '../design_system/cubit/group_photo_cubit.dart';

import 'package:get_it/get_it.dart';

import '../auth/session_gateway.dart';
import '../config/app_config.dart';
import '../network/connectivity_service.dart';
import '../network/rpc_client.dart';
import '../network/supabase_client_provider.dart';
import '../quran/quran_metadata_repository.dart';
import '../quran/mushaf/mushaf_repository.dart';
import '../quran/mushaf/qpc_v2_repository.dart';
import '../settings/settings_repository.dart';
import '../settings/settings_repository_impl.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/settings/cubit/settings_cubit.dart';
import '../../features/quran_groups/cubit/selected_group/selected_group_cubit.dart';
import '../../features/quran_groups/cubit/dashboard/dashboard_cubit.dart';
import '../../features/quran_groups/data/data_sources/khatma_remote_data_source.dart';
import '../../features/quran_groups/data/repositories/khatma_repository.dart';
import '../../features/quran_groups/data/repositories/khatma_repository_impl.dart';
import '../../features/quran_groups/data/use_cases/completion_use_cases.dart';
import '../storage/daos/daos.dart';
import '../../features/mushaf/data/mushaf_remote_data_source.dart';
import '../../features/mushaf/data/mushaf_sync_repository.dart';
import '../../features/mushaf/data/reader_storage.dart';
import '../../features/mushaf/cubit/mushaf_font_download_cubit.dart';
import '../../features/auth/data/data_sources/supabase_auth_data_source.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/data/data_sources/google_auth_client.dart';
import '../../features/quran_groups/data/data_sources/groups_remote_data_source.dart';
import '../../features/quran_groups/data/repositories/groups_repository.dart';
import '../../features/quran_groups/data/repositories/groups_repository_impl.dart';
import '../../features/quran_groups/cubit/discovery/discovery_cubit.dart';
import '../../features/quran_groups/cubit/join/join_cubit.dart';
import '../../features/quran_groups/cubit/group_settings/group_settings_cubit.dart';
import '../../features/quran_groups/cubit/create_group/create_group_cubit.dart';
import '../../features/quran_groups/cubit/members/members_cubit.dart';
import '../../features/quran_groups/cubit/join_requests/join_requests_cubit.dart';
import '../../features/quran_groups/cubit/group_list/group_list_cubit.dart';
import '../../features/reminders/data/notification_scheduler.dart';
import '../../features/reminders/data/reminders_repository.dart';
import '../../features/reminders/data/reminders_repository_impl.dart';
import '../../features/reminders/cubit/reminders_cubit.dart';
import '../../features/reminders/data/reminder_planning_service.dart';
import '../../features/admin/cubit/admin_cubit.dart';
import '../../features/admin/data/admin_repository.dart';
import '../../features/admin/data/admin_repository_impl.dart';
import '../../features/quran_groups/cubit/member_profile/member_profile_cubit.dart';
import '../../features/quran_groups/cubit/group_info/group_info_cubit.dart';
import '../../features/profile/cubit/profile_cubit.dart';
import '../../features/profile/data/repositories/profile_repository.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/data/sources/profile_local_data_source.dart';
import '../../features/profile/data/sources/profile_remote_data_source.dart';
// --- 005 home ---
import '../../features/home/cubit/home_cubit.dart';
import '../../features/home/data/today_remote_data_source.dart';
import '../../features/home/data/today_repository.dart';
import '../../features/home/data/today_repository_impl.dart';
// --- end 005 home ---
import '../../features/log/data/data_sources/log_remote_data_source.dart';
import '../../features/log/data/repositories/log_repository.dart';
import '../../features/log/data/repositories/log_repository_impl.dart';
import '../../features/log/cubit/log_cubit.dart';

final serviceLocator = GetIt.instance;

void configureServiceLocator({
  GetIt? getIt,
  AppConfig? appConfig,
  bool withSupabase = true,
}) {
  final locator = getIt ?? serviceLocator;

  if (withSupabase && !locator.isRegistered<AppConfig>()) {
    locator.registerSingleton<AppConfig>(
      appConfig ?? AppConfig.fromDartEnvironment(),
    );
  }

  if (!locator.isRegistered<LocalDatabase>()) {
    locator.registerLazySingleton<LocalDatabase>(LocalDatabase.new);
  }

  if (!locator.isRegistered<SettingsRepository>()) {
    locator.registerLazySingleton<SettingsRepository>(
      SettingsRepositoryImpl.new,
    );
  }

  if (!locator.isRegistered<QuranMetadataRepository>()) {
    locator.registerLazySingleton<QuranMetadataRepository>(
      QuranMetadataRepository.new,
    );
  }

  if (!locator.isRegistered<MushafRepository>()) {
    locator.registerLazySingleton<MushafRepository>(
      () => MushafRepositoryImpl(metadata: locator<QuranMetadataRepository>()),
    );
  }

  if (!locator.isRegistered<QpcV2Repository>()) {
    locator.registerLazySingleton<QpcV2Repository>(QpcV2Repository.new);
  }
  if (!locator.isRegistered<QpcFontManager>()) {
    locator.registerLazySingleton<QpcFontManager>(
      () => QpcFontManager(layout: locator<QpcV2Repository>()),
    );
  }
  if (!locator.isRegistered<MushafFontDownloadCubit>()) {
    locator.registerFactory<MushafFontDownloadCubit>(
      () => MushafFontDownloadCubit(locator<QpcFontManager>()),
    );
  }

  if (!locator.isRegistered<NotificationScheduler>()) {
    locator.registerLazySingleton<NotificationScheduler>(
      NotificationScheduler.new,
    );
  }

  if (!locator.isRegistered<ConnectivityService>()) {
    locator.registerLazySingleton<ConnectivityService>(
      ConnectivityServiceImpl.new,
    );
  }

  if (!locator.isRegistered<GroupPhotoCubit>()) {
    locator.registerFactory<GroupPhotoCubit>(
      () => GroupPhotoCubit(
        loadPhoto: locator<GroupsRepository>().getGroupPhotoBytes,
      ),
    );
  }

  if (withSupabase) {
    if (!locator.isRegistered<SupabaseClientProvider>()) {
      locator.registerLazySingleton<SupabaseClientProvider>(
        () => SupabaseClientProvider(config: locator<AppConfig>()),
      );
    }

    if (!locator.isRegistered<MushafRemoteDataSource>()) {
      locator.registerLazySingleton<MushafRemoteDataSource>(
        () => SupabaseMushafRemoteDataSource(
          () => locator<SupabaseClientProvider>().client,
        ),
      );
    }

    if (!locator.isRegistered<MushafSyncRepository>()) {
      locator.registerLazySingleton<MushafSyncRepository>(
        () => MushafSyncRepository(
          remote: locator<MushafRemoteDataSource>(),
          storeFor: (userId) => SqfliteReaderStorage(
            database: locator<LocalDatabase>(),
            userId: userId,
          ),
          currentUserId: () => locator<SessionGateway>().currentUserId,
        ),
        dispose: (sync) => sync.dispose(),
      );
    }

    // Local-first: writes land in SQLite, then a background sync is queued.
    if (!locator.isRegistered<ReaderStorage>()) {
      locator.registerFactory<ReaderStorage>(
        () => SyncingReaderStorage(
          SqfliteReaderStorage(
            database: locator<LocalDatabase>(),
            userId: locator<SessionGateway>().currentUserId!,
          ),
          onLocalChange: locator<MushafSyncRepository>().schedule,
        ),
      );
    }

    if (!locator.isRegistered<RpcClient>()) {
      locator.registerLazySingleton<RpcClient>(
        () => RpcClient.forClient(locator<SupabaseClientProvider>().client),
      );
    }

    if (!locator.isRegistered<RemindersRepository>()) {
      locator.registerLazySingleton<RemindersRepository>(
        () => RemindersRepositoryImpl(
          rpc: locator<RpcClient>(),
          onChanged: () => locator<ReminderPlanningService>().refresh(),
        ),
      );
    }
    if (!locator.isRegistered<ReminderPlanningService>()) {
      locator.registerLazySingleton<ReminderPlanningService>(
        () => ReminderPlanningService(
          snapshots: locator<CachedSnapshotsDao>(),
          metadata: locator<QuranMetadataRepository>(),
          preferences: locator<RemindersRepository>(),
          notifications: locator<NotificationScheduler>(),
        ),
      );
    }
    if (!locator.isRegistered<RemindersCubit>()) {
      locator.registerFactory<RemindersCubit>(
        () => RemindersCubit(
          repository: locator<RemindersRepository>(),
          showTestNotification: () =>
              locator<NotificationScheduler>().showTestNotification(),
          requestPermissions: () =>
              locator<NotificationScheduler>().requestPermissions(),
        ),
      );
    }
    if (!locator.isRegistered<AdminRepository>()) {
      locator.registerLazySingleton<AdminRepository>(
        () => AdminRepositoryImpl(
          rpc: locator<RpcClient>(),
          invoke: (name, body) async => locator<SupabaseClientProvider>()
              .client
              .functions
              .invoke(name, body: body)
              .then((response) => response.data),
        ),
      );
    }
    if (!locator.isRegistered<AdminCubit>()) {
      locator.registerFactory<AdminCubit>(
        () => AdminCubit(locator<AdminRepository>()),
      );
    }

    if (!locator.isRegistered<CachedSnapshotsDao>()) {
      locator.registerLazySingleton<CachedSnapshotsDao>(
        () => CachedSnapshotsDao(locator<LocalDatabase>()),
      );
    }

    if (!locator.isRegistered<SyncQueueDao>()) {
      locator.registerLazySingleton<SyncQueueDao>(
        () => SyncQueueDao(locator<LocalDatabase>()),
      );
    }

    if (!locator.isRegistered<KhatmaRemoteDataSource>()) {
      locator.registerLazySingleton<KhatmaRemoteDataSource>(
        () => KhatmaRemoteDataSourceImpl(locator<RpcClient>()),
      );
    }

    if (!locator.isRegistered<KhatmaRepository>()) {
      locator.registerLazySingleton<KhatmaRepository>(
        () => KhatmaRepositoryImpl(
          remote: locator<KhatmaRemoteDataSource>(),
          cache: locator<CachedSnapshotsDao>(),
          queue: locator<SyncQueueDao>(),
          historyDao: CachedHistoryDao(locator<LocalDatabase>()),
          onCompletionChanged: (_) async {
            locator<ProfileRepository>().invalidate();
            await locator<ReminderPlanningService>().refresh();
          },
        ),
      );
    }

    if (!locator.isRegistered<DashboardCubit>()) {
      locator.registerFactoryParam<DashboardCubit, String, void>(
        (groupId, _) => DashboardCubit(
          repository: locator<KhatmaRepository>(),
          groupsRepository: locator<GroupsRepository>(),
          groupId: groupId,
          syncPending: SyncPendingCompletions(locator<KhatmaRepository>()),
          connectivityService: locator<ConnectivityService>(),
          onOpened: () => locator<TodayRepository>().markGroupOpened(groupId),
          setAsMain: () async {
            await locator<TodayRepository>().setMainGroup(groupId);
          },
        ),
      );
    }

    if (!locator.isRegistered<SupabaseAuthDataSource>()) {
      locator.registerLazySingleton<SupabaseAuthDataSource>(
        () => SupabaseAuthDataSourceImpl(),
      );
    }

    if (!locator.isRegistered<AuthRepository>()) {
      locator.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
          dataSource: locator<SupabaseAuthDataSource>(),
          googleAuthClient: locator<GoogleAuthClient>(),
        ),
      );
    }

    if (!locator.isRegistered<GoogleAuthClient>()) {
      locator.registerLazySingleton<GoogleAuthClient>(
        () => GoogleSignInAuthClient(
          webClientId: locator<AppConfig>().googleWebClientId,
          iosClientId: locator<AppConfig>().googleIosClientId,
        ),
      );
    }

    // Core session access for non-auth features (constitution IV).
    if (!locator.isRegistered<SessionGateway>()) {
      locator.registerLazySingleton<SessionGateway>(
        () => locator<AuthRepository>(),
      );
    }

    if (!locator.isRegistered<AuthCubit>()) {
      locator.registerLazySingleton<AuthCubit>(
        () => AuthCubit(
          repository: locator<AuthRepository>(),
          googleSignInEnabled:
              locator<AppConfig>().googleWebClientId.isNotEmpty,
        ),
      );
    }

    if (!locator.isRegistered<SelectedGroupCubit>()) {
      locator.registerFactory<SelectedGroupCubit>(
        () => SelectedGroupCubit(
          settingsRepository: locator<SettingsRepository>(),
          sessionGateway: locator<SessionGateway>(),
        ),
      );
    }

    if (!locator.isRegistered<RpcClient>()) {
      locator.registerLazySingleton<RpcClient>(
        () => RpcClient.forClient(locator<SupabaseClientProvider>().client),
      );
    }

    if (!locator.isRegistered<GroupsRemoteDataSource>()) {
      locator.registerLazySingleton<GroupsRemoteDataSource>(
        () => GroupsRemoteDataSourceImpl(locator<RpcClient>()),
      );
    }

    if (!locator.isRegistered<GroupsRepository>()) {
      locator.registerLazySingleton<GroupsRepository>(
        () => GroupsRepositoryImpl(
          rpc: locator<RpcClient>(),
          remote: locator<GroupsRemoteDataSource>(),
          cache: CachedGroupsDao(locator<LocalDatabase>()),
          sessionGateway: locator<SessionGateway>(),
          connectivity: locator<ConnectivityService>(),
          clientProvider: locator.isRegistered<SupabaseClientProvider>()
              ? locator<SupabaseClientProvider>()
              : null,
          onProfileChanged: () => locator<ProfileRepository>().invalidate(),
        ),
      );
    }

    if (!locator.isRegistered<DiscoveryCubit>()) {
      locator.registerFactory<DiscoveryCubit>(
        () => DiscoveryCubit(repository: locator<GroupsRepository>()),
      );
    }

    if (!locator.isRegistered<GroupListCubit>()) {
      locator.registerFactory<GroupListCubit>(
        () => GroupListCubit(repository: locator<GroupsRepository>()),
      );
    }

    if (!locator.isRegistered<CreateGroupCubit>()) {
      locator.registerFactory<CreateGroupCubit>(
        () => CreateGroupCubit(repository: locator<GroupsRepository>()),
      );
    }

    if (!locator.isRegistered<GroupSettingsCubit>()) {
      locator.registerFactory<GroupSettingsCubit>(
        () => GroupSettingsCubit(repository: locator<GroupsRepository>()),
      );
    }

    if (!locator.isRegistered<MembersCubit>()) {
      locator.registerFactory<MembersCubit>(
        () => MembersCubit(locator<GroupsRepository>()),
      );
    }

    if (!locator.isRegistered<JoinRequestsCubit>()) {
      locator.registerFactory<JoinRequestsCubit>(
        () => JoinRequestsCubit(locator<GroupsRepository>()),
      );
    }

    if (!locator.isRegistered<JoinCubit>()) {
      locator.registerFactory<JoinCubit>(
        () => JoinCubit(repository: locator<GroupsRepository>()),
      );
    }

    // --- 005 log ---
    if (!locator.isRegistered<LogRemoteDataSource>()) {
      locator.registerLazySingleton<LogRemoteDataSource>(
        () => LogRemoteDataSource(locator<RpcClient>()),
      );
    }
    if (!locator.isRegistered<LogRepository>()) {
      locator.registerLazySingleton<LogRepository>(
        () => LogRepositoryImpl(
          remote: locator<LogRemoteDataSource>(),
          cache: CachedHistoryDao(locator<LocalDatabase>()),
          session: locator<SessionGateway>(),
        ),
      );
    }
    if (!locator.isRegistered<LogCubit>()) {
      locator.registerFactory<LogCubit>(
        () => LogCubit(repository: locator<LogRepository>()),
      );
    }
    // --- end 005 log ---

    if (!locator.isRegistered<SettingsCubit>()) {
      locator.registerFactory<SettingsCubit>(
        () => SettingsCubit(
          settingsRepository: locator<SettingsRepository>(),
          sessionGateway: locator<SessionGateway>(),
          adminRepository: locator<AdminRepository>(),
        ),
      );
    }

    // --- 007 profiles ---
    if (!locator.isRegistered<MemberProfileCubit>()) {
      locator.registerFactory<MemberProfileCubit>(
        () => MemberProfileCubit(locator<GroupsRepository>()),
      );
    }
    if (!locator.isRegistered<GroupInfoCubit>()) {
      locator.registerFactory<GroupInfoCubit>(
        () => GroupInfoCubit(locator<GroupsRepository>()),
      );
    }
    // --- 005 profile ---
    if (!locator.isRegistered<ProfileRemoteDataSource>()) {
      locator.registerLazySingleton<ProfileRemoteDataSource>(
        () => ProfileRemoteDataSourceImpl(locator<RpcClient>()),
      );
    }

    if (!locator.isRegistered<ProfileLocalDataSource>()) {
      locator.registerLazySingleton<ProfileLocalDataSource>(
        () => ProfileLocalDataSourceImpl(locator<LocalDatabase>()),
      );
    }

    if (!locator.isRegistered<ProfileRepository>()) {
      locator.registerLazySingleton<ProfileRepository>(
        () => ProfileRepositoryImpl(
          remote: locator<ProfileRemoteDataSource>(),
          cache: locator<ProfileLocalDataSource>(),
          sessionGateway: locator<SessionGateway>(),
          connectivity: locator<ConnectivityService>(),
          nextRollover: () => _nextProfileRollover(locator),
        ),
      );
    }

    if (!locator.isRegistered<ProfileCubit>()) {
      locator.registerFactory<ProfileCubit>(
        () => ProfileCubit(repository: locator<ProfileRepository>()),
      );
    }
    // --- 005 home ---
    if (!locator.isRegistered<CachedTodayDao>()) {
      locator.registerLazySingleton<CachedTodayDao>(
        () => CachedTodayDao(locator<LocalDatabase>()),
      );
    }
    if (!locator.isRegistered<TodayRemoteDataSource>()) {
      locator.registerLazySingleton<TodayRemoteDataSource>(
        () => TodayRemoteDataSource(locator<RpcClient>()),
      );
    }
    if (!locator.isRegistered<TodayRepository>()) {
      locator.registerLazySingleton<TodayRepository>(
        () => TodayRepositoryImpl(
          remote: locator<TodayRemoteDataSource>(),
          cache: locator<CachedTodayDao>(),
          session: locator<SessionGateway>(),
        ),
      );
    }
    if (!locator.isRegistered<HomeCubit>()) {
      locator.registerFactory<HomeCubit>(
        () => HomeCubit(
          repository: locator<TodayRepository>(),
          khatmaRepository: locator<KhatmaRepository>(),
          profileRepository: locator<ProfileRepository>(),
        ),
      );
    }
    // --- end 005 home ---
  }
}

Future<void> resetServiceLocator({GetIt? getIt}) {
  return (getIt ?? serviceLocator).reset();
}

Future<DateTime?> _nextProfileRollover(GetIt locator) async {
  final ends = <DateTime>[];
  final userId = locator<SessionGateway>().currentUserId;
  if (userId != null) {
    final today = await locator<CachedTodayDao>().read(userId);
    for (final raw in today?.json['groups'] as List? ?? const []) {
      final day = (raw as Map)['day'] as Map?;
      if (day != null) ends.add(DateTime.parse(day['ends_at'] as String));
    }
  }
  for (final row in await locator<CachedSnapshotsDao>().readAll()) {
    final day = row.json['today'] as Map?;
    if (day != null) ends.add(DateTime.parse(day['ends_at'] as String));
  }
  ends.removeWhere((end) => !end.isAfter(DateTime.now()));
  ends.sort();
  return ends.firstOrNull;
}
