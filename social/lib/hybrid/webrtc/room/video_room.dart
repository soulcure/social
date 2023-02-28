import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_audio_manager/flutter_audio_manager.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' as x;
import 'package:im/global.dart';
import 'package:im/hybrid/webrtc/config.dart';
import 'package:im/hybrid/webrtc/room/base_room.dart';
import 'package:im/hybrid/webrtc/room/text_room.dart';
import 'package:im/hybrid/webrtc/room_manager.dart';
import 'package:im/hybrid/webrtc/signal/connection.dart';
import 'package:im/hybrid/webrtc/signal/signal.dart';
import 'package:im/hybrid/webrtc/tools/audio_help.dart';
import 'package:im/hybrid/webrtc/tools/rtc_log.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';
import 'package:pedantic/pedantic.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

import '../../../loggers.dart';

const ScreenShareConstraints = {
  "audio": true,
  "video": {
    "cursor": "always",
    "displaySurface": ["application", "browser", "monitor", "window"],
    "logicalSurface": true,
    "width": 1280,
    "height": 720,
    "resizeMode": "crop-and-scale",
    "frameRate": 10,
  },
};

class VideoParams {
  final int width;
  final int height;
  final int minBitrate;
  final int maxBitrate;
  final int fps;

  VideoParams(
      this.width, this.height, this.minBitrate, this.maxBitrate, this.fps);

  factory VideoParams.createGroupVideoParams() =>
      VideoParams(320, 240, 50, 150, 15);

  factory VideoParams.createSingleVideoParams() =>
      VideoParams(1280, 720, 200, 1000, 15);

  factory VideoParams.createScreenShareParams() =>
      VideoParams(720, 1280, 1200, 2000, 10);
}

/// 视频房间
class VideoRoom extends BaseRoom {
  Signal _signal;
  MediaStream _localStream;
  MediaStream _screenShareStream;
  int _pluginHandleId;
  int _screenSharePluginHandleId;
  bool _disposed = false;
  AudioHelp _audioHelp;
  RoomParams _params;
  Timer _keepTimer;
  VideoUser get user => _me;
  VideoUser _me;
  VideoUser _screenShareUser;
  final bool _useFrontCamera = true;
  TextRoom _textRoom;

  TextRoom get textRoom => _textRoom;
  bool _isConnected = false;

  // static const methodChannel = MethodChannel("broadcast");
  void Function(MediaStream) onScreenShared;

  VideoParams _videoParams;
  VideoParams _screenParams;

  /// 房间id
  String roomId;

  /// 事件回调
  void Function(RoomState, [Object data]) onEvent;

  /// 麦克风是否可用
  bool get muted => _params.muted;

  /// 获取本地音频输入的定时器
  Timer _localAudioInputTimer;

  static const String SESSION_KEY = 'video_session_key';

  SharedPreferences _sp;

  Lock lock = Lock();

  /// 是否使用前置摄像头
  bool get useFrontCamera => _params.useFrontCamera;

  /// 房间用户列表
  final List<VideoUser> _users = [];
  List<VideoUser> get users => _users;

  /// 屏幕共享用户列表
  final List<VideoUser> _screenUsers = [];
  List<VideoUser> get screenUsers => _screenUsers;

  VideoUser get screenShareUser {
    if (_screenUsers.isNotEmpty)
      return _screenUsers[0];
    else
      return null;
  }

  set muted(bool value) {
    RtcLog.log("Self muted", value);
    _params.muted = value;
    _me?.muted = value;
    if (value) {
      _me?.talking = false;
    }
    _notice(RoomState.changed);
    if (_localStream != null) {
      try {
        _localStream.getAudioTracks()[0].enabled = !value;
        if (_isConnected)
          _signal.configure(_pluginHandleId, {
            "request": "configure",
            "audio": !value,
            "mute": value,
          });
      } catch (e) {
        print("设置音频设备失败$e");
      }
    }
  }

