import 'package:event_bus/event_bus.dart';

class EventBusManager {
  static EventBus? _eventBus;

  static EventBus get eventBus => _eventBus ??= EventBus();

  /// Destroy this [EventBus]. This is generally only in a testing context.
  static void destroy() {
    _eventBus?.destroy();
    _eventBus = null;
  }
}
