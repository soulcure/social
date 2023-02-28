import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/model/chat_target_model.dart';

import '../../global.dart';
import 'last_reaction_item.dart';

part 'dm_last_message_desc.g.dart';

@HiveType(typeId: 16)
class DmLastMessageDesc extends HiveObject {
  @HiveField(0)
  final BigInt messageId;
  @HiveField(1)
  String desc;
  @HiveField(2)
  final String senderId;
  @HiveField(3)
  final String senderNiceName;

  //圈子消息频道使用guildId,取服务器昵称
  @HiveField(4)
  final String guildId; //只有圈子消息才有guildId
  @HiveField(5)
  final List<String> userIdList;
  @HiveField(6)
  List<LastReactionItem> lastReaction; //来自于hive

  String channelId;
  Map reaction; //来自notPull,notPull如果有数据，全量替换hive,并存储

  DmLastMessageDesc({
    this.messageId,
    this.desc,
    this.senderId,
    this.senderNiceName,
    this.channelId,
    this.guildId,
    this.userIdList,
    this.lastReaction,
    this.reaction,
  });

  ///普通纯文字描述信息
  DmLastMessageDesc.normal(this.messageId, this.desc,
      {this.senderId, this.senderNiceName, this.guildId, this.userIdList})
      : lastReaction = [] {
    //_checkAtUserId(); //不一次性转换@userId
  }

  ///群聊消息描述信息
  DmLastMessageDesc.fromGroup(
      this.messageId, this.desc, this.senderId, this.senderNiceName,
      {this.guildId, this.userIdList})
      : lastReaction = [] {
    //_checkAtUserId(); //不一次性转换@userId
  }

  ///圈子消息通道描述信息
  DmLastMessageDesc.fromGuild(
      this.messageId, this.desc, this.guildId, this.channelId,
      {this.senderId, this.senderNiceName, this.userIdList})
      : lastReaction = [] {
    // _checkTransformGuildNickName(guildId, channelId, desc);
  }

  ///离线最后一条消息描述信息
  DmLastMessageDesc.fromNotPull(
      this.messageId, this.desc, this.channelId, this.reaction,
      {this.senderId, this.senderNiceName, this.guildId, this.userIdList})
      : lastReaction = [] {
    ///来自notPull,notPull如果有数据，全量替换hive,并存储
    if (reaction != null && reaction.isNotEmpty) {
      lastReaction.clear();
      debugPrint("DmLastMessageDesc reaction map=$reaction");
      reaction.forEach((key, value) {
        try {
          final name = key;
          final count = (value as List).length;
          final item = LastReactionItem(name, count);
          lastReaction.add(item);
        } catch (e) {
          print("DmLastMessageDesc e=$e");
        }
      });
    }
  }

  // void _checkAtUserId() {
  //   ///私信列表被收到清除hive数据的情况
  //   if (desc.contains(r'${@!') && desc.contains('}')) {
  //     final int start = desc.indexOf(r'${@!');
  //     final int end = desc.indexOf('}', start + 4);
  //
  //     final String endStr = desc.substring(end + 1, desc.length);
  //
  //     final id = desc.substring(start + 4, end);
  //     if (id == Global.user.id) {
  //       desc = '${'@了你'.tr}$endStr';
  //     } else if (id.isNotEmpty) {
  //       final String name =
  //           Db.userInfoBox.get(id)?.showName(hideRemarkName: true);
  //       if (name != null) {
  //         desc = "@$name $endStr";
  //       } else {
  //         _reqUserInfo(id, endStr);
  //       }
  //     }
  //   } else if (desc.contains(r'${#') && desc.contains('}')) {
  //     final int start = desc.indexOf(r'${#');
  //     final int end = desc.indexOf('}', start + 3);
  //     final id = desc.substring(start + 3, end);
  //     final channel = Db.channelBox.get(id);
  //     if (channel != null) {
  //       desc = "#${channel.name}";
  //     }
  //   }
  // }

  // Future<void> _reqUserInfo(String id, String endStr) async {
  //   if (id == null || id.isEmpty) return;
  //
  //   final List<UserInfo> res = await UserApi.getUserInfo([id]);
  //   if (res != null && res.isNotEmpty) {
  //     res.forEach((e) => Db.userInfoBox.put(e.userId, e));
  //
  //     if (channelId != null) {
  //       final String name =
  //           Db.userInfoBox.get(id)?.showName(hideRemarkName: true);
  //       if (name != null) {
  //         desc = "@$name $endStr";
  //       }
  //
  //       ///只尝试一次，方式死循环
  //       if (desc.contains(r'${@!') && desc.contains('}')) return;
  //
  //       final newDesc = DmLastMessageDesc.normal(messageId, desc);
  //       await Db.dmLastDesc.put(channelId, newDesc);
  //     }
  //   }
  // }

  // //是否圈子通道消息中带有 @ userId
  // void _checkTransformGuildNickName(
  //     String guildId, String channelId, String desc) {
  //   if (guildId.noValue || channelId.noValue) return;
  //
  //   ///是否圈子通道消息中带有 @ userId
  //   final List<String> idList = MessageUtil.getUserIdListInText(desc);
  //
  //   ///需要置换成对应服务台的昵称
  //   if (idList != null && idList.isNotEmpty) {
  //     _transformGuildNickName(guildId, channelId, desc);
  //   }
  // }
  //
  // ///转换圈子通道消息中带有 @ userId
  // Future<void> _transformGuildNickName(
  //     String guildId, String channelId, String desc) async {
  //   if (guildId.noValue || channelId.noValue) return;
  //
  //   this.desc = await MessageUtil.toDescString(desc, guildId);
  //
  //   ///是否圈子通道消息中带有 @ userId,只尝试一次，方式死循环
  //   final List<String> idList = MessageUtil.getUserIdListInText(this.desc);
  //   if (idList != null && idList.isNotEmpty) return;
  //
  //   final newDesc = DmLastMessageDesc.normal(messageId, this.desc);
  //   await Db.dmLastDesc.put(channelId, newDesc);
  // }

  String descText(ChatChannel channel) {
    if (channel?.type == ChatChannelType.group_dm) {
      final bool isSelf = Global.user.id == senderId;
      final bool hasSend = senderNiceName?.hasValue ?? false;

      final nickName = hasSend ? '$senderNiceName: ' : '';
      final text = '${isSelf ? '' : nickName}${desc ?? ''}';
      return text;
    } else if (channel?.type == ChatChannelType.dm) {
      if (senderId.hasValue) {
        final user = Db.userInfoBox.get(senderId);
        final showName = user?.showName(hideGuildNickname: true);
        if (showName != null) return '你已添加了%s,现在可以开始聊天了'.trArgs([showName]);
      }
    }
    return desc;
  }
}
