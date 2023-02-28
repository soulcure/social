import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_audio_manager/flutter_audio_manager.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' as x;
import 'package:im/api/data_model/user_info.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/hybrid/web_player/web_player_manager.dart';
import 'package:im/hybrid/webrtc/config.dart';
import 'package:im/hybrid/webrtc/room/base_room.dart';
import 'package:im/hybrid/webrtc/room_manager.dart';
import 'package:im/hybrid/webrtc/signal/connection.dart';
import 'package:im/hybrid/webrtc/signal/signal.dart';
import 'package:im/hybrid/webrtc/tools/rtc_log.dart';
import 'package:im/services/connectivity_service.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:pedantic/pedantic.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 语音房间
class AudioRoom extends BaseRoom {
  Signal _signal;
  MediaStream _localStream;

  int _pluginHandleId;
  int _sessionId;

  bool _disposed = false;
  bool _isConnected = false;
  bool _isPCRetrying = false;

  Connection _connect;
  RoomParams _roomParams;
  Timer _keepTimer;
  AudioUser _audioUser;
  final List<AudioUser> _audioUsers = [];

  Timer _reconnectTimer;

  /// 获取本地音频输入的定时器
  Timer localAudioInputTimer;

  /// ws断线重连定时器，有可能ws断开重连，但rtc不需要重连，signal 'reconnect'状态没改变
  Timer _wsReconnectTime;

  /// 房间id
  String _roomId;

  /// 事件回调
  void Function(RoomState, [Object data]) onEvent;

  /// 房间用户列表
  List<AudioUser> get users => _audioUsers;

  /// 麦克风是否可用
  bool get muted => _roomParams.muted;

  static const String SESSION_KEY = 'audio_session_key';

  int _reconnectPcTime = 0;

  SharedPreferences _sp;

  set muted(bool value) {
    if (_disposed) return;
    _roomParams.muted = value;
    _audioUser?.muted = value;
    _notice(RoomState.changed);
    if (_localStream != null) {
      try {
        _localStream.getAudioTracks()?.first?.enabled = !value;
        if (_isConnected)
          _signal.configure(_pluginHandleId, {
            "request": "configure",
            "muted": value,
          }).catchError((e) => RtcLog.log("mute error", e.toString()));
      } catch (e) {
        RtcLog.log("设置音频设备失败", e.toString());
      }
    }
  }

  // 踢人
  Future<void> kickOut(AudioUser user) async {
    await _signal.kickOutUser(_roomId, _pluginHandleId, user.id);
  }

  // 闭玩家的麦
  Future<void> muteUser(AudioUser user, bool mute) async {
    await _signal.muteUser(_roomId, _pluginHandleId, user.id, mute);
  }

  @override
  Future<void> leave() async {
    if (!_disposed) {
      _disposed = true;
      await _streamSubscription?.cancel();
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      _wsReconnectTime?.cancel();
      _wsReconnectTime = null;
      unawaited(WebPlayerManager.instance.setSrcObject(null));
      _keepTimer?.cancel();
      localAudioInputTimer?.cancel();
      try {
        if (_pluginHandleId != null) _signal.leave(_pluginHandleId);
        _signal.destroySession();
      } catch (e) {
        print(e);
      }
      _notice(RoomState.quited);

      onEvent = null;
      await _localStream?.dispose();

      //fix by rain: 此处必须调用dispose方法，flutter_webrtc底层才会真正调用audioManager.abandonAudioFocus，
      //以释放音频占用，其他背景音乐才可以正常播放
      await _connect?.dispose();
      await _signal.dispose();

      if (UniversalPlatform.isMobileDevice) await WebRTCInit.deInitialize();
      RtcLog.log("=========Leaved audio room $_roomId=========");
    }
  }

  AudioRoom() {
    _signal = Signal();
    _signal.onEvent = _onEvent;
    _signal.onWsReconnected = _onWsReconnected;
  }

