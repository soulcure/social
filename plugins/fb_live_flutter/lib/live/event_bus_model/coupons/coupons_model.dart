import 'package:event_bus/event_bus.dart';

EventBus couponsBus = EventBus();

class CouponsRefreshModel {
  final int count;

  CouponsRefreshModel(this.count);
}
