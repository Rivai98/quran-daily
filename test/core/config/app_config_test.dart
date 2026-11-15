import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/config/app_config.dart';

void main() {
  test('loads Supabase configuration from environment values', () {
    final config = AppConfig.fromEnvironment(const {
      AppConfig.supabaseUrlKey: 'https://example.supabase.co',
      AppConfig.supabaseAnonKeyKey: 'anon-key',
    });

    expect(config.supabaseUrl.toString(), 'https://example.supabase.co');
    expect(config.supabaseAnonKey, 'anon-key');
  });

  test('rejects missing Supabase URL or anon key', () {
    expect(
      () => AppConfig.fromEnvironment(const {
        AppConfig.supabaseAnonKeyKey: 'anon-key',
      }),
      throwsA(isA<AppConfigException>()),
    );
    expect(
      () => AppConfig.fromEnvironment(const {
        AppConfig.supabaseUrlKey: 'https://example.supabase.co',
      }),
      throwsA(isA<AppConfigException>()),
    );
  });

  test('rejects invalid Supabase URL values', () {
    expect(
      () => AppConfig.fromEnvironment(const {
        AppConfig.supabaseUrlKey: 'not-a-url',
        AppConfig.supabaseAnonKeyKey: 'anon-key',
      }),
      throwsA(isA<AppConfigException>()),
    );
  });
}
