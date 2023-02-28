import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/mute/controllers/mute_listener_controller.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/db/db.dart';
import 'package:im/db/reaction_table.dart';
import 'package:im/global.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/common.dart';
import 'package:im/pages/home/view/text_chat/items/components/message_reaction.dart';
import 'package:im/pages/home/view/text_chat/items/components/reaction_cache_bean.dart';
import 'package:im/pages/home/view/text_chat/items/components/reaction_detail.dart';
import 'package:im/pages/home/view/text_chat/items/components/reaction_util.dart';
import 'package:im/pages/topic/controllers/topic_controller.dart';
import 'package:oktoast/oktoast.dart';

import '../../../utils/emo_util.dart';
import 'chat_target_model.dart';

class ReactionModel {
  String messageId;
  String channelId;
  List<ReactionEntity> actions;

  /// * 是否圈子回复消息
  /// * 圈子回复消息的表态：不入库，没有notPull离线
  bool get isCircleMessage => postId.hasValue;
  String guildId;
  String postId;

  List<ReactionEntity> get reactions {
    final int index =
        actions.indexWhere((v) => TopicController.isSurrounding(v.name));
    if (index >= 0) {
      actions.removeAt(index);
    }
    return actions;
  }

  Rx<ReactionModel> updater;

  ReactionModel({
    this.messageId,
    this.actions,
    @required this.channelId,
    this.guildId,
    this.postId,
  }) {
    actions ??= [];
    actions.sort((a, b) => (b.name).compareTo(a.name));
    updater = obs;
  }

  /// - 通用表态入口
  /// - isShowMutedMsg:true ,默认要提示禁言提示，在自动表态场景下被禁言了就不提示了。
  Future<void> toggle(
    String emojiName, {
    String msgId,
    bool isShowMutedMsg = true,
  }) async {
    if (MuteListenerController.to.isMuted && !GlobalState.isDmChannel) {
      // 是否被禁言
      if (isShowMutedMsg) showToast('你已被禁言，无法操作'.tr);
      return;
    }

    ///表态前判断是否有表态权限
    if (!checkPermission()) {
      showToast(errorCode2Message['1012']);
      return;
    }

    final reaction =
        actions.firstWhere((v) => v.name == emojiName, orElse: () => null);
    if (reaction != null && reaction.me) {
      ///取消表态
      await deleteReaction(reaction, emojiName, msgId ?? messageId);
    } else {
      ///新增表态
      await createReaction(reaction, emojiName, msgId ?? messageId);
    }
  }

  ///创建表态
  Future<void> createReaction(
      ReactionEntity reaction, String emojiName, String messageId) async {
    int count = 0;
    if (reaction != null) {
      reaction.count++;
      reaction.me = true;
      count = reaction.count;
    } else {
      reaction = ReactionEntity(emojiName, me: true);
      actions.add(reaction);
      actions.sort((a, b) => (b.name).compareTo(a.name));
      count = 1;
    }
    notify();

    EmoUtil.instance.updateReactionEmojiOrder(emojiName);

    ReactionResult res;
    if (!isCircleMessage) {
      await ReactionTable.append(messageId, emojiName, count, true);
      res = await ReactionUtil()
          .createReaction(Global.user.id, messageId, channelId, emojiName);
    } else {
      res = await ReactionUtil().createCircleReaction(
          guildId, channelId, postId, messageId, emojiName);
    }

    if (res == ReactionResult.success) {
      debugPrint("reaction createReaction success");
    } else if (res == ReactionResult.error) {
      ///客户端已经表态成功，服务器返回你已经表态过了
      ///*NOTE*:客户端本地状态正确，无需回撤
      // reaction.count--;
      // reaction.me = true; //暂时的错误只有一种，重复表态
      // if (reaction.count <= 0) {
      //   actions.remove(reaction);
      // }
      // count = reaction.count;
      //
      // notify();
      // if (!isCircleMessage)
      //   await ReactionTable.remove(messageId, emojiName, count, true);
    } else if (res == ReactionResult.notPermission) {
      showToast(errorCode2Message['1012']);

      reaction.count--;
      reaction.me = false; //无权限表态
      if (reaction.count <= 0) {
        actions.remove(reaction);
      }
      count = reaction.count;

      notify();
      if (!isCircleMessage)
        await ReactionTable.remove(messageId, emojiName, count, false);
    } else {
      if (!isCircleMessage) {
        debugPrint("reaction createReaction add to cache");

        ///add to cache
        final ReactionCacheBean cacheBean =
            ReactionCacheBean.formValue(channelId, messageId, emojiName, 1);
        await ReactionUtil().appendReactionToCache(cacheBean);
      }
    }
  }

