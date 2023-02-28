import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/app/modules/friend_list_page/controllers/friend_list_page_controller.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/global_methods/goto_direct_message.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/search/model/search_model.dart';
import 'package:pedantic/pedantic.dart';

class CommonShareController extends GetxController {
  CommonShareController({this.guildId, this.data});

  final MessageContentEntity data;

  final String guildId;

  FocusNode focusNode = FocusNode();
  SearchInputModel searchInputModel;
  TextEditingController searchInputController;
  String searchKey;

  List<UserInfo> _recentUsers;

  GuildTarget _guildTargetModel;
  final List<ChatChannel> channels = [];

  // final List<bool> channelValue = [];
  final _selectedIndex = (-1).obs;

  int get select => _selectedIndex.value;

  set select(int index) => _selectedIndex.value = index;

  ChatChannel _selectedChannel;

  ChatChannel get selectedChannel => _selectedChannel;

  ///key为channelId
  // final Map<String, ChatChannel> selectedChannels = {};

  @override
  void onInit() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    searchInputModel = SearchInputModel();
    searchInputController = TextEditingController();

    _loadChannels();

    super.onInit();
  }

  @override
  void onClose() {
    searchInputModel.dispose();
    searchInputController.dispose();
    super.onClose();
  }

  void _loadChannels() {
    if (guildId == null) return;
    final list = ChatTargetsModel.instance.chatTargets;
    list.forEach((e) {
      if (e is GuildTarget && e.id == guildId) _guildTargetModel = e;
    });
    if (_guildTargetModel == null) return;

    _guildTargetModel.channels?.forEach((channel) {
      final isTextChannel = channel.type == ChatChannelType.guildText;
      final GuildPermission gp = PermissionModel.getPermission(channel.guildId);
      final canSendMes = PermissionUtils.oneOf(gp, [Permission.SEND_MESSAGES],
          channelId: channel.id);
      final isVisible = PermissionUtils.isChannelVisible(
          gp, channel.id); //[dj private channel]
      if (isTextChannel && canSendMes && isVisible) {
        channels.add(channel);
        // channelValue.add(false);
      }
    });
  }

  Future<List<UserInfo>> searchMembers(String key,
      {String source = "all"}) async {
    final Set<UserInfo> userList = {};

    final friends =
        FriendListPageController.to.list.map((e) => e.user).toList();
    if (source == "recents" || source == "all") {
      unawaited(loadCompleteInfo());
      final recentUsers = UnmodifiableListView(_recentUsers);
      userList.addAll(recentUsers.where((element) =>
          (element.nickname != null && element.nickname.contains(key)) ||
          (element.gnick != null && element.gnick.contains(key)) ||
          (element.username != null && element.username.contains(key))));
    }

    if (source == "friends" || source == "all") {
      userList.addAll(friends.where((element) =>
          (element.nickname != null && element.nickname.contains(key)) ||
          (element.gnick != null && element.gnick.contains(key)) ||
          (element.username != null && element.username.contains(key))));
    }
    return userList.toList();
  }

  Future loadCompleteInfo() async {
    // 首次获取，则拉取
    if (_recentUsers != null) return;
    _recentUsers = [];
    final channelsDm = DirectMessageController.to.channelsDm;
    for (final ChatChannel c in channelsDm) {
      final u = await UserInfo.get(c.guildId);
      _recentUsers.add(u);
    }
  }

  void onChannelItemClick(int index) {
    select = index;
    _selectedChannel = index >= 0 ? channels[index] : null;
  }

  /// 分享给用户
  void onShareToUser(UserInfo user) {
    sendDirectMessage(user.userId, data);
    Get.back(result: [
      {
        "type": "user",
        "userId": user?.userId ?? "",
        "nickname": user?.nickname ?? "",
        "avatar": user.avatar ?? "",
        "gender": user?.gender ?? "",
        "shortId": user?.username ?? "",
      }
    ]);
  }

  /// 分享到频道
  void onShareToChannel<T>(String channelId) {
    TextChannelController.to(channelId: selectedChannel.id).sendContent(data);
    Get.back(result: [
      {
        "type": "channel",
        "id": selectedChannel.id,
        "guildId": selectedChannel.guildId,
        "name": selectedChannel.name,
        "topic": selectedChannel.topic
      }
    ]);
  }
}
