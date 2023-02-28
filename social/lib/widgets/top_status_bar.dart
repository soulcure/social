import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/util_api.dart';
import 'package:im/app.dart';
import 'package:im/loggers.dart';
import 'package:im/services/connectivity_service.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/ws/ws.dart';

///顶部状态栏显示的级别： netWorkOff > webSocketOffLine > loadingMessage > veryWell
enum TopStatusBarEvent {
  netWorkOff, //网络连接断开
  webSocketOffLine, //webSocket连接断开
  loadingMessage, //正在加载未读消息
  veryWell, //没有异常
}

///顶部状态栏-工具
class TopStatusController extends GetxController {
  TopStatusBarEvent topStatusBarEvent = TopStatusBarEvent.veryWell;

  StreamSubscription _connectivityStatusStreamSubscription;
  ConnectivityResult _curConnectivityStatus = ConnectivityResult.wifi;

  WsConnectionStatus _wsConnectionStatus = WsConnectionStatus.connected;

  bool _isLoadingMessage = false;
  bool _firstInit = true;
  bool _delayRefresh = false;
  bool _isWaitingForUpdateUI = false;
  int _currentDelay = 0;

  Timer _delayUpdateUITimer;
  ValueNotifier<bool> showStatusUI = ValueNotifier(false);

  static TopStatusController to() {
    TopStatusController c;
    try {
      c = Get.find<TopStatusController>();
    } catch (_) {}
    return c ?? Get.put(TopStatusController());
  }

  TopStatusController() {
    _curConnectivityStatus = Get.find<ConnectivityService>().state;
    _connectivityStatusStreamSubscription = Get.find<ConnectivityService>()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);
    _onConnectivityChanged(_curConnectivityStatus);

