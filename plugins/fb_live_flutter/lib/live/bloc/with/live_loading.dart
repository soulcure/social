import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fb_live_flutter/live/event_bus_model/refresh_room_list_model.dart';
import 'package:fb_live_flutter/live/pages/live_room/interface/live_interface.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/live_status_enum.dart';
import 'package:fb_live_flutter/live/utils/manager/event_bus_manager.dart';
import 'package:fb_live_flutter/live/utils/other/fb_api_model.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/dialog_util.dart';
import 'package:fb_live_flutter/live/utils/ui/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';

class LiveNetErrorLogic {
  /// 网络检测相关
  bool isNetError = false;
  int netErrorCount = 0;
  Timer? netErrorTimer;

  /*
  * 网路异常计时器取消
  * */
  void netErrorTimerCancel() {
    netErrorCount = 0;
    netErrorTimer?.cancel();
    netErrorTimer = null;
  }

  /*
  * 网路异常计时器开始
  * */

  /// 好的，那需求调整一下：如何出现的是1002051的错误代码，
  /// 就可以延后15秒再提示“网络连接不稳定，正在重新连接”， 15秒内连接成功后，不提示内容。
  /// 【2021 11.7】
  void netErrorStart({VoidCallback? onComplete, bool isMinute = false}) {
    netErrorTimerCancel();
    if (isMinute) {
      netErrorCount = 60;
    } else {
      netErrorCount = 15;
    }
    netErrorTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (netErrorCount > 0) {
        netErrorCount--;
        return;
      }
      netErrorTimerCancel();
      if (onComplete != null) {
        onComplete();
      }
    });
  }
}

class LiveOutSyncLogic {
  /// 音频画面异常【不同步】检测相关
  bool isOutSyncError = false;
  int outSyncCount = 0;
  Timer? outSyncTimer;

  /*
  * 音频画面异常计时器取消
  * */
  void outSyncCancel() {
    outSyncCount = 0;
    outSyncTimer?.cancel();
    outSyncTimer = null;
  }

  /*
  * 画面不同步异常计时器开始
  * */
  void outSyncErrorStart({VoidCallback? onComplete}) {
    outSyncCancel();
    outSyncCount = 10;
    outSyncTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (outSyncCount > 0) {
        outSyncCount--;
        return;
      }
      outSyncCancel();
      if (onComplete != null) {
        onComplete();
      }
    });
  }
}

abstract class LiveLoadInterface {
  // 上下文
  BuildContext? context;

  //是否是主播
  late bool isAnchor;

  // 获取房间信息
  Future getRoomInfo();

  // 返回上一页
  void goBack();

  /// 主动关闭直播【无论主播还是观众都是用这个】
  bool isProactiveClose = false;

  Loading? _loading;

  bool isEnterSuccess = false;
  bool fanBookClose = false;

  void netConnect();

  final Connectivity connectivity = Connectivity(); //网络监测

  Future<String> initConnectivity();

  bool get mounted;

  void showConfirmDialog(Function _callback);

  Future<String> updateConnectionStatus(ConnectivityResult result);

  void closeLoading();

  void openLoading(String text,
      {int width = 150, int height = 130, Function? callback});
}

