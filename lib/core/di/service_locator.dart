import 'package:get_it/get_it.dart';

import '../auth/session_gateway.dart';
import '../config/app_config.dart';
import '../network/connectivity_service.dart';
import '../network/rpc_client.dart';
import '../network/supabase_client_provider.dart';
import '../quran/quran_metadata_repository.dart';
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

  if (!locator.isRegistered<ConnectivityService>()) {
    locator.registerLazySingleton<ConnectivityService>(
      ConnectivityServiceImpl.new,
    );
  }

  if (withSupabase) {
    if (!locator.isRegistered<SupabaseClientProvider>()) {
      locator.registerLazySingleton<SupabaseClientProvider>(
        () => SupabaseClientProvider(config: locator<AppConfig>()),
      );
    }

    if (!locator.isRegistered<RpcClient>()) {
      locator.registerLazySingleton<RpcClient>(
        () => RpcClient.forClient(locator<SupabaseClientProvider>().client),
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
          setAsMain: () async { await locator<TodayRepository>().setMainGroup(groupId); },
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
        ),
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
      locator.registerLazySingleton<CachedTodayDao>(() => CachedTodayDao(locator<LocalDatabase>()));
    }
    if (!locator.isRegistered<TodayRemoteDataSource>()) {
      locator.registerLazySingleton<TodayRemoteDataSource>(() => TodayRemoteDataSource(locator<RpcClient>()));
    }
    if (!locator.isRegistered<TodayRepository>()) {
      locator.registerLazySingleton<TodayRepository>(() => TodayRepositoryImpl(remote: locator<TodayRemoteDataSource>(), cache: locator<CachedTodayDao>(), session: locator<SessionGateway>()));
    }
    if (!locator.isRegistered<HomeCubit>()) {
      locator.registerFactory<HomeCubit>(() => HomeCubit(repository: locator<TodayRepository>(), khatmaRepository: locator<KhatmaRepository>()));
    }
    // --- end 005 home ---
  }
}

Future<void> resetServiceLocator({GetIt? getIt}) {
  return (getIt ?? serviceLocator).reset();
}