  Future<void> publishSharedScreenInRoom(
    String nickname,
    String id,
    String secret,
    // String iosExtension,
    // String iosSuiteName,
  ) async {
    _screenParams = VideoParams.createScreenShareParams();
    _screenShareStream = await navigator.mediaDevices.getDisplayMedia({
      'video': {
        'mandatory': {
          'minWidth': _screenParams.width,
          'minHeight': _screenParams.height,
          'minFrameRate': _screenParams.fps
        }
      },
    });

    onScreenShared?.call(_screenShareStream);

    final RoomParams screenShareParams = RoomParams(
        enableCamera: true,
        userId: "screenshared",
        // nickname: "共享屏幕-%s".trArgs([Global.user.nickname]),
        nickname: "%s".trArgs([Global.user.nickname]),
        avatar:
            "https://fb-cdn.fanbook.mobi/x-project/user-upload-files/37d38d73449a8ff3935deb0fc9a31839.jpg");
    _screenShareUser = VideoUser.from(screenShareParams, _screenShareStream);
    _screenShareUser.flag = 'screen_share';
    _screenUsers.add(_screenShareUser);

    _screenSharePluginHandleId = await _signal.attachPlugin(videoPlugin);
    _screenShareUser.handleId = _screenSharePluginHandleId;

    final data = await _await(_signal.joinVideoRoom(
      roomId,
      _screenSharePluginHandleId,
      screenShareParams.display,
      "publisher",
      _params.deviceId,
      contentType: "screen_share",
      video: true,
    ));
    // 协商
    await _await(_screenShareConsult(data));

    _notice(RoomState.changed);
  }

  Future<void> closeSharedScreenInRoom() async {
    await _screenShareUser?.dispose();
    _signal.leave(_screenSharePluginHandleId);
    _screenUsers.remove(_screenShareUser);
  }

  /// 是否开启摄像头
  bool get enableCamera => _params.enableCamera;

  set enableCamera(bool value) {
    RtcLog.log("Self camera", value);
    _params.enableCamera = value;
    if (_localStream != null) {
      try {
        _localStream.getVideoTracks()[0].enabled = value;
        user?.enableCamera = value;
        if (_isConnected)
          _signal.configure(_pluginHandleId, {
            "request": "configure",
            "video": value,
            "externals": {"enableVideo": value}
          });
      } catch (e) {
        print("设置视频设备失败$e");
      }
    }
  }

  /// 切换摄像头，返回是否是前置摄像头
  Future<bool> switchCamera() async {
    bool isFrontCamera = _params.useFrontCamera;
    if (_localStream != null) {
      try {
        isFrontCamera =
            await Helper.switchCamera(_localStream.getVideoTracks()[0]);
        _params.useFrontCamera = isFrontCamera;
        user?.useFrontCamera = isFrontCamera;
        if (_isConnected)
          unawaited(_signal.configure(
            _pluginHandleId,
            {"request": "configure", "fm": isFrontCamera ? 'user' : 'env'},
          ));
      } catch (e) {
        print("设置视频设备失败$e");
      }
    }
    return isFrontCamera;
  }

  void enabledLocalVideoTrack(bool isEnabled) {
    if (_localStream != null) {
      try {
        final MediaStreamTrack track = _localStream.getVideoTracks()[0];
        track?.enabled = isEnabled;
      } catch (e) {
        print("设置视频失败$e");
      }
    }
  }

  VideoRoom() {
    _signal = Signal();
    _signal.onEvent = _onEvent;
  }

  void changeToSpeaker() {
    ///ios平台默认是打开听筒的，所以做下切换
    if (UniversalPlatform.isIOS) _audioHelp?.changeToSpeaker();
  }

  /// 处理推送信息
  void _onEvent(Map data) {
    if (data["plugindata"] != null &&
        data["plugindata"]["plugin"] == videoPlugin) {
      final plugindata = data["plugindata"]["data"];
      final type = plugindata["videoroom"];

      switch (type) {
        case "talking":
          _handleTalking(plugindata["id"], true);
          break;
        case "stopped-talking":
          _handleTalking(plugindata["id"], false);
          break;
        case "event":
          if (plugindata["leaving"] != null) {
            _leave(plugindata);
          } else if (plugindata["publishers"] != null) {
            _handleUsers(plugindata);
          } else if (plugindata["participants"] != null) {
            _handleMuted(plugindata["participants"]);
          }
          break;
        case "configured":
          _changeUserConfig(plugindata);
          break;
        default:
          break;
      }
    } else if (data["close"] == true) {
      _notice(RoomState.disconnected);
      RtcLog.log("audio room disconnected by server");
    }
  }

  void _leave(data) => lock.synchronized(() => _otherLeave(data));

  Future<void> _otherLeave(data) async {
    ///如果_disposed为true，说明已经在leave会去销毁资源了
    if (_disposed) return;
    final leaveId = data["leaving"];

    ///如果收到自己共享屏幕离开
    if (leaveId == _screenShareUser?.id) {
      RtcLog.log("--- I leave with screen share $leaveId");
      if (_screenUsers.contains(_screenShareUser))
        _screenUsers.remove(_screenShareUser);
      _screenSharePluginHandleId = null;
      _screenShareStream = null;
      _screenShareUser = null;
      return;
    }

    final screenUser = _screenUsers.firstWhere((item) {
      return item.id == leaveId;
    }, orElse: () => null);
    if (screenUser != null) {
      RtcLog.log("leave user", screenUser.nickname);
      _screenUsers.remove(screenUser);
      await screenUser.dispose();
      _notice(RoomState.leaved, screenUser);
    }

    final user = _users.firstWhere((item) {
      return item.id == leaveId;
    }, orElse: () => null);
    if (user != null) {
      RtcLog.log("leave user", user.nickname);
      _users.remove(user);
      await user.dispose();
      _notice(RoomState.leaved, user);
    }
  }

