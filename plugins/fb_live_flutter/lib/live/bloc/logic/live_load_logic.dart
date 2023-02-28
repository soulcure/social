import 'package:fb_live_flutter/live/bloc/with/live_loading.dart';
import 'package:fb_live_flutter/live/bloc_model/show_anchor_leave_blic_model.dart';
import 'package:fb_live_flutter/live/bloc_model/show_image_filter_bloc_model.dart';
import 'package:fb_live_flutter/live/event_bus_model/live_status_model.dart';
import 'package:fb_live_flutter/live/pages/live_room/interface/live_interface.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/live_status_enum.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

/// 普通直播、obs直播、web都需要使用
mixin LiveLoadLogic
    on LiveOutSyncLogic, LiveNetErrorLogic, LiveLoadInterface, LiveInterface {
  bool isUse = false;
  bool anchorIsClose = false;

  bool showImageFilter = false; //是否显示蒙层图片
  bool showAnchorLeave = false; //是否主播离开

  /// 流附加信息是否显示主播离开
  bool streamInfoIsAnchorLeave = false;

  bool isRenderVideoFirstFrame = false;
  late bool isShowOverlayView;

  /// 是否音画不同步
  bool intervalLarge = false;

  ShowImageFilterBlocModel? showImageFilterBlocModel;
  ShowAnchorLeaveBlocModel? showAnchorLeaveBlocModel;

  ZegoStreamQualityLevel? mLevel;

  /// 【APP】主播结束直播，观众没有直播结束反应
  bool get routeHasLive {
    return RouteUtil.routeHasLive;
  }

  /// 设置主播离开
  void setAnchorLeave() {
    showImageFilter = false;
    showAnchorLeave = false;
    showImageFilterBlocModel?.add(showImageFilter);
    showAnchorLeaveBlocModel?.add(showAnchorLeave);
  }

  /// 设置主播不离开
  void setNotAnchorLeave() {
    showImageFilter = true;
    showAnchorLeave = true;
    showImageFilterBlocModel?.add(showImageFilter);
    showAnchorLeaveBlocModel?.add(showAnchorLeave);
  }

  /// errorCode == 1002051【old】
  void netErrorCall(ZegoStreamQualityLevel level) {
    if (level == mLevel) {
      return;
    }
    mLevel = level;
    if (anchorIsClose) {
      return;
    }

    if (mLevel == ZegoStreamQualityLevel.Bad) {
      isNetError = true;

      /// 好的，那需求调整一下：如何出现的是1002051的错误代码，
      /// 就可以延后15秒再提示“网络连接不稳定，正在重新连接”， 15秒内连接成功后，不提示内容。

      netErrorHandle();
    } else {
      /// 如果不是异常状态清除倒计时
      netErrorTimerCancel();
    }
  }

  //1. 观众端重画流程：去掉10002051 ，使用拉流质量回调判断。
  //
  // - 修改弱网判断：
  // 在直播间内不再按1002051的错误码给用户做出提示，而是使用拉流质量回调的质量等级来进行判断。
  // 1. 当回调 = Bad，表示网络很差，持续15秒后，Toast轻提示“ 网络很差，有点卡哟……”，Toast提示3秒后消失，如果未改善，1分钟后再次提示。
  // 2. 当回调 = Die，表示网络断开了，持续5秒后，Toast轻提示“ 网络已断开，正在重新连接……”，Toast提示不消失。
  // 3. 当房间状态错误码 = 1002053，表示房间连接断开且重试也无效，重提示“ 网络已断开，请检测网络”带按钮【退出】（退出到列表）【重试】（重新连接房间、拉流）。
  void netErrorHandle({bool isMinute = false}) {
    netErrorStart(
      onComplete: () {
        if (isNetError) {
          liveValueModel!.liveStatus = LiveStatus.networkError;
          eventBus.fire(LiveStatusEvent(LiveStatus.networkError));
          // 网络原因导致房间连接临时中断，正在重试
          closeLoading();
          // 重开
          if (!isShowOverlayView || routeHasLive) {
            myToast('网络很差，有点卡哟……',
                duration: const Duration(milliseconds: 3000));
            netErrorHandle(isMinute: true);
            // netConnect();
          }
        }
      },
      isMinute: isMinute,
    );
  }

  /*
  * 【拉流端】首帧绘制完毕
  *
  * 2. 观众端重画流程：进入直播间，房间状态回调，流成功回调，首帧画面回调。
  * - 调整原因：
  * 观众端在弱网时偶现进入直播间后，黑屏好长一段时间没有反应，这误让人以为是事故。
  *
  * - 增加首帧画面的判断：
  * 在直播间拉流得到拉流成功的回调后，不要关闭toast轻提示“正在连接……”，
  * 而是继续判断首帧画面的回调成功后，方显示画面。
  *
  * - 首帧画面接口：
  * Flutter实时音视频API功能列表 - 开发者中心 - ZEGO即构科技
  * */
  void playerRenderVideoFirstFrame() {
    // 是否渲染首帧标记为true
    isRenderVideoFirstFrame = true;

    /// 【取消加载效果】
    /// 无论是不是为主播离开，第一帧触发都要去除loading，
    /// 主播离开也不能与loading同时存在
    closeLoading();

    /// 流附加信息显示不为主播离开才去隐藏背景
    /// 否则会导致设置主播离开无效
    /// 从而显示空白
    if (!streamInfoIsAnchorLeave) {
      // 切换背景-隐藏主播已离开提示
      setNotAnchorLeave();
    }

    // 清除计时器
    netErrorTimerCancel();
  }

  /*
  * - 增加音视频不同步的判断：
  *
  * 当音频不同步的回调值 > 200时，表示为异常，当异常时，给到用户直播间将重新拉流。
  * 在测试环境中，加入toast提示“音视频不同步，正在重新拉流”，用于测试本流程逻辑是否完成。
  * */
  void handleRePull(int avTimestampDiff, {VoidCallback? onComplete}) {
    const String tip = "音频与画面不同步，重新拉流";

    /// 是否间隔过大
    final bool _intervalLarge = avTimestampDiff > 200 || avTimestampDiff < -200;
    if (intervalLarge == _intervalLarge) {
      /// 与上次存储的状态一致，不需要处理，直接返回
      return;
    } else {
      intervalLarge = _intervalLarge;
    }

    /// 没有间隔过大，销毁计时器且返回
    if (!intervalLarge) {
      isOutSyncError = false;
      outSyncCancel();
      return;
    }

    /// 重新拉流音频不同步的回调值依然 > 200
    /// 是否需要加上时间上的判断，比如当回调的值连续10秒>200时。
    ///
    /// 在文档是这么写的，当绝对值连续10秒时才算异常；
    ///
    /// 彭路
    /// 那就10秒
    outSyncErrorStart(
      onComplete: () {
        if (isOutSyncError) {
          /// 改成包名判断
          /// 只在我们自己测试包出现的，按包名判断显示错误提示。
          ///
          /// 【2021 11.19】
          PackageInfo.fromPlatform().then((packageInfo) {
            const String iosPackage = "zeinn.ios.app.flutterFanbookLive";
            const String androidPackage = "com.example.flutter_fanbook_live";
            final bool isShowTip = packageInfo.packageName == iosPackage ||
                packageInfo.packageName == androidPackage;
            if (isShowTip) {
              myToast(tip);
            }
          });
          if (onComplete != null) {
            onComplete();
          }
        }
      },
    );
  }
}