  /// ws重连成功，但rtc不一定需要重连，由于ws会改为reconnect，所以需要再更新一下RoomState.ready
  void _onWsReconnected() {
    _wsReconnectTime?.cancel();
    _wsReconnectTime = Timer.periodic(5.seconds, (_) {
      // print('------------------------ ${_connect?.getConnectionStatus()}');
      if (_connect?.isRtcConnected() ?? false) {
        // 房间准备成功， 重连成功
        _notice(RoomState.ready);
        _wsReconnectTime?.cancel();
      }
    });
  }

  /// 处理推送信息
  Future<void> _onEvent(Map data) async {
    if (data["plugindata"] != null &&
        data["plugindata"]["plugin"] == audioPlugin) {
      final plugindata = data["plugindata"]["data"];
      final type = plugindata["audiobridge"];

      switch (type) {
        case "talking":
          _handleTalking(plugindata["id"], true);
          break;
        case "stopped-talking":
          _handleTalking(plugindata["id"], false);
          break;
        case "joined":
          _handleUsers(plugindata, joinEvent: true);
          break;
        case "event":
          if (plugindata["participants"] != null) {
            _handleMuted(plugindata["participants"]);
          } else if (plugindata["leaving"] != null) {
            _leave(plugindata);
          } else if (plugindata["kicked"] != null) {
            _kickOut(plugindata);
          }
          break;
        default:
          break;
      }
    } else if (data["close"] == true) {
      _notice(RoomState.disconnected);
      RtcLog.log("audio room disconnected by server");
    } else if (data["reconnect"] == true) {
      _notice(RoomState.reconnect);
      RtcLog.log("audio room reconnect");
    } else if (data["reconnectFail"] == true) {
      _notice(RoomState.reconnectFail);
      RtcLog.log("audio room reconnectFail");
    }
  }

  void _leave(data) {
    final leavedId = data["leaving"];
    final leavedUser = _audioUsers.firstWhere((item) => item.id == leavedId,
        orElse: () => null);
    if (leavedUser != null) _audioUsers.remove(leavedUser);
    _notice(RoomState.leaved);
    RtcLog.log("user leaved", leavedUser?.nickname);
  }

  void _kickOut(data) {
    final kickedId = data["kicked"];
    final kickedUser =
        _audioUsers.firstWhere((e) => e.id == kickedId, orElse: () => null);
    if (kickedUser != null) _audioUsers.remove(kickedUser);
    _notice(
        RoomState.kickOut, [if (_audioUser.id == kickedId) true else false]);
    RtcLog.log("Kicked user", kickedUser?.nickname);
  }

  /// 处理静音通知
  void _handleMuted(List participants) {
    for (final audioUser in _audioUsers) {
      for (final participant in participants) {
        if (participant["id"] == audioUser.id) {
          audioUser.muted = participant["muted"];
          if (audioUser.muted) audioUser.talking = false;
          RtcLog.log("Muted ${audioUser.muted} for", audioUser.nickname);
          // 被动收到的静音消息，如果是自己，表明是自己被别人禁麦/开麦
          if (audioUser.id == _audioUser.id)
            _notice(RoomState.muted, [participant["muted"]]);
        }
      }
    }
    _notice(RoomState.changed);
  }

  /// 处理当前正在发言用户状态通知
  void _handleTalking(String id, bool value) {
    final user =
        _audioUsers.firstWhere((item) => item.id == id, orElse: () => null);
    if (user != null) {
      RtcLog.log("Talking state change($value) for", user.nickname);
      user.talking = value;
      if (value) {
        _audioUsers.remove(_audioUser);
        _audioUsers.remove(user);
        _audioUsers.insert(0, _audioUser);
        if (_audioUser != user) _audioUsers.insert(0, user);
      }
      _notice(RoomState.changed);
    }
  }

  @override
  Future<void> init(String roomId, RoomParams params) async {
    assert(params != null);
    _sp = await SharedPreferences.getInstance();
    _initNetListener();
    RtcLog.log("=====Joining audio room:$roomId=====");
    _roomId = roomId;
    _roomParams = params;
    // 初始化本地音频，这要先初始化，否则无法显示视频
    ///callback回调是iOS原生向flutter传递语音通道状态
    if (UniversalPlatform.isMobileDevice)
      await WebRTCInit.initialize(
          "Flutter screen sharing", "Flutter", "Flutter WebRTC Demo",
          callback: rtcCallHandler);

    // 获取本地媒体
    try {
      _localStream = await _await(
          navigator.mediaDevices.getUserMedia({'audio': true, 'video': false}));
      RtcLog.log("Geted user audio media");
    } catch (e) {
      RtcLog.log("getUserMedia Exception", e.toString());
      throw RoomManager.premissError;
    }

    RtcLog.log("adding self");
    _audioUser = AudioUser.from(_roomParams);
    _audioUsers.add(_audioUser);
    _notice(RoomState.inited);
    RtcLog.log("audio room inited)");
  }

