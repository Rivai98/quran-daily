import 'package:flutter/widgets.dart';

/// Snappy scroll physics that reduces the distance threshold for flipping pages:
/// dragging by 15% of the viewport (instead of 50%) or a gentle flick is enough to advance.
///
/// Thresholds are symmetric in both forward and backward directions, measured
/// from the settled page where the drag began.
class SnappyMushafScrollPhysics extends ScrollPhysics {
  const SnappyMushafScrollPhysics({
    super.parent,
    this.settledPage,
    this.settledPageGetter,
    this.dragThreshold = 0.15,
  });

  /// The settled page index where the current interaction began.
  final double? settledPage;

  /// Optional dynamic getter for the settled page index.
  final ValueGetter<double?>? settledPageGetter;

  /// The fraction of viewport width required to trigger a page turn (default 0.15).
  final double dragThreshold;

  @override
  SnappyMushafScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SnappyMushafScrollPhysics(
      parent: buildParent(ancestor),
      settledPage: settledPage,
      settledPageGetter: settledPageGetter,
      dragThreshold: dragThreshold,
    );
  }

  @override
  bool get allowSelectionEdgeScrolling => false;

  double _getPage(ScrollMetrics position) {
    return position.pixels / position.viewportDimension;
  }

  double _getPixels(ScrollMetrics position, double page) {
    return page * position.viewportDimension;
  }

  @visibleForTesting
  double getTargetPixels(
    ScrollMetrics position,
    Tolerance tolerance,
    double velocity,
  ) {
    final page = _getPage(position);
    final origin =
        settledPage ?? settledPageGetter?.call() ?? page.roundToDouble();
    final flingThreshold = tolerance.velocity * 0.25;

    double targetPage;
    if (velocity < -flingThreshold) {
      // Fling backward: turn to previous page relative to drag origin
      targetPage = origin - 1.0;
    } else if (velocity > flingThreshold) {
      // Fling forward: turn to next page relative to drag origin
      targetPage = origin + 1.0;
    } else {
      // Symmetric 15% threshold measured from the settled page in BOTH directions:
      final delta = page - origin;
      if (delta > dragThreshold) {
        targetPage = origin + 1.0;
      } else if (delta < -dragThreshold) {
        targetPage = origin - 1.0;
      } else if (delta.abs() <= dragThreshold) {
        targetPage = origin;
      } else {
        targetPage = origin;
      }
    }

    final maxPage = position.maxScrollExtent / position.viewportDimension;
    return _getPixels(position, targetPage.clamp(0.0, maxPage));
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tolerance = toleranceFor(position);
    final target = getTargetPixels(position, tolerance, velocity);
    if (target != position.pixels) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        target,
        velocity,
        tolerance: tolerance,
      );
    }
    return null;
  }
}