mixin LiveLoadWith on LiveLoadInterface, LiveInterface {
  // 初始化loading
  @override
  void openLoading(String text,
      {int width = 150, int height = 130, Function? callback}) {
    myLoadingToast(
      tips: text,
      onComplete: () {
        if (callback != null) {
          callback();
          return;
        }

        /// 【2022 02 25】
        /// 使用Loading内的，使对话框可被closeLoading关闭
        Loading.connectionFailureTip(context, isAnchor,
            onPressed: getRoomInfo, onCancel: goBack);
      },
      duration: const Duration(minutes: 20),
    );
  }

  // 返回上一页
  @override
  void goBack() {
    isProactiveClose = true;
    closeLoading();

    /// 保证当前页面是直播页面
    /// 【APP】主播直播结束观众小窗口下点击直播间封面返回直播间，画面会卡住
    Future.delayed(Duration.zero).then((value) {
      RouteUtil.popToLive();
    });

    if (!fanBookClose) {
      // 由于直播内容违规，直播已被系统禁播。如果有疑问，请联系管理员
      /// 【2022 0124】直接把调用 这个backToLiveRoomList的地衣改成Get.back()
      // fbApi.backToLiveRoomList(context: context);

      /// 延迟200毫秒防止前面的pop没执行完，RouteUtil.routeHasLive没及时变更。
      Future.delayed(const Duration(milliseconds: 100)).then((value) {
        /// 【2022 02.25】防止popToLive时某个pop附带了pop，导致多pop了；
        if (RouteUtil.routeHasLive) {
          Get.back();
        }
      });

      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    }
  }

  /// 15秒计时显示轻提示，直到1002052和1002053退出时才出现重提示。15秒计时器，在1002051改变时需要清除计时器。
  void showConfirmDialogNew() {
    showConfirmDialog(() {
      Loading.showConfirmDialogNew(context, onCancel: goBack, onPressed: () {
        connectivity.checkConnectivity().then((value) {
          final ConnectivityResult connectivityResult = value;
          if (connectivityResult == ConnectivityResult.none) {
            netConnect();
          }
        });
      });
    });
  }

  @override
  void netConnect() {
    /// 网络连接不稳定，\n正在重新连接 [旧版提示] 2021 10.28
    openLoading('网络不稳定，请检查网络。', width: 160, height: 170, callback: () {
      // showConfirmDialogNew();
    });
  }

  // 关闭loading
  @override
  void closeLoading() {
    isEnterSuccess = true;
    Loading.cancelLoadingTimer();
    Loading.cleanContext();
    if (_loading != null) {
      _loading!.dismiss();
    }
    dismissAllToast();
  }

  // 开启showConfirmDialog
  @override
  void showConfirmDialog(Function _callback) {
    closeLoading();
    _callback();
  }

  // 初始化网络状态
  @override
  Future<String> initConnectivity() async {
    final Completer<String> completer = Completer();
    ConnectivityResult result = ConnectivityResult.none;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await connectivity.checkConnectivity();
    } on PlatformException catch (_) {}

    if (!mounted) {
      completer.complete('none');
    }

    await updateConnectionStatus(result).then(completer.complete);

    return completer.future;
  }

  // 获取网络状态
  @override
  Future<String> updateConnectionStatus(ConnectivityResult result) {
    final Completer<String> completer = Completer();
    switch (result) {
      case ConnectivityResult.wifi:

        /// 没明白为什么使用此方法，已经影响了初始化的连接中提示
        /// 【2022 02.25】可能之前是网络变化后需要隐藏"加载中"提示，
        // dismissAllToast();
        completer.complete('wifi');
        break;
      case ConnectivityResult.mobile:

        /// 没明白为什么使用此方法，已经影响了初始化的连接中提示
        /// 【2022 02.25】可能之前是网络变化后需要隐藏"加载中"提示，
        // dismissAllToast();
        completer.complete('mobile');
        break;
      case ConnectivityResult.none:
        completer.complete('none');
        break;
      default:
        completer.complete('fail');
        break;
    }
    return completer.future;
  }

  /*
  * 检测直播状态
  * */
  bool checkLiveStatus(
      {VoidCallback? navigatorToAudienceClosePage,
      required VoidCallback anchorCloseRoomHandle}) {
    if (liveValueModel!.liveStatus == LiveStatus.abnormalLogin) {
      Future.delayed(Duration.zero).then((value) {
        showConfirmDialog(() {
          RouteUtil.popToLive();
          Loading.showConfirmDialog(context!, {
            'content': '你的账号当前在另一台设备中登录，如果这不是你本人的操作，请立刻重新登录修改密码',
            'confirmText': '退出',
            'cancelShow': false
          }, () {
            goBack();
            EventBusManager.eventBus.fire(RefreshRoomListModel(true));
          });
        });
      });
      return true;
    } else if (liveValueModel!.liveStatus == LiveStatus.anchorViolation) {
      FbApiModel.violationsAction(getRoomInfoObject!.roomId);

      Future.delayed(Duration.zero).then((value) {
        /// 主要为了解决列表时还弹出提示【禁播提示】
        ///
        /// [anchorCloseLiveActively]是为了防止出现已经在执行主动关闭了还执行被动关闭，
        /// 但这是初始化检测，根本来不及主动点关闭直播，所以不需要使用[anchorCloseLiveActively]
        if (!mounted || !RouteUtil.routeHasLive) {
          return;
        }

        /// 取消掉原有的重提示再显示被禁播的重提示，如以下场景：
        ///   1.点击结束直播按钮还没点确定；
        ///   2.禁播提示弹出覆盖1的提示；
        showConfirmDialog(() {
          Loading.liveWillClose(context, onPressed: () {
            if (isAnchor) {
              anchorCloseRoomHandle();
            } else {
              goBack();
              EventBusManager.eventBus.fire(RefreshRoomListModel(true));
            }
          });
        });
      });
      return true;
    } else if (liveValueModel!.liveStatus == LiveStatus.anchorClosesLive) {
      // todo 【2022 0205】 可能忘记取反了，需要测试后再改，估算影响范围
      if (isAnchor) {
        navigatorToAudienceClosePage!();
        return true;
      } else {
        return false;
      }
    } else if (liveValueModel!.liveStatus == LiveStatus.kickOutServer) {
      Future.delayed(Duration.zero).then((value) {
        DialogUtil.kickOutServerClose(context, isAnchor, onPressed: () {
          goBack();
          EventBusManager.eventBus.fire(RefreshRoomListModel(true));
        });
      });
      return true;
    }
    return false;
  }
}
