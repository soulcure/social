import 'dart:async';
import 'dart:io';

import 'package:fb_live_flutter/live/api/fblive_model.dart';
import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/other/float/float_mode.dart';
import 'package:fb_live_flutter/live/utils/other/float/float_preview_mode.dart';
import 'package:fb_live_flutter/live/widget_common/dialog/sw_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import 'float_plugin.dart';

class FloatUtil {
  /// 1。是否已有弹窗显示，防止多个重叠；
  /// 2。是否去设置悬浮窗权限了，如果是则不再弹出申请授权提示；
  static bool isHaveFloatPermission = false;

  /// 是否进行中【防多次点击】
  static bool isProgress = false;

  /*
  * 显示悬浮窗
  * */
  static Future showFloat(
    BuildContext? context,
    String? roomId, {
    bool isPop = false,
    required final bool isObs,
    final bool? isShowClose,
    final ZegoViewMode? zegoViewMode,
    required bool isOutsideApp,
    required LiveValueModel liveValueModel,
  }) async {
    if (Platform.isIOS) {
      return;
    }

    /// 操作太快防止原生层没响应过来，以为isFloat为true，然后直接【已经显示小窗口】返回了
    await Future.delayed(const Duration(milliseconds: 300));

    await reqPermission(context, roomId == null, false,
        onHavePermission: () async {
      if (zegoViewMode != null) {
        liveValueModel.zegoViewMode = zegoViewMode;
      }
      try {
        if (!RouteUtil.routeIsLive || isOutsideApp) {
          await FloatPlugin.open(roomId, liveValueModel.isScreenSharing, isObs,
              isShowClose, liveValueModel.zegoViewMode, liveValueModel);

          await Future.delayed(const Duration(milliseconds: 100))
              .then((value) async {
            if (RouteUtil.routeIsLive) {
              await FloatUtil.dismissFloat(0);
            }
          });
        }
      } catch (e) {
        fbApi.fbLogger.warning('open float window failed');
      }
    }, isPop: isPop);
  }

  /*
  * 显示悬浮窗[预览]
  * */
  static Future showPreviewFloat(
      BuildContext context, bool isOutsideApp) async {
    if (Platform.isIOS) {
      return;
    }

    /// 防止RouteUtil.routeIsPreview没反应过来
    await Future.delayed(const Duration(milliseconds: 200));

    await reqPermission(context, true, true, onHavePermission: () async {
      try {
        if (!RouteUtil.routeIsPreview || isOutsideApp) {
          await FloatPlugin.openPreview();
        }
      } catch (e) {
        fbApi.fbLogger.warning('open preview failed');
      }
    }, isPop: true);
  }

