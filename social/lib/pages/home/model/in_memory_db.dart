import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/role_bean.dart';
import 'package:im/api/entity/user_config.dart';
import 'package:im/api/text_chat_api.dart';
import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/http_middleware/interceptor/channel_mutex_interceptor.dart';
import 'package:im/db/bean/dm_last_message_desc.dart';
import 'package:im/db/bean/last_reaction_item.dart';
import 'package:im/db/chat_db.dart';
import 'package:im/db/cicle_news_table.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/json/add_friend_tips_entity.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/model/text_channel_event.dart';
import 'package:im/pages/home/model/text_channel_util.dart';
import 'package:im/pages/topic/controllers/topic_controller.dart';
import 'package:im/utils/im_utils/channel_util.dart';
import 'package:im/utils/message_util.dart';
import 'package:pedantic/pedantic.dart';

class MessageList {
  ///消息list，用于展示
  final SplayTreeMap<BigInt, MessageEntity> _list = SplayTreeMap();

  SplayTreeMap<BigInt, MessageEntity> getSplayTreeMap() => _list;

  /// 保存置顶等不在 IM 列表展示消息
  Map<String, MessageEntity> cacheMap = {};

  DmLastMessageDesc _latestMessageDesc;

  DmLastMessageDesc get latestMessageDesc {
    ///fix 撤回消息 刷新内容为空
    final temp = Db.dmLastDesc.get(channelId);
    if (temp != null) {
      _latestMessageDesc = temp;
    }
    return _latestMessageDesc;
  }

