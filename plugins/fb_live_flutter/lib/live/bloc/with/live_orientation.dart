import 'dart:async';
import 'dart:io';

import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/model/live/view_render_alg_model.dart';
import 'package:fb_live_flutter/live/pages/live_room/interface/live_interface.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rotate/flutter_rotate.dart';
import 'package:flutter_screen_orientation/flutter_screen_orientation.dart';

mixin LiveOrientation on LiveInterface {
  /// 是否旋转动画中
  bool isRotating = false;

  /// 是否离开了app，离开了app回来才需要去旋转竖屏，
  /// 因为调用打开原生主路由页面也是会有回来的事件，
  /// 但其实一直在app内，这个时候就不需要去旋转。
  bool isLeaveApp = false;

  ViewRenderAlgModel algModel = ViewRenderAlgModel();

  /// 旋转刷新[isScreenRotation]标记状态，
  /// 具体实现看混入[LiveOrientation]的覆盖[@override]
  void negationScreenRotation([bool? value]) {}

  /// 旋转刷新直播画面状态，
  /// 具体实现看混入[LiveOrientation]的覆盖[@override]
  Future rotationRefreshState([bool isCancelScreenPush = false]) async {}

  /*
  * app恢复设置竖屏【2022 01.07】
  *
  * 【APP】部分机型小窗口进直播间显示横屏
  * 横屏退桌面，点小窗口返回直播间，有的机型是竖屏，有的机型是横屏，需求：进入直播间都应该是竖机
  *
  * 【2022 01.10】
  * 再次优化【APP】部分机型小窗口进直播间显示横屏
  * */
  void appResumedSetVertical() {
    /// 修复iOS横屏切换到桌面再进入app旋转了两次竖屏
    if (Platform.isIOS) {
      return;
    }

    Future.delayed(const Duration(milliseconds: 700)).then((value) {
      if (FrameSize.isHorizontal() && isLeaveApp) {
        portraitUpState();
      }
      isLeaveApp = false;
    });
  }

  /// 旋转屏幕再执行
  @override
  Future<BuildContext?> rotateScreenExec(BuildContext? context) async {
    if (isRotating) {
      return null;
    }
    final bool isNeedRotate = FrameSize.isNeedRotate();
    final BuildContext? contextValue =
        isNeedRotate ? fbApi.globalNavigatorKey.currentContext : context;
    if (FrameSize.isNeedRotate()) {
      await rotationHandle(false);
    }

    /// 防止响应延迟
    await Future.delayed(const Duration(milliseconds: 10));
    return contextValue;
  }

  /*
  * 设置系统竖屏
  * */
  Future setSystemPortraitVertical() async {
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    /// 【2022 01.10】
    /// 【APP】直播列表内，点击直播间卡片或者小窗口返回直播间，需点击两次才可进入直播间
    /// 【APP】观众旋转屏幕后，需点击两次关闭直播间，才可关闭直播
    /// 一定要包含[SystemUiOverlay.bottom]否则执行之后首次点击失效；
    ///  flutter 旧版
    // ignore: deprecated_member_use
    await SystemChrome.setEnabledSystemUIOverlays(
        [SystemUiOverlay.top, SystemUiOverlay.bottom]);

    /// 解决iOS旋转拉伸
    /// 【APP】ios横屏切换小窗口，开播按钮与通知栏重合无法点击
    unawaited(FlutterRotate.changeVertical());
  }

  /*
  * 设置系统横屏
  * */
  Future setSystemPortraitHorizontal(DeviceOrientation orientation) async {
    await SystemChrome.setPreferredOrientations([orientation, orientation]);

    // ignore: deprecated_member_use
    await SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);

    /// 解决iOS旋转拉伸
    /// 【APP】ios横屏切换小窗口，开播按钮与通知栏重合无法点击
    unawaited(FlutterRotate.changeHorizontal());
  }

  /*
  * 旋转中设置
  * */
  void rotatingSet() {
    isRotating = true;
    Future.delayed(const Duration(milliseconds: 500)).then((value) {
      isRotating = false;
    });
  }

  /*
  * 重力旋转左横屏
  * */
  Future orientationLandscapeLeft() async {
    if (!RouteUtil.routeCanRotate()) {
      return;
    }

    if (isRotating) {
      return null;
    }

    rotatingSet();
    await orientationLandscapeLeftAndRight(false);
  }

  /*
  * 重力旋转右横屏
  * */
  Future orientationLandscapeRight() async {
    if (!RouteUtil.routeCanRotate()) {
      return;
    }
    if (isRotating) {
      return null;
    }

    rotatingSet();
    await orientationLandscapeLeftAndRight(true);
  }

  /*
  * 重力旋转竖屏
  * */
  Future portraitUpState() async {
    rotatingSet();
    await rotationHandle(false);
  }

  /*
  * 重力旋转左横屏与右横屏处理
  * */
  Future orientationLandscapeLeftAndRight(bool isRevers) async {
    negationScreenRotation(true);

    DeviceOrientation deviceOrientation;

    /// iOS与Android是反的，所以需要加isRevers
    if (Platform.isAndroid) {
      isRevers = !isRevers;
    }

    if (isRevers) {
      deviceOrientation = DeviceOrientation.landscapeLeft;
    } else {
      deviceOrientation = DeviceOrientation.landscapeRight;
    }

    await setSystemPortraitHorizontal(deviceOrientation);

    await rotationRefreshState();
  }

  /*
  * 点击旋转按钮
  * */
  @override
  Future rotationHandle([bool? value]) async {
    rotatingSet();

    negationScreenRotation(value);
    if (isScreenRotation) {
      /// 路由不是直播页面不允许旋转且重置[isScreenRotation]
      if (!RouteUtil.routeCanRotate()) {
        isScreenRotation = false;
        return;
      }

      await setSystemPortraitHorizontal(Platform.isIOS
          ? DeviceOrientation.landscapeRight
          : DeviceOrientation.landscapeLeft);
    } else {
      await setSystemPortraitVertical();
    }
    await rotationRefreshState();
    if (!isScreenRotation) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  /*
  * 重力感应处理
  * */
  Future screenOrientationHandle(int orientationValue) async {
    if (orientationValue == FlutterScreenOrientation.portraitUp) {
      await portraitUpState();
    } else if (orientationValue == FlutterScreenOrientation.landscapeLeft) {
      await orientationLandscapeLeft();
    } else if (orientationValue == FlutterScreenOrientation.landscapeRight) {
      await orientationLandscapeRight();
    }
  }
}
