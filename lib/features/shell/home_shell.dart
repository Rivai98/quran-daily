import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../app/router.dart';
import 'app_tab_bar.dart';
import 'shell_cubit.dart';

typedef TabScreenBuilder = Widget Function(BuildContext context);

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.homeBuilder, this.groupsBuilder, this.logBuilder});
  final TabScreenBuilder? homeBuilder;
  final TabScreenBuilder? groupsBuilder;
  final TabScreenBuilder? logBuilder;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _keys = List<GlobalKey<NavigatorState>>.generate(3, (_) => GlobalKey<NavigatorState>());
  late final _cubit = ShellCubit();

  Widget _tab(int index, TabScreenBuilder? builder) => Navigator(
    key: _keys[index],
    onGenerateRoute: (settings) {
      if (settings.name != null && settings.name != Navigator.defaultRouteName) {
        final route = AppRoutes.onGenerateRoute(settings);
        if (route != null) return route;
        final page = AppRoutes.routes[settings.name];
        if (page != null) return MaterialPageRoute<void>(settings: settings, builder: page);
      }
      return MaterialPageRoute<void>(
        settings: settings,
        builder: builder ?? (context) => AppRoutes.routes[index == 1 ? AppRoutes.groups : AppRoutes.settings]!(context),
      );
    },
  );

  Future<bool> _back() async {
    final navigator = _keys[_cubit.state.index].currentState;
    if (navigator != null && await navigator.maybePop()) return false;
    if (_cubit.state.index != 0) {
      _cubit.select(0);
      return false;
    }
    return true;
  }

  @override
  void dispose() { _cubit.close(); super.dispose(); }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _cubit,
    child: BlocBuilder<ShellCubit, ShellState>(
      builder: (context, state) => WillPopScope(
        onWillPop: _back,
        child: Scaffold(
          body: IndexedStack(index: state.index, children: [
            _tab(0, widget.homeBuilder), _tab(1, widget.groupsBuilder), _tab(2, widget.logBuilder),
          ]),
          bottomNavigationBar: AppTabBar(index: state.index, onSelected: _cubit.select),
        ),
      ),
    ),
  );
}

class LogTabPlaceholder extends StatelessWidget {
  const LogTabPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('السجل')));
}
