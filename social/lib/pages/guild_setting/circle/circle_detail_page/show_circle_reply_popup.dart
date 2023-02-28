import 'package:flutter/cupertino.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/show_landscape_circle_reply_popup.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/show_portrait_circle_reply_popup.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:im/utils/orientation_util.dart';

typedef OnReplySend = void Function(Document doc);

Future<void> showCircleReplyPopup(BuildContext context,
    {@required String guildId,
    @required String channelId,
    MessageEntity reply,
    String hintText = '说点什么...',
    String commentId,
    OnReplySend onReplySend}) {
  if (OrientationUtil.portrait) {
    return showPortraitCircleReplyPopup(
      context,
      guildId: guildId,
      channelId: channelId,
      reply: reply,
      hintText: hintText,
      commentId: commentId,
      onReplySend: onReplySend,
    );
  } else {
    return showLandscapeCircleReplyPopup(
      context,
      guildId: guildId,
      channelId: channelId,
      reply: reply,
      hintText: hintText,
      commentId: commentId,
      onReplySend: onReplySend,
    );
  }
}
