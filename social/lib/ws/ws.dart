import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/task_bean.dart';
import 'package:im/api/util_api.dart';
import 'package:im/app.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/app/modules/manage_guild/models/ban_type.dart';
import 'package:im/app/modules/mute/controllers/mute_listener_controller.dart';
import 'package:im/app/modules/task/task_util.dart';
import 'package:im/db/guild_table.dart';
import 'package:im/global.dart';
import 'package:im/pages/guild_setting/circle/entry/circle_entry_handler.dart';
import 'package:im/pages/guild_setting/guild/quit_guild.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/action_processor/av_call.dart';
import 'package:im/pages/home/model/action_processor/channel_status.dart';
import 'package:im/pages/home/model/action_processor/circle.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/model/text_channel_util.dart';
import 'package:im/pages/logging/let_log.dart';
import 'package:im/routes.dart';
import 'package:im/services/connectivity_service.dart';
import 'package:im/services/server_side_configuration.dart';
import 'package:im/utils/debug_flag.dart';
import 'package:im/web/utils/decode_ws_data.dart';
import 'package:im/ws/bot_setting_handler.dart';
import 'package:im/ws/live_status_handler.dart';
import 'package:im/ws/message_card_handler.dart';
import 'package:im/ws/pin_handler.dart';
import 'package:im/ws/tc_doc_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/config.dart';
import '../loggers.dart';
import 'guild_notice_handler.dart';

class Connected {}

class Disconnected {}

class UnreadMessage {
  String channelId;
  String guildId;
  String readId;
  int unRead;

  UnreadMessage(this.channelId, this.guildId, this.readId, this.unRead);
}

class OnlineMessage {
  int online;

  OnlineMessage(this.online);
}

const pushMainPlatform = MethodChannel('buff.com/ws');

class WsMessage {
  String action;
  dynamic data;

  WsMessage(this.action, this.data);
}

enum WsConnectionStatus {
  disconnected,
  connecting,
  connected,
}

class Ws extends EventBus {
  static const pingInterval = Duration(seconds: 25);
  static Ws instance;
  static int _retryReconnectTime = 5;

  // 只有第一次主动连接后才考虑重连,不然在注册完成填写信息界面前后台切换会重连从而导致填写完信息进入homepage异常.
  // 原因是注册完成后就拿到了token满足了重连条件,但实际上只有进入了homepage才考虑重连.
  static bool _canReconnect = false;

  /// 服务器时间 是十位单位秒
  static int serverTime = -1;

  /// 服务器时间与本地时间差值，用于本地时间不正确时，修正文件上传签名时间
  static int differenceTime = 0; //serverTime - localTime

  // ignore: avoid_annotating_with_dynamic
  static Map<String, void Function(dynamic)> actionProcessor = {
    MessageAction.callNotice: AVCall.process,
    MessageAction.guildNotice: guildNoticeHandler,
    MessageAction.channelStatus: onChannelStatus,
    MessageAction.channelNotice: onChannelNotice,
    MessageAction.pin: pinHandler,
    MessageAction.notPull: TextChannelUtil.notPullHandler,
    MessageAction.botSetting: botSettingHandler,
    MessageAction.voiceStateUpdate: onVoiceStateUpdate,
    MessageAction.liveStatusUpdate: liveStatusHandler,
    MessageAction.circleEnter: circleEntryHandler,
    MessageAction.circlePost: circlePostHandler,
    MessageAction.handleNonEntity: nonEntityHandler,
  };

  static final Map<int, Completer<dynamic>> _completerMap = {};
  static int __messageSequence = 0;

  static int get messageSequence => __messageSequence++;

  ConnectivityResult _connectionType;

  WebSocketChannel _channel;
  StreamSubscription _webSocketChannelSubscription;
  ValueNotifier<WsConnectionStatus> connectionStatus =
      ValueNotifier(WsConnectionStatus.disconnected);
  Timer _pingTimer;

  // 如果正在重连中则不考虑重连.不用connectionStatus来判断的原因是connect方法调用前会判断是否满足重连条件.
  // 而此操作是耗时操作,会导致connectionStatus延时更新,
  // 如果方法在此时被第二次调用(双卡双待手机WiFi断开会导致调用多次_listenConnectivity),则会导致两次connect
  // 而此属性只会在connect方法开始的时候置为true,结束置为false.
  bool _isConnecting = false;