  void setLastMessageDesc(
      {MessageEntity message,
      DmLastMessageDesc descMap,
      Map<dynamic, dynamic> jsonMap,
      bool force = false,
      Map author}) {
    DmLastMessageDesc curDesc;
    if (message != null) {
      ///非私信频道，无需保存LastMessageDesc
      ChatChannelType type = message.channelType;
      type ??= Db.channelBox.get(message.channelId)?.type;
      if (type == null || !dmTypeSet.contains(type)) return;

      if (message.content is ReactionEntity2) {
        final reactionContent = message.content as ReactionEntity2;
        if (reactionContent?.emoji?.name == TopicController.emojiName) return;

        final last = Db.dmLastDesc.get(channelId);
        if (last != null) {
          final reactionEntity2 = message.content as ReactionEntity2;
          if (BigInt.parse(reactionEntity2.id) == last.messageId) {
            if (reactionEntity2.action == 'del') {
              final reaction = last.lastReaction.firstWhere(
                  (v) => v.emojiName == reactionEntity2.emoji.name,
                  orElse: () => null);
              if (reaction != null) {
                reaction.count--;
                if (reaction.count <= 0) {
                  last.lastReaction.remove(reaction);
                }
                Db.dmLastDesc.put(channelId, last);
              }
            } else {
              final reaction = last.lastReaction.firstWhere(
                  (v) => v.emojiName == reactionEntity2.emoji.name,
                  orElse: () => null);
              if (reaction != null) {
                reaction.count++;
              } else {
                final item = LastReactionItem(reactionEntity2.emoji.name, 1);
                last.lastReaction.add(item);
              }
              Db.dmLastDesc.put(channelId, last);
            }
            // 表态置顶
            final ChatChannel channel = Db.channelBox.get(channelId);
            if (channel != null) {
              DirectMessageController.to.bringChannelToTop(channel);
            }
          }
        }
      } else if (message.content is RecallEntity || message.isRecalled) {
        ///撤销最后一条消息，才需要更新
        final lastVisibleMessageId = Db.lastVisibleMessageIdBox.get(channelId);
        final recallMessageId =
            BigInt.parse((message.content as RecallEntity).id);
        if (recallMessageId != lastVisibleMessageId) {
          return;
        }
        final isSelf = message.userId == Global.user.id;
        curDesc = DmLastMessageDesc.normal(
          message.messageIdBigInt,
          '%s已撤回该消息'.trArgs([if (isSelf) '你'.tr else '对方'.tr]),
        );
        _latestMessageDesc = curDesc;
        Db.dmLastDesc.put(channelId, curDesc);
      } else if (message.content is CirclePostNewsEntity) {
        ///圈子消息
        final circleNews = message.content as CirclePostNewsEntity;

        final circleType = CircleNewsTable.getCircleType(circleNews.circleType);
        if (!CircleNewsTable.isUpdateLastDesc(circleType)) return;
        String descString;
        if (circleNews.desc.hasValue) {
          descString = MessageUtil.trimEmptyEnd(circleNews.desc);
          // debugPrint('getChat setLastMessageDesc 1 desc: $descString, ${circleNews.desc}');
          curDesc = DmLastMessageDesc.fromGuild(
            message.messageIdBigInt,
            descString,
            message.guildId,
            message.channelId,
          );
        } else if (circleNews.msg.hasValue) {
          descString = MessageUtil.trimEmptyEnd(circleNews.msg);
          curDesc = DmLastMessageDesc.normal(
            message.messageIdBigInt,
            descString,
          );
        }
        if (curDesc != null) Db.dmLastDesc.put(channelId, curDesc);
      } else if (message.deleted == 1) {
        ///本地删除最后一条消息，才需要更新
        final lastVisibleMessageId = Db.lastVisibleMessageIdBox.get(channelId);
        if (message.messageIdBigInt != lastVisibleMessageId) {
          return;
        }
        curDesc = DmLastMessageDesc.normal(
          message.messageIdBigInt,
          '你删除了一条消息'.tr,
        );
        _latestMessageDesc = curDesc;
        Db.dmLastDesc.put(channelId, curDesc);
      } else if (message.content is AddFriendTipsEntity) {
        final AddFriendTipsEntity entity =
            message.content as AddFriendTipsEntity;

        final String userId = entity.getOtherUserId();
        UserInfo.get(userId).then((userInfo) {
          final String showName = userInfo?.showName(hideGuildNickname: true);
          final String desc = '你已添加了%s,现在可以开始聊天了'.trArgs([showName]);

          curDesc = DmLastMessageDesc.normal(
            message.messageIdBigInt,
            desc,
            senderId: userId,
          );
          _latestMessageDesc = curDesc;
          Db.dmLastDesc.put(channelId, curDesc);
        });
      } else {
        message.toNotificationString().then((value) {
          curDesc = DmLastMessageDesc.fromGroup(
            message.messageIdBigInt,
            value,
            message.userId,
            author == null ? null : author["nickname"],
          );
          _latestMessageDesc = curDesc;
          Db.dmLastDesc.put(channelId, curDesc);
        });
      }
    } else if (descMap != null) {
      ///离线消息
      final preMessage = latestMessageDesc;
      if (preMessage != null && !force) {
        final preMessageId = preMessage.messageId;
        final currentBigInt = descMap.messageId ?? BigInt.from(0);
        if (currentBigInt < preMessageId) return;
      }
      final strArr = descMap.desc.split('::');
      if (strArr.length == 1) {
        ///私信
        Db.dmLastDesc.put(
          channelId,
          descMap,
        );
        Db.channelBox.get(channelId)?.lastMessageId = descMap.messageId;
      } else if (strArr.length == 3) {
        ///群聊
        curDesc = DmLastMessageDesc.fromGroup(
          descMap.messageId,
          strArr[2],
          strArr[0],
          strArr[1],
        );
        Db.dmLastDesc.put(channelId, curDesc);
        Db.channelBox.get(channelId)?.lastMessageId = descMap.messageId;
      }
    } else if (jsonMap != null) {
      final type = jsonMap['type'] as String;
      final mId = BigInt.parse(jsonMap['mid'] as String);
      switch (type) {
        // case '0':
        //   //私信
        //   Db.dmLastDesc.put(
        //     channelId,
        //     DmLastMessageDesc(
        //       messageId: mId,
        //       desc: descList[2],
        //     ),
        //   );
        //   break;
        // case '1':
        //   //群聊
        //   Db.dmLastDesc.put(
        //     channelId,
        //     DmLastMessageDesc(
        //       messageId: mId,
        //       desc: descList[4],
        //       senderId: descList[2],
        //       senderNiceName: descList[3],
        //     ),
        //   );
        //   break;
        case '2':
          //圈子频道消息
          final circleType =
              CircleNewsTable.getCircleType(jsonMap['ctype'] as String);
          if (!CircleNewsTable.isUpdateLastDesc(circleType)) return;
          final desc = jsonMap['desc'] as String;
          final msg = jsonMap['msg'] as String;
          final guildId = jsonMap['guild_id'] as String;
          String descString;

          if (desc.hasValue) {
            descString = MessageUtil.trimEmptyEnd(desc);
            // debugPrint('getChat setLastMessageDesc 3 desc: $descString, $desc');
            curDesc = DmLastMessageDesc.fromGuild(
              mId,
              descString,
              guildId,
              channelId,
            );
          } else if (msg.hasValue) {
            descString = MessageUtil.trimEmptyEnd(msg);
            curDesc = DmLastMessageDesc.normal(
              mId,
              descString,
            );
          }
          if (curDesc != null) Db.dmLastDesc.put(channelId, curDesc);
          break;
      }
      Db.channelBox.get(channelId)?.lastMessageId = mId;
    }
  }

