import 'dart:async';

import 'package:im/community/unity_bridge_controller.dart';
import 'package:im/community/virtual_video_room/controllers/virtual_room_controller.dart';
import 'package:im/loggers.dart';
import 'package:get/get.dart';

enum _WebRTCState
{
  Joining,
  Joined,
  Exiting,
  Exited,
}

abstract class _WebRTCAction
{
  final UnityBridgeWithWebRTC _controller;
  _WebRTCAction(this._controller);

  /// 是否可以跳过
  bool get canSkip;
  /// 是否可以执行
  bool get canExecute;
  /// 执行动作，ignore: 忽略执行，认为执行失败
  Future<void> execute(bool ignore);
}

class _WebRTCJoinAction extends _WebRTCAction
{
  String messageId;
  String roomId;
  bool isMicrophoneEnable;
  bool isCameraEnable;
  bool isSpeakerEnable;
  _WebRTCJoinAction(UnityBridgeWithWebRTC bridge, this.roomId, this.messageId, this.isMicrophoneEnable, this.isCameraEnable, this.isSpeakerEnable) : super(bridge);

  /// 是否可以跳过，要加入房间与当前房间相同则可以跳过
  @override
  bool get canSkip => _controller._webRTCState == _WebRTCState.Joined && roomId == _controller._virtualRoomController.roomParams.roomId;

  /// 是否可以执行，处于退出状态可以加入
  @override
  bool get canExecute => _controller._webRTCState == _WebRTCState.Exited;

  @override
  Future<void> execute(bool ignore) async {
    if(ignore){
      _controller.unityBridgeController.unityCallback(messageId, {"isJoined": "-1"});
      return;
    }
    if(canSkip){
      _controller.unityBridgeController.unityCallback(messageId, {"isJoined": "-2"});
      return;
    }
    _controller._webRTCState = _WebRTCState.Joining;
    try {
      await _controller._virtualRoomController.joinRoom(VirtualRoomParams(
          roomId, isMuted: !isMicrophoneEnable,
          isCameraOpen: isCameraEnable,
          isAllAudioMuted: !isSpeakerEnable), _controller);
      while(_controller._virtualRoomController.myRoomState == MyRoomState.joining) {
        await 100.milliseconds.delay();
      }
    }catch(e){
      logger.info("虚拟社区加入webRtc失败:$e");
    }
    if(_controller._virtualRoomController.myRoomState == MyRoomState.joined){
      _controller._webRTCState = _WebRTCState.Joined;
      _controller.unityBridgeController.unityCallback(messageId, {"isJoined": "1"});
    }else{
      _controller._webRTCState = _WebRTCState.Exited;
      _controller.unityBridgeController.unityCallback(messageId, {"isJoined": "0"});
    }
  }
}

class _WebRTCExitAction extends _WebRTCAction
{
  _WebRTCExitAction(UnityBridgeWithWebRTC bridge) : super(bridge);

  /// 是否可以跳过，退出不能跳过
  @override
  bool get canSkip => false;

  /// 是否可以执行，处于已加入状态可以退出
  @override
  bool get canExecute => _controller._webRTCState == _WebRTCState.Joined;

  @override
  Future<void> execute(bool ignore) async {
    if(ignore){
      return;
    }
    _controller._webRTCState = _WebRTCState.Exiting;
    try{
      await _controller._virtualRoomController.exitRoom();
    }catch(e){
      logger.info("虚拟社区退出webRtc失败:$e");
    }
    _controller._webRTCState = _WebRTCState.Exited;
  }
}

class UnityBridgeWithWebRTC extends UnityBridgeWithPartial
{
  _WebRTCState _webRTCState = _WebRTCState.Exited;
  final List<_WebRTCAction> _webRTCActions = <_WebRTCAction>[];

  final VirtualRoomController _virtualRoomController;
  UnityBridgeWithWebRTC(UnityBridgeController controller)
      : _virtualRoomController = VirtualRoomController.to(), super(controller);

  @override
  Future<void> destroy() async {
    await _virtualRoomController.exitRoom();
    await _virtualRoomController.destroy();
  }

  Future<String> getUserPhoto(String userId) async {
    final Map<String, String> result = await unityBridgeController.callUnity("GetUserPhoto", userId);
    return result["path"];
  }

  @override
  bool handleUnityMessage(String messageId, String method,
      Map<String, String> parameters) {
    switch (method) {
      case "WebRTCJoinRoom":
        _joinRoom(
          parameters["roomId"],
          messageId,
          parameters["isMicrophoneEnable"] == "1",
          parameters["isCameraEnable"] == "1",
          parameters["isSpeakerEnable"] == "1",
        );
        break;
      case "WebRTCQuitRoom":
        _quitRoom();
        break;
      case "WebRTCToggleRoomParams":
        _toggleRoomParams(
          parameters["isMicrophoneEnable"] == "1",
          parameters["isCameraEnable"] == "1",
          parameters["isSpeakerEnable"] == "1",
        );
        break;
      default:
        return false;
    }
    return true;
  }

  void _joinRoom(String roomId, String messageId, bool isMicrophoneEnable, bool isCameraEnable, bool isSpeakerEnable)
  {
    _webRTCActions.add(_WebRTCJoinAction(
      this,
      roomId,
      messageId,
      isMicrophoneEnable,
      isCameraEnable,
      isSpeakerEnable,
    ));
    if(_webRTCActions.length == 1){
      _excuteWebRTCActions();
    }
  }

  void _quitRoom()
  {
    _webRTCActions.add(_WebRTCExitAction(this));
    if(_webRTCActions.length == 1){
      _excuteWebRTCActions();
    }
  }

  void _toggleRoomParams(bool isMicrophoneEnable, bool isCameraEnable, bool isSpeakerEnable)
  {
    if(_virtualRoomController.myRoomState == MyRoomState.joining ||
        _virtualRoomController.myRoomState == MyRoomState.joined) {
      if(_virtualRoomController.roomParams.isMuted == isMicrophoneEnable){
        _virtualRoomController.toggleMuted();
      }
      if(_virtualRoomController.roomParams.isCameraOpen != isCameraEnable){
        _virtualRoomController.toggleCamera();
      }
      if(_virtualRoomController.roomParams.isAllAudioMuted == isSpeakerEnable){
        _virtualRoomController.muteAllAudio();
      }
    }
  }

  Future<void> _excuteWebRTCActions() async{
    //1. 执行第一个Action
    final _WebRTCAction action = _webRTCActions[0];
    await action.execute(false);

    //2. 第一个Action执行完后如果还有Action，则需要按逆序判断状态是否可以执行
    _webRTCActions.removeAt(0);
    final int length = _webRTCActions.length;
    if(length > 0)
    {
      //找到最后一个可执行或可跳过的Action
      int lastCanExcuteIndex = -1;
      for(int i=length-1;i>=0;i--){
        if(_webRTCActions[i].canExecute || _webRTCActions[i].canSkip) {
          lastCanExcuteIndex = i;
          break;
        }
      }
      //先将可执行或可跳过前的Action做忽略处理，再对最后一个可执行或可跳过的Action执行动作
      if(lastCanExcuteIndex >= 0){
        for(int i=0; i< lastCanExcuteIndex-1; i++){
          // ignore: unawaited_futures
          _webRTCActions[i].execute(true);
        }
        _webRTCActions.removeRange(0, lastCanExcuteIndex);
        await _excuteWebRTCActions();
      }else{
        for(int i=0; i< length; i++){
          // ignore: unawaited_futures
          _webRTCActions[i].execute(true);
        }
        _webRTCActions.clear();
      }
    }
  }
}

