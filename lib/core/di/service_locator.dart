import 'package:get_it/get_it.dart';

import '../auth/session_gateway.dart';
import '../config/app_config.dart';
import '../network/connectivity_service.dart';
import '../network/rpc_client.dart';
import '../network/supabase_client_provider.dart';
import '../quran/quran_metadata_repository.dart';
import '../settings/settings_repository.dart';
import '../settings/settings_repository_impl.dart';
import '../storage/daos/daos.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/quran_groups/cubit/selected_group/selected_group_cubit.dart';
import '../../features/auth/data/data_sources/supabase_auth_data_source.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/quran_groups/data/data_sources/groups_remote_data_source.dart';
import '../../features/quran_groups/data/repositories/groups_repository.dart';
import '../../features/quran_groups/data/repositories/groups_repository_impl.dart';
import '../../features/quran_groups/cubit/discovery/discovery_cubit.dart';
import '../../features/quran_groups/cubit/join/join_cubit.dart';
import '../../features/quran_groups/cubit/group_list/group_list_cubit.dart';

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

    if (!locator.isRegistered<SupabaseAuthDataSource>()) {
      locator.registerLazySingleton<SupabaseAuthDataSource>(
        () => SupabaseAuthDataSourceImpl(),
      );
    }

    if (!locator.isRegistered<AuthRepository>()) {
      locator.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(dataSource: locator<SupabaseAuthDataSource>()),
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
        () => AuthCubit(repository: locator<AuthRepository>()),
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

    if (!locator.isRegistered<JoinCubit>()) {
      locator.registerFactory<JoinCubit>(
        () => JoinCubit(repository: locator<GroupsRepository>()),
      );
    }
  }
}

Future<void> resetServiceLocator({GetIt? getIt}) {
  return (getIt ?? serviceLocator).reset();
}