  @override
  Future<void> leave() async {
    await lock.synchronized(_myLeave);
  }

  // 全员闭麦
  Future<void> muteRoom(bool mute) async {
    await _signal.muteRoom(roomId, _pluginHandleId, mute);
  }

  Future<void> _myLeave() async {
    if (!_disposed) {
      RtcLog.log("=========Leaving video room $roomId=========");
      _disposed = true;
      _keepTimer?.cancel();
      _localAudioInputTimer?.cancel();
      try {
        if (_screenSharePluginHandleId != null) {
          await _screenShareUser?.dispose();
          _signal.leave(_screenSharePluginHandleId);
        }
      } catch (e) {
        print(e);
      }

      /// 销毁所有连接及渲染对象，包括本地摄像头
      for (final p in _users) {
        await p.dispose();
      }

      for (final screenUser in _screenUsers) {
        if (screenUser == _screenShareUser) continue;
        await screenUser.dispose();
      }

      try {
        _audioHelp?.dispose();
        if (_pluginHandleId != null) _signal.leave(_pluginHandleId);
        _signal.destroySession();
      } catch (e) {
        print(e);
      }

      onEvent = null;

      if (_params.enableTextRoom) await _textRoom?.leave();
      await _signal.dispose();

      _users.clear();
      _screenUsers.clear();

      if (UniversalPlatform.isMobileDevice) await WebRTCInit.deInitialize();

      RtcLog.log("=========Leaved video room=========");
    }
  }

  /// 处理静音通知
  void _changeUserConfig(data) {
    for (final it in _users) {
      if (data["id"] == it.id) {
        if (data["mute"] != null) {
          it.muted = data["mute"];
          if (it.muted) {
            it.talking = false;
          }
          RtcLog.log("Muted ${it.muted} for", it.nickname);
        } else if (data["fm"] != null) {
          // 临时方案，用fm承载屏幕内容分类和前后摄像头信息
          if (data["fm"] == "screen_share") {
            it.flag = "screen_share";
          } else {
            it.useFrontCamera = data["fm"] == "user";
          }
          RtcLog.log("Use front camera ${it.useFrontCamera} for", it.nickname);
        } else if (data["externals"] != null &&
            data["externals"]["enableVideo"] != null) {
          it.enableCamera = data["externals"]["enableVideo"];
          RtcLog.log("Enable camera ${it.enableCamera} for", it.nickname);
        }
      }
    }
    _notice(RoomState.changed);
  }

  /// 处理静音通知
  void _handleTalking(String id, bool value) {
    if (_users.isEmpty) return;
    final user = _users.firstWhere((item) {
      return item.id == id;
    }, orElse: () => null);
    if (user != null) {
      RtcLog.log("Talking state change($value) for", user.nickname);
      user.talking = value;
      if (user.muted) {
        user.talking = false;
      }
      if (value) {
        _users.remove(user);
        _users.insert(0, user);
      }
      _notice(RoomState.changed);
    }
  }

