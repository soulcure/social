//Bus 初始化
import 'package:event_bus/event_bus.dart';

EventBus roomListEventBus = EventBus();
EventBus roomListSetStateEventBus = EventBus();

class LiveRoomListEvent {}

class LiveRoomListSetStateEvent {}
