import 'package:event_bus/event_bus.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import '../utils/live_status_enum.dart';

//Bus 初始化
EventBus eventBus = EventBus();

class LiveStatusEvent {
  LiveStatus status;

  LiveStatusEvent(this.status);
}

/// 用户小窗口尺寸变更
class LiveSizeEvent {
  double width;
  double height;
  /// 屏幕共享和obs使用ZegoViewMode.AspectFit否则使用ZegoViewMode.AspectFILL
  ZegoViewMode viewMode;

  LiveSizeEvent(this.width, this.height, this.viewMode);
}

class LiveCloseEvent {
  LiveCloseEvent();
}
