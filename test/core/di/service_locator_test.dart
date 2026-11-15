import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:quran_daily/core/config/app_config.dart';
import 'package:quran_daily/core/di/service_locator.dart';
import 'package:quran_daily/core/network/supabase_client_provider.dart';
import 'package:quran_daily/core/quran/mushaf/mushaf_repository.dart';
import 'package:quran_daily/features/mushaf/data/mushaf_remote_data_source.dart';
import 'package:quran_daily/features/mushaf/data/mushaf_sync_repository.dart';
import 'package:quran_daily/features/mushaf/data/reader_storage.dart';
import 'package:quran_daily/core/storage/local_database.dart';

void main() {
  test('registers core dependencies once', () async {
    final getIt = GetIt.asNewInstance();
    final config = AppConfig.fromEnvironment(const {
      AppConfig.supabaseUrlKey: 'https://example.supabase.co',
      AppConfig.supabaseAnonKeyKey: 'anon-key',
    });

    configureServiceLocator(getIt: getIt, appConfig: config);
    configureServiceLocator(getIt: getIt, appConfig: config);

    expect(getIt<AppConfig>(), config);
    expect(getIt.isRegistered<LocalDatabase>(), isTrue);
    expect(getIt.isRegistered<SupabaseClientProvider>(), isTrue);
    expect(getIt<MushafRepository>(), isA<MushafRepositoryImpl>());
    expect(getIt.isRegistered<ReaderStorage>(), isTrue);
    expect(
      getIt<MushafRemoteDataSource>(),
      isA<SupabaseMushafRemoteDataSource>(),
    );
    expect(getIt.isRegistered<MushafSyncRepository>(), isTrue);
  });
}
