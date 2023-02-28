import 'package:im/db/chat_db.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/model/text_channel_util.dart';
import 'package:im/utils/im_utils/channel_util.dart';

// ignore: avoid_annotating_with_dynamic
Future<void> pinHandler(dynamic data, {bool updateLastId = true}) async {
  final message =
      data.runtimeType == MessageEntity ? data : MessageEntity.fromJson(data);
  final oriMessageId = (message.content as PinEntity).id;
  final channelId = message.channelId;
  final userId = message.userId;
  final pinned = (message.content as PinEntity).action == 'pin';

  TextChannelController.to(channelId: channelId)?.changeMemoryMessage(
    messageId: BigInt.parse(oriMessageId),
    callback: (m, _) {
      m.pin = pinned ? userId : '0';
    },
  );

  ChatTable.updatePin(oriMessageId, pinned ? userId : '0');
  if (updateLastId) {
    ChannelUtil.instance
        .updateLastMessageIdBoxById(channelId, message.messageId);
  }
  TextChannelUtil.instance.stream.add(PinEvent(message: message));
}

class PinEvent {
  final MessageEntity message;

  PinEvent({this.message});
}
