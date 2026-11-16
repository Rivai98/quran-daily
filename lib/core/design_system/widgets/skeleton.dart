import 'package:material_ui/material_ui.dart';

import '../app_colors.dart';

/// Skeleton placeholder shaped like the final content; loading states use
/// these instead of full-screen spinners (Constitution Principle VI & ui-craft.md).
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = 8,
    this.shape = BoxShape.rectangle,
  });

  final double width;
  final double height;
  final double radius;
  final BoxShape shape;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final boxDecoration = widget.shape == BoxShape.circle
        ? BoxDecoration(color: colors.surfaceMuted, shape: BoxShape.circle)
        : BoxDecoration(
            color: colors.surfaceMuted,
            borderRadius: BorderRadius.all(Radius.circular(widget.radius)),
          );

    if (reduceMotion) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: boxDecoration,
      );
    }

    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: boxDecoration,
      ),
    );
  }
}
