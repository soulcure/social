import 'package:event_bus/event_bus.dart';

class TextureOverlapNotifier {
  TextureOverlapNotifier._();

  static final TextureOverlapNotifier instance = TextureOverlapNotifier._();

  EventBus eventBus;

  void emit(TextureOverlapEvent event) {
    (eventBus ??= EventBus()).fire(event);
  }

  void listen(void Function(TextureOverlapEvent event) onData) {
    (eventBus ??= EventBus()).on<TextureOverlapEvent>().listen(onData);
  }
}

class TextureOverlapEvent {
  /// push到了android原生view,即可能导致重叠的问题
  bool overlap;

  TextureOverlapEvent({this.overlap = false});
}