  final String channelId;

  int get length => _list.length;

  MessageList(this.channelId,
      {this.notSyncMessageId, bool remoteSynchronized}) {
    //初始化时，如果lastId为空，表示本地没有消息，缓存设为true
    if (Db.lastMessageIdBox.get(channelId) == null) {
      _remoteSynchronized = true;
    }
    if (remoteSynchronized != null) _remoteSynchronized = remoteSynchronized;
  }

  @visibleForTesting
  MessageList.forTest(this.channelId);

  bool get isEmpty => _list.isEmpty;

  bool get isNotEmpty => _list.isNotEmpty;

  MessageEntity get first => _list[_list.firstKey()];

  List<MessageEntity> get list => _list.values.toList(growable: false);

  MessageEntity get firstValidMessage {
    for (final e in _list.entries) {
      if (e.value.localStatus != MessageLocalStatus.illegal) return e.value;
    }
    return null;
  }

  ///是否在读取本地历史数据中
  bool _readHistoryIng = false;

  bool _remoteSynchronized = false;

  ///离线消息是否处理完成
  bool get remoteSynchronized => _remoteSynchronized;

  ///notPull未处理完时，push或者其他途径过来的消息ID
  String notSyncMessageId;

  BigInt get firstMessageId => _list.firstKey();

  BigInt get lastMessageId => _list.lastKey();

  MessageEntity<MessageContentEntity> get lastMessage => _list[lastMessageId];

  ///设置消息列表的缓存标记：为true时，才将 notSyncMessage 设置为lastId
  Future<void> setRemoteSynchronized(bool value) async {
    _remoteSynchronized = value;
    if (value && notSyncMessageId != null) {
      ChannelUtil.instance
          .updateLastMessageIdBoxById(channelId, notSyncMessageId);
      notSyncMessageId = null;
    }
    final channelType = Db.channelBox.get(channelId)?.type;
    if (value && dmTypeSet.contains(channelType)) {
      ///清除: 消息列表的待更新频道ID
      final idsList =
          Db.userConfigBox.get(UserConfig.dmList2ChannelIds) as List<String>;
      if (idsList != null && idsList.contains(channelId)) {
        // debugPrint('getChat dmList2ChannelIds - remove: $channelId');
        idsList.remove(channelId);
        unawaited(Db.userConfigBox.put(UserConfig.dmList2ChannelIds, idsList));
      }
    }
  }

