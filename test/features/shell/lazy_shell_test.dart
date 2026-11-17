import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/shell/home_shell.dart';
import 'package:quran_daily/features/shell/shell_cubit.dart';

void main() {
  test('shell records only tabs selected so far (#4)', () async {
    final cubit = ShellCubit();
    expect(cubit.state.mountedTabs, {0});
    cubit.select(3);
    cubit.select(1);
    cubit.select(0);
    expect(cubit.state.mountedTabs, {0, 1, 3});
    await cubit.close();
  });
  testWidgets(
    'defers navigators and disables tickers while retaining tab state (#4)',
    (tester) async {
      final mounts = <int>[];
      Widget tab(int index) =>
          _TrackedTab(index: index, onMount: () => mounts.add(index));
      await tester.pumpWidget(
        MaterialApp(
          home: HomeShell(
            homeBuilder: (_) => tab(0),
            groupsBuilder: (_) => tab(1),
            mushafBuilder: (_) => tab(2),
            profileBuilder: (_) => tab(3),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(mounts, [0]);
      await tester.tap(find.text(ArabicStrings.groupsTab));
      await tester.pumpAndSettle();
      expect(mounts, [0, 1]);
      final home = tester.element(find.text('tab 0', skipOffstage: false));
      expect(TickerMode.valuesOf(home).enabled, isFalse);
      await tester.tap(find.text(ArabicStrings.homeTab));
      await tester.pumpAndSettle();
      expect(mounts, [0, 1]);
      final group = tester.element(find.text('tab 1', skipOffstage: false));
      expect(TickerMode.valuesOf(group).enabled, isFalse);
      ShellNavigation.showTab(3);
      await tester.pumpAndSettle();
      expect(mounts, [0, 1, 3]);
    },
  );
}

class _TrackedTab extends StatefulWidget {
  const _TrackedTab({required this.index, required this.onMount});
  final int index;
  final VoidCallback onMount;
  @override
  State<_TrackedTab> createState() => _TrackedTabState();
}

class _TrackedTabState extends State<_TrackedTab> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Text('tab ${widget.index}'));
}
