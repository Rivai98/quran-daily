import 'package:flutter/material.dart';

import '../app_colors.dart';

/// Skeleton placeholder shaped like the final content; loading states use
/// these instead of full-screen spinners (only app startup may show one).
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width = double.infinity, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(
        color: colors.surfaceMuted,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    );
  }
}
