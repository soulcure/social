import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/tab_bar.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:pedantic/pedantic.dart';

import '../routes.dart';

Future<void> gotoDirectMessageChat(String userId) async {
  final channel = await DirectMessageController.to.createChannel(userId);
  if (OrientationUtil.portrait) {
    return Routes.pushDirectChatPage(channel);
  } else {
    return ChatTargetsModel.instance.selectChatTarget(null, channel: channel);
  }
}

Future<void> sendDirectMessage(
  String userId,
  MessageContentEntity messageContent, {
  bool jump = false,
}) async {
  final channel = await DirectMessageController.to.createChannel(userId);
  if (channel == null) return;

  await TextChannelController.to(channelId: channel.id).sendContent(
    messageContent,
    guildId: userId,
    channelType: ChatChannelType.dm,
  );

  if (jump) {
    if (OrientationUtil.portrait) {
      await Routes.pushDirectChatPage(channel);
    } else {
      /// TODO: 还没想好
      Routes.backHome();
      HomeTabBar.gotoIndex(0);
      HomeScaffoldController.to.windowIndex.value = 1;
      unawaited(ChatTargetsModel.instance.selectChatTarget(
        null,
        channel: channel,
        gotoChatView: true,
      ));
    }
  }
}