  MessageEntity get(BigInt messageId) => _list[messageId];

  void forEach(void Function(MessageEntity) f) {
    _list.forEach((k, v) => f(v));
  }

  void clear() {
    _list.clear();
  }

  ///添加消息到内存
  void add(MessageEntity message) {
    assert(message?.messageIdBigInt != null);
    assert(message.messageIdBigInt != BigInt.from(0));
    assert(message.content != null &&
        message.content != MessageEntity.nullContent);
    assert(message.time.year > 2019);
    _list[message.messageIdBigInt] = message;
  }

  /// SPLAY TREE OPERATIONS
  void addAll(Iterable<MessageEntity> iterable) {
    iterable.forEach(add);
  }

  void remove(BigInt messageId) {
    _list.remove(messageId);
  }

  /// CACHE OPERATIONS
  void addCache(MessageEntity message) {
    cacheMap[message.messageId] = message;
  }

  MessageEntity getFromCache(String id) {
    return cacheMap[id];
  }

  void updateMessageId(
      BigInt newMessageId, MessageEntity<MessageContentEntity> message) {
    _list.remove(message.messageIdBigInt);
    message.messageId = newMessageId.toString();
    message.messageIdBigInt = newMessageId;
    add(message);
  }

  ///读取本地历史消息<p>
  ///before：是否向上读取，默认为true<p>
  Future<int> readHistory({
    bool before = true,
    bool autoRetry = false,
    int retryTimes = 0,
    bool throwError = false,
    MutexOption mutexOption,
    Completer completer,
  }) async {
    if (_readHistoryIng) return -1;
    //如果向上读取，且第一条是StartEntity，直接返回
    if (before &&
        _list.isNotEmpty &&
        _list[firstMessageId].content is StartEntity) return 0;

    _readHistoryIng = true;
    List<MessageEntity> list = [];
    BigInt curFirstId;
    if (_list.isNotEmpty) {
      curFirstId = before ? _list.firstKey() : _list.lastKey();
    }

    final res =
        await ChatTable.getChatHistory(channelId, curFirstId, before: before);
    for (final message in res) {
      if (message.deleted == 1) continue;

      /// 现在的版本不会出现这些类型，未来可以去掉这段代码
      switch (message.content.runtimeType) {
        case ReactionEntity2:
        case RecallEntity:
        case PinEntity:
        case MessageModificationEntity:
          continue;
      }
      list.add(message);
    }

    list = await getBatchMessages(
      list,
      retryTimes: retryTimes,
      throwError: throwError,
      mutexOption: mutexOption,
      completer: completer,
    );

    list.forEach((element) {
      add(element);
      TextChannelUtil.instance.stream.add(UpdateTopicMessageEvent(element));
    });

    // debugPrint('getChat readHistory: $channelId - length: $length');
    _readHistoryIng = false;

    return list.length;
  }

  ///读取本地最后一段完整历史消息，可以是1条
  Future<void> readCompleteHistory() async {
    ///先读取最后一条完整消息
    BigInt lastCompleteId = Db.lastCompleteMessageIdBox.get(channelId);
    MessageEntity lastCompleteMessage;

    if (lastCompleteId == null) {
      ///旧版用户第一次启动，lastCompleteId 为空
      lastCompleteMessage = await ChatTable.getLastCompleteMessage(channelId);

      ///还查不到完整消息，直接返回
      if (lastCompleteMessage == null) return;
      ChannelUtil.instance.updateLastCompleteMessageIdBox(
          lastCompleteMessage.channelId, lastCompleteMessage.messageIdBigInt);
      lastCompleteId = lastCompleteMessage.messageIdBigInt;
    } else {
      lastCompleteMessage =
          await ChatTable.getMessage(lastCompleteId.toString());
    }
    // debugPrint('getChat readComplete last: $lastCompleteMessage');
    ///fix: 开发过程中发现 lastCompleteId==null 的情况
    if (lastCompleteMessage != null) add(lastCompleteMessage);
    final res = await ChatTable.getChatHistory(channelId, lastCompleteId);
    for (final message in res) {
      if (message.deleted == 1) continue;

      ///有不完整，就退出，保证本地消息连续
      if (message.isIncomplete) break;
      add(message);
    }
    debugPrint('getChat readComplete length: $length');
  }

