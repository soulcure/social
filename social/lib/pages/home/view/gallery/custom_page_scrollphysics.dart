import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';


class CustomPageScrollPhysics extends PageScrollPhysics {
  /// Creates physics for a [PageView].
  const CustomPageScrollPhysics({ScrollPhysics parent}) : super(parent: parent);

  @override
  CustomPageScrollPhysics applyTo(ScrollPhysics ancestor) {
    return CustomPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  Simulation createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final Simulation simulation = super.createBallisticSimulation(position, velocity);
    if (simulation != null && simulation is ScrollSpringSimulation) {
      final simulationInfo = simulation.toString();
      try {
        final targetStr = simulationInfo.substring(simulationInfo.indexOf('end:') + 5,simulationInfo.indexOf(','));
        final target = double.parse(targetStr);
        if (target != position.pixels)
          return ScrollSpringSimulation(
              spring, position.pixels, target, velocity * 2,
              tolerance: tolerance);
      } catch (e) {
        return simulation;
      }
    }
    return simulation;
  }

  @override
  bool get allowImplicitScrolling => false;
}
