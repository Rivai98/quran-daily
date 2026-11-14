import 'package:get_it/get_it.dart';

import '../auth/session_gateway.dart';
import '../config/app_config.dart';
import '../network/connectivity_service.dart';
import '../network/supabase_client_provider.dart';
import '../quran/quran_metadata_repository.dart';
import '../settings/settings_repository.dart';
import '../settings/settings_repository_impl.dart';
import '../storage/local_database.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/quran_groups/cubit/selected_group/selected_group_cubit.dart';
import '../../features/auth/data/data_sources/supabase_auth_data_source.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';

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
        SettingsRepositoryImpl.new);
  }

  if (!locator.isRegistered<QuranMetadataRepository>()) {
    locator.registerLazySingleton<QuranMetadataRepository>(
        QuranMetadataRepository.new);
  }

  if (!locator.isRegistered<ConnectivityService>()) {
    locator.registerLazySingleton<ConnectivityService>(
        ConnectivityServiceImpl.new);
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
        () => AuthRepositoryImpl(
          dataSource: locator<SupabaseAuthDataSource>(),
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
  }
}

Future<void> resetServiceLocator({GetIt? getIt}) {
  return (getIt ?? serviceLocator).reset();
}