  ///保存消息到数据库中： 收到push消息或发送消息时
  Future<void> saveMessage(MessageEntity<MessageContentEntity> message,
      {Map author, bool privateMsg = false}) async {
    if (!MessageEntity.messageIsNotVisible(message)) {
      if (message.content is CirclePostNewsEntity) {
        await CircleNewsTable.append(message);
      } else {
        await ChatTable.append(message);
      }
    }

    if (message.content?.messageState?.value == MessageState.sent) {
      ChannelUtil.instance.updateLastMessageIdBoxById(
          message.channelId, message.messageId,
          privateMsg: privateMsg);
      // TODO 标记：发送消息会设置最后一条描述信息，检查代码，能不能只设置一次
      setLastMessageDesc(message: message, author: author);
    }
  }

  ///检查是否有不完整消息，有则从服务端批量获取消息的所有数据
  Future<List<MessageEntity>> getBatchMessages(
    List<MessageEntity> messages, {
    bool throwError = false,
    bool showDefaultErrorToast = false,
    int retryTimes = 0,
    MutexOption mutexOption,
    Completer completer,
  }) async {
    if (messages == null || messages.isEmpty) return [];
    final List<String> messageIds = [];

    ///找出不完整消息,并且删除它
    MessageEntity item;
    for (var i = messages.length - 1; i >= 0; i--) {
      item = messages[i];
      if (item.isIncomplete) {
        messageIds.add(item.messageId);
        messages.removeAt(i);
      }
    }
    // debugPrint('getChat batchMsg id.length: ${messageIds.length}');
    ///如果没有不完整ID，直接返回
    if (messageIds.isEmpty) return messages;

    ///发起batchMsg接口，获取完整消息
    final List<MessageEntity> remoteMessages =
        await TextChatApi.getBatchMessages(
      channelId,
      messageIds,
      showDefaultErrorToast: showDefaultErrorToast,
      retryTimes: retryTimes,
      mutexOption: mutexOption,
    ).catchError((e) {
      _readHistoryIng = false;
      debugPrint('getChat batchMsg error: $e');

      ///throwError为true时，直接抛出网络异常
      if (throwError) {
        throw e;
      }
    });

    ///保存batchMsg接口返回到数据库
    Future<void> saveToDb() async {
      if (remoteMessages == null || remoteMessages.isEmpty) return;
      remoteMessages.forEach((e) {
        if (e.roleIds != null) RoleBean.update(e.userId, e.guildId, e.roleIds);
      });
      await ChatTable.appendAll(remoteMessages, isUpdate: true);
    }

    if (completer != null && completer.isCompleted) {
      // debugPrint('getChat batchMsg completer');
      _readHistoryIng = false;

      ///不用加入内存，只保存到数据库
      await saveToDb();
      throw 'not need return';
    }

    // debugPrint('getChat batchMsg -- 2');
    if (remoteMessages == null || remoteMessages.isEmpty) return messages;
    await saveToDb();

    final tcController = TextChannelController.to(channelId: channelId);
    final Map sendFailIdMap = InMemoryDb.getSendFailMessageIdMap(channelId);

    ///更新 messages 并返回它
    remoteMessages.forEach((r) {
      messages.add(r);

      ///服务端返回的消息中，可能包含相同nonce的情况，删除重复的那条
      if (sendFailIdMap.containsKey(r.nonce) && r.nonce != null) {
        unawaited(ChatTable.deletePermanently(r.nonce));
        unawaited(InMemoryDb.deleteSendFailMessageId(null,
            channelId: channelId, messageId: r.nonce));
        messages.removeWhere((e) => e.messageId == r.nonce);

        ///内存里的也要同步删除
        tcController.changeMemoryMessage(
            messageId: BigInt.parse(r.nonce),
            callback: (m, map) {
              map.remove(BigInt.parse(r.nonce));
            });
      }
    });
    return messages;
  }

