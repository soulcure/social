import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/routes/app_pages.dart' as get_pages;
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_state.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/json/redpack_entity.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/json/unsupported_entity.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/stick_message_controller.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/topic/controllers/topic_controller.dart';
import 'package:im/utils/emo_util.dart';
import 'package:im/utils/im_utils/channel_util.dart';

import 'items/components/message_reaction.dart';

class MessagePermissionState<T extends StatefulWidget>
    extends PermissionState<T> {
  final List<ReactionEntity> emojiList = [];
  ChatChannel _channel;
  bool _manageMessageAllowed = true;

  MessageEntity message;

  bool get isHigherRole {
    final UserInfo user = Db.userInfoBox.get(message.userId);
    return PermissionUtils.comparePosition(roleIds: user.roles) == 1;
  }

  bool get canManageMessages {
    return _channel?.type == ChatChannelType.dm ||
        PermissionUtils.oneOf(guildPermission, [Permission.MANAGE_MESSAGES],
            channelId: _channel.id);
  }

  bool get addReactionAllowed {
    return message.isNormal &&
        !message.isBlocked &&
        !message.isIllegal &&
        (_channel?.type == ChatChannelType.dm ||
            PermissionUtils.oneOf(guildPermission, [Permission.ADD_REACTIONS],
                channelId: _channel.id));
  }

  bool get canRecall {
    if (message.isCircleMessage) return false;
    final m = message;
    final isLocalUser = Global.user.id == m.userId;

    if (m.isRecalled || m.deleted == 1) return false;

    /// 本地消息不可撤回
    if (!m.isNormal) return false;

    /// 被对方屏蔽消息不可撤回
    if (m.isBlocked) return false;

    /// 红包消息不可撤回
    if (m.content is RedPackEntity) return false;

    /// 消息是服务器拥有者发的，如果就是自己，则能撤回，否则不能撤回
    if (PermissionUtils.isGuildOwner(userId: m.userId) &&
        !GlobalState.isDmChannel) {
      return isLocalUser;
    }

    /// 发送者有 2 分钟时间限制去撤回消息
    if (isLocalUser) {
      if (m.time.add(const Duration(minutes: 2)).isBefore(DateTime.now())) {
        return false;
      }
    } else if (GlobalState.isDmChannel) {
      return false;
    } else if (!(_manageMessageAllowed && isHigherRole)) {
      return false;
    }

    return true;
  }

  bool get canBack {
    if (kIsWeb) {
      if (TopicController.to().channelId != null) {
        return true;
      }
      return false;
    }

    final bool isRoute = Get.currentRoute == get_pages.Routes.TOPIC_PAGE;
    // final msg = InMemoryDb.getMessage(
    //     message.channelId, BigInt.parse(message.messageId));
    // final TopicController topicController = TopicController.to();
    //
    // return isRoute && msg != null && !topicController.isTopicShare;
    return isRoute;
  }

  bool get canLink {
    if (message.isCircleMessage) return false;
    if (!message.isNormal) {
      return false;
    } else if (_channel?.type == ChatChannelType.dm ||
        _channel?.type == ChatChannelType.group_dm) {
      return false;
    } else {
      final GuildPermission gp =
          PermissionModel.getPermission(_channel?.guildId);
      return PermissionUtils.oneOf(gp, [Permission.MANAGE_MESSAGES]);
    }
  }

  bool get canPin {
    if (message.isCircleMessage) return false;
    final m = message;
    if (!m.isNormal ||
        m.isPinned ||
        m.isRecalled ||
        m.deleted == 1 ||
        m.content.messageState.value != MessageState.sent ||
        m.isIllegal) return false;
    if (message.isDmGroupMessage) return false;
    final GuildPermission gp = PermissionModel.getPermission(guildId);
    if (!GlobalState.isDmChannel &&
        !PermissionUtils.oneOf(gp, [Permission.MANAGE_MESSAGES],
            channelId: _channel.id)) {
      // 判断权限，但是私聊的权限不管
      return false;
    }
    return true;
  }

  bool get canUnpin {
    if (message.isCircleMessage) return false;
    if (!message.isNormal) return false;
    final GuildPermission gp = PermissionModel.getPermission(guildId);
    if (!GlobalState.isDmChannel &&
        !PermissionUtils.oneOf(gp, [Permission.MANAGE_MESSAGES],
            channelId: _channel.id)) {
      // 判断权限，但是私聊的权限不管
      return false;
    }
    if (message.isDmGroupMessage) return false;
    return message.isPinned;
  }

  bool get canStick {
    if (message.isCircleMessage) return false;
    if (!message.isNormal) return false;
    final GuildPermission gp = PermissionModel.getPermission(guildId);
    if (TextChannelController.dmChannel?.type == ChatChannelType.group_dm)
      return false;
    if (message.isDmGroupMessage) return false;
    if (!GlobalState.isDmChannel &&
        !PermissionUtils.oneOf(gp, [Permission.MANAGE_MESSAGES],
            channelId: _channel.id)) {
      return false;
    }
    final StickMessageController stickMessageController =
        Get.find(tag: _channel.id);
    return !stickMessageController.isMessageSticky(message.messageId);
  }

  bool get canUnStick {
    if (message.isCircleMessage) return false;
    if (!message.isNormal) return false;
    final GuildPermission gp = PermissionModel.getPermission(guildId);
    if (TextChannelController.dmChannel?.type == ChatChannelType.group_dm)
      return false;
    if (message.isDmGroupMessage) return false;
    if (!GlobalState.isDmChannel &&
        !PermissionUtils.oneOf(gp, [Permission.MANAGE_MESSAGES],
            channelId: _channel.id)) {
      return false;
    }
    final StickMessageController stickMessageController =
        Get.find(tag: _channel.id);
    return stickMessageController.isMessageSticky(message.messageId);
  }

  bool get canCopy {
    final m = message;
    if (m.content is UnSupportedEntity) return false;

    final content = m.content;
    return [TextEntity, StickerEntity, RichTextEntity]
        .contains(content.runtimeType);
  }

  bool get canReaction {
    final ret = message.canAddReaction &&
        message.isNormal &&
        !message.isBlocked &&
        !message.isIllegal &&
        (_channel.type == ChatChannelType.dm ||
            _channel.type == ChatChannelType.group_dm ||
            PermissionUtils.oneOf(guildPermission, [Permission.ADD_REACTIONS],
                channelId: _channel.id));
    return ret;
  }

  bool get canForward {
    return false; // 暂时隐藏该功能

//    final m = widget.message;
//    if (m.isRecalled || m.deleted == 1 || m.isIllegal) return false;
//
//    /// 被对方屏蔽消息
//    if (m.isBlocked) return false;
//    return true;
  }

  // bool get canDel {
  //   final content = message.content;
  //   if (content is RedPackEntity) {
  //     return false;
  //   }
  //   return true;
  // }

  @override
  String get guildId => GlobalState.selectedChannel?.value?.guildId;

  @override
  void initPermissionState() {
    if (EmoUtil.instance.curReaEmoList.isEmpty) {
      EmoUtil.instance.doInitial().then((value) {
        emojiList.addAll(EmoUtil.instance.curReaEmoList);
        setState(() {});
      });
    } else
      emojiList.addAll(EmoUtil.instance.curReaEmoList);
    _channel = ChannelUtil.instance.getChannel(message.channelId);

    ///移除围观表情
    final int index =
        emojiList.indexWhere((e) => e.name == TopicController.emojiName);

    if (index >= 0) {
      emojiList.removeAt(index);
    }
  }

  @override
  void onPermissionStateChange() {
    refresh(notify: false);
  }

  void refresh({bool notify = true}) {
    if (message.isCircleMessage) return;
    if (guildPermission == null) return;
    _manageMessageAllowed = _channel?.type == ChatChannelType.dm ||
        _channel?.type == ChatChannelType.group_dm ||
        PermissionUtils.oneOf(guildPermission, [Permission.MANAGE_MESSAGES],
            channelId: _channel.id);
  }
}
