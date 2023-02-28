import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:im/hybrid/webrtc/tools/rtc_log.dart';
import 'package:im/hybrid/webrtc/web_socket_channel/web_socket_channel.dart';
import 'package:im/services/connectivity_service.dart';
import 'package:im/utils/random_string.dart';
import 'package:pedantic/pedantic.dart';
import 'package:rxdart/rxdart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../global.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
}

class Signal {
  static const int MAX_SOCKET_RETRY_NUM = 60;
  static const int MAX_RETRY_NUM = 1;

  static const String MUTE_TYPE_SINGLE = "single";
  static const String MUTE_TYPE_GROUP = "group";

  void Function(Map) onEvent;
  void Function() onWsReconnected;

  final Map _handlerMap = {};

  String _url;
  int _sessionId;
  bool _disposed = false;
  WebSocketChannel _channel;
  StreamSubscription _channelStreamSubscription;

  int socketRetryNum = 0;
  int keepRetryNum = 0;

  ///ws重连超时检查定时器
  Timer _reconnectTimer;
  Timer _reconnectTimeOutTimer;

  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;

  bool get isDisposed => _disposed;

  bool isConnected() => _connectionStatus == ConnectionStatus.connected;

  StreamSubscription _streamSubscription;

  PublishSubject<int> _stream;
  static const FROM_NET_LISTEN = 1;
  static const FROM_WS_DONE = 2;

  bool _isWsReconnect = false;

  Signal() {
    _initNetListener();

    ///由于onConnectivityChanged事件会上报多次，增加去重处理
    _stream = PublishSubject();
    _stream.debounceTime(const Duration(milliseconds: 200)).listen(
      (type) {
        RtcLog.log("=== ws type = $type");
        _isWsReconnect = true;
        if (type == FROM_NET_LISTEN) {
          _wsReconnect(notDelayConnect: true);
        } else if (type == FROM_WS_DONE) {
          _wsReconnect();
        }
      },
    );
  }

  void _initNetListener() {
    final connectivityService = Get.find<ConnectivityService>();
    _streamSubscription =
        connectivityService.onConnectivityChanged.listen(_listenConnectivity);
  }

  void _listenConnectivity(ConnectivityResult state) {
    RtcLog.log("ws Network has change, status: $state");
    if (state != ConnectivityResult.none &&
        _connectionStatus != ConnectionStatus.connecting) {
      _stream.add(FROM_NET_LISTEN);
    }
  }

  Future<void> connect(String url, {Function() onWsDone}) async {
    _url = url;
    _connectionStatus = ConnectionStatus.connecting;
    _channel = connectWebScoket(url, protocols: ['janus-protocol']);
    RtcLog.message('Janus connecting');
    await _channelStreamSubscription?.cancel();
    _channelStreamSubscription = _channel.stream.listen(_onChannelMessage)
      ..onError((e) => RtcLog.message('Janus error', e))
      ..onDone(() => _stream.add(FROM_WS_DONE));
  }

  ///ws重连
  void _wsReconnect({bool notDelayConnect}) {
    RtcLog.message('Janus onDone $notDelayConnect , $_connectionStatus');
    if (!_disposed) {
      _checkReconnectTimeout();
      RtcLog.message('Janus disconnect socketRetryNum: $socketRetryNum');
      if (socketRetryNum < MAX_SOCKET_RETRY_NUM) {
        _connectionStatus = ConnectionStatus.connecting;
        RtcLog.message('Reconnecting janus');
        _channel.sink.close();
        socketRetryNum++;
        if (socketRetryNum == 1 || (notDelayConnect ?? false)) {
          RtcLog.message(
              'Reconnecting quick：$socketRetryNum, notDelayConnect:$notDelayConnect');

          ///使用定时器，避免重复连接
          _connectTimer(5);
          return;
        }
        _connectTimer(500);
      } else {
        reconnectFail();
      }
    }
  }

