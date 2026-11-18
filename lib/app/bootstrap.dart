import 'package:flutter/widgets.dart';

import '../core/di/service_locator.dart';
import '../core/network/supabase_client_provider.dart';
import 'app.dart';

Future<Widget> bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureServiceLocator();

  // Supabase must initialize before any auth/group data source is used.
  // Requires --dart-define-from-file=.env (see README).
  await serviceLocator<SupabaseClientProvider>().initialize();

  return const QuranDailyApp();
}
