// 悬浮窗模式更新

import 'dart:async';
import 'dart:io';

import 'package:fb_live_flutter/live/api/fblive_model.dart';
import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/event_bus_model/close_live_model.dart';
import 'package:fb_live_flutter/live/event_bus_model/goods_html_bus.dart';
import 'package:fb_live_flutter/live/event_bus_model/live/live_route_active_close.dart';
import 'package:fb_live_flutter/live/event_bus_model/live_status_model.dart';
import 'package:fb_live_flutter/live/event_bus_model/liveroom_chat_model.dart';
import 'package:fb_live_flutter/live/event_bus_model/refresh_room_list_model.dart';
import 'package:fb_live_flutter/live/net/api.dart';
import 'package:fb_live_flutter/live/pages/create_room/create_room.dart';
import 'package:fb_live_flutter/live/pages/live_room/room_middle_page.dart';
import 'package:fb_live_flutter/live/utils/config/route_path.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/live/zego_manager.dart';
import 'package:fb_live_flutter/live/utils/live_status_enum.dart';
import 'package:fb_live_flutter/live/utils/manager/event_bus_manager.dart';
import 'package:fb_live_flutter/live/utils/other/float_plugin.dart';
import 'package:fb_live_flutter/live/utils/other/float_util.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/loading.dart';
import 'package:fb_live_flutter/live/utils/ui/overlay.dart';
import 'package:flutter/cupertino.dart';

// 抽象类，接口作用
abstract class FloatWindow {
  LiveValueModel? liveValueModel;

  bool get isHaveFloat;

  /// 打开悬浮窗
  void open(
    BuildContext context,
    LiveValueModel? liveValueModel,
    bool isOutsideApp, {
    final bool showSmallWindowNeedDelay = false,
    final bool? isShowClose,
  });

  /// 打开悬浮窗
  void openFloatUI(
    BuildContext context,
    LiveValueModel? liveValueModel,
    bool isOutsideApp, {
    final bool showSmallWindowNeedDelay = false,
    final bool? isShowClose,
  });

  /// 关闭悬浮窗
  Future<bool> close();

  /// 关闭悬浮窗UI
  void closeFloatUI([bool isCleanLiveValue = true]);

  /// 销毁小窗实体与引擎
  void closeFloatUIAndEngine();

  /// 悬浮窗被点击
  void floatClick();

  /// 事件总线关闭直播
  void eventBusCloseLive(CloserLiveEvent event);

  /// 推送到直播页面
  void pushToLive(FBLiveEvent event);

  Widget pushToLiveWidget();
}