  @override
  Future<void> init(String roomId, RoomParams params) async {
    assert(params != null);
    _sp = await SharedPreferences.getInstance();
    this.roomId = roomId;
    _params = params;
    _videoParams = _params.isGroupRoom
        ? VideoParams.createGroupVideoParams()
        : VideoParams.createSingleVideoParams();
    if (_params.enableTextRoom) _textRoom = TextRoom(_signal);

    try {
      // 初始化本地音频，这要先初始化，否则无法显示视频
      if (UniversalPlatform.isMobileDevice) {
        await WebRTCInit.initialize(
            "Flutter screen sharing", "Flutter", "Flutter WebRTC Demo");
      }

      _localStream = await _await(navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'facingMode': 'user',
          'mandatory': {
            'minWidth': _videoParams.width,
            'minHeight': _videoParams.height,
            'minFrameRate': _videoParams.fps
          }
        },
      }));

      RtcLog.log("Got user media");
    } catch (e) {
      print(e);
      throw RoomManager.premissError;
    }

    _audioHelp = AudioHelp();
    await _audioHelp.init();

    // 增加自己
    _me = VideoUser.from(_params, _localStream);
    _users.add(_me);
    RtcLog.log("create self");
  }

  Future<void> join() async {
    ///补充因为room对象还没创建，补充发一下自己初始化完成
    _notice(RoomState.inited);
    RtcLog.log("=====Joining video room:$roomId=====");

    // 不用等待
    unawaited(_joinRoom().catchError((e) {
      _notice(RoomState.error, e);
    }));
  }

  Future<void> _joinRoom() async {
    // 链接janus服务器
    try {
      await _await(_signal.connect(rtcHost));
      RtcLog.log("Janus connected", rtcHost);
    } catch (e) {
      print(e);
      _notice(RoomState.inRoomStatus, false);
      throw '连接视频服务器失败！%s'.trArgs([rtcHost]);
    }

    final lastSession = _sp.getInt(SESSION_KEY);
    if (lastSession != null && lastSession > 0)
      try {
        _signal.destroySession(paramSessionId: lastSession);
      } catch (e) {
        RtcLog.log("destroySession", e);
      }

    // 创建会话
    final currentSessionId = await _await(_signal.createSession());
    if (currentSessionId != null && currentSessionId > 0)
      await _sp.setInt(SESSION_KEY, currentSessionId);
    RtcLog.log("Created Session");

    // 挂载插件
    _pluginHandleId = await _await(_signal.attachPlugin(videoPlugin));
    RtcLog.log("Attached plugin", _pluginHandleId);
    _me.handleId = _pluginHandleId;

    // 创建房间
    await _await(_signal.createVideoRoom(
        roomId, _pluginHandleId, _params.userId, _params.publishers));
    RtcLog.log("Created video room");

    // 加入房间
    final data = await _await(_signal.joinVideoRoom(
        roomId, _pluginHandleId, _params.display, "publisher", _params.deviceId,
        enableCamera: _params.enableCamera,
        mute: _params.muted,
        video: _params.enableCamera));
    RtcLog.log("Joined room", roomId);
    _notice(RoomState.inRoomStatus, true);

    // 协商
    await _await(_consult(data));

    // 加入文本房间
    if (_params.enableTextRoom) await _await(_textRoom.init(roomId, _params));

    // 房间准备成功
    _notice(RoomState.ready);
  }

  Future _await(Future future) async {
    if (!_disposed) {
      final res = await future;
      return res;
    }
    throw 'canceled';
  }

  /// 媒体协商
  Future<void> _screenShareConsult(Map data) async {
    final plugindata = data["plugindata"]["data"];
    if (plugindata["videoroom"] == "joined") {
      _screenShareUser.id = data["plugindata"]["data"]["id"];

      // 创建peerConnection
      final Connection connect = _screenShareUser.connect;
      await _await(
        connect.createPeer(
            onIceCandidate: (candidate) {
              _signal.trickleCandidate(_screenSharePluginHandleId, candidate);
            },
            onError: (state, handleId) {
              if (state == "failed") _reConnect(handleId);
            },
            reconnectPeer: _reConnect,
            handleId: _screenSharePluginHandleId),
      );

      // 添加本地流
      await _await(connect.addStream(_screenShareStream));

      // 创建 Offer
      final sdp =
          await _await(connect.createOffer(Connection.publicVideoConstraints));

      // 配置
      final Map body = {
        "request": "configure",
        "muted": true,
        "audio": false,
        "video": true,
        "externals": {"enableVideo": true}
      };
      final Map jsep = {"type": sdp.type, "sdp": sdp.sdp};
      final res = await _await(_signal.configure(
        _screenSharePluginHandleId,
        body,
        jsep: jsep,
      ));

      // 主叫方收到应答
      await _await(connect.receiveAnswer(res["jsep"]));
      _isConnected = true;
    }
  }

  /// 媒体协商
  Future<void> _consult(Map data, {bool reConnect = false}) async {
    final plugindata = data["plugindata"]["data"];
    if (plugindata["videoroom"] == "joined") {
      _me.id = data["plugindata"]["data"]["id"];

      // 创建peerConnection
      final Connection connect = _me.connect;
      await _await(connect.createPeer(
          onIceCandidate: (candidate) =>
              _signal.trickleCandidate(_pluginHandleId, candidate),
          onError: (state, handleId) {
            if (state == "failed") _reConnect(handleId);
          },
          reconnectPeer: _reConnect,
          handleId: _me.handleId));
      RtcLog.log("Created peer connection");

      // 添加本地流
      await _await(connect.addStream(_localStream));
      RtcLog.log("Added local stream");
      _localStream.getAudioTracks()[0].enabled = !_params.muted;
      _localStream.getVideoTracks()[0].enabled = _params.enableCamera;

      // 创建 Offer
      final sdp =
          await _await(connect.createOffer(Connection.publicVideoConstraints));
      RtcLog.log("Created Offer");

      await _setVideoCodecParams(connect, _videoParams);
      RtcLog.log("Set VideoCodecParams");

      // 配置
      final Map body = {
        "request": "configure",
        "mute": _params.muted,
        "video": _params.enableCamera
      };
      final Map jsep = {"type": sdp.type, "sdp": sdp.sdp};
      final res =
          await _await(_signal.configure(_pluginHandleId, body, jsep: jsep));
      RtcLog.log("Setting local description");

      ///房间已满，不能推流了
      if (res["jsep"] == null &&
          res['plugindata']['data'] != null &&
          res['plugindata']['data']['error_code'] == 432) {
        await _handleFull(res, plugindata);
      } else {
        // 主叫方收到应答
        await _await(connect.receiveAnswer(res["jsep"]));
        RtcLog.log("Received answer");

        // 处理用户列表信息
        await _await(_handleUsers(plugindata));

        _isConnected = true;
        // 同步一下当前状态
        Future.delayed(const Duration(seconds: 1), _asyncConfig);
      }

      // 保活
      _keepAlive();
      RtcLog.log("=====Joined video room=====");

      _runLocalAudioInputTimer();
    }
  }

  Future<void> _reConnect(int handleId) async {
    VideoUser restartUser = _users
        .firstWhere((user) => user.handleId == handleId, orElse: () => null);

    restartUser ??= _screenUsers.firstWhere((user) => user.handleId == handleId,
        orElse: () => null);

    RtcLog.log(
        "===== reConnect $restartUser, handleId:$handleId,_signal.isDisposed:${_signal.isDisposed},_disposed:$_disposed, socketRetryNum:${_signal.socketRetryNum}, restartUser:${restartUser?.nickname}");

    if (restartUser == null ||
        _signal.isDisposed ||
        _disposed ||
        _signal.socketRetryNum >= Signal.MAX_SOCKET_RETRY_NUM) return;

    final isConnected = _signal.isConnected();
    bool isSessionExpire = false;

    if (isConnected) {
      try {
        restartUser._reconnectTimer?.cancel();
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
          restartUser._reconnectTimer =
              Timer(const Duration(seconds: 1), () => _reConnect(handleId));
          return;
        }
      }
    } else {
      _keepTimer?.cancel();
      restartUser._reconnectTimer?.cancel();
      restartUser._reconnectTimer =
          Timer(const Duration(seconds: 1), () => _reConnect(handleId));
      return;
    }

    RtcLog.log("_isPConnectRetrying =  ${restartUser._isPCRetrying}");
    if (restartUser._isPCRetrying) return;

    restartUser._isPCRetrying = true;

    ///如果session超时，其他peer过来不进行重连，只需一个走_reJoinRoom
    if (isSessionExpire) {
      for (final user in _users) {
        user._isPCRetrying = true;
      }
      for (final user in _screenUsers) {
        user._isPCRetrying = true;
      }
    }
    final bool result = isSessionExpire
        ? await _reJoinRoom()
        : await _restartPeer(restartUser, handleId);
    RtcLog.log(
        'isSessionExpire = $isSessionExpire, reconnect result = $result');

    /// 如果进入视频房间的信令出错，重走_reConnect
    if (!result &&
        !_disposed &&
        _signal.socketRetryNum < Signal.MAX_SOCKET_RETRY_NUM) {
      restartUser._reconnectPcTime++;
      restartUser._isPCRetrying = false;
      restartUser._reconnectTimer?.cancel();
      if (restartUser._reconnectPcTime >= 3) {
        _signal.reconnectFail();
      } else {
        restartUser._reconnectTimer =
            Timer(const Duration(seconds: 1), () => _reConnect(handleId));
      }
      RtcLog.log('===== join room end ${restartUser._isPCRetrying}');
      return;
    }
    restartUser._reconnectPcTime = 0;
    restartUser._isPCRetrying = false;
    for (final user in _users) {
      user._isPCRetrying = false;
    }
    for (final user in _screenUsers) {
      user._isPCRetrying = false;
    }
    _keepAlive();
  }

  Future<bool> _restartPeer(VideoUser restartUser, int handleId) async {
    try {
      if (_me.id == restartUser.id || _screenShareUser?.id == restartUser.id) {
        RtcLog.log('--publisher restart');
        final Connection connect = restartUser.connect;

        /// iceRestart
        await connect.restartIce();
        //发布者
        // 创建 Offer
        final sdp = await _await(
            connect.createOffer(Connection.publicVideoConstraints));
        RtcLog.log("--publish Created restart ice Offer");

        // 配置
        final Map body = {"request": "configure", "restart": true};
        final Map jsep = {"type": sdp.type, "sdp": sdp.sdp};
        final res = await _await(
            _signal.configure(restartUser.handleId, body, jsep: jsep));

        // 主叫方收到应答
        await _await(connect.receiveAnswer(res["jsep"]));
        RtcLog.log("Received answer");

        // 房间准备成功， 重连成功
        _notice(RoomState.changed);
      } else {
        RtcLog.log('--subscriber restart');
        final Connection connect = restartUser.connect;
        // 告诉服务需要获取offer
        final res = await _signal.getRestartOffer(roomId, restartUser.handleId);

        // 拿到远程offer setRemoteDescription
        await _await(connect.receiveAnswer(res["jsep"]));

        // 创建answer
        final sdp = await _await(
            connect.createAnswerSubs(Connection.subscribeVideoConstraints));

        // 配置
        final Map body = {"request": "start"};
        final Map jsep = {"type": sdp.type, "sdp": sdp.sdp};
        // 发送answer
        await _await(_signal.configure(restartUser.handleId, body, jsep: jsep));

        await connect.setLocalDescription(sdp);

        // 房间准备成功， 重连成功
        _notice(RoomState.changed);
      }
    } catch (e) {
      RtcLog.log('_restartIce error', e.toString());
      return false;
    }
    // 房间准备成功， 重连成功
    _notice(RoomState.ready);
    return true;
  }

  Future<bool> _reJoinRoom() async {
    try {
      /// 保存重连前的听筒或者扬声器状态等状态
      AudioInput audioInput;
      if (Platform.isIOS)
        audioInput = await FlutterAudioManager.getCurrentOutput();
      RtcLog.log("video reJoinRoom audioInpt", audioInput);

      // 重连方案
      if (!UniversalPlatform.isIOS) {
        for (final _user in _users) {
          await _user.connect?.close();
        }
      }

      // 创建会话
      final currentSessionId = await _await(_signal.createSession());
      if (currentSessionId != null && currentSessionId > 0)
        await _sp.setInt(SESSION_KEY, currentSessionId);
      RtcLog.log("Created Session");

      // 挂载插件
      _pluginHandleId = await _await(_signal.attachPlugin(videoPlugin));
      user.handleId = _pluginHandleId;
      RtcLog.log("Attached plugin", _pluginHandleId);

      // 创建房间
      await _await(_signal.createVideoRoom(
          roomId, _pluginHandleId, _params.userId, _params.publishers));
      RtcLog.log("Created video room");

      // 加入房间
      final data = await _await(_signal.joinVideoRoom(roomId, _pluginHandleId,
          _params.display, "publisher", _params.deviceId,
          enableCamera: _params.enableCamera,
          mute: _params.muted,
          video: _params.enableCamera));
      RtcLog.log("Joined room", roomId);
      _notice(RoomState.inRoomStatus, true);

      // 协商
      await _await(_consult(data, reConnect: true));

      // 房间准备成功， 重连成功
      _notice(RoomState.ready);

      /// 恢复听筒或者扬声器状态
      if (Platform.isIOS) {
        if (audioInput.port == AudioPort.receiver) {
          await FlutterAudioManager.changeToReceiver();
        } else if (audioInput.port == AudioPort.speaker) {
          await FlutterAudioManager.changeToSpeaker();
        }
      }
    } catch (e) {
      RtcLog.log('video reJoinRoom error', e.toString());
      return false;
    }
    return true;
  }

  Future<void> _handleFull(res, plugindata) async {
    RtcLog.message('offer result : ${res['plugindata']['data']['error']}');
    final self =
        _users.firstWhere((element) => Global.user.id == element.userId);
    await self.dispose();
    _users.remove(self);
    _notice(RoomState.roomFull);
    await _await(_handleUsers(plugindata));
  }

  Future<void> _setVideoCodecParams(
      Connection connect, VideoParams videoParams) async {
    final RTCRtpSender rtpSender = await connect.getVideoRtpSender();
    final parameters = rtpSender.parameters;
    parameters.encodings.forEach((parameter) {
      parameter.maxBitrate = videoParams.maxBitrate * 1000;
      parameter.minBitrate = videoParams.minBitrate * 1000;
      parameter.maxFramerate = videoParams.fps;
    });
    await rtpSender.setParameters(parameters);
  }

  /// 同步一下当前状态
  void _asyncConfig() {
    if (!_disposed) {
      muted = _params.muted;
      enableCamera = _params.enableCamera;
      if (_useFrontCamera != _params.useFrontCamera) {
        switchCamera();
      }
    }
  }

  /// 保活
  void _keepAlive() {
    _keepTimer?.cancel();
    _keepTimer = Timer.periodic(const Duration(seconds: 25), (t) {
      _signal?.keepAlive()?.catchError((e) {
        _notice(RoomState.error, "网络链接超时".tr);
        _keepTimer.cancel();
      });
    });
    RtcLog.log("Keep alive");
  }

  /// 通知回调
  void _notice(RoomState state, [data]) {
    if (!_disposed && onEvent != null) {
      onEvent(state, data);
    }
  }

  /// 处理静音通知
  void _handleMuted(List participants) {
    for (final videoUser in _users) {
      for (final participant in participants) {
        if (participant["id"] == videoUser.id) {
          videoUser.muted = participant["muted"];
          if (videoUser.muted) videoUser.talking = false;
          // 被动收到的静音消息，如果是自己，表明是自己被别人禁麦/开麦
          if (videoUser.id == _me.id)
            _notice(RoomState.muted, [participant["muted"]]);
        }
      }
    }
    _notice(RoomState.changed);
  }

  /// 处理用户信息
  Future<void> _handleUsers(Map data) async {
    final List list = data['publishers'];
    if (list != null && list.isNotEmpty) {
      for (final p in list) {
        await _handleUser(p);
      }
    }

    ///ios平台默认是打开听筒的，所以做下切换
    if (UniversalPlatform.isIOS) _audioHelp.changeToSpeaker();
  }

  Future<void> _handleUser(p) async {
    if (_screenShareUser?.id == p['id']) {
      RtcLog.log("-----------------is my screen share ignore-----------------");
      return;
    }
    final user = VideoUser();
    try {
      user.id = p['id'];
      user.display = p['display'];
      user.muted = p['mute'] ?? false;
      user.enableCamera =
          p['externals'] == null ? false : p['externals']['enableVideo'];
      user.useFrontCamera = p['fm'] == 'user';
      user.flag = p['fm'] == 'screen_share' ? 'screen_share' : "";
      user.talking = p['talking'];
    } catch (e) {
      RtcLog.log(e);
    }
    if (user.flag == "screen_share" || user.userId == "screenshared") {
      // _screenShareUser = user;
      _screenUsers.add(user);
    } else {
      _users.add(user);
    }
    RtcLog.log("Added user", user.nickname);

    await _await(_handleSubscriber(user));
    _notice(RoomState.joined);
  }

  /// 媒体协商
  Future<void> _handleSubscriber(VideoUser user) async {
    RtcLog.log("=====Start subscriber=====");
    final handleId = await _await(_signal.attachPlugin(videoPlugin));
    user.handleId = handleId;
    final data = await _await(_signal.joinVideoRoom(
        roomId, handleId, user.display, "subscriber", _params.deviceId,
        feed: user.id));

    if (data["plugindata"]["data"] != null)
      _updateMute(user, data["plugindata"]["data"]);
    // 创建peerConnection
    final connect = user.connect;
    await _await(connect.createPeer(
        onIceCandidate: (candidate) =>
            _signal.trickleCandidate(handleId, candidate),
        onError: (state, handleId) {
          if (state == "failed") _reConnect(handleId);
        },
        reconnectPeer: _reConnect,
        handleId: user.handleId));
    RtcLog.log("Created peer connection");

    // 被呼叫方收到 Offer
    await _await(connect.receiveOffer(data["jsep"]));
    RtcLog.log("Receive offer");

    // 被呼叫方创建应答
    final sdp = await _await(
        connect.createAnswerSubs(Connection.subscribeVideoConstraints));
    RtcLog.log("Created answer");

    // 配置
    final Map body = {"request": "start", "room": roomId};
    final Map jsep = {"type": sdp.type, "sdp": sdp.sdp};
    await _await(_signal.configure(handleId, body, jsep: jsep));

    await connect.setLocalDescription(sdp);

    RtcLog.log("Setting local description");
    RtcLog.log("=====End subscriber=====");
  }

  void _updateMute(VideoUser user, p) {
    try {
      user.muted = p['mute'] ?? false;
      user.enableCamera =
          p['externals'] == null ? false : p['externals']['enableVideo'];
    } catch (e) {
      RtcLog.log(e);
    }
  }

  /// 定时获取本地音频状态，来控制自己的说话状态(绿色圈圈)
  void _runLocalAudioInputTimer() {
    _localAudioInputTimer?.cancel();
    _localAudioInputTimer = Timer.periodic(1.seconds, (timer) async {
      // print('getChat localAudio ----- muted: $muted');
      if (muted) {
        user.talking = false;
        _notice(RoomState.changed, 'localTalkingChanged');
        return;
      }

      if (_me == null ||
          _me.connect == null ||
          _signal == null ||
          _signal.isDisposed ||
          !_signal.isConnected()) {
        // print('getChat localAudio -----> timer.cancel');
        _localAudioInputTimer?.cancel();
        return;
      }
      final statList = await _me.connect.getStats();
      if (statList == null) return;

      ///本地音频输入的key值
      const levelKey = 'audioInputLevel';

      // statList.where((s) => s.type == 'ssrc').forEach((e) {
      //   print('getChat ssrc: ${e.id}, ${e.type}, ${e.values}');
      // });
      final stat = statList?.firstWhere(
          (s) =>
              s.type == 'ssrc' &&
              s.values != null &&
              s.values.containsKey(levelKey),
          orElse: () => null);
      if (stat != null) {
        final audioInputLevel =
            int.tryParse(stat.values[levelKey]?.toString() ?? '0') ?? 0;
        // print('getChat ---> level: $audioInputLevel');
        // 测试一些安卓和iOS设备后，1500为一个比较准确的麦克风音量值
        // 大于它就为说话中状态
        if (audioInputLevel > 1500) {
          if (!_me.talking) {
            _me.talking = true;
            // print('getChat ---> level: $audioInputLevel, ${user.nickname}, 说话中 talking: ${user.talking}');
            _notice(RoomState.changed, 'localTalkingChanged');
          }
        } else {
          if (_me.talking) {
            _me.talking = false;
            // print('getChat level: $audioInputLevel, ${user.nickname}, 没说了，talking:${user.talking}');
            _notice(RoomState.changed, 'localTalkingChanged');
          }
        }
      } else {
        ///未获取到stat状态消息
        if (_me.talking) {
          _me.talking = false;
          _notice(RoomState.changed, 'localTalkingChanged');
        }
      }
    });
  }
}