  /// 获取 messageId 前后的历史消息
  Future<List<MessageEntity>> getMessageNearHistory(String messageId,
      {bool showDefaultErrorToast = false, bool before = true}) async {
    final List<MessageEntity> nearList = await ChatTable.getMessageNearHistory(
        channelId, messageId,
        before: before);
    return getBatchMessages(nearList,
        throwError: true, showDefaultErrorToast: showDefaultErrorToast);
  }
}

class InMemoryDb {
  static final Map<String, MessageList> map = <String, MessageList>{};

  static MessageList getMessageList(String channelId) {
    map[channelId] ??= MessageList(channelId);
    return map[channelId];
  }

  ///频道MessageList是否存在InMemoryDb中
  static bool isExist(String channelId) {
    return map.containsKey(channelId);
  }

  static MessageEntity getMessage(String channelId, BigInt messageId) {
    return map[channelId]?.get(messageId);
  }

  static void cleanChannel(String channelId) {
    map[channelId]?.clear();
  }

  static bool isChannelInitialized(String channelId) =>
      map.containsKey(channelId);

  static void updateMessageId(BigInt messageId, MessageEntity message) {
    map[message.channelId]?.updateMessageId(messageId, message);
  }

  static void removeMessage(MessageEntity message) {
    map[message.channelId]?.remove(message.messageIdBigInt);
  }

  static void clear() {
    map.forEach((key, value) {
      Future.delayed(const Duration(seconds: 1), () {
        value.forEach((value) {
          value.content.messageState?.close();
          value.content.messageState = null;
        });
      });
    });
    map.clear();
  }

  static void remove(String channelId) {
    final messages = map.remove(channelId);
    Future.delayed(const Duration(seconds: 1), () {
      messages?.forEach((v) {
        v.content.messageState?.close();
        v.content.messageState = null;
      });
    });
  }

  /// 重置所有的 MessageList
  /// 目前主要是 ws 断开时，使 MessageList 的同步远端消息状态重置
  static void resetAllMessageList() {
    if (kIsWeb) return;
    map.values.forEach((element) {
      element.setRemoteSynchronized(false);
    });
  }

  ///新增 sendFailMessageId
  static Future<void> addSendFailMessageId(MessageEntity failMessage) async {
    if (failMessage == null || failMessage.nonce == null) return;
    final channelId = failMessage.channelId;
    final Map idMap = getSendFailMessageIdMap(channelId);
    idMap[failMessage.nonce] = 1;
    await Db.sendFailMessageIdBox.put(channelId, idMap);
  }

  ///获取 sendFailMessageIdBox 的map
  static Map getSendFailMessageIdMap(String channelId) {
    return Db.sendFailMessageIdBox
        .get(channelId, defaultValue: <String, int>{});
  }

  ///删除 sendFailMessageIdBox 中一条记录
  static Future<void> deleteSendFailMessageId(MessageEntity failMessage,
      {String channelId, String messageId}) async {
    final cId = channelId ?? failMessage?.channelId;
    final mId = messageId ?? failMessage?.nonce;
    if (cId == null || mId == null) return;
    final Map idMap = getSendFailMessageIdMap(cId);
    if (idMap.isEmpty || !idMap.containsKey(mId)) return;
    idMap.remove(mId);
    await Db.sendFailMessageIdBox.put(cId, idMap);
  }
}