// 混装类，通用
mixin FloatWindowMixin on FloatWindow {
  StreamSubscription? _liveSizeSubscription;
  StreamSubscription? _liveRoomChartSubscription;
  StreamSubscription? _liveStatusSubscription;

  @override
  bool get isHaveFloat => liveValueModel != null;

  // 设置直播数据模型数据，在打开小窗时调用
  void setLiveValueModel(LiveValueModel? liveValueModel) {
    this.liveValueModel = liveValueModel;
    return;
  }

  @override
  void open(
    BuildContext context,
    LiveValueModel? liveValueModel,
    bool isOutsideApp, {
    final bool showSmallWindowNeedDelay = false,
    final bool? isShowClose,
  }) {
    // 设置直播数据模型
    setLiveValueModel(liveValueModel);

    // 监听注册
    fbApi.registerLiveCloseListener(close);
    fbApi.addFBLiveEventListener(pushToLive);

    // 订阅事件总线
    eventBusSubs();
  }

  // 订阅事件总线
  void eventBusSubs() {
    _liveStatusSubscription = eventBus.on<LiveStatusEvent>().listen((event) {
      if (!isHaveFloat) return;
      liveValueModel!.liveStatus = event.status;
    });
    _liveRoomChartSubscription =
        chartEventBus.on<LiveRoomChartEvent>().listen((event) {
      if (!isHaveFloat) return;
      liveValueModel!.chatList = event.chartList;
    });
    _liveSizeSubscription = eventBus.on<LiveSizeEvent>().listen((event) {
      if (!isHaveFloat) return;
      liveValueModel!.playerVideoWidth = event.width;
      liveValueModel!.playerVideoHeight = event.height;
      liveValueModel!.zegoViewMode = event.viewMode;
    });
  }

  // 小窗关闭逻辑处理【通用】
  Future<bool> closeHandle(bool isCleanLiveValue) async {
    fbApi.fbLogger.info('设置直播数据模型为空');

    /// 点击分享卡片进入直播间绝对不能清除
    if (isCleanLiveValue) {
      // 设置直播数据模型为空
      setLiveValueModel(null);
    }

    // 监听销毁
    fbApi.unregisterLiveCloseListener(close);
    fbApi.removeFBLiveEventListener(pushToLive);

    // 取消事件总线监听
    cancelEventbus();

    /// 关闭小窗口后告诉直播间
    liveRouteActiveCloseBus.fire(LiveRouteActiveCloseModel(false));

    /// 发送事件给直播页面，让其重新播放画面
    goodsHtmlBus.fire(GoodsHtmlEvenModel(0));

    return true;
  }

  // 取消事件总线监听
  void cancelEventbus() {
    fbApi.fbLogger.info("cancelEventbus::取消事件总线监听");
    _liveStatusSubscription?.cancel();
    _liveStatusSubscription = null;
    _liveRoomChartSubscription?.cancel();
    _liveRoomChartSubscription = null;
    _liveSizeSubscription?.cancel();
    _liveSizeSubscription = null;
  }

  @override
  void pushToLive(FBLiveEvent event) {
    if (liveValueModel == null) {
      myFailToast('出现错误');
      closeFloatUI();
      return;
    }

    /// 不包含直播间才去正常跳转
    if (!RouteUtil.routeHasLive) {
      if (event == FBLiveEvent.fullscreen) {
        RouteUtil.push(
          fbApi.globalNavigatorKey.currentContext,
          RoomMiddlePage(
            isOverlayViewPush: true,
            liveValueModel: liveValueModel,
          ),
          "/liveRoom",
        );

        /// 跳转到页面之后需要关闭悬浮窗UI
        closeFloatUI();
      }

      /// 存在直播页面则不去跳转，而是执行清除直播上层路由
    } else if (!RouteUtil.routeIsLive) {
      /// 点击小窗进入app清除直播页面上层页面
      RouteUtil.popToLive();
    }
  }

  @override
  Widget pushToLiveWidget() {
    if (liveValueModel == null) {
      myFailToast('出现错误');
      closeFloatUI();
      return Container();
    }

    /// 跳转到页面之后需要关闭悬浮窗UI
    /// 这里一定要传false，否则跳转的时候[liveValueModel]就是[false]了。
    closeFloatUI(false);

    return RoomMiddlePage(
      isOverlayViewPush: true,
      liveValueModel: liveValueModel,
    );
  }

  @override
  void floatClick() {
    /// app内进入直播页面
    if (RouteUtil.routeHasLive) {
      /// 有包含直播页面，说明是在直播间页面内页
      /// 【APP】观众进入详情页，点击小窗无法返回直播间
      /// date: 2021 11.1
      ///
      /// 【APP】ios小窗返回直播间后，关闭直播间，未返回至直播列表页
      /// date: 2021 11.2
      RouteUtil.popToLive();
    } else {
      // 点击之后现有普通文本提示框消失
      Loading.confirmFunc(null);
      pushToLive(FBLiveEvent.fullscreen);
    }
  }

  @override
  void closeFloatUIAndEngine() {
    ZegoManager.destroyEngine(
        isAnchor: liveValueModel!.isAnchor,
        textureID: liveValueModel!.textureId,
        roomId: liveValueModel!.getRoomId);

    closeFloatUI();
  }

  // 上报当前角色直播间
  void _setLiveExit(LiveValueModel liveValueModel) {
    fbApi.exitLiveRoom(liveValueModel.roomInfoObject!.serverId,
        liveValueModel.roomInfoObject!.channelId, liveValueModel.getRoomId);
    Api.liveExit(
        liveValueModel.getRoomId,
        liveValueModel.zegoTokenModel?.userToken,
        liveValueModel.isAnchor,
        liveValueModel.roomInfoObject!);
  }

  // 上报主播关闭直播
  void _anchorCloseLive() {
    Api.closeLiveRoom(liveValueModel!.getRoomId);
  }

  /*
  * 关闭小窗实际处理
  * */
  Future<bool> closeFloatHandle() async {
    // 没有悬浮窗，不去关闭
    if (!isHaveFloat) {
      // 顺便再次关闭一次悬浮窗ui，防止上次关闭失败了
      closeFloatUI(false);
      return false;
    }

    if (RouteUtil.routeHasLive) {
      closeFloatUI();
      return true;
    }

    /// 账号异地登录
    if (liveValueModel!.liveStatus == LiveStatus.abnormalLogin) {
      /// 不需要调用后续接口，直接关闭小窗
      closeFloatUIAndEngine();
      return true;
    }

    // 上报当前角色直播间
    _setLiveExit(liveValueModel!);

    // 如果是主播的话
    if (liveValueModel!.isAnchor) {
      // 上报主播关闭直播【服务api】
      _anchorCloseLive();

      // 主播停止直播【fbApi】
      unawaited(fbApi.stopLive(
          liveValueModel!.roomInfoObject!.serverId,
          liveValueModel!.roomInfoObject!.channelId,
          liveValueModel!.zegoTokenModel!.roomId!));

      // 刷新直播列表
      EventBusManager.eventBus.fire(RefreshRoomListModel(true));
    }

    closeFloatUIAndEngine();
    return true;
  }

  @override
  void eventBusCloseLive(CloserLiveEvent event) {
    if (event.onlyCloseOverlay) {
      close();
      return;
    }
    close().then((value) {
      if (event.isPushLive) {
        /// 延时100毫秒防止小窗口的引擎没有销毁完毕
        Future.delayed(const Duration(milliseconds: 100)).then((value) {
          liveValueModel!.setRoomId(event.roomId!);

          // OBS 主播账号异地登陆恢复直播画面
          liveValueModel!.setObs(event.isObs);
          liveValueModel!.isAnchor = event.isAnchor!;

          RouteUtil.push(
              fbApi.globalNavigatorKey.currentContext,
              RoomMiddlePage(
                isOverlayViewPush: event.isOverlayViewPush,
                liveValueModel: liveValueModel,
              ),
              "/liveRoom");
        });
      } else {
        fbApi
            .getUserInfo(event.userId!,
                guildId: liveValueModel!.roomInfoObject!.serverId)
            .then((value) {
          RouteUtil.push(
              fbApi.globalNavigatorKey.currentContext,
              CreateRoom(
                nickName: value.name!,
              ),
              RoutePath.liveCreateRoom);
        });
      }
    });
  }
}

