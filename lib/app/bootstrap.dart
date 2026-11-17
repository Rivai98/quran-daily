import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/service_locator.dart';
import '../core/network/supabase_client_provider.dart';
import '../core/design_system/app_theme.dart';
import '../core/design_system/widgets/state_panel.dart';
import '../core/localization/arabic_strings.dart';
import 'app.dart';
import 'bootstrap_cubit.dart';

Future<void> initializeServices() async {
  configureServiceLocator();
  await serviceLocator<SupabaseClientProvider>().initialize();
}

// Device integration journeys initialize services before pumping their app.
Future<Widget> bootstrapApp() async {
  await initializeServices();
  return const QuranDailyApp();
}

class BootstrapApp extends StatelessWidget {
  const BootstrapApp({super.key, required this.initialize, required this.app});
  final Future<void> Function() initialize;
  final Widget app;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => BootstrapCubit(initialize),
    child: _BootstrapGate(app: app),
  );
}

class _BootstrapGate extends StatefulWidget {
  const _BootstrapGate({required this.app});
  final Widget app;
  @override
  State<_BootstrapGate> createState() => _BootstrapGateState();
}

class _BootstrapGateState extends State<_BootstrapGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BootstrapCubit>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<BootstrapCubit, BootstrapState>(
        builder: (context, state) {
          if (state.status == BootstrapStatus.ready) return widget.app;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            builder: (context, child) =>
                Directionality(textDirection: TextDirection.rtl, child: child!),
            home: state.status == BootstrapStatus.failure
                ? Scaffold(
                    body: StatePanel.error(
                      title: ArabicStrings.networkFailure,
                      message: ArabicStrings.networkFailure,
                      actionLabel: ArabicStrings.retry,
                      onAction: context.read<BootstrapCubit>().initialize,
                    ),
                  )
                : const AppSplashScreen(),
          );
        },
      );
}