  ///ws连接超时检查-定时器
  Timer _connectTimer;

  Ws() {
    final connectivityService = Get.find<ConnectivityService>();
    _connectionType = connectivityService.state;
    connectivityService.onConnectivityChanged.listen(_listenConnectivity);
    pushMainPlatform.setMethodCallHandler(handlePushCall);
    _startPing();
  }

  Future<dynamic> handlePushCall(MethodCall methodCall) {
    if (methodCall.method == "ws_close") {
      logger.warning("disconnected ws by app suspend.");
      _close();
      return Future.value(true);
    } else if (methodCall.method == "ws_reconnect") {
      _reconnect();
      return Future.value(true);
    }
    return Future.value(false);
  }

  void _listenConnectivity(ConnectivityResult state) {
    logger.info("Network has change, status: $state");
    _connectionType = state;

    ///fix: ios 打开飞行模式再关闭，不发起重连和请求notPull
    if (state == ConnectivityResult.none) {
      connectionStatus.value = WsConnectionStatus.disconnected;
    }

    _reconnect();
  }

  /// 开始连接 WS，必须在获取到用户当前 Token 之后，连接参数中会去获取 [Global.token]
  Future<void> connect() async {
    if (_isConnecting) return;
    _isConnecting = true;
    try {
      _canReconnect = true;
      final canTryToConnectWs = await _canTryToConnectWs();
      logger.warning("start connect");
      if (canTryToConnectWs) {
        connectionStatus.value = WsConnectionStatus.connecting;
        logger.warning("disconnected ws by connect.");
        _close();
      } else {
        logger.warning("_canTryToConnectWs false.");
        _isConnecting = false;
        return;
      }

      /// app版本号
      final version = Global.packageInfo?.version ?? '';
      final buildNumber = Global.packageInfo?.buildNumber ?? '';
      final channel = Config.channel;
      final platform = Global.deviceInfo.systemName.toLowerCase();
      final deviceId = Global.deviceInfo.identifier;

      final headerMap = {
        'platform': platform ?? '',
        'version': version ?? '',
        'channel': channel ?? '',
        'device_id': deviceId ?? '',
        'build_number': buildNumber ?? '',
      };

      final jsonString = jsonEncode(headerMap);
      final content = utf8.encode(jsonString);
      final base64String = base64Encode(content);

      final queryParameters = {
        "id": Config.token,
        "dId": deviceId,
        "v": kIsWeb ? "1.6.2" : version,
        'x-super-properties': base64String,
      };

      logger.info("Try to connecting to web socket...");
      final baseUri = Uri.parse("ws://${Config.wsUri}");

      _channel = WebSocketChannel.connect(Uri(
          scheme: Config.useHttps ? "wss" : "ws",
          host: baseUri.host,
          path: baseUri.path,
          queryParameters: queryParameters));

      checkConnectTimeout();
      _webSocketChannelSubscription = _channel.stream
          .listen(_onServerMessage, onError: _onError, onDone: _onDone);
    } catch (e) {
      logger.info(e.toString());
    } finally {
      _isConnecting = false;
    }
  }

  /// ws发起连接后等待20秒，未收到回调，则主动重连
  void checkConnectTimeout() {
    _connectTimer?.cancel();
    _connectTimer = Timer(const Duration(seconds: 20), () {
      logger.info('ws发起连接后等待20秒，未收到回调，则主动重连');
      if (!kIsWeb) {
        connectionStatus.value = WsConnectionStatus.disconnected;
        _reconnect();
      }
    });
  }

  /// 关闭 WS 连接
  void close() {
    _canReconnect = false;
    _close();
  }

  void _close() {
    fire(Disconnected());
    _webSocketChannelSubscription?.cancel();
    _channel?.sink?.close();
    connectionStatus.value = WsConnectionStatus.disconnected;
  }

  Future<dynamic> send(Map data) {
    try {
      final seq = messageSequence;
      data["seq"] = seq;
      data["app_version"] = Global.packageInfo?.version ?? "";
      final string = jsonEncode(data);
      LoggerPage.ws(WsLogType.Up, data);

      _channel.sink.add(string);

      final c = Completer<dynamic>();
      _completerMap[seq] = c;
      const timeoutDuration = Duration(seconds: 30);
      return c.future.timeout(timeoutDuration).catchError((e) {
        throw WsUnestablishedException(msg: "[WS] seq $seq response timeout");
      });
    } catch (e) {
      throw WsUnestablishedException(msg: e?.toString());
    }
  }