// IOS专用
class IosFloatWindow extends FloatWindow with FloatWindowMixin {
  @override
  void open(
    BuildContext context,
    LiveValueModel? liveValueModel,
    bool isOutsideApp, {
    final bool showSmallWindowNeedDelay = false,
    final bool? isShowClose,
  }) {
    /// 打开悬浮窗UI
    openFloatUI(context, liveValueModel, isOutsideApp,
        showSmallWindowNeedDelay: showSmallWindowNeedDelay,
        isShowClose: isShowClose);

    super.open(context, liveValueModel, isOutsideApp,
        showSmallWindowNeedDelay: showSmallWindowNeedDelay,
        isShowClose: isShowClose);
    fbApi.fbLogger.info("IOS打开悬浮窗");
  }

  @override
  Future<bool> close() async {
    return closeFloatHandle();
  }

  @override
  void closeFloatUI([bool isCleanLiveValue = true]) {
    // 小窗关闭逻辑处理【通用】
    closeHandle(isCleanLiveValue);

    if (OverlayView.overlayEntry != null) {
      OverlayView.removeOverlayEntry();
    }
  }

  @override
  void openFloatUI(
    BuildContext context,
    LiveValueModel? liveValueModel,
    bool isOutsideApp, {
    bool showSmallWindowNeedDelay = false,
    final bool? isShowClose,
  }) {
    OverlayView.showOverlayEntry(
      context: context,
      showSmallWindowNeedDelay: showSmallWindowNeedDelay,
      liveValueModel: liveValueModel!,
    );
  }
}

// Android专用
class AndroidFloatWindow extends FloatWindow with FloatWindowMixin {
  @override
  void open(
    BuildContext context,
    LiveValueModel? liveValueModel,
    bool isOutsideApp, {
    final bool showSmallWindowNeedDelay = false,
    final bool? isShowClose,
  }) {
    /// 打开悬浮窗UI
    openFloatUI(context, liveValueModel, isOutsideApp,
        showSmallWindowNeedDelay: showSmallWindowNeedDelay,
        isShowClose: isShowClose);

    super.open(context, liveValueModel, isOutsideApp,
        showSmallWindowNeedDelay: showSmallWindowNeedDelay,
        isShowClose: isShowClose);
    fbApi.fbLogger.info("Android打开悬浮窗");
  }

  @override
  Future<bool> close() async {
    return closeFloatHandle();
  }

  @override
  void closeFloatUI([bool isCleanLiveValue = true]) {
    // 小窗关闭逻辑处理【通用】
    closeHandle(isCleanLiveValue);

    /// 一次关闭小窗
    FloatPlugin.dismiss();

    /// 防止没有关闭悬浮窗成功，二次检测
    FloatUtil.dismissFloat(300);
  }

  @override
  void openFloatUI(
    BuildContext context,
    LiveValueModel? liveValueModel,
    bool isOutsideApp, {
    bool showSmallWindowNeedDelay = false,
    final bool? isShowClose,
  }) {
    FloatUtil.showFloat(
      context,
      liveValueModel!.isAnchor && !liveValueModel.getIsObs
          ? null
          : liveValueModel.getRoomId,
      isPop: true,
      isObs: liveValueModel.getIsObs,
      isOutsideApp: isOutsideApp,
      liveValueModel: liveValueModel,
      isShowClose: isShowClose,
    ).then((value) {
      /// 打开小窗口后更新小窗口中直播状态
      FloatPlugin.liveStatusChange(liveValueModel.liveStatus.index);
    });
  }
}

FloatWindow floatWindow =
    Platform.isIOS ? IosFloatWindow() : AndroidFloatWindow();
