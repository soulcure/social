import 'package:event_bus/event_bus.dart';

//Bus 初始化
EventBus chartEventBus = EventBus();

class LiveRoomChartEvent {
  List chartList;

  LiveRoomChartEvent(this.chartList);
}
