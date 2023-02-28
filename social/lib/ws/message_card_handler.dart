// ignore_for_file: type_annotate_public_apis
/// 消息卡片 WS信息处理

import 'package:im/pages/home/json/message_card_entity.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/in_memory_db.dart';
import 'package:im/pages/home/model/text_channel_util.dart';
import 'package:im/pages/home/view/text_chat/items/model/message_card_helper.dart';
import 'package:im/utils/im_utils/channel_util.dart';

/// 无实体消息处理
Future<void> nonEntityHandler(data) async {
  if (data == null) {
    return;
  }
  //  消息主体内容
  final message = MessageEntity.fromJson(data);
  TextChannelUtil.instance.stream.add(message);

  ChannelUtil.instance
      .updateLastMessageIdBoxById(message.channelId, message.messageId);
  //  内容实例
  final entity = message.content as MessageCardKeyPushEntity;
  //  原卡片内容
  final originMessageCard =
      InMemoryDb.getMessage(message.channelId, BigInt.parse(entity.id));
  if (originMessageCard == null) {
    return;
  }
  await MessageCardHelper.setKeyState(
    entity.key,
    originMessageCard.content,
    remove: entity.action == "del",
    messageId: originMessageCard.messageId,
    channelId: originMessageCard.channelId,
    userId: message.userId,
  );
}