  void sendNotRead(Map data) {
    try {
      ///加入pull超时上报设置
      final seq = messageSequence;
      data["seq"] = seq;
      data["app_version"] = Global.packageInfo?.version ?? "";
      final c = Completer<dynamic>();
      _completerMap[seq] = c;
      const timeoutDuration = Duration(seconds: 30);
      LoggerPage.ws(WsLogType.Up, data);
      _channel.sink.add(jsonEncode(data));
      c.future.timeout(timeoutDuration).catchError((e) {
        ///如果超时就重发notPull并且上报
        // sendNotRead(data);
        throw WsUnestablishedException(
            msg: "[WS] NotPull seq $seq response timeout");
      });
    } on WsUnestablishedException catch (e) {
      throw WsUnestablishedException(msg: e?.toString());
    } catch (e, s) {
      logger.severe("send not read error", e, s);
    }
  }

  // ignore: avoid_annotating_with_dynamic
  void _onServerMessage(dynamic rawData) {
    connectionStatus.value = WsConnectionStatus.connected;
    _retryReconnectTime = 5;
    _connectTimer?.cancel();
    _pingTimer?.cancel();

    final stringData = decodeWsData(rawData);
    if (DebugFlag.printWsIncoming) {
      dev.log(stringData, name: "WS incoming");
    }

    final jsonData = jsonDecode(stringData) as Map;
    LoggerPage.ws(WsLogType.Down, jsonData);
    debugPrint('colin ws: $stringData');

    if(stringData.contains("391457616477290496")){
      debugPrint("colin 391457616477290496");
    }

    final sequence = jsonData['seq'];
    final action = jsonData["action"];
    final data = jsonData["data"];
    if (action != "pong")
    // 这是后来和陈志峰定的同步规范，暂时不管耦合
    if (jsonData.containsKey("model")) {
      // 圈子相关通知
      if (jsonData["model"] == "Circle")
        syncCircle(jsonData['action'], jsonData['method'], jsonData['data']);
      // 文档相关通知
      if (jsonData["model"] == "doc")
        tcDocHandler(jsonData['action'], jsonData['data']);
      return;
    }

    if (actionProcessor.containsKey(action)) {
      if (MessageAction.notPull == action ||
          MessageAction.voiceStateUpdate == action) {
        if (_completerMap.containsKey(sequence))
          _completerMap[sequence].complete(data);
        actionProcessor[action](jsonData);
      } else {
        actionProcessor[action](data);
      }
      return;
    }

    if (action == MessageAction.pong) {
      if (data != null && data is Map)
        TextChannelUtil.updatePullTime(data['time']);
      serverTime = data['time'] ?? -1;
      differenceTime = serverTime == -1
          ? 0
          : serverTime - DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return;
    }

    if (action == MessageAction.upLastRead) {
      ///未读消息同步
      final String channelId = data['channel_id'];
      final String guildId = data['guild_id'];
      final String readId = data['read_id'];
      final int unRead = data['un_read'];
      fire(UnreadMessage(channelId, guildId, readId, unRead)); //notify message
      return;
    }

    if (action == MessageAction.onlineDevice) {
      ///账号多端登录
      final int online = data['online'];
      fire(OnlineMessage(online)); //notify message
      return;
    }

    if (action == MessageAction.taskNote) {
      ///接收到未完成任务
      final List<TaskBean> list = TaskUtil.instance.undoneTask(data);
      if (list != null && list.isNotEmpty) {
        list.forEach(fire);
      }
      return;
    }

    if (action == MessageAction.taskDone) {
      ///任务已经完成
      final List<TaskBean> list = TaskUtil.instance.doneTask(data);
      if (list != null && list.isNotEmpty) {
        list.forEach(fire);
      }
      return;
    }

    if (action == MessageAction.miniPush) {
      final message = MessageEntity.fromJson(data);
      try {
        final tcController =
            TextChannelController.to(channelId: message.channelId);
        tcController.onNewMessage(
          message,
          member: data['member'],
          author: data['author'],
          privateMsg: true,
        );
      } catch (e, s) {
        logger.severe("on server message", e, s);
      }
      return;
    }

    // 禁言/解除禁言通知
    if (action == MessageAction.mute) {
      try {
        final String guildId = data['guild_id'];
        final int endTime = data['endtime'];
        MuteListenerController.to.onWsMessage(guildId, endTime);
      } catch (e, s) {
        logger.severe("on server message", e, s);
      }
      return;
    }

    ///支付宝内解绑fanbook，推送通知
    if (action == MessageAction.unbind) {
      ServerSideConfiguration.to.aliPayUid = null;
      return;
    }

    ///服务器封控推送通知
    if (action == MessageAction.GuildStatus) {
      final String guildId = data['guild_id'];
      final banType = BanTypeExtension.fromInt(data['banned_level'] ?? 0);
      _guildStatus(guildId, banType);
      return;
    }

    if (_completerMap.containsKey(sequence))
      _completerMap[sequence].complete(data);

    fire(WsMessage(action, data));
  }

