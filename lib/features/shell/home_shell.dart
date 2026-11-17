import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/router.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../../core/localization/arabic_strings.dart';
import 'app_tab_bar.dart';
import 'shell_cubit.dart';

typedef TabScreenBuilder = Widget Function(BuildContext context);

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    this.homeBuilder,
    this.groupsBuilder,
    this.mushafBuilder,
    this.profileBuilder,
    this.onHomeSelected,
  });

  final TabScreenBuilder? homeBuilder;
  final TabScreenBuilder? groupsBuilder;
  final TabScreenBuilder? mushafBuilder;
  final TabScreenBuilder? profileBuilder;
  final VoidCallback? onHomeSelected;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _keys = List<GlobalKey<NavigatorState>>.generate(
    4,
    (_) => GlobalKey<NavigatorState>(),
  );
  late final _cubit = ShellCubit();
  StreamSubscription<int>? _tabRequests;

  @override
  void initState() {
    super.initState();
    _tabRequests = ShellNavigation.tabRequests.listen(_showTab);
  }

  void _showTab(int index) {
    if (!mounted || index < 0 || index >= _keys.length) return;
    _keys[index].currentState?.popUntil((route) => route.isFirst);
    _cubit.select(index);
    if (index == 0) widget.onHomeSelected?.call();
  }

  Widget _tab(int index, TabScreenBuilder? builder) => Navigator(
    key: _keys[index],
    onGenerateRoute: (settings) {
      if (settings.name != null &&
          settings.name != Navigator.defaultRouteName) {
        final route = AppRoutes.onGenerateRoute(settings);
        if (route != null) return route;
        final page = AppRoutes.routes[settings.name];
        if (page != null) {
          return MaterialPageRoute<void>(settings: settings, builder: page);
        }
      }
      return MaterialPageRoute<void>(
        settings: settings,
        builder: builder ?? _defaultTab(index),
      );
    },
  );

  WidgetBuilder _defaultTab(int index) => switch (index) {
    0 => (_) => const Scaffold(body: SizedBox.shrink()),
    1 => AppRoutes.routes[AppRoutes.groups]!,
    2 => AppRoutes.mushafTab,
    _ =>
      AppRoutes.routes[AppRoutes.profile] ??
          (_) => const ProfileTabPlaceholder(),
  };

  Future<bool> _back() async {
    final navigator = _keys[_cubit.state.index].currentState;
    if (navigator != null && await navigator.maybePop()) return false;
    if (_cubit.state.index != 0) {
      _cubit.select(0);
      widget.onHomeSelected?.call();
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _tabRequests?.cancel();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _cubit,
    child: BlocBuilder<ShellCubit, ShellState>(
      builder: (context, state) => PopScope(
        canPop:
            state.index == 0 &&
            !(_keys[state.index].currentState?.canPop() ?? false),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(_back());
        },
        child: Scaffold(
          body: IndexedStack(
            index: state.index,
            children: [
              for (var index = 0; index < _keys.length; index++)
                TickerMode(
                  enabled: index == state.index,
                  child: state.mountedTabs.contains(index)
                      ? _tab(
                          index,
                          [
                            widget.homeBuilder,
                            widget.groupsBuilder,
                            widget.mushafBuilder,
                            widget.profileBuilder,
                          ][index],
                        )
                      : const SizedBox.shrink(),
                ),
            ],
          ),
          bottomNavigationBar: AppTabBar(
            index: state.index,
            onSelected: (index) {
              _cubit.select(index);
              if (index == 0) widget.onHomeSelected?.call();
            },
          ),
        ),
      ),
    ),
  );
}

class ProfileTabPlaceholder extends StatelessWidget {
  const ProfileTabPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(ArabicStrings.profileTab)),
    body: ListView(
      padding: AppSpacing.screenContent,
      children: [
        Center(
          child: Text(ArabicStrings.profileTab, style: AppTypography.title),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
          icon: const Icon(Icons.settings_outlined),
          label: const Text(ArabicStrings.settingsTitle),
        ),
      ],
    ),
  );
}