  StreamSubscription _streamSubscription;

  void _initNetListener() {
    final connectivityService = x.Get.find<ConnectivityService>();
    _streamSubscription =
        connectivityService.onConnectivityChanged.listen(_listenConnectivity);
  }

  void _listenConnectivity(ConnectivityResult state) {
    if (state != ConnectivityResult.none) {
      final isConnected = _signal.isConnected();
      RtcLog.log(
          "audio rtc Network has change, status:$state,isConnected: $isConnected");
      if (isConnected) {
        _reConnect();
      } else {
        _reconnectTimer?.cancel();

        ///ws重连需要200ms，每隔50ms查询下状态
        _reconnectTimer = Timer(
            const Duration(milliseconds: 50), () => _listenConnectivity(state));
      }
    }
  }

  /// iOS端音频通道状态回调
  void rtcCallHandler(String callName, Map arguments) {
    switch (callName) {
      case 'audioSessionBeginInterruption':
        {
          RtcLog.log("音频通道被中断");
          break;
        }
      case 'audioSessionEndInterruption':
        {
          RtcLog.log("音频通道被恢复");
          break;
        }
      case 'audioSessionOutputVolume':
        {
          RtcLog.log("语音输出音量被改为${arguments['volume']}");
          break;
        }
      case 'audioSessionActive':
        {
          final String active = arguments['active'] ? '打开' : '关闭';
          RtcLog.log("语音通道被$active");
          break;
        }
    }
  }

  Future join() async {
    await _joinRoom().catchError((e) => _notice(RoomState.error, e));
  }

  Future _signalConnect() async {
    try {
      await _await(_signal.connect(rtcHost));
      RtcLog.log("Janus connected", rtcHost);
    } catch (e) {
      RtcLog.log("连接语音服务器失败！", e.toString());
      throw '连接语音服务器失败！%s'.trArgs([rtcHost]);
    }
  }

  Future<void> _joinRoom() async {
    // 连接janus信令服务器
    await _signalConnect();

    final lastSession = _sp.getInt(SESSION_KEY);
    if (lastSession != null && lastSession > 0)
      try {
        _signal.destroySession(paramSessionId: lastSession);
      } catch (e) {
        RtcLog.log("destroySession", e);
      }

    // 创建会话
    _sessionId = await _await(_signal.createSession());
    if (_sessionId != null && _sessionId > 0)
      await _sp.setInt(SESSION_KEY, _sessionId);
    RtcLog.log("Created Session");

    // 挂载插件
    _pluginHandleId = await _await(_signal.attachPlugin(audioPlugin));
    RtcLog.log("Attached plugin", _pluginHandleId);

    // 创建房间
    await _await(_signal.createAudioRoom(_roomId, _roomParams.guildId,
        _roomParams.maxParticipants, _pluginHandleId, _roomParams.userId));
    RtcLog.log("Created audio room");

    // 加入房间
    final data = await _await(_signal.joinAudioRoom(_roomId, _pluginHandleId,
        _roomParams.display, _roomParams.userId, _roomParams.deviceId));
    RtcLog.log("Joined room", _roomId);

    // 协商
    await _await(_consult(data));

    // 房间准备成功
    _notice(RoomState.ready);
    _keepAlive();
    RtcLog.log("end Notice");
  }

  Future _await(Future future) async {
    if (!_disposed) {
      final res = await future;
      return res;
    }
    throw 'canceled';
  }

