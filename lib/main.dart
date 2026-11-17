import 'package:flutter/widgets.dart';

import 'app/bootstrap.dart';
import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const BootstrapApp(initialize: initializeServices, app: QuranDailyApp()),
  );
}
