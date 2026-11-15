import 'package:flutter/material.dart';
import '../../core/localization/arabic_strings.dart';

class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key, required this.index, required this.onSelected});
  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: index,
    onDestinationSelected: onSelected,
    destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: ArabicStrings.homeTab),
      NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: ArabicStrings.groupsTab),
      NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: ArabicStrings.logTab),
    ],
  );
}
