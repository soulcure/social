import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/common/extension/list_extension.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/db/db.dart';
import 'package:im/hybrid/webrtc/room/base_room.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/member_list/item_renderer/audio_chat_member_item_renderer.dart';
import 'package:im/pages/member_list/item_renderer/text_chat_member_item_renderer.dart';
import 'package:im/utils/random_string.dart';
import 'package:pedantic/pedantic.dart';

import '../../../loggers.dart';

class MemberListModel extends ChangeNotifier {
  static final MemberListModel instance = MemberListModel();

  final List<String> _list = [];

  String _guildId;
  String _setMemberSession;

  String get guildIdFlag {
    return _guildId + _setMemberSession;
  }

  UnmodifiableListView<String> get fullList {
    return UnmodifiableListView(_list);
  }

  UnmodifiableListView<String> get list {
    final channel = GlobalState.selectedChannel.value;
    if (channel == null) return UnmodifiableListView(const []);
    final gp = PermissionModel.getPermission(channel.guildId);

    /// 下面的 return 后面的代码的时间复杂度为 n^2，所以应该尽量避免。
    /// 如果当前不是私密频道，就不需要私密判断
    if (!PermissionUtils.isPrivateChannel(gp, channel.id))
      return UnmodifiableListView(_list);

    // 过滤掉私密的,dm的不管
    final tempList = List<String>.from(_list);
    tempList.removeWhere((element) {
      if (channel.type != ChatChannelType.dm) {
        return !PermissionUtils.isChannelVisible(
            gp, GlobalState.selectedChannel.value?.id,
            userId: element);
      }
      return false;
    });
    return UnmodifiableListView(tempList);
  }

  /// 按照角色分类后的用户列表
  final LinkedHashMap<String, Set<String>> _groupList = LinkedHashMap();
  LinkedHashMap<String, List<String>> _filterPrivacyGroupList = LinkedHashMap();

  LinkedHashMap<String, List<String>> get groupList {
    // 过滤掉私密的,dm的不管
    return _filterPrivacyGroupList;
  }

  List<RoomUser> mediaUsers = [];

  ChatChannelType _channelType;

  int get length {
    switch (GlobalState.selectedChannel.value?.type) {
      case ChatChannelType.guildVideo:
      case ChatChannelType.guildVoice:
        return 1;
        break;
      default:
        return groupList.entries
            .where((element) => element.value.isNotEmpty)
            .length;
    }
  }

  int countOfItemInSection(int section) {
    switch (GlobalState.selectedChannel.value?.type) {
      case ChatChannelType.guildVideo:
      case ChatChannelType.guildVoice:
        return mediaUsers.length;
        break;
      default:
        return groupList.values
            .where((element) => element.isNotEmpty)
            .toList()[section]
            .length;
    }
  }

  void setMemberList(
      String guildId, ChatChannelType channelType, List<String> val,
      {String channelId}) {
    logger.info("MemberListModel setMemberList");
    _setMemberSession = RandomString.str;
    _guildId = guildId;

    _channelType = channelType;
    // _channelId = channelId;

    _list.clear();
    _groupList.clear();
    _filterPrivacyGroupList.clear();

    if (_channelType == ChatChannelType.dm) {
      _groupList["0"] = {};
      if (val.hasValue) {
        for (final v in val) {
          _groupList["0"].add(v);
          _list.add(v);
        }
      }
      // filterGroupList();
    } else {
      _list.addAll(val);
    }
    notifyListeners();
  }

  Widget buildItem(int section, int index) {
    switch (GlobalState.selectedChannel.value?.type) {
      case ChatChannelType.guildVideo:
      case ChatChannelType.guildVoice:
        return AudioChatMemberItemRenderer(mediaUsers[index]);
        break;
      default:
        Color color;
        try {
          // 用户正在一直加入时出现过 index 范围错误
          final entry = groupList.entries
              .where((element) => element.value.isNotEmpty)
              .elementAt(section);
          color = PermissionUtils.getRoleColor([entry.key]);
          final userInfo = Db.userInfoBox.get(entry.value[index]);
          return TextChatMemberItemRenderer(userInfo, color: color);
        } catch (e) {
          return const SizedBox();
        }
    }
  }

  void filterGroupList() {
    if (_filterPrivacyGroupList == null || _filterPrivacyGroupList.isEmpty) {
      final guildId = GlobalState.selectedChannel.value?.guildId;
      final channelId = GlobalState.selectedChannel.value?.id;
      final gp = PermissionModel.getPermission(guildId);
      _filterPrivacyGroupList = _groupList.map((key, value) {
        if (!PermissionUtils.isPrivateChannel(gp, channelId))
          return MapEntry<String, List<String>>(key, value.toList());

        final List<String> temp = List<String>.from(value);
        temp.removeWhere((element) {
          if (_channelType != ChatChannelType.dm) {
            return !PermissionUtils.isChannelVisible(gp, channelId,
                userId: element);
          }
          return false;
        });
        return MapEntry<String, List<String>>(key, temp);
      });
    }
  }

  Future<void> remove(String userId) async {
    _list.removeWhere((v) => v == userId);
    final user = await UserInfo.get(userId);
    user.roles = [];
    UserInfo.set(user);
    unawaited(Db.memberListBox
        .put(ChatTargetsModel.instance.selectedChatTarget.id, _list));
  }
}
