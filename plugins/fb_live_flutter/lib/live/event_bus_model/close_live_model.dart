import 'package:event_bus/event_bus.dart';

//Bus 初始化
EventBus closeEventBus = EventBus();

class CloserLiveEvent {
  String? roomLogo;
  bool? isAnchor;
  String? roomId;
  bool? isOverlayViewPush;
  bool isPushLive; //是否跳转直播页面
  String? userId;
  bool isObs;

  /// 是否只关闭悬浮窗不做其他操作
  bool onlyCloseOverlay;

  CloserLiveEvent(
      {this.roomLogo,
      this.isAnchor,
      this.roomId,
      this.isOverlayViewPush,
      this.isPushLive = false,
      this.isObs = false,
      this.onlyCloseOverlay = false,
      this.userId});
}
