import 'package:flutter/material.dart';

/// Keeps long-form screen content comfortable on phones and bounded on tablets.
class AppPageContent extends StatelessWidget {
  const AppPageContent({super.key, required this.child, this.maxWidth = 560});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
