import 'package:event_bus/event_bus.dart';

EventBus liveRouteActiveCloseBus = EventBus();

class LiveRouteActiveCloseModel {
  final bool value;

  LiveRouteActiveCloseModel(this.value);
}