  /// 媒体协商
  Future<void> _consult(Map data, {bool reConnect = false}) async {
    final plugindata = data["plugindata"]["data"];
    if (plugindata["audiobridge"] == "joined") {
      if (reConnect) {
        _audioUsers.clear();
        _audioUser = AudioUser.from(_roomParams);
        _audioUsers.add(_audioUser);
      }

      _audioUser.id = plugindata["id"];

      // 处理用户列表信息
      _handleUsers(plugindata, reConnect: reConnect);

      await _await(_connecting());

      _runLocalAudioInputTimer();
      RtcLog.log("=====Joined Audio room=====");
    } else if (plugindata["audiobridge"] == "event") {
      final code = plugindata["error_code"];
      if (code == 494) {
        // 超出人数限制，加入不了
        throw "频道已满".tr;
      } else if (code == 485) {
        /// 一个人的时候，退出房间会被销毁，需要重新创建房间
        // 创建房间
        await _await(_signal.createAudioRoom(_roomId, _roomParams.guildId,
            _roomParams.maxParticipants, _pluginHandleId, _roomParams.userId));
        RtcLog.log("Created audio room");
        // 加入房间
        final data = await _await(_signal.joinAudioRoom(
            _roomId,
            _pluginHandleId,
            _roomParams.display,
            _roomParams.userId,
            _roomParams.deviceId));
        RtcLog.log("Joined room2", data);
        if (!_disposed) await _consult(data, reConnect: true);
      }
    }
  }

  Future<void> _connecting() async {
    // 创建peerConnection
    _connect = Connection();
    RtcLog.log("_connecting");
    if (kIsWeb) {
      final pc = await _await(_connect.createPeer(
        onIceCandidate: (candidate) =>
            _signal.trickleCandidate(_pluginHandleId, candidate),
        onError: (state, _) => _reConnect(),
      )) as RTCPeerConnection;
      pc.onAddStream = WebPlayerManager.instance.setSrcObject;
    } else {
      await _await(_connect.createPeer(
        onIceCandidate: (candidate) =>
            _signal.trickleCandidate(_pluginHandleId, candidate),
        onError: (state, _) {
          if (state == "failed") _reConnect();
        },
        reconnectPeer: (_) => _reConnect(),
      ));
    }

    RtcLog.log("Created peer connection");

    // 添加本地流
    await _await(_connect.addStream(_localStream));
    RtcLog.log("Added local stream");

    // 创建 Offer
    final sdp = await _await(_connect.createOffer(Connection.audioConstraints));
    RtcLog.log("Created Offer");

    // 配置
    final Map body = {"request": "configure", "muted": true};
    final Map jsep = {"type": sdp.type, "sdp": sdp.sdp};
    final res =
        await _await(_signal.configure(_pluginHandleId, body, jsep: jsep));
    RtcLog.log("Setting local description");

    // 主叫方收到应答
    await _await(_connect.receiveAnswer(res["jsep"]));
    RtcLog.log("Received answer");
    _isConnected = true;

    // 根据设置，重新设置硬件状态
    muted = _roomParams.muted;
  }

