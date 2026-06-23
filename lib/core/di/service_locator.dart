import 'package:get_it/get_it.dart';

import '../config/app_config.dart';
import '../network/supabase_client_provider.dart';
import '../storage/local_database.dart';

final serviceLocator = GetIt.instance;

void configureServiceLocator({
  GetIt? getIt,
  AppConfig? appConfig,
}) {
  final locator = getIt ?? serviceLocator;

  if (!locator.isRegistered<AppConfig>()) {
    locator.registerSingleton<AppConfig>(
      appConfig ?? AppConfig.fromDartEnvironment(),
    );
  }

  if (!locator.isRegistered<LocalDatabase>()) {
    locator.registerLazySingleton<LocalDatabase>(LocalDatabase.new);
  }

  if (!locator.isRegistered<SupabaseClientProvider>()) {
    locator.registerLazySingleton<SupabaseClientProvider>(
      () => SupabaseClientProvider(config: locator<AppConfig>()),
    );
  }
}

Future<void> resetServiceLocator({GetIt? getIt}) {
  return (getIt ?? serviceLocator).reset();
}
