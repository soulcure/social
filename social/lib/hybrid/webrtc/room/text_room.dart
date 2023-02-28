import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:im/hybrid/webrtc/config.dart';
import 'package:im/hybrid/webrtc/room/base_room.dart';
import 'package:im/hybrid/webrtc/signal/connection.dart';
import 'package:im/hybrid/webrtc/signal/signal.dart';
import 'package:im/hybrid/webrtc/tools/rtc_log.dart';

/// 文本聊天室
class TextRoom extends BaseRoom {
  final Signal _signal;
  RoomParams _params;
  Connection _connect;
  bool _disposed = false;
  RTCDataChannel _sendChannel;
  RTCDataChannel _receiveChannel;

  /// 房间id
  String roomId;

  /// 事件回调
  void Function(RoomState state, [TextMessage data]) onEvent;

  TextRoom(this._signal);

  @override
  Future<void> init(String roomId, RoomParams params) async {
    this.roomId = roomId;
    _params = params;
    await _join();
  }

  Future<void> _join() async {
    RtcLog.log("=====Joining text room:$roomId=====");

    // 挂载插件
    final int pluginHandleId = await _await(_signal.attachPlugin(textPlugin));
    RtcLog.log("Attached text plugin", pluginHandleId);

    // 创建文本房间
    await _await(_signal.createTextRoom(roomId, pluginHandleId));
    RtcLog.log("Created text room");

    // 启动数据通道
    final data = await _await(_signal.setupDataChannel(pluginHandleId));
    RtcLog.log("Setup data channel");

    // 媒体协商
    await _await(_consult(data));

    if (onEvent != null) onEvent(RoomState.ready);
  }

  /// 媒体协商
  Future<void> _consult(Map data) async {
    final completer = Completer();
    final handleId = data["sender"];

    // 创建 peerConnection
    _connect = Connection();
    final RTCPeerConnection peer = await _await(_connect.createPeer(
      onIceCandidate: (candidate) {
        _signal.trickleCandidate(handleId, candidate);
      },
    ));
    RtcLog.log("Created peer connection");

    // 接受返回消息
    peer.onDataChannel = (channel) {
      _receiveChannel = channel;
      channel.onMessage = (msg) {
        _onChannelMessage(msg.text);
      };
    };

    // 创建发送通道
    _sendChannel = await _await(_connect.createDataChannel("chat"));
    RtcLog.log("Created send channel");

    // 监听发送通道状态
    _sendChannel.onDataChannelState = (state) {
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        if (completer.isCompleted) return;
        //TODO:这里有问题
        RtcLog.log("Joining room");
        _joinTextRoom(_params.display);

        if (onEvent != null) {
          final message = TextMessage();
          message
            ..date = DateTime.now().toString()
            ..userId = _params.userId
            ..nickname = _params.nickname
            ..avatar = _params.avatar;
          RtcLog.log("=====Joined text room=====");
          onEvent(RoomState.joined, message);
        }

        completer.complete();
      }
    };

    // 接受offer
    await _await(_connect.receiveOffer(data["jsep"]));
    RtcLog.log("Received offer");

    // 被呼叫方创建应答
    final RTCSessionDescription sdp = await _await(_connect.createAnswer(
      Connection.textConstraints,
    ));
    RtcLog.log("Create answer");

    // 配置
    final Map body = {"request": "ack"};
    final Map jsepMap = {"type": sdp.type, "sdp": sdp.sdp};
    await _await(_signal.configure(handleId, body, jsep: jsepMap));
    RtcLog.log("Setting local description");

    return completer;
  }

  /// 加入文字聊天室
  void _joinTextRoom(String display) {
    final Map<String, dynamic> msg = {
      "textroom": 'join',
      "transaction": "transaction",
      "room": roomId,
      "username": display,
    };

    _sendByChannel(msg);
  }

  /// 离开文字聊天室
  void _leaveTextRoom() {
    final Map<String, dynamic> msg = {
      "textroom": "leave",
      "room": roomId,
      "transaction": "",
    };
    _sendByChannel(msg);
  }

  /// 发送文本消息
  void _sendDataMessage(String display, String content) {
    final Map<String, dynamic> msg = {
      "textroom": 'message',
      "transaction": "",
      "room": roomId,
      "username": display,
      "text": content,
    };
    _sendByChannel(msg);
  }

  void _sendByChannel(Map data) {
    if (_sendChannel != null) {
      final msg = json.encode(data);
      RtcLog.message('Send text message', data);
      _sendChannel.send(RTCDataChannelMessage(msg));
    }
  }

  void _onChannelMessage(String msg) {
    RtcLog.message('Receive text message', msg);
    if (onEvent == null) return;
    final Map data = json.decode(msg);
    switch (data['textroom']) {
      case 'message':
        final body = jsonDecode(data["text"] ?? '[]');
        final List from = json.decode(data["from"]);
        final message = TextMessage();
        message
          ..date = data['date']
          ..type = body[0]
          ..content = body[1]
          ..userId = from[0]
          ..nickname = from[1]
          ..avatar = from[2];
        RtcLog.log("Receive message", message.content);
        onEvent(RoomState.messaged, message);
        break;
      case 'join':
        final username = data["username"];
        // 判断解决有概率会发送两次
        if (username != _params.display) {
          final List from = json.decode(data["username"]);
          final message = TextMessage();
          message
            ..date = DateTime.now().toString()
            ..userId = from[0]
            ..nickname = from[1]
            ..avatar = from[2];
          RtcLog.log("Joined text room", message.nickname);
          onEvent(RoomState.joined, message);
        }
        break;
      case 'leave':
        final List from = json.decode(data["username"]);
        final message = TextMessage();
        message
          ..date = DateTime.now().toString()
          ..userId = from[0]
          ..nickname = from[1]
          ..avatar = from[2];
        RtcLog.log("Leaved text room", message.nickname);
        onEvent(RoomState.leaved, message);
        break;
    }
  }

  /// 发送消息 type 消息类型（text、image）
  void sendMessage(String type, String content) {
    RtcLog.log("Send message", content);
    _sendDataMessage(_params?.display, json.encode([type, content]));
  }

  Future _await(Future future) async {
    if (!_disposed) {
      final res = await future;
      return res;
    }
    throw 'canceled';
  }

  @override
  Future<void> leave() async {
    if (!_disposed) {
      _disposed = true;
      onEvent = null;
      _leaveTextRoom();
      await _sendChannel?.close();
      await _receiveChannel?.close();
      await _connect?.close();
    }
  }
}

/// 消息体
class TextMessage {
  String content;
  String date;
  String type;
  String userId;
  String nickname;
  String avatar;
}