  ///取消表态
  Future<void> deleteReaction(
      ReactionEntity reaction, String emojiName, String messageId) async {
    assert(reaction != null);

    reaction.count--;
    reaction.me = false;
    if (reaction.count <= 0) {
      actions.remove(reaction);
    }
    notify();
    ReactionResult res;
    if (!isCircleMessage) {
      await ReactionTable.remove(messageId, emojiName, reaction.count, false);
      res = await ReactionUtil()
          .deleteReaction(Global.user.id, messageId, channelId, emojiName);
    } else {
      res = await ReactionUtil().deleteCircleReaction(
          guildId, channelId, postId, messageId, emojiName);
    }

    if (res == ReactionResult.success) {
      debugPrint("reaction deleteReaction success");
    } else if (res == ReactionResult.error) {
      ///客户端已经取消表态成功，服务器返回你未表态过，取消表态错误
      ///*NOTE*:客户端本地状态正确，无需回撤
      // int count;
      // reaction.count++;
      // reaction.me = false; //暂时的错误只有一种，重复表态
      // if (reaction.count == 1) {
      //   actions.add(reaction);
      // }
      // count = reaction.count;
      //
      // notify();
      // await ReactionTable.append(messageId, emojiName, count, false);
    } else if (res == ReactionResult.notPermission) {
      showToast(errorCode2Message['1012']);

      int count;
      final tempReaction =
          actions.firstWhere((v) => v.name == emojiName, orElse: () => null);
      if (tempReaction != null) {
        tempReaction.count++;
        tempReaction.me = true;
        count = tempReaction.count;
      } else {
        final ReactionEntity emoji = ReactionEntity(emojiName);
        actions.add(emoji);
        actions.sort((a, b) => (b.name).compareTo(a.name));
        count = 1;
      }
      notify();
      if (!isCircleMessage)
        await ReactionTable.append(messageId, emojiName, count, true);
    } else {
      if (!isCircleMessage) {
        debugPrint("reaction deleteReaction add to cache");

        ///remove to cache
        final ReactionCacheBean cacheBean =
            ReactionCacheBean.formValue(channelId, messageId, emojiName, -1);
        await ReactionUtil().delReactionToCache(cacheBean);
      }
    }
  }

  ///push表态数据，携带count总数，消息在内存中
  Future<void> append(String emojiName, bool me, {int count = 1}) async {
    final reaction =
        actions.firstWhere((v) => v.name == emojiName, orElse: () => null);
    if (reaction != null) {
      if (reaction.me == me && reaction.count == count) {
        debugPrint("push append reaction not need refresh count");
        return;
      }

      debugPrint("push add reaction emojiName=$emojiName me=$me count=$count");

      reaction.count = count;
      reaction.me = reaction.me || me;
    } else {
      debugPrint("push new reaction emojiName=$emojiName me=$me count=$count");

      final ReactionEntity emoji = ReactionEntity(emojiName, me: me);
      actions.add(emoji);
      actions.sort((a, b) => (b.name).compareTo(a.name));
    }

    notify();
    if (!isCircleMessage)
      await ReactionTable.append(
          messageId, emojiName, count, reaction?.me ?? me);
  }