/// 用户数据体
class VideoUser extends RoomUser {
  Connection connect;
  Object dBov;
  MediaStream _stream;
  RTCVideoRenderer _video;
  bool _videoInited = false;
  String flag = "";
  String unityImagePath;
  int handleId;

  ///重连使用
  Timer _reconnectTimer;
  bool _isPCRetrying = false;
  int _reconnectPcTime = 0;

  /// [兼容 Web] 原本类型 RTCVideoRenderer
  dynamic get video {
    if (_videoInited) {
      return _video;
    } else {
      _initVideo();
      return null;
    }
  }

  Future<void> _initVideo() async {
    if (!_videoInited) {
      try {
        _video = RTCVideoRenderer();
        await _video.initialize();
        if (_enableCamera && _stream != null) _video.srcObject = _stream;
        _videoInited = true;
      } catch (e, s) {
        _videoInited = false;

        ///_video?.srcObject 会抛异常，这里catch一下
        logger.severe('_initVideo', e, s);
      }
    }
  }

  VideoUser() {
    _init();
    _initVideo();
  }

  VideoUser.from2();

  void _init() {
    connect = Connection();
    try {
      if (_stream == null) {
        connect.onAddStream = (value) {
          _stream = value;
          if (_videoInited && _stream != null) _video.srcObject = _stream;
        };
      } else {
        _video?.srcObject = _stream;
      }
    } catch (e, s) {
      ///_video?.srcObject 会抛异常，这里catch一下
      logger.severe('_init', e, s);
    }
  }