  /*
  * 请求权限
  *
  * onHavePermission：有权限时所做的事情
  * */
  static Future reqPermission(
      BuildContext? context, bool isAnchor, bool isPreview,
      {VoidCallback? onHavePermission, bool isPop = false}) async {
    if (Platform.isIOS) {
      return;
    }
    final isRequestFloatPermission = await FloatPlugin.isRequestFloatPermission;
    if (isRequestFloatPermission ?? false) {
      if (onHavePermission != null) {
        onHavePermission();
      }
    } else {
      /// 【悬浮窗权限跳转与判断】
      ///
      ///
      /// 怎么做【逻辑】？
      /// 1。如果未开启则弹出【浮窗权限未获取】提示；
      /// 2。点击【开启】跳转到权限设置页面且不关闭对话框；
      ///
      /// 3。当用户开启后返回到app进行判断，
      ///    如开启则：销毁提示且显示悬浮窗；
      ///    如未开启：弹出开启失败提示；
      ///
      /// 4。当用户不开启【弹出对话框直接系统返回键】；
      ///    直接处理没有开启的逻辑，不延时操作，防止出现悬浮窗实体没有被销毁，
      ///    然后进入直播间直接打开了悬浮窗的实体，但引擎被销毁了，所以画面卡住。
      ///
      ///
      /// 怎么做【技术】？
      /// 1。[confirmSwDialog]传`isOkPop`为`false`，点击确定就不销毁对话框了；
      /// 2。在[confirmSwDialog]新增判断app生命周期回调，给外部进行使用；
      ///
      ///
      /// 有没有更好的方案？
      /// 目前来看没有更好的。
      ///
      ///
      /// 会影响哪些地方？
      /// 1。【APP】不开启浮窗权限，再次进入该直播间卡住
      ///   解释：不开启=系统返回键关闭对话框
      /// 2。【APP】安卓开启浮窗权限之后返回APP还是弹出浮窗权限通知
      ///
      ///
      /// 有哪些需要注意的点？
      /// 1。授权悬浮成功后悬浮窗画面显示；
      /// 2。保证系统键返回后下次还能打开授权对话框；
      /// 3。【主播/观众】在【直播间/预览页面】内返回到app外尝试【不开启/开启】权限；

      if (!isHaveFloatPermission) {
        isHaveFloatPermission = true;
        try {
          /// 【2021 12.08】修复上下文错误导致【浮窗权限对话框】未显示
          await confirmSwDialog(fbApi.globalNavigatorKey.currentContext,
              text: "你的手机没有授权获得浮窗权限，直播最小化不能正常使用。",
              title: "浮窗权限未获取",
              contentStyle:
                  TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 14),
              onPressed: FloatPlugin.requestPermission,
              okText: "开启",
              isHaveCancel: false,
              isOkPop: false, onWillPop: () async {
            /// 授权成功返回时
            if ((await FloatPlugin.isRequestFloatPermission) ?? false) {
              if (onHavePermission != null) {
                onHavePermission();
              }
            } else if (!isAnchor || isPreview) {
              /// 不包含直播间和预览
              if (!RouteUtil.routeHasLive && !RouteUtil.routeHasPreView) {
                if (!isPreview) {
                  if (isPop) {
                    floatWindow.closeFloatUIAndEngine();
                  } else {
                    floatWindow.closeFloatUI();
                  }
                } else {
                  if (isPop) {
                    floatPreViewWindow.closeFloatUIAndEngine();
                  } else {
                    floatPreViewWindow.closeFloatUI();
                  }
                }
              }
            }
            return true;
          }, callAppState: (state) async {
            if (state == AppLifecycleState.resumed) {
              if ((await FloatPlugin.isRequestFloatPermission) ?? false) {
                RouteUtil.pop();
                if (onHavePermission != null) {
                  onHavePermission();
                }
              } else {
                /// 未开启悬浮窗权限
              }
            }
          });

          /// 【APP】无小窗口，也无获取浮窗权限提示
          /// 保证系统键返回后下次还能打开授权对话框
          print("权限对话框关闭，isHaveFloatPermission设置为false");
          isHaveFloatPermission = false;
        } catch (e) {
          isHaveFloatPermission = false;
        }
      }
    }
  }

  /// 点击悬浮窗
  // ignore: type_annotate_public_apis
  static void clickFloat(event) {
    /// 悬浮窗防多次点击
    if (isProgress) {
      return;
    }
    isProgress = true;
    Future.delayed(const Duration(milliseconds: 600)).then((value) {
      isProgress = false;
    });

    if (event.toString().contains("preViewLaunchApp")) {
      /// 需要判断路由名当前是否为预览页面
      /// 不是且不包含预览路由页面的话跳转
      /// 不是且包含预览路由页面的话返回
      if (!RouteUtil.routeHasPreView) {
        floatPreViewWindow.pushToPreView();
      }
      return;
    }
    if (event.toString().contains("preViewClick")) {
      /// 点击了直播预览页面小窗口
      floatPreViewWindow.pushToPreView();
      return;
    }
    if (event.toString().contains("checkFloat")) {
      /// 再次检测悬浮窗是否关闭，如果没有关闭则关闭

      /// 【2021 12.08】
      /// 修复小窗口打不开与打开直播间后小窗还在
      ///
      /// 问题原因：
      /// 打开直播间后直播间检测到app生命周期恢复后未执行到关闭小窗口,
      /// didChangeAppLifecycleState有执行到恢复，
      FloatUtil.dismissFloat(0);
      return;
    }
    if (event.toString().contains("preViewClose")) {
      floatPreViewWindow.close();
      return;
    }
    if (event.toString().contains("launchApp")) {
      /// 跳转直播页面
      floatWindow.pushToLive(FBLiveEvent.fullscreen);
      return;
    }
    if (event == "close") {
      floatWindow.close();
      return;
    }

    /// 跳转直播页面
    floatWindow.pushToLive(FBLiveEvent.fullscreen);
  }

  static Future<int> pushToPreView(final LiveValueModel? liveValueModel) async {
    if (!floatPreViewWindow.isHaveFloat) {
      return 0;
    }
    floatPreViewWindow.pushToPreView();
    return 1;
  }

  /*
  * 关闭小窗方法，Android和iOS通用
  * */
  static Future dismissFloat(int milliseconds, {VoidCallback? onThen}) async {
    await Future.delayed(Duration(milliseconds: milliseconds));

    if (Platform.isIOS) {
      /// 【iOS】修复小窗进入直播间小窗口还存在
      floatWindow.closeFloatUI();
      return;
    }

    final value = await FloatPlugin.isRunningForeground;

    /// 如果app是在前台
    if (value ?? false) {
      /// 如果显示悬浮窗中
      final isShow = await FloatPlugin.isShowFloat;

      if (isShow ?? false) {
        if (onThen != null) {
          onThen();
        }
        await FloatPlugin.dismiss();
      }
    }
    return;
  }
}
