import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/db/chat_db.dart';
import 'package:im/db/cicle_news_table.dart';
import 'package:im/db/message_search_table.dart';
import 'package:im/pages/home/json/message_card_entity.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/json/unsupported_entity.dart';
import 'package:im/pages/home/model/text_channel_util.dart';
import 'package:im/pages/home/view/text_chat/items/components/message_reaction.dart';
import 'package:im/utils/message_util.dart';

///频道消息 Isolate
class TextChannelIsolate {
  static Isolate isolate;
  static SendPort isolateSendPort;

  static Future init() async {
    if (isolate == null) {
      final receivePort = ReceivePort();
      //创建子Isolate对象
      isolate = await Isolate.spawn(unReadIsolate, receivePort.sendPort);
      //监听子Isolate的返回数据
      receivePort.listen((data) {
        if (data is SendPort) {
          isolateSendPort = data;
        } else if (data is UnReadIsolateResult) {
          TextChannelUtil.instance.isolateStream.add(data);
        } else {
          debugPrint('getChat isolate listen: $data');
        }
      });
    }
    debugPrint('getChat isolate init');
  }

  static void run(UnReadIsolateParam param) {
    isolateSendPort?.send(param);
  }

  // ----------------- 子Isolate操作 ---------------------

  //入口函数
  static void unReadIsolate(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    receivePort.listen((data) async {
      if (data is UnReadIsolateParam) {
        final result = await onPullUnReadMessages(data);
        sendPort.send(result);
      }
    });
    sendPort.send("init complete");
  }

