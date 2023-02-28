import 'package:im/db/message_card_key_table.dart';
import 'package:im/pages/home/json/message_card_entity.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/in_memory_db.dart';
import 'package:meta/meta.dart';

import '../../../../../../global.dart';

/// 同时操作消息卡片的数据库和内存
class MessageCardHelper {
  /// 设置 [key] 的状态，如果 [remove] 为 true，表示删除这个用户 key 操作。
  static Future<void> setKeyState(
    String key,
    MessageCardEntity messageCard, {
    @required bool remove,
    @required String messageId,
    @required String channelId,
    @required String userId,
  }) {
    if (remove) {
      return _clearKey(
        key,
        messageCard,
        messageId: messageId,
        channelId: channelId,
        userId: userId,
      );
    } else {
      return _setKey(
        key,
        messageCard,
        messageId: messageId,
        channelId: channelId,
        userId: userId,
      );
    }
  }

  static Future<void> _setKey(
    String key,
    MessageCardEntity messageCard, {
    @required String messageId,
    @required String channelId,
    @required String userId,
  }) async {
    await MessageCardKeyTable.insert(
      channelId: channelId,
      messageId: messageId,
      userId: userId,
      key: key,
      me: userId == Global.user.id,
    );
    messageCard.setKey(key, userId);
  }

  static Future<void> _clearKey(
    String key,
    MessageCardEntity messageCard, {
    @required String messageId,
    @required String channelId,
    @required String userId,
  }) async {
    await MessageCardKeyTable.remove(
      messageId: messageId,
      userId: userId,
      key: key,
    );
    messageCard.clearKey(key, userId);
  }

  /// 批量插入来自 notpull 的数据
  static void bulkSetKeys(List<MessageEntity> messages) {
    for (final msg in messages) {
      final entity = msg.content as MessageCardKeyPushEntity;
      final message =
          InMemoryDb.getMessage(msg.channelId, BigInt.parse(entity.id));
      // 如果原始消息不存在，则跳过，当拉取原始消息时自然会获取到数据
      if (message == null) continue;
      final messageCard = message.content as MessageCardEntity;
      if (message != null) {
        if (entity.action == "del") {
          messageCard.clearKey(entity.key, msg.userId);
        } else {
          messageCard.setKey(entity.key, msg.userId);
        }
      }
    }

    MessageCardKeyTable.bulkInsert(messages);
  }

  /// 把在线 key push 应用到内存中的消息，此消息与 IM 列表中的消息实例独立
  /// 例如 pin 列表、话题详情页
  static void applyKeyPushToMemoryMessage(
      MessageEntity keyPush, MessageEntity Function(String) getMessage) {
    final keyMsg = keyPush.content as MessageCardKeyPushEntity;
    final message = getMessage(keyMsg.id);
    if (message == null) return;
    if (keyMsg.action == "add")
      (message.content as MessageCardEntity).setKey(keyMsg.key, keyPush.userId);
    else
      (message.content as MessageCardEntity)
          .clearKey(keyMsg.key, keyPush.userId);
  }
}