  Future<void> remove(String emojiName, bool me, {int count = 1}) async {
    final reaction =
        actions.firstWhere((v) => v.name == emojiName, orElse: () => null);
    if (reaction != null) {
      if (reaction.me == !me && reaction.count == count) {
        debugPrint("push remove reaction not need refresh count");
        return;
      }
      debugPrint(
          "push remove reaction emojiName=$emojiName me=$me count=$count");

      if (count <= 0) {
        actions.remove(reaction);
      } else {
        reaction.count = count;
        if (me) {
          reaction.me = false;
        }
      }

      notify();
      if (!isCircleMessage)
        await ReactionTable.remove(messageId, emojiName, count, reaction.me);
    }
  }

  Future<void> removeAll(String emojiName, bool me) async {
    final reaction =
        actions.firstWhere((v) => v.name == emojiName, orElse: () => null);
    if (reaction != null) {
      if (me) {
        debugPrint("reaction app by me not remove");
        return;
      }

      reaction.count = 0;
      reaction.me = reaction.me || me;

      actions.remove(reaction);

      notify();

      await ReactionTable.remove(
          messageId, emojiName, reaction.count, reaction.me);
    }
  }

  /// NotPull离线合并表态,此消息在内存中
  Future<void> appendByNotPull(ReactionEntity entity) async {
    final reaction =
        actions.firstWhere((v) => v.name == entity.name, orElse: () => null);
    int count;
    bool me;
    if (reaction != null) {
      count = reaction.count + entity.count;

      if (reaction.me == true && entity.me == true) {
        count--;
      }

      if (count <= 0) {
        actions.remove(reaction);
        notify();
        await ReactionTable.remove(messageId, entity.name, 0, false);
        return;
      } else {
        reaction.count = count;
        reaction.me = (me = reaction.me || entity.me);
      }
    } else {
      if (entity.count <= 0) return;

      actions.add(entity);
      actions.sort((a, b) => (b.name).compareTo(a.name));
      count = entity.count;
      me = entity.me;
    }

    notify();
    await ReactionTable.append(messageId, entity.name, count, me);
  }

  Future<void> update(ReactionCountChange data) async {
    final String name = data.name;
    final int count = data.count;
    final bool me = data.me;

    if (count == 0) {
      final int index = actions.indexWhere((e) => e.name == name);
      if (index > -1) {
        actions.removeAt(index);
        await ReactionTable.remove(messageId, name, 0, false);
      }
    } else {
      final ReactionEntity item = actions.firstWhere((e) => e.name == name);
      if (item != null) {
        item.count = count;
        await ReactionTable.append(messageId, name, count, me);
      }
    }
    notify();
  }

  void notify() {
    updater.subject.add(this);
  }

  ///此接口只能表态，不能取消，去掉不能表态的toast提示
  Future<void> addReaction(
    String emojiName, {
    String msgId,
    bool isShowMutedMsg = true,
  }) async {
    ///表态前判断是否有表态权限
    if (!checkPermission()) return;

    final reaction =
        actions.firstWhere((v) => v.name == emojiName, orElse: () => null);
    if (reaction == null || !reaction.me) {
      ///新增表态
      await createReaction(reaction, emojiName, msgId ?? messageId);
    }
  }

  ///判断是否有权限
  bool checkPermission() {
    //表态前判断是否有表态权限
    if (isCircleMessage) {
      return hasCirclePermission(
          guildId: guildId,
          permission: Permission.CIRCLE_REPLY,
          topicId: channelId);
    }

    final ChatChannel channel = Db.channelBox.get(channelId);
    if (channel != null) {
      final ChatChannelType type = channel.type;
      //私信和部落不判断权限
      if (type != ChatChannelType.dm && type != ChatChannelType.group_dm) {
        final guildId = channel.guildId;
        if (guildId.hasValue) {
          final canReaction = PermissionUtils.oneOf(
              Db.guildPermissionBox.get(guildId), [Permission.ADD_REACTIONS],
              channelId: channelId);
          if (!canReaction) {
            return false;
          }
        }
      }
    }
    return true;
  }
}