    _wsConnectionStatus = Ws.instance.connectionStatus.value;
    Ws.instance.connectionStatus.addListener(_onWsStatusChange);
    _onWsStatusChange();
  }

  @override
  void onClose() {
    _delayUpdateUITimer?.cancel();
    Ws.instance.connectionStatus.removeListener(_onWsStatusChange);
    _connectivityStatusStreamSubscription.cancel();
    super.onClose();
  }

  void refreshStatus({bool delay = false}) {
    logger.info('TopStatusController refreshStatus');
    _delayRefresh = delay;
    _onWsStatusChange();
    _onConnectivityChanged(Get.find<ConnectivityService>().state);
  }

  void startLoadingMessage() {
    _isLoadingMessage = true;
    _caculateCurrentTopBarEvent();
  }

  void endLoadingMessage() {
    _isLoadingMessage = false;
    _caculateCurrentTopBarEvent();
  }

  void _onWsStatusChange() {
    _wsConnectionStatus = Ws.instance.connectionStatus.value;
    // logger.info(
    //     'TopStatusController _onWsStatusChange _wsConnectionStatus:$_wsConnectionStatus');
    _caculateCurrentTopBarEvent();
  }

  Future _onConnectivityChanged(ConnectivityResult result) async {
    ConnectivityResult tmp = result;
    if (tmp == ConnectivityResult.none) {
      try {
        final available = await UtilApi.postNetWorkIsAvailabel()
            .timeout(const Duration(seconds: 3));
        tmp = available ? ConnectivityResult.mobile : result;
      } catch (e) {
        tmp = result;
      }
    }
    _curConnectivityStatus = tmp;
    logger.info(
        'TopStatusController _onConnectivityChanged _curConnectivityStatus:$_curConnectivityStatus');
    _caculateCurrentTopBarEvent();
  }

  /// 顶部状态栏显示的级别： netWorkOff > webSocketOffLine > loadingMessage > veryWell
  ///
  /// 如果用户打开了网络，会从网络异常变成连接中 websocketoffline
  /// 等待 ws 连接上后，变成 verywell
  /// 如果用户是关闭了网络，则是立刻显示 ConnectivityErrorBar
  ///
  /// 用户刚进入APP,延时2s显示连接中
  ///
  /// 目前有几部 HUAWEI 设备，即使连接上了网络，也不会触发 Connectivity 的事件
  /// 因此通过 ws 连接上的方式隐藏错误提示
  /// 先加上，不一定有效，因为如果无网络，不会进行重连尝试
  ///
  /// 断开 ws 连接后，10s 内没有连接上，才显示
  ///
  /// Connectivity 有BUG，
  /// 在华为手机上在移动网络下打开代理，
  /// 会有_connectionType == ConnectivityResult.none但是实际网络是正常的情况。
  ///
  void _caculateCurrentTopBarEvent() {
    if (App.appLifecycleState != AppLifecycleState.resumed) return;
    int delay;
    if (_curConnectivityStatus == ConnectivityResult.none) {
      delay = _firstInit ? 10 : 0;
    } else if (_wsConnectionStatus == WsConnectionStatus.connecting ||
        _wsConnectionStatus == WsConnectionStatus.disconnected) {
      delay = 10;
    } else if (_isLoadingMessage) {
      delay = (_firstInit || _delayRefresh) ? 10 : 2;
    } else {
      delay = _firstInit ? 10 : 0;
    }
    if (_isWaitingForUpdateUI && delay >= _currentDelay) return;
    _isWaitingForUpdateUI = true;
    _currentDelay = delay;

    logger
        .info('TopStatusController before topStatusBarEvent $topStatusBarEvent '
            '_wsConnectionStatus $_wsConnectionStatus '
            '_curConnectivityStatus:$_curConnectivityStatus '
            'showStatusUI:${showStatusUI.value}');
    _delayUpdateUITimer?.cancel();
    _delayUpdateUITimer = Timer(Duration(seconds: _currentDelay), () {
      _firstInit = false;
      _delayRefresh = false;
      _isWaitingForUpdateUI = false;
      if (_curConnectivityStatus == ConnectivityResult.none) {
        topStatusBarEvent = TopStatusBarEvent.netWorkOff;
      } else if (_wsConnectionStatus == WsConnectionStatus.connecting ||
          _wsConnectionStatus == WsConnectionStatus.disconnected) {
        topStatusBarEvent = TopStatusBarEvent.webSocketOffLine;
      } else if (_isLoadingMessage) {
        topStatusBarEvent = TopStatusBarEvent.loadingMessage;
      } else {
        topStatusBarEvent = TopStatusBarEvent.veryWell;
      }
      showStatusUI.value = topStatusBarEvent != TopStatusBarEvent.veryWell;
      update();
      logger.info(
          'TopStatusController after topStatusBarEvent $topStatusBarEvent '
          '_wsConnectionStatus $_wsConnectionStatus'
          ' _curConnectivityStatus:$_curConnectivityStatus '
          ' showStatusUI:${showStatusUI.value}');
    });
  }
}

///首页顶部状态栏（包括：网络连接状态，ws连接状态，消息加载状态）
class TopStatusBar extends StatefulWidget {
  static const height = 17;

  @override
  _TopStatusBarState createState() => _TopStatusBarState();
}

class _TopStatusBarState extends State<TopStatusBar> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<TopStatusController>(builder: (c) {
      final status = c.topStatusBarEvent;
      if (status == null ||
          status == TopStatusBarEvent.veryWell ||
          !c.showStatusUI.value) return const SizedBox();
      final iconColor = status == TopStatusBarEvent.netWorkOff
          ? CustomColor.red
          : Colors.grey;
      String text = '';
      switch (status) {
        case TopStatusBarEvent.netWorkOff:
          text = "网络异常，请检查网络".tr;
          break;
        case TopStatusBarEvent.webSocketOffLine:
          text = "连接中...".tr;
          break;
        case TopStatusBarEvent.loadingMessage:
          text = "收取中...".tr;
          break;
        default:
          text = "";
          break;
      }
      return Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        alignment: Alignment.topCenter,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.signal_cellular_alt_rounded,
              size: 12,
              color: iconColor,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
    });
  }
}