  ///处理频道离线消息<p>
  static Future<UnReadIsolateResult> onPullUnReadMessages(
      UnReadIsolateParam param) async {
    final start = DateTime.now();
    final length = param.unReadList.length;
    final channelId = param.channelId;
    final guildId = param.guildId;

    final result =
        UnReadIsolateResult(param.isDm, channelId, param.isUpdateUnRead);
    debugPrint('getChat isolate onPullUnReadMessages: $channelId');
    final List<String> sqlList = result.sqlList;

    String e;
    Map map;
    List<String> eList;
    MessageEntity m, firstMessage;
    int realNumUnread = 0;
    //最后一条消息为数组里最大的消息
    BigInt maxMessageId = BigInt.from(0);
    for (int i = 0; i < length; i++) {
      e = param.unReadList[i] as String;
      // debugPrint('getChat -> notPull index:$i, e:$e ');
      if (e == null) continue;

      ///notRead接口改造: 兼容使用-新旧消息格式
      if (e.contains("{")) {
        ///旧消息格式 json
        map = jsonDecode(e) as Map;
        map["channel_id"] = channelId;
        map["guild_id"] = guildId;
        m = MessageEntity.fromJson(map);

        ///旧消息也设置为 incomplete, 这样消息表中的不完整消息就是连续的
        ///后续和新消息做同样的处理,简化逻辑
        if (!MessageEntity.messageIsNotVisible(m)) {
          m.localStatus = MessageLocalStatus.incomplete;
        }
        MessageUtil.setMessageMentions(m);
      } else {
        ///新消息格式: 消息ID;消息类型;.......
        eList = e.split(";");
        if (eList.length == 1) {
          //普通消息
          m = MessageEntity<MessageContentEntity>(
            MessageAction.message,
            channelId,
            null,
            guildId,
            null,
            null,
            messageId: eList[0],
            localStatus: MessageLocalStatus.incomplete,
          );
        } else {
          switch (eList[1]) {
            case '0': //普通消息
              m = MessageEntity<MessageContentEntity>(
                MessageAction.message,
                channelId,
                eList[2],
                guildId,
                null,
                null,
                messageId: eList[0],
                localStatus: MessageLocalStatus.incomplete,
              );
              break;
            case '9': //圈子消息
              final circleType = CircleNewsTable.getCircleType(eList[6]);
              if (circleType == null) continue;
              final cEntity = CirclePostNewsEntity(
                  postId: eList[3],
                  commentId: eList[4].hasValue
                      ? BigInt.parse(eList[4])
                      : BigInt.from(0),
                  circleType: eList[6],
                  atMe: (eList[7] ?? '').contains(param.userId) ? 1 : 0);
              m = MessageEntity<MessageContentEntity>(
                null,
                channelId,
                eList[2],
                guildId,
                null,
                cEntity,
                messageId: eList[0],
                quoteL1: eList[5],
                localStatus: MessageLocalStatus.normal,
              );
              break;
            case '8': //开始消息
              m = MessageEntity<MessageContentEntity>(
                MessageAction.message,
                channelId,
                null,
                guildId,
                null,
                StartEntity(),
                messageId: eList[0],
                localStatus: MessageLocalStatus.normal,
              );
              m.content.messageState = MessageState.sent.obs;
              break;
            case '7': //艾特消息
              m = MessageEntity<MessageContentEntity>(
                MessageAction.message,
                channelId,
                eList[3],
                guildId,
                null,
                null,
                messageId: eList[0],
                localStatus: MessageLocalStatus.incomplete,
              );
              MessageUtil.setMessageMentions(m,
                  atContent: eList[2], pattern: TextEntity.atPatternIncomplete);
              break;
            case '7.1': //机器人隐身消息
              m = MessageEntity<MessageContentEntity>(
                MessageAction.message,
                channelId,
                eList[3],
                guildId,
                null,
                TextEntity(text: eList[2], contentType: ContentMask.hide),
                messageId: eList[0],
                localStatus: MessageLocalStatus.incomplete,
              );
              break;

            case '1': //表态 add
            case '2': //表态 del
              String emojiName = eList[2];
              if (emojiName == null || emojiName.isEmpty) continue;
              try {
                emojiName = Uri.decodeComponent(emojiName);
              } catch (e) {
                print(e);
              }

              final ReactionEntity emojiEntity = ReactionEntity(emojiName);
              m = MessageEntity<MessageContentEntity>(
                null,
                channelId,
                eList[4],
                guildId,
                null,
                ReactionEntity2(
                    action: eList[1] == '1' ? 'add' : 'del',
                    id: eList[3],
                    emoji: emojiEntity),
                messageId: eList[0],
              );
              break;

            case '3': //pin
            case '4': //unpin
              m = MessageEntity<MessageContentEntity>(
                null,
                channelId,
                eList[3],
                guildId,
                null,
                PinEntity(
                    action: eList[1] == '3' ? 'pin' : 'unpin', id: eList[2]),
                messageId: eList[0],
              );
              break;

            case '5': //撤回 recall
              m = MessageEntity<MessageContentEntity>(
                null,
                channelId,
                eList[3],
                guildId,
                null,
                RecallEntity(id: eList[2]),
                messageId: eList[0],
              );
              break;

            case '6': //修改消息 upMsg
              m = MessageEntity<MessageContentEntity>(
                null,
                channelId,
                null,
                guildId,
                null,
                MessageModificationEntity(messageId: eList[2]),
                messageId: eList[0],
              );
              break;
            case '10':
              if (eList[2] != param.userId)
                m = MessageEntity<MessageContentEntity>(
                    null, channelId, null, guildId, null, EmptyEntity(),
                    messageId: eList[0],
                    localStatus: MessageLocalStatus.normal);
              break;
            case '10.1': // 关闭圈子频道, 需要清空未读数
              realNumUnread = 0;
              break;
            case '11': // 添加好友
              m = MessageEntity<MessageContentEntity>(
                MessageAction.message,
                channelId,
                null,
                guildId,
                null,
                null,
                messageId: eList[0],
                localStatus: MessageLocalStatus.incomplete,
              );
              break;
            case '12': // 消息卡片的 key 推送
              final key = eList[2];

              m = MessageEntity<MessageContentEntity>(
                null,
                channelId,
                eList[4],
                guildId,
                null,
                MessageCardKeyPushEntity(
                  action: "add",
                  id: eList[3],
                  key: key,
                ),
                messageId: eList[0],
                localStatus: MessageLocalStatus.normal,
              );
              break;
            case '13': // 消息卡片的 key 推送
              // 360458345422782464;13;1;360444722893815808;86654728397791232;1
              // 消息 id;消息类型;key;被操作消息 id
              final key = eList[2];

              m = MessageEntity<MessageContentEntity>(
                null,
                channelId,
                eList[4],
                guildId,
                null,
                MessageCardKeyPushEntity(
                  action: "del",
                  id: eList[3],
                  key: key,
                ),
                messageId: eList[0],
                localStatus: MessageLocalStatus.normal,
              );
              break;
            default:
              m = MessageEntity<MessageContentEntity>(
                null,
                channelId,
                null,
                guildId,
                null,
                UnSupportedEntity(messageId: eList[0]),
                messageId: eList[0],
                localStatus: MessageLocalStatus.normal,
              );
          }
        }
      }

      if (m == null) continue;

      switch (m.content.runtimeType) {
        case MessageModificationEntity:
          result.messageModifications ??= [];
          result.messageModifications.add(m);
          break;
        case RecallEntity:
          result.recalls ??= [];
          result.recalls.add(m);
          break;
        case ReactionEntity2:
          result.reactions ??= [];
          result.reactions.add(m);
          break;
        case MessageCardKeyPushEntity:
          result.messageCardKeys ??= [];
          result.messageCardKeys.add(m);
          break;
        case PinEntity:
          result.pins ??= [];
          result.pins.add(m);
          break;
        case CirclePostNewsEntity:
          result.circleNews ??= [];
          result.circleNews.add(m);
          final circleType = CircleNewsTable.getCircleType(eList[6]);
          if (m.userId != param.userId &&
              CircleNewsTable.isUpdateUnread(circleType)) {
            firstMessage ??= m;
            realNumUnread++;
            final content = m.content as CirclePostNewsEntity;
            if (content.atMe == 1 && content.commentId != null)
              result.atList.add(content.commentId.toString());
          }
          break;

        default:
          //不是自己发的消息、非start消息 和 非隐身消息: 提示未读数
          if (m.userId != param.userId &&
              MessageUtil.canISeeThisMessage(m,
                  userId: param.userId,
                  useParam: true,
                  userRoles: param.userRoles) &&
              (m.content is! StartEntity)) {
            firstMessage ??= m;

            if (param.isUpdateUnRead &&
                (m.messageId.compareTo(param.lastReadMessageId) > 0)) {
              realNumUnread++;
            }
            //检查是否有at
            if (MessageUtil.atMeInMentions(m,
                    userId: param.userId,
                    useParam: true,
                    userRoles: param.userRoles) !=
                AtMeType.none) {
              result.atList.add(m.messageId);
            }
          }

          result.lastRealMessage = m;
          result.realMessageLength++;
          map = m.toJson();
          ChatTable.processInsertMap(map);
          sqlList.add(getInsertSql(ChatTable.table, map, isIgnoreMode: true));
          map = MessageSearchTable.getMessageSearchTableInsertion(m);
          sqlList.add(getInsertSql(MessageSearchTable.table, map));
      }
      if (m.messageIdBigInt > maxMessageId) {
        maxMessageId = m.messageIdBigInt;
        result.lastMessage = m;
      }
    }

    // await ChatTable.appendAllBySql(sqfLiteChannel, param.dbPath, result.messages);
    // 子线程不能调用平台方法
    result.firstMessage = firstMessage;
    result.realNumUnread = realNumUnread;
    debugPrint(
        "getChat isolate onPullUnReadMessages $channelId, 耗时:${DateTime.now().difference(start).inMilliseconds} ms");
    return result;
  }
}

///Isolate 参数
class UnReadIsolateParam {
  ///是否私信或群聊
  bool isDm;
  String channelId;
  String guildId;
  List unReadList;
  bool isUpdateUnRead;
  String userId;
  List<String> userRoles;
  String lastReadMessageId;

  UnReadIsolateParam(this.isDm, this.channelId, this.guildId, this.unReadList,
      this.isUpdateUnRead, this.userId, this.userRoles, this.lastReadMessageId);
}

///Isolate 返回结果
class UnReadIsolateResult {
  ///是否私信或群聊
  bool isDm;
  String channelId;
  bool isUpdateUnRead;
  int realNumUnread;

  List<MessageEntity> recalls;
  List<MessageEntity> messageModifications;
  List<MessageEntity> reactions;
  List<MessageEntity> messageCardKeys;
  List<MessageEntity> pins;
  List<MessageEntity> circleNews;

  List<String> sqlList = [];
  // 最后一条消息
  MessageEntity lastMessage;
  MessageEntity firstMessage;
  // 最后一条实体消息
  MessageEntity lastRealMessage;
  int realMessageLength = 0;
  List<String> atList = [];

  UnReadIsolateResult(this.isDm, this.channelId, this.isUpdateUnRead);
}