  void _startPing() {
    Timer.periodic(pingInterval, (_) {
      if (connectionStatus.value != WsConnectionStatus.connected) return;
      _sendPing();
      _pingTimer = Timer(pingInterval, () {
        logger.warning("No pong received.");
        connectionStatus.value = WsConnectionStatus.disconnected;
        _reconnect();
      });
    });
  }

  void _sendPing() {
    _channel.sink.add('{"type":"ping"}');
  }

  void _onError(error) {
    logger.severe("websocket error delay 5 seconed connect", error);
    Future.delayed(const Duration(seconds: 5), _reconnect);
  }

  void _onDone() {
    logger.warning(
        '_webSocketChannelSubscription onDone delay 2 seconed connect');
    Future.delayed(const Duration(seconds: 2), () {
      fire(Disconnected());
      connectionStatus.value = WsConnectionStatus.disconnected;
      _reconnect();
    });
  }

  void _reconnect() {
    if (_canReconnect == false) return;

    if (App.appLifecycleState == AppLifecycleState.resumed) {
      logger.warning("_reconnect from front");
      connect();
    } else {
      logger.warning("_reconnect from background");
      Future.delayed(Duration(seconds: _retryReconnectTime), connect);
      _retryReconnectTime = min(2 * _retryReconnectTime, 300);
    }
  }

// 此处加入API的原因是 Connectivity 有BUG，
// 在华为手机上在移动网络下打开代理，
// 会有_connectionType == ConnectivityResult.none但是实际网络是正常的情况。
  Future<bool> _canTryToConnectWs() async {
    logger.warning(
        "_canTryToConnectWs: connectionType ${_connectionType?.toString()} login ${!(Global.user?.id?.isEmpty ?? true)} connectionStatus ${connectionStatus.toString()}");
    if (Global.user?.id?.isEmpty ?? true) return false;
    if (connectionStatus.value != WsConnectionStatus.disconnected) return false;
    if (_connectionType == ConnectivityResult.none) {
      try {
        final result = await UtilApi.postNetWorkIsAvailabel()
            .timeout(const Duration(seconds: 5));

        return result;
      } catch (e) {
        return false;
      }
    } else {
      return true;
    }
  }

  ///服务器收到封禁推送
  Future<void> _guildStatus(String guildId, BanType banType) async {
    final guild = ChatTargetsModel.instance.getChatTarget(guildId);
    if (guild is GuildTarget) {
      guild.bannedLevel.value = banType;
      GuildTable.add(guild);

      if (banType == BanType.dissolve) {
        ///服务器被解散,移除此服务台
        await ChatTargetsModel.instance.removeDissolveGuild(guildId);
        if (guild == ChatTargetsModel.instance.selectedChatTarget) {
          ///当前服务台被选中的话，调整到默认第一个
          quitGuild(guild);
        }
      }

      // 当前服务台需刷新[HomeScaffoldController.scrollEnable]状态
      if (guild == ChatTargetsModel.instance.selectedChatTarget) {
        ///在应用的其他界面，收到封禁，自动返回homePage index 0 页
        Routes.gotoHome();
        await HomeScaffoldController.to.gotoIndex(0);
        ChatTargetsModel.instance.notify();
      }
    }
  }

  //优先取服务器时间
  static DateTime get nowDateTime {
    return DateTime.now().add(Duration(seconds: differenceTime));
  }
}

///ws 发送失败异常
class WsUnestablishedException implements Exception {
  final String msg;

  WsUnestablishedException({this.msg});

  @override
  String toString() => msg ?? 'WsUnestablishedException';
}
