import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/bloc/with/live_loading.dart';
import 'package:fb_live_flutter/live/model/live/obs_rsp_model.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/model/zego_token_model.dart';
import 'package:fb_live_flutter/live/net/api.dart';
import 'package:fb_live_flutter/live/utils/config/steam_info_config.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/live/zego_manager.dart';
import 'package:fb_live_flutter/live/utils/live_status_enum.dart';
import 'package:fb_live_flutter/live/utils/other/float_plugin.dart';
import 'package:fb_live_flutter/live/utils/other/float_util.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/draggable_widget.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

typedef CallCanvas = Function(ZegoCanvas previewCanvas);

/// 内存存储直播间信息[普通直播]
///
class LiveValueModel {
  // 获取房间id
  String get getRoomId {
    return roomInfoObject!.roomId;
  }

  // 设置房间id
  void setRoomId(String roomId) {
    roomInfoObject!.roomId = roomId;
    return;
  }

  // 设置房间logo
  void setRoomLogo(String roomLogo) {
    roomInfoObject!.roomLogo = roomLogo;
    return;
  }

  // 获取是否OBS
  bool get getIsObs {
    return roomInfoObject?.liveType == 3;
  }

  // 设置为Obs
  void setObs([bool isObs = true]) {
    if (isObs) {
      roomInfoObject!.liveType = 3;
    } else {
      roomInfoObject!.liveType = 4;
    }
  }

  /// 直播间视图模式
  ZegoViewMode zegoViewMode = ZegoViewMode.AspectFill;

  /// 本次进入直播是否上报优惠券入口日志
  bool isUpLogCoupons = false;

  /// 是否是屏幕共享推送
  bool isScreenPush = false;

  /// 旋转方向
  String? screenDirection = "V";

  /// 直播带货商品数量
  int? goodsCount = 0;

  /// 是否显示优惠券入口
  bool? isShowCoupons = false;

  /// 是否使用前置摄像头
  bool useFrontCamera = true;

  /// 是否镜像
  bool isMirror = true;

  ///是否是主播
  bool isAnchor = false;

  /// 视频画面
  int textureId = -1;

  /// token对象
  ZegoTokenModel? zegoTokenModel;

  //是否屏幕共享中
  bool isScreenSharing = false;

  /// 直播间状态
  LiveStatus liveStatus = LiveStatus.none;

  /// 视频宽度
  double playerVideoWidth = 720;

  /// 视频高度
  double playerVideoHeight = 1280;

  /// 会话列表
  List chatList = [];

  /// 悬浮窗左边距离
  double overlayLeft = FrameSize.screenW() - FrameSize.px(90);

  /// 悬浮窗顶部距离
  double overlayTop = DraggableViewState.defTopOffset;

  /// 悬浮窗【小房子图标】左边距离
  double overlayHomeLeft = 5.5.px;

  /// 悬浮窗【小房子图标】顶部距离
  double overlayHomeTop = 5.5.px + FrameSize.padTopH();

  /// obs数据模型
  ObsRspModel? obsModel;

  /// 房间信息对象
  RoomInfon? roomInfoObject = defRoomInfo;

  static RoomInfon get defRoomInfo {
    return RoomInfon(
        serverId: '',
        channelId: '',
        roomLogo: '',
        status: 0,
        liveType: 0,
        roomId: '');
  }

  /*
  * 初次跳转直播页面必需调用
  *
  * 确保有[required]标识的属性不为空
  * */
  void setRoomInfo(
      {required String roomId,
      required String serverId,
      required String channelId,
      required String roomLogo,
      required int status,
      required int liveType,
      RoomInfon? roomInfoObject}) {
    if (this.roomInfoObject != null) {
      this.roomInfoObject = roomInfoObject;
    }
    this.roomInfoObject!.roomId = roomId;
    this.roomInfoObject!.serverId = serverId;
    this.roomInfoObject!.channelId = channelId;
    this.roomInfoObject!.roomLogo = roomLogo;
    this.roomInfoObject!.status = status;
    this.roomInfoObject!.liveType = liveType;
    return;
  }

  /// 流附加消息实体
  SteamInfoStore steamInfoStore = SteamInfoStore();
}

