import 'package:event_bus/event_bus.dart';
import 'package:flutter_screen_orientation/flutter_screen_orientation.dart';

EventBus orientationBus = EventBus();

class ScreenOrientationEven {
  final int orientation;

  ScreenOrientationEven(this.orientation);
}

// 1:竖屏[V]   6：右横屏[RH]    8：左横屏[LH]

class ScreenOrientationUtil {
  static void init() {
    FlutterScreenOrientation.instance()!.init();
    FlutterScreenOrientation.instance()!.listenerOrientation((e) {
      orientationBus.fire(ScreenOrientationEven(e));
    });
  }
}