  Future<void> _reConnect() async {
    final isConnected = _signal.isConnected();
    bool isSessionExpire = false;
    RtcLog.log(
        "reConnect _signal.isDisposed:${_signal.isDisposed}, $isConnected, ${_signal.socketRetryNum}");
    if (_signal.isDisposed ||
        _disposed ||
        _signal.socketRetryNum >= Signal.MAX_SOCKET_RETRY_NUM) return;

    if (isConnected) {
      try {
        _reconnectTimer?.cancel();

        /// 只是检测是否连通
        await _signal?.keepAliveForCheckConnectivity();
        isSessionExpire = false;
      } catch (e) {
        /// 如果session失效，要重走入会流程，不失效，走iceRestart
        if (e is Map && e['janus'] == 'error' && e['error']['code'] == 458) {
          RtcLog.log(
              ' reConnect keepAlive session expire exception', e.toString());
          isSessionExpire = true;
        } else {
          isSessionExpire = false;
          _reconnectTimer =
              Timer(const Duration(milliseconds: 500), _reConnect);
          return;
        }
      }
    } else {
      RtcLog.log(
          ' reConnect isConnected false disposed=$_disposed, socketRetryNum=${_signal.socketRetryNum}');
      _keepTimer?.cancel();
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 1), _reConnect);
      return;
    }

    RtcLog.log("_isPConnectRetrying =  $_isPCRetrying");
    if (_isPCRetrying) return;

    _isPCRetrying = true;
    final bool result =
        isSessionExpire ? await _reJoinRoom() : await _restartIce();
    RtcLog.log(
        'isSessionExpire = $isSessionExpire, reconnect result = $result');

    /// 如果进入音频房间的信令出错，重走_reConnect
    if (!result &&
        !_disposed &&
        _signal.socketRetryNum < Signal.MAX_SOCKET_RETRY_NUM) {
      _reconnectPcTime++;
      _isPCRetrying = false;
      _reconnectTimer?.cancel();
      if (_reconnectPcTime >= 60) {
        _signal.reconnectFail();
      } else {
        _reconnectTimer = Timer(const Duration(milliseconds: 500), _reConnect);
      }
      RtcLog.log(
          '===== join room end $_isPCRetrying, _reconnectPcTime:$_reconnectPcTime');
      return;
    }
    _reconnectPcTime = 0;
    _isPCRetrying = false;
    _runLocalAudioInputTimer();
  }

  Future<bool> _restartIce() async {
    try {
      // iceRestart方案
      await _connect.restartIce();

      // 创建 Offer
      final sdp = await _await(
          _connect.createOffer(Connection.restartAudioConstraints));
      // RtcLog.log("created restart ice offer", sdp.sdp);

      // 配置
      final Map body = {"request": "configure", "muted": false};
      final Map jsep = {"type": sdp.type, "sdp": sdp.sdp, "iceRestart": true};
      final res =
          await _await(_signal.configure(_pluginHandleId, body, jsep: jsep));

      // 主叫方收到应答
      await _await(_connect.receiveAnswer(res["jsep"]));
      RtcLog.log("received answer");
    } catch (e) {
      RtcLog.log('_restartIce error', e.toString());
      return false;
    }

    // 房间准备成功， 重连成功
    _notice(RoomState.ready);
    _keepAlive();
    return true;
  }

  Future<bool> _reJoinRoom() async {
    try {
      /// 保存重连前的听筒或者扬声器状态等状态
      AudioInput audioInput;
      if (Platform.isIOS)
        audioInput = await FlutterAudioManager.getCurrentOutput();
      RtcLog.log("reJoinRoom audioInpt", audioInput);

      // 重连方案
      if (!UniversalPlatform.isIOS) await _await(_connect?.close());

      // 创建会话
      _sessionId = await _await(_signal.createSession());
      if (_sessionId != null && _sessionId > 0)
        await _sp.setInt(SESSION_KEY, _sessionId);
      RtcLog.log("Created Session", _sessionId);

      // 挂载插件
      _pluginHandleId = await _await(_signal.attachPlugin(audioPlugin));
      RtcLog.log("Attached plugin", _pluginHandleId);

      // 加入房间
      final data = await _await(_signal.joinAudioRoom(_roomId, _pluginHandleId,
          _roomParams.display, _roomParams.userId, _roomParams.deviceId));
      RtcLog.log("Joined room", data);

      // 协商
      await _await(_consult(data, reConnect: true));

      // 房间准备成功， 重连成功
      _notice(RoomState.ready);

      // 保活
      _keepAlive();

      /// 恢复听筒或者扬声器状态
      if (Platform.isIOS) {
        if (audioInput.port == AudioPort.receiver)
          await FlutterAudioManager.changeToReceiver();
        else if (audioInput.port == AudioPort.speaker)
          await FlutterAudioManager.changeToSpeaker();
      }
    } catch (e) {
      RtcLog.log('reJoinRoom error', e.toString());
      return false;
    }
    _isPCRetrying = false;
    return true;
  }

  /// 保活
  void _keepAlive() {
    _keepTimer?.cancel();
    _keepTimer = Timer.periodic(const Duration(seconds: 25), (t) {
      _signal?.keepAlive()?.catchError((e) {
        _notice(RoomState.error, "网络链接超时".tr);
        _keepTimer.cancel();
        RtcLog.log('keepAlive error', e.toString());
      });
    });
    RtcLog.log("Keep alive");
  }

  /// 通知回调
  void _notice(RoomState state, [data]) {
    if (!_disposed && onEvent != null) onEvent(state, data);
  }

  /// 处理用户信息
  void _handleUsers(Map data,
      {bool reConnect = false, bool joinEvent = false}) {
    final List participants = data['participants'];
    if (participants != null && participants.isNotEmpty) {
      RtcLog.log(
          '语音成员列表数量:${participants.length} reConnect:$reConnect joinEvent:$joinEvent');
      final joinedUsers = [];
      for (final p in participants) {
        final user = AudioUser();
        user
          ..id = p['id']
          ..display = p['display']
          ..muted = p['muted']
          ..talking = p['talking'] ?? false
          ..deviceId = p['device_id'] ?? "";
        if (user.muted) user.talking = false;

        // 过滤掉userId和deviceId都相同的人。保留后加入的
        final existUser = _audioUsers.firstWhere(
            (u) =>
                u.userId.hasValue &&
                user.userId.hasValue &&
                u.userId == user.userId &&
                u.deviceId.hasValue &&
                user.deviceId.hasValue &&
                u.deviceId == user.deviceId,
            orElse: () => null);

        if (existUser != null) _audioUsers.remove(existUser);
        _audioUsers.add(user);
        joinedUsers.add(user.userId);
        RtcLog.log("Added user", user.nickname);
      }
      // 通知加入
      _notice(RoomState.joined, joinedUsers);
    }
  }

  ///返回 sessionId 和 pluginHandleId
  Map<String, int> getRoomParams() {
    final Map<String, int> param = {};
    if ((_sessionId ?? 0) > 0) param['sessionId'] = _sessionId;
    if ((_pluginHandleId ?? 0) > 0) param['pluginHandleId'] = _pluginHandleId;
    return param.isNotEmpty ? param : null;
  }

  /// 定时获取本地音频状态，来控制自己的说话状态(绿色圈圈)
  void _runLocalAudioInputTimer() {
    localAudioInputTimer?.cancel();
    localAudioInputTimer = Timer.periodic(1.seconds, (timer) async {
      // print('getChat localAudio ----- muted: $muted, rtc status = ${_connect.getConnectionStatus()}');
      if (muted) {
        _audioUser.talking = false;
        _notice(RoomState.changed);
        return;
      }
      if (_connect == null ||
          _signal == null ||
          _signal.isDisposed ||
          !_signal.isConnected()) {
        localAudioInputTimer?.cancel();
        return;
      }
      final statList = await _connect.getStats();
      if (statList == null) return;

      ///本地音频输入的key值
      const levelKey = 'audioInputLevel';
      final stat = statList?.firstWhere(
          (s) =>
              s.type == 'ssrc' &&
              s.values != null &&
              s.values.containsKey(levelKey),
          orElse: () => null);
      if (stat != null) {
        final audioInputLevel =
            int.tryParse(stat.values[levelKey]?.toString() ?? '0') ?? 0;
        // 测试一些安卓和iOS设备后，1500为一个比较准确的麦克风音量值
        // 大于它就为说话中状态
        if (audioInputLevel > 1500) {
          if (!_audioUser.talking) {
            _audioUser.talking = true;
            _notice(RoomState.changed);
          }
        } else {
          if (_audioUser.talking) {
            _audioUser.talking = false;
            _notice(RoomState.changed);
          }
        }
      } else {
        ///未获取到stat状态消息
        if (_audioUser.talking) {
          _audioUser.talking = false;
          _notice(RoomState.changed);
        }
      }
    });
  }
}

/// 用户数据体
class AudioUser extends RoomUser {
  AudioUser();

  AudioUser.from(RoomParams roomParams) {
    userId = roomParams.userId;
    nickname = roomParams.nickname;
    avatar = roomParams.avatar;
    muted = roomParams.muted;
    deviceId = roomParams.deviceId;
  }

  set display(String value) {
    if (value.hasValue)
      try {
        final map = json.decode(value);
        if (map is List) {
          userId = map[0];
          nickname = map[1];
          avatar = map[2];
        }
      } catch (e) {
        RtcLog.log("audio user display", e);
      }
  }

  @override
  bool isEqual(UserInfo userInfo) => false;
}