  void _connectTimer(int milliseconds) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: milliseconds), () {
      RtcLog.message('Reconnecting _disposed：$_disposed');
      if (!_disposed) connect(_url);
    });
    if (onEvent != null) onEvent({"reconnect": true});
  }

  ///重连失败
  void reconnectFail() {
    onEvent?.call({"close": true});
    onEvent?.call({"reconnectFail": true});
    dispose();
  }

  void _onChannelMessage(msg) {
    RtcLog.message('server->client:', msg);
    _closeReconnectTimer();
    if (_disposed) return;
    socketRetryNum = 0;
    _connectionStatus = ConnectionStatus.connected;
    final Map data = json.decode(msg);
    final String type = data['janus'];
    if (type != null) {
      ///第一次连上ws不需要发claim
      if (_isWsReconnect && type == 'pong') {
        onWsReconnected?.call();
        claimForCheckConnectivity(needTimeout: false);
        return;
      }
      final transaction = data['transaction'];
      switch (type) {
        case 'error':
          _getHandler(transaction)?.completeError(data);
          break;
        case 'success':
        case 'event':
          if (transaction != null) {
            final getHandler = _getHandler(transaction);
            if (!(getHandler?.isCompleted ?? true)) getHandler?.complete(data);
          } else if (onEvent != null) {
            onEvent(data);
          }
          break;
        case 'timeout':
          RtcLog.message('Janus timeout');
          onEvent?.call({"close": true});
          break;
        case 'ack':
          if (transaction?.startsWith('Keep') ?? false)
            _getHandler(transaction)?.complete(data);
          // print('----------------- _handlerMap length = ${_handlerMap.length}');
          break;
        default:
          break;
      }
    } else {
      RtcLog.message('_onChannelMessage server->client unknow type:', msg);
    }
  }

  /// 计时器: 发起重连后等待30秒，未取消则[reconnectFail]
  void _checkReconnectTimeout() {
    if (_reconnectTimeOutTimer != null || _disposed) return;
    _reconnectTimeOutTimer?.cancel();
    _reconnectTimeOutTimer = Timer(const Duration(seconds: 30), () {
      RtcLog.message('_reconnectTimeOutTimer: reconnectFail');
      reconnectFail();
    });
  }

  ///关闭重连计时器
  void _closeReconnectTimer() {
    _reconnectTimeOutTimer?.cancel();
    _reconnectTimeOutTimer = null;
  }

  Future<int> createSession() async {
    final String transaction = RandomString.length(12);
    final completer = _createHandler(transaction);
    _completerTimeout(completer);
    _send({'janus': 'create', 'transaction': transaction});
    final Map data = await completer.future;
    final int id = data['data']['id'];
    return _sessionId = id;
  }

  void destroySession({int paramSessionId}) {
    final String transaction = RandomString.length(12);
    _send({
      'janus': 'destroy',
      'transaction': transaction,
      'session_id': paramSessionId ?? _sessionId,
    });
  }

  void _send(Map map) {
    if (!_disposed) {
      if (map != null && map["version"] == null)
        map["version"] = Global.packageInfo.version;
      final String data = json.encode(map);
      RtcLog.message('client->server:', data);
      _channel.sink.add(data);
    }
  }

  Completer _createHandler(String key) {
    final completer = Completer();
    _handlerMap[key] = completer;
    return completer;
  }

  Completer _getHandler(String key) {
    final completer = _handlerMap[key];
    if (completer != null) _handlerMap.remove(key);
    return completer;
  }

  Future<int> attachPlugin(String pluginName) async {
    final String transaction = RandomString.length(12);
    final handler = _createHandler(transaction);
    final msg = {
      "janus": "attach",
      "plugin": pluginName,
      "transaction": transaction,
      "session_id": _sessionId,
      "opaque_id": "audiobridge-${RandomString.length(12)}"
    };
    _completerTimeout(handler);
    _send(msg);
    final data = await handler.future;
    final int id = data['data']['id'];
    return id;
  }

  String getKeepTransaction() => 'Keep${RandomString.length(7)}';

  /// 向janus发送心跳
  Future<dynamic> keepAlive() {
    final String transaction = getKeepTransaction();
    final completer = _createHandler(transaction);
    final Map msg = {
      "janus": "keepalive",
      "session_id": _sessionId,
      "transaction": transaction
    };

    completer.future.timeout(const Duration(seconds: 10)).catchError((error) {
      if (_disposed) return;
      if (keepRetryNum < MAX_RETRY_NUM) {
        keepRetryNum++;
        _send(msg);
        RtcLog.message('Retry keep alive');
      } else {
        completer.completeError("Keep alive timeout.");
      }
    });
    _send(msg);
    return completer.future;
  }

  /// 向janus发送心跳以确认是否连通
  Future<dynamic> keepAliveForCheckConnectivity() {
    final String transaction = getKeepTransaction();
    final completer = _createHandler(transaction);
    final Map msg = {
      "janus": "keepalive",
      "session_id": _sessionId,
      "transaction": transaction
    };
    completer.future.timeout(const Duration(seconds: 2)).catchError((error) {
      final completer = _handlerMap[transaction];
      if (completer != null) _handlerMap.remove(transaction);
      if (completer != null && !completer.isCompleted)
        completer.completeError("Keep alive timeout");
    });
    _send(msg);
    return completer.future;
  }

  Future<dynamic> claimForCheckConnectivity({bool needTimeout = true}) {
    final String transaction = RandomString.length(12);
    final completer = _createHandler(transaction);
    final Map msg = {
      "janus": "claim",
      "session_id": _sessionId,
      "transaction": transaction
    };
    if (needTimeout ?? true)
      completer.future.timeout(const Duration(seconds: 2)).catchError((error) {
        final completer = _handlerMap[transaction];
        if (completer != null) _handlerMap.remove(transaction);
        if (completer != null && !completer.isCompleted)
          completer.completeError("claim timeout");
      });
    _send(msg);
    return completer.future;
  }

  void _completerTimeout(Completer completer) {
    completer.future.timeout(const Duration(seconds: 5)).catchError((error) {
      if (completer != null && !completer.isCompleted)
        completer.completeError("timeout");
    });
  }

  /// 发送候选者
  void trickleCandidate(int handleId, Map candidate) {
    /// 如果是relay类型candidate，不发给服务器
    if (candidate['candidate'] is String &&
        (candidate['candidate'] as String).contains('relay')) return;

    final Map trickleMessage = {
      "janus": "trickle",
      "candidate": candidate,
      "transaction": RandomString.length(12),
      "session_id": _sessionId,
      "handle_id": handleId
    };
    _send(trickleMessage);
  }

  Future<dynamic> configure(int handleId, Map body, {Map jsep}) {
    final String transaction = RandomString.length(12);
    final completer = _createHandler(transaction);
    final Map<String, dynamic> msg = {
      "janus": "message",
      "body": body,
      "transaction": transaction,
      "session_id": _sessionId,
      "handle_id": handleId
    };
    if (jsep != null) msg["jsep"] = jsep;
    _completerTimeout(completer);
    _send(msg);
    return completer.future;
  }

  Future<dynamic> listParticipants(int roomHandleId, String roomId) {
    final String transaction = RandomString.length(12);
    final completer = _createHandler(transaction);
    final Map<String, dynamic> msg = {
      "janus": "message",
      "body": {
        "request": "listparticipants",
        "room": roomId,
      },
      "session_id": _sessionId,
      "handle_id": roomHandleId,
      "transaction": transaction,
    };

    _completerTimeout(completer);
    _send(msg);
    return completer.future;
  }

  Future<dynamic> unPublish(int roomHandleId) {
    final String transaction = RandomString.length(12);
    final completer = _createHandler(transaction);
    final Map<String, dynamic> msg = {
      "janus": "message",
      "body": {"request": "unpublish"},
      "session_id": _sessionId,
      "handle_id": roomHandleId,
      "transaction": transaction,
    };

    _completerTimeout(completer);
    _send(msg);
    return completer.future;
  }

  void leave(int roomHandleId, {int paramSessionId}) {
    final String transaction = RandomString.length(12);
    final Map<String, dynamic> msg = {
      "janus": "message",
      "body": {"request": "leave"},
      "session_id": paramSessionId ?? _sessionId,
      "handle_id": roomHandleId,
      "transaction": transaction,
    };

    _send(msg);
  }

  Future<void> leaveForResult(int roomHandleId, {int paramSessionId}) {
    final String transaction = RandomString.length(12);
    final completer = _createHandler(transaction);
    final Map<String, dynamic> msg = {
      "janus": "message",
      "body": {"request": "leave"},
      "session_id": paramSessionId ?? _sessionId,
      "handle_id": roomHandleId,
      "transaction": transaction,
    };

    _completerTimeout(completer);
    _send(msg);
    return completer.future;
  }

  /// 创建音频房间
  Future<void> createAudioRoom(String roomId, String guildId,
      int maxParticipants, int handleId, String uId) async {
    final String transaction = RandomString.length(12);
    final completer = _createHandler(transaction);

    final msg = {
      "janus": "message",
      "body": {
        "request": "create",
        "room": roomId,
        "guild_id": guildId,
        "max_participants": maxParticipants >= 0 ? maxParticipants : 0x7FFFFFFF,
        "description": 'test',
        "fb_user_id": uId,
        "audiolevel_ext": true,
        "audiolevel_event": true,
        "audio_level_average": 45,
        "audio_active_packets": 50,
      },
      "transaction": transaction,
      "session_id": _sessionId,
      "handle_id": handleId,
    };
    _completerTimeout(completer);
    _send(msg);
    return completer.future;
  }

  Future<dynamic> kickOutUser(String roomId, int handleId, String id) {
    final String transaction = RandomString.length(12);
    final completer = _createHandler(transaction);
    final msg = {
      "janus": "message",
      "body": {"request": "kick", "room": roomId, "id": id},
      "transaction": transaction,
      "session_id": _sessionId,
      "handle_id": handleId
    };
    _completerTimeout(completer);
    _send(msg);
    return completer.future;
  }

  // 禁言用户
  Future<dynamic> muteUser(String roomId, int handleId, String id, bool mute) {
    final String transaction = RandomString.length(12);
    final completer = _createHandler(transaction);
    final msg = {
      "janus": "message",
      "body": {
        "request": mute ? "mute" : "unmute",
        "room": roomId,
        "desc": MUTE_TYPE_SINGLE,
        "id": id,
      },
      "transaction": transaction,
      "session_id": _sessionId,
      "handle_id": handleId
    };
    _completerTimeout(completer);
    _send(msg);
    return completer.future;
  }

  //全员闭麦
  Future<dynamic> muteRoom(String roomId, int handleId, bool mute) {
    final String transaction = RandomString.length(12);
    final completer = _createHandler(transaction);
    final msg = {
      "janus": "message",
      "body": {
        "request": mute ? "mute_room" : "unmute_room",
        "room": roomId,
        "desc": MUTE_TYPE_GROUP,
      },
      "transaction": transaction,
      "session_id": _sessionId,
      "handle_id": handleId
    };
    _completerTimeout(completer);
    _send(msg);
    return completer.future;
  }