mixin LiveMix on LiveLoadWith {
  int liveOrientationValue = 0;

  /// 主播主动点结束直播且【确定】
  ///
  /// 当[anchorCloseLiveActively]为true时，有关直播结束的并发情况不需要再执行，如：
  ///   1.被系统禁播；
  ///   2.内容违规被禁播；
  bool anchorCloseLiveActively = false;

  //上报用户信息
  Future saveUserInfo(String guildId) async {
    final String? userId = fbApi.getUserId();

    final value = await fbApi.getUserInfo(userId!, guildId: guildId);
    await Api.postUserInfo(value.nickname, value.avatar, userId, value.shortId);
  }

  /*
  * 主播关闭直播失败【2022 02.25】
  *
  * 1.弹出3秒提示"退出直播间失败，请联系管理员";
  * 2.返回到直播列表页；
  * 3.提示toast提示依然显示；
  * */
  Future closeFail() async {
    /// 一定要在包含直播时才返回到列表，防止因为被禁播等并发系列操作多次调用。
    if (RouteUtil.routeHasLive) {
      /// 回到列表
      goBack();
    }

    /// 延迟主要防止[`closeLoading`]触发把提示给删除了
    await Future.delayed(const Duration(milliseconds: 500));

    /// 关闭重原有的提示【如：后台禁播与退出直播失败并发情况】
    showConfirmDialog(() {
      /// 弹出3秒提示"退出直播间失败，请联系管理员"
      myFailToast(
        '退出直播间失败，请联系管理员',
        duration: const Duration(seconds: 3),
      );
    });

    /// 检测小窗【关闭小窗方法，Android和iOS通用】
    /// 防止提前显示了小窗【比如：在h5页面等】
    unawaited(FloatUtil.dismissFloat(100));
  }

  /*
  * 流更新后拉流
  * */
  void addStreamAfterPull(String? useRoomId) {
    fbApi.fbLogger.info('audience pull stream when updated');

    /// 【APP】观众去到H5详情页，IOS主播暂时离开又返回直播间。观众小窗口画面不会恢复

    /// 【2021 12.09】先拉流，监听到尺寸回调后自然会刷新视图
    /// 修复 【APP】观看obs直播，出现3-5秒画面异常
    ///
    /// 【2021 12.15】不能直接使用[ZegoExpressEngine.instance.startPlayingStream]
    /// 如果直接使用的话线上环境会出现拉流失败，必须配置[ZegoStreamResourceMode]
    /// 问题：【修复观众进入直播间显示拉流失败】
    /// 相关范围：Android悬浮窗拉流
    if (Platform.isIOS) {
      ZegoManager.audiencePullStream(null, useRoomId!);
    } else {
      FloatPlugin.isShowFloat.then((value) {
        if (!value!) {
          ZegoManager.audiencePullStream(null, useRoomId!);
        }
      }).catchError((e) {
        ZegoManager.audiencePullStream(null, useRoomId!);
      });
    }
  }
}

/*
* 获取时间-打印前缀
* */
String get timePrintStr {
  return "[${DateTime.now()}]";
}

/// 【2021 12.13】路由方案-检测是否可路由变动
///
/// 1.在直播间添加bool变量；
/// 2.观众点击x后立刻改变bool变量；
/// 3.进入小窗前改变bool变量；
/// 4.在所有回调触发重提示与直播结束页面跳转时判断bool变量；
/// 5.在任何关闭小窗后改回bool变量的值；
///
/// 【2021 12.14】已更改为内存存储，每次进入直播间都将重置；
class RouteCloseMix {
  /// 是否主动关闭
  /// 默认值为false
  ///
  /// 在第4中情况下使用；
  ///
  /// 不用audienceIsClose的原因：
  /// 控制影响范围
  static bool isActiveClose = false;

  /// 设置为主动关闭；
  ///
  /// tip：
  /// 在第二、三种情况下调用
  /// 显示小窗口的情况：页面返回事件；直播间新增页面路由；app生命周期暂停；
  static void setActiveClose() {
    isActiveClose = true;
  }

  /// 设置为非主动关闭；
  ///
  /// 小窗口关闭显示时需要触发
  static void setNotActiveClose() {
    isActiveClose = false;
  }

  /// 没有主动关闭时执行
  ///
  /// action就是[isActiveClose]为false时执行的事件，在第4种情况下使用
  static void notActiveCloseThen({required VoidCallback action}) {
    /// 判断是否观众关闭直播
    if (isActiveClose) {
      return;
    }
    setActiveClose();
    action();
  }
}

mixin SmallWindowMixin {
  /// 显示小窗是否需要等待100毫秒
  /// 解决【iOS主播退桌面，然后回直播间，立刻切小窗口，小窗口消失】
  ///
  /// 1.调用`showOverlayEntry`时传入；
  /// 2.调用`showOverlayEntry`之后设置为false；
  /// 3.app切换到前后台设置为true；
  bool showSmallWindowNeedDelay = false;

  /*
  * 设置显示小窗需要延时
  * */
  void setNeedDelay(AppLifecycleState state) {
    /// app切换过到后台，设置显示小窗需要延时100毫秒
    if (state != AppLifecycleState.resumed) {
      showSmallWindowNeedDelay = true;
    }
  }
}