  VideoUser.from(RoomParams roomParams, [MediaStream stream]) {
    _stream = stream;
    userId = roomParams.userId;
    nickname = roomParams.nickname;
    avatar = roomParams.avatar;
    muted = roomParams.muted;
    enableCamera = roomParams.enableCamera;
    useFrontCamera = roomParams.useFrontCamera;
    _init();
    _initVideo();
  }

  bool _enableCamera = false;

  @override
  bool get enableCamera => _enableCamera;

  @override
  set enableCamera(bool value) {
    if (_enableCamera != value) {
      _enableCamera = value;
      _video?.srcObject = value ? _stream : null;
    }
  }

  set display(String value) {
    if (isNotNullAndEmpty(value)) {
      try {
        final map = json.decode(value);
        if (map is List) {
          userId = map[0];
          nickname = map[1];
          avatar = map[2];
        }
      } catch (e) {
        print(e);
      }
    }
  }

  Future<void> dispose() async {
    _reconnectTimer?.cancel();
    _reconnectPcTime = 0;
    _isPCRetrying = false;

    if (_stream != null)
      for (final track in _stream.getTracks()) {
        await track.stop();
      }

    await _stream?.dispose();
    _stream = null;

    await connect?.dispose();
    connect = null;

    await _video?.dispose();
    _video = null;
    _videoInited = false;
  }

  void muteVideo(bool isMuted) {
    enableCamera = !isMuted;
    _stream?.getVideoTracks()[0].enabled = !isMuted;
  }

  void muteAudio(bool isMuted) {
    muted = isMuted;
    _stream?.getAudioTracks()[0].enabled = !isMuted;
  }
}
