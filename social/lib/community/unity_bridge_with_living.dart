import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/model/room_list_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:im/community/unity_bridge_controller.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/live_status_model.dart';

import '../global.dart';

class UnityBridgeWithLiving extends UnityBridgeWithPartial {
  String _roomGuildId;

  UnityBridgeWithLiving(UnityBridgeController controller) : super(controller) {
    _roomGuildId = ChatTargetsModel.instance?.selectedChatTarget?.id;
  }

  @override
  Future<void> destroy() async {}

  @override
  bool handleUnityMessage(
      String messageId, String method, Map<String, String> parameters) {
    switch (method) {
      case "GetLiving":
        _getLiving(messageId, parameters["channelId"]);
        break;
      case "ShowLiving":
        _showLiving(unityBridgeController.context, parameters["channelId"]);
        break;
      case "CloseLiving":
        _closeLiving();
        break;
      case "StartLiving":
        _startLiving(unityBridgeController.context, parameters["channelId"]);
        break;
      case "CanStartLiving":
        _canStartLiving(messageId, parameters["channelId"]);
        break;
      default:
        return false;
    }
    return true;
  }

  /// 6.获取当前指定服务器与频道内的直播ing数量
  static int getLivingCount(String guildId, String channelId) {
    return LiveStatusManager.instance.getChannelLivingCount(guildId, channelId);
  }

  Future<RoomListModel> _getLivingStatus(String roomChannelId) async {
    if (getLivingCount(_roomGuildId, roomChannelId) <= 0) {
      return null;
    }
    final roomListModel =
        await CommunityLiveApi.getLivingStatus(_roomGuildId, roomChannelId);
    if (roomListModel?.anchorId == Global.user.id) {
      return null;
    }
    return roomListModel;
  }

  Future<void> _getLiving(String messageId, String roomChannelId) async {
    final roomListModel = await _getLivingStatus(roomChannelId);
    if (roomListModel == null) {
      unityBridgeController.unityCallback(messageId, {
        "status": "0",
      });
      return;
    }

    unityBridgeController.unityCallback(messageId, {
      "status": "1",
      "anchorId": roomListModel.anchorId,
      "nickname": roomListModel.okNickName,
      "title": roomListModel.roomTitle,
    });
  }

  Future<void> _showLiving(BuildContext context, String roomChannelId) async {
    final roomListModel = await _getLivingStatus(roomChannelId);
    if (roomListModel != null) {
      await CommunityLiveApi.enterLivingRoom(context, roomListModel);
    }
  }

  void _closeLiving() {
    CommunityLiveApi.closeLivingRoom();
  }

  void _startLiving(BuildContext context, String roomChannelId) {
    CommunityLiveApi.startLive(context,
        guildId: _roomGuildId, channelId: roomChannelId);
  }

  void _canStartLiving(String messageId, String roomChannelId) {
    final flag = CommunityLiveApi.hasPermission(
        guildId: _roomGuildId, channelId: roomChannelId);
    unityBridgeController
        .unityCallback(messageId, {"status": flag ? "1" : "0"});
  }
}
