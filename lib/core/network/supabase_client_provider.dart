import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class SupabaseClientProvider {
  SupabaseClientProvider({required this.config});

  final AppConfig config;
  bool _initialized = false;

  Future<SupabaseClient> initialize() async {
    if (!_initialized) {
      await Supabase.initialize(
        url: config.supabaseUrl.toString(),
        // 2.x publishable key (sb_publishable_...); anonKey is deprecated.
        publishableKey: config.supabaseAnonKey,
      );
      _initialized = true;
    }

    return client;
  }

  SupabaseClient get client => Supabase.instance.client;
}
