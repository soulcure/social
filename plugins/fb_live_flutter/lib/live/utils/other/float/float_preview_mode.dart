// 悬浮窗模式更新

import 'dart:async';
import 'dart:io';

import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/pages/preview/live_preview.dart';
import 'package:fb_live_flutter/live/pages/preview/preview_overlay.dart';
import 'package:fb_live_flutter/live/utils/config/route_path.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/other/float_plugin.dart';
import 'package:fb_live_flutter/live/utils/other/float_util.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

// 抽象类，接口作用
abstract class FloatPreViewWindow {
  LiveValueModel? liveValueModel;

  bool get isHaveFloat;

  /// 打开悬浮窗
  void open(
    BuildContext context,
    LiveValueModel? liveValueModel,
    bool isOutsideApp, {
    final bool showSmallWindowNeedDelay = false,
  });

  /// 打开悬浮窗
  void openFloatUI(
    BuildContext context,
    LiveValueModel? liveValueModel,
    bool isOutsideApp, {
    final bool showSmallWindowNeedDelay = false,
  });

  /// 关闭悬浮窗
  Future<bool> close();

  /// 关闭悬浮窗UI
  void closeFloatUI();

  /// 销毁小窗实体与引擎
  void closeFloatUIAndEngine();

  /// 悬浮窗被点击
  void floatClick();

  /// 推送到预览页面
  void pushToPreView();
}

// 混装类，通用
mixin FloatPreViewWindowMixin on FloatPreViewWindow {
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
  }) {
    // 设置直播数据模型
    setLiveValueModel(liveValueModel);
  }

  // 小窗关闭逻辑处理【通用】
  Future<bool> closeHandle() async {
    fbApi.fbLogger.info('设置【预览】数据模型为空');

    // 设置直播数据模型为空
    setLiveValueModel(null);

    return true;
  }

  @override
  void pushToPreView() {
    if (liveValueModel == null) {
      myFailToast('出现错误');
      closeFloatUI();
      return;
    }

    RouteUtil.push(
      fbApi.globalNavigatorKey.currentContext,
      LivePreviewPage(
        liveValueModel: liveValueModel,
      ),
      RoutePath.livePreviewPage,
    );

    /// 跳转到页面之后需要关闭悬浮窗UI
    closeFloatUI();
  }

  @override
  void floatClick() {
    pushToPreView();
  }

  @override
  void closeFloatUIAndEngine() {
    //停止本地预览
    ZegoExpressEngine.instance.stopPreview();
    //销毁预览容器
    ZegoExpressEngine.instance
        .destroyTextureRenderer(liveValueModel!.textureId);
    //注销
    ZegoExpressEngine.destroyEngine();

    closeFloatUI();
  }

  /*
  * 关闭小窗实际处理
  * */
  Future<bool> closeFloatHandle() async {
    // 没有悬浮窗，不去关闭
    if (!isHaveFloat) {
      // 顺便再次关闭一次悬浮窗ui，防止上次关闭失败了
      closeFloatUI();
      return false;
    }

    closeFloatUIAndEngine();
    return true;
  }
}

// IOS专用
class IosFloatPreViewWindow extends FloatPreViewWindow
    with FloatPreViewWindowMixin {
  @override
  void open(
    BuildContext context,
    LiveValueModel? liveValueModel,
    bool isOutsideApp, {
    final bool showSmallWindowNeedDelay = false,
  }) {
    /// 打开悬浮窗UI
    openFloatUI(context, liveValueModel, isOutsideApp,
        showSmallWindowNeedDelay: showSmallWindowNeedDelay);

    super.open(context, liveValueModel, isOutsideApp,
        showSmallWindowNeedDelay: showSmallWindowNeedDelay);
    fbApi.fbLogger.info("IOS打开预览悬浮窗");
  }

  @override
  Future<bool> close() async {
    return closeFloatHandle();
  }

  @override
  void closeFloatUI() {
    // 小窗关闭逻辑处理【通用】
    closeHandle();

    if (OverlayPreView.overlayEntry != null) {
      OverlayPreView.removeOverlayEntry();
    }
  }

  @override
  void openFloatUI(
      BuildContext context, LiveValueModel? liveValueModel, bool isOutsideApp,
      {bool showSmallWindowNeedDelay = false}) {
    OverlayPreView.showOverlayEntry(
      context: context,
      showSmallWindowNeedDelay: showSmallWindowNeedDelay,
      liveValueModel: liveValueModel,
    );
  }
}

// Android专用
class AndroidFloatPreViewWindow extends FloatPreViewWindow
    with FloatPreViewWindowMixin {
  @override
  void open(
    BuildContext context,
    LiveValueModel? liveValueModel,
    bool isOutsideApp, {
    final bool showSmallWindowNeedDelay = false,
  }) {
    /// 打开悬浮窗UI
    openFloatUI(context, liveValueModel, isOutsideApp,
        showSmallWindowNeedDelay: showSmallWindowNeedDelay);

    super.open(context, liveValueModel, isOutsideApp,
        showSmallWindowNeedDelay: showSmallWindowNeedDelay);
    fbApi.fbLogger.info("Android打开预览悬浮窗");
  }

  @override
  Future<bool> close() async {
    return closeFloatHandle();
  }

  @override
  void closeFloatUI() {
    // 小窗关闭逻辑处理【通用】
    closeHandle();

    /// 一次关闭小窗
    FloatPlugin.dismiss();

    /// 防止没有关闭悬浮窗成功，二次检测
    FloatUtil.dismissFloat(300);
  }

  @override
  void openFloatUI(
      BuildContext context, LiveValueModel? liveValueModel, bool isOutsideApp,
      {bool showSmallWindowNeedDelay = false}) {
    /// Android应该显示全局悬浮窗,不直接返回是因为还是要存储一些参数
    FloatUtil.showPreviewFloat(context, isOutsideApp);
  }
}

FloatPreViewWindow floatPreViewWindow =
    Platform.isIOS ? IosFloatPreViewWindow() : AndroidFloatPreViewWindow();