// 获取restartOffer
  Future<dynamic> getRestartOffer(String roomId, int handleId) {
    final String transaction = RandomString.length(12);
    final completer = _createHandler(transaction);
    final msg = {
      "janus": "message",
      "body": {
        "request": "configure",
        "restart": true,
        "room": roomId,
      },
      "transaction": transaction,
      "session_id": _sessionId,
      "handle_id": handleId
    };
    _completerTimeout(completer);
    _send(msg);
    return completer.future;
  }

  /// 加入音频房间
  Future<dynamic> joinAudioRoom(String roomId, int handleId, String display,
      String uId, String deviceId) {
    final String transaction = RandomString.length(12);
    final completer = _createHandler(transaction);
    final msg = {
      "janus": "message",
      "body": {
        "request": "join",
        "room": roomId,
        "fb_user_id": uId,
        "device_id": deviceId,
        "display": display,
      },
      "transaction": transaction,
      "session_id": _sessionId,
      "handle_id": handleId
    };
    _completerTimeout(completer);
    _send(msg);
    return completer.future;
  }

  /// 创建视频房间
  Future<void> createVideoRoom(
      String roomId, int handleId, String uId, int publishers,
      {String guildId}) async {
    final String transaction = RandomString.length(12);
    final completer = _createHandler(transaction);

    final msg = {
      "janus": "message",
      "body": {
        "request": "create",
        "room": roomId,
        if (guildId != null) "guild_id": guildId,
        "fb_user_id": uId,
        "description": 'test',
        "publishers": publishers,
        "bitrate": 512000,
        "audiolevel_ext": true,
        "audiolevel_event": true,
        "keyframe": true,
        "notify_joining": true,
        "audio_level_average": 45,
        "audio_active_packets": 50,
        "audiocodec": "opus",
        "videocodec": "vp8",
      },
      "transaction": transaction,
      "session_id": _sessionId,
      "handle_id": handleId
    };
    _send(msg);
    return completer.future;
  }

  /// 加入视频房间 type publisher,subscriber
  Future<dynamic> joinVideoRoom(
      String roomId, int handleId, String display, String type, String deviceId,
      {String feed,
      String uId,
      String contentType,
      bool enableCamera,
      bool mute,
      bool audio,
      bool video}) {
    final String transaction = RandomString.length(12);
    final completer = _createHandler(transaction);
    final Map<String, dynamic> msg = {
      "janus": "message",
      "body": {
        "request": "join",
        "room": roomId,
        "ptype": type,
        "display": display,
        "audiocodec": "opus",
        "videocodec": "vp8",
        "device_id": deviceId,
        if (uId != null) "fb_user_id": uId,
        if (type == 'subscriber') "audio": audio,
        if (type == 'publisher') "mute": mute,
        if (type == 'publisher') "video": video,
        if (type == 'publisher')
          "externals": {"enableVideo": enableCamera ?? true}
      },
      "transaction": transaction,
      "session_id": _sessionId,
      "handle_id": handleId
    };
    if (feed != null) msg["body"]["feed"] = feed;
    if (contentType != null) msg["body"]["fm"] = contentType;
    _send(msg);
    return completer.future;
  }

  /// 注册用户
  Future<dynamic> register(int handleId, String username) {
    final String transaction = RandomString.length(12);
    final completer = _createHandler(transaction);
    final msg = {
      "janus": "message",
      "body": {"request": "register", "username": username},
      "transaction": transaction,
      "session_id": _sessionId,
      "handle_id": handleId
    };
    _send(msg);
    return completer.future;
  }

  /// 呼叫用户
  Future<dynamic> call(int handleId, String username, Map jsep) {
    final String transaction = RandomString.length(12);
    final completer = _createHandler(transaction);
    final msg = {
      "janus": "message",
      "body": {"request": "call", "username": username},
      "transaction": transaction,
      "session_id": _sessionId,
      "handle_id": handleId,
      "jsep": jsep
    };
    _send(msg);
    return completer.future;
  }

  /// 接收通话
  Future<dynamic> accept(int handleId, Map jsep) {
    final String transaction = RandomString.length(12);
    final completer = _createHandler(transaction);
    final msg = {
      "janus": "message",
      "body": {"request": "accept"},
      "transaction": transaction,
      "session_id": _sessionId,
      "handle_id": handleId,
      "jsep": jsep
    };
    _send(msg);
    return completer.future;
  }

  /// 挂断音视频通话
  Future<dynamic> hangup(int handleId) {
    final String transaction = RandomString.length(12);
    final completer = _createHandler(transaction);
    final msg = {
      "janus": "message",
      "body": {"request": "hangup"},
      "transaction": transaction,
      "session_id": _sessionId,
      "handle_id": handleId,
    };
    _send(msg);
    return completer.future;
  }

  /// 设置DataChannel
  Future<dynamic> setupDataChannel(int handleId) {
    final String transaction = RandomString.length(12);
    final completer = _createHandler(transaction);
    final Map<String, dynamic> msg = {
      "janus": "message",
      "body": {"request": "setup"},
      "transaction": transaction,
      "session_id": _sessionId,
      "handle_id": handleId
    };

    _send(msg);
    return completer.future;
  }

  /// 创建文字聊天室
  Future<dynamic> createTextRoom(String roomId, int handleId) {
    final String transaction = RandomString.length(12);
    final completer = _createHandler(transaction);

    final Map<String, dynamic> msg = {
      "janus": "message",
      "body": {"request": "create", "room": roomId, "description": 'test'},
      "transaction": transaction,
      "session_id": _sessionId,
      "handle_id": handleId
    };
    _send(msg);
    return completer.future;
  }

  Future<void> dispose() async {
    if (!_disposed) {
      _disposed = true;
      _isWsReconnect = false;
      await _stream.close();
      await _streamSubscription?.cancel();
      _reconnectTimer?.cancel();
      await _channelStreamSubscription?.cancel();
      RtcLog.message('Janus closed');
      onEvent = null;
      onWsReconnected = null;
      try {
        unawaited(_channel.sink.close());
      } catch (e) {
        RtcLog.log("dispose ws error", e);
      }
      _channel = null;
      _closeReconnectTimer();
      _handlerMap.clear();
    }
  }
}
