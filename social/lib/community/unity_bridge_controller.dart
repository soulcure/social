import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_unity/flutter_unity.dart';
import 'package:im/community/unity_bridge_with_common.dart';
import 'package:im/community/unity_bridge_with_interactive_entity.dart';
import 'package:im/community/unity_bridge_with_link.dart';
import 'package:im/community/unity_bridge_with_living.dart';
import 'package:im/community/unity_bridge_with_webrtc.dart';
import 'package:im/loggers.dart';
import 'package:im/routes.dart';
import 'package:pedantic/pedantic.dart';
import 'package:wakelock/wakelock.dart';

enum UnityViewPageProgress {
  LOADING,
  SHOWING,
  UNLOADING,
}

class _UnityBridgeCallData {
  String methodName;
  String message;
  Completer completer;
}

abstract class UnityBridgeWithPartial {
  final UnityBridgeController unityBridgeController;
  UnityBridgeWithPartial(this.unityBridgeController);

  bool handleUnityMessage(
      String messageId, String method, Map<String, String> parameters);
  Future<void> destroy();
}

class UnityBridgeController with WidgetsBindingObserver {
  final BuildContext _context;
  UnityViewController _unityViewController;
  ValueNotifier<UnityViewPageProgress> unityViewPageProgress =
      ValueNotifier(UnityViewPageProgress.LOADING);
  final List<_UnityBridgeCallData> _unityCallDataList =
      <_UnityBridgeCallData>[];
  BuildContext get context => _context;

  static bool _isFirstStartup = true;
  static bool _isCommunityRunning = false;

  bool get isFirstStartup => _isFirstStartup;
  bool get isCommunityRunning => _isCommunityRunning;

  final List<UnityBridgeWithPartial> _bridgePartials =
      <UnityBridgeWithPartial>[];

  UnityBridgeController(this._context) {
    WidgetsBinding.instance.addObserver(this);

    _bridgePartials.add(UnityBridgeWithCommon(this));
    _bridgePartials.add(UnityBridgeWithWebRTC(this));
    _bridgePartials.add(UnityBridgeWithLiving(this));
    _bridgePartials.add(UnityBridgeWithInteractiveEntity(this));
    _bridgePartials.add(UnityBridgeWithLink(this));

    Wakelock.enable();
  }

  void setUnityViewController(UnityViewController controller) {
    _unityViewController = controller;

    if (_isFirstStartup) {
      _isFirstStartup = false;
      _unityViewController?.resume();
    } else {
      _unityViewController?.resume();
      _unityViewController?.send("Engine", "EnterCommunity", "");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _unityViewController?.resume();
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        _unityViewController?.pause();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  void onUnityMessage(String message) {
    final Map<String, String> parameters =
        Map<String, String>.from(jsonDecode(message));
    final String messageId = parameters["messageId"];
    final String method = parameters["method"];
    _handleUnityMessage(messageId, method, parameters);
  }

  void _handleUnityMessage(
      String messageId, String method, Map<String, String> parameters) {
    switch (method) {
      case "CompleteEnter":
        unityViewPageProgress.value = UnityViewPageProgress.SHOWING;
        _isCommunityRunning = true;
        break;
      case "PrepareQuit":
        unityViewPageProgress.value = UnityViewPageProgress.UNLOADING;
        break;
      case "QuitCommunity":
        _unityViewController?.pause();
        Routes.pop(_context);
        _isCommunityRunning = false;
        break;
      default:
        //具体功能逻辑分拆到相应桥阶层处理
        bool isProcessed = false;
        for (int i = 0; i < _bridgePartials.length; i++) {
          if (_bridgePartials[i]
              .handleUnityMessage(messageId, method, parameters)) {
            isProcessed = true;
            break;
          }
        }
        //Notify开头的方法名表示Flutter调用Unity的回调通知
        if (!isProcessed && method.startsWith("Notify")) {
          _onCallUnityComplete(parameters);
          isProcessed = true;
        }
        if (!isProcessed) {
          logger.warning('虚拟社区Unity通知Flutter消息未处理');
        }
        break;
    }
  }

  void unityCallback(String messageId, Map<String, String> parameters) {
    parameters["messageId"] = messageId;
    sendToUnity("HandleCallbacks", jsonEncode(parameters));
  }

  void sendToUnity(String methodName, String message) {
    _unityViewController?.send("Engine", methodName, message);
  }

  /// Flutter调用Unity等待结果的函数需要排队处理
  Future<Map<String, String>> callUnity(
      String methodName, String message) async {
    final _UnityBridgeCallData data = _UnityBridgeCallData();
    data.methodName = methodName;
    data.message = message;
    data.completer = Completer<Map<String, String>>();
    _unityCallDataList.add(data);
    if (_unityCallDataList.length == 1) {
      sendToUnity(methodName, message);
    }
    final Map<String, String> result = await data.completer.future;
    return result;
  }

  void _onCallUnityComplete(Map<String, String> parameters) {
    if (_unityCallDataList == null || _unityCallDataList.isEmpty) {
      return;
    }
    final _UnityBridgeCallData data = _unityCallDataList.removeAt(0);
    data.completer.complete(parameters);
    if (_unityCallDataList.isNotEmpty) {
      sendToUnity(
          _unityCallDataList[0].methodName, _unityCallDataList[0].message);
    }
  }

  Future<void> dispose() async {
    unawaited(Wakelock.disable());
    WidgetsBinding.instance.removeObserver(this);
    for (int i = _bridgePartials.length - 1; i >= 0; i--) {
      await _bridgePartials[i].destroy();
    }
    _bridgePartials.clear();
  }
}
