import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_util.dart';
import 'package:im/app/modules/circle_detail/entity/circle_detail_message.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/guild_setting/circle/circle_share/circle_share_item.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/guild_topic_model.dart';
import 'package:im/pages/home/model/in_memory_db.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/widgets/realtime_user_info.dart';

final RegExp _multiEmptyLinePattern = RegExp("\n{2,}");
final quoteRecalledText = "引用消息已撤回".tr;
final quoteDeletedText = "引用消息已删除".tr;

class ReplyItem extends StatefulWidget {
  final MessageEntity message;
  final Widget child;

  const ReplyItem(this.message, {this.child, Key key}) : super(key: key);

  @override
  _ReplyItemState createState() => _ReplyItemState();
}

class ReplyCacheItem {
  String userId;
  String text;

  ReplyCacheItem(this.userId, this.text);
}

class _ReplyItemState extends State<ReplyItem> {
  static Map<String, ReplyCacheItem> quoteTextMap = {};
  String quoteText;
  MessageEntity quoteMessage;

  Future<void> _init() async {
    if (!widget.message.isCircleMessage) {
      final model =
          TextChannelController.to(channelId: widget.message.channelId);
      quoteMessage = await model.getQuoteMessage(mid);
      quoteMessage ??= model.messageList
          .firstWhere((e) => e.messageId == mid, orElse: () => null);
      if (quoteMessage == null) return;
      InMemoryDb.getMessageList(widget.message.channelId)
          .addCache(quoteMessage);
    } else {
      quoteMessage = await CircleDetailUtil.getCommentMessage(
          (widget.message as CommentMessageEntity).postId, mid);
      if (quoteMessage == null) return;
    }

    final notificationString = await quoteMessage.toNotificationString();
    final endText = notificationString
        ?.toString()
        ?.replaceAll(_multiEmptyLinePattern, '\n');
    String newQuoteText = endText;

    if (quoteMessage.isRecalled == true) {
      newQuoteText = quoteRecalledText;
    } else if (quoteMessage.deleted == 1) {
      newQuoteText = quoteDeletedText;
    }
    if (newQuoteText != quoteText) {
      quoteTextMap[mid] = ReplyCacheItem(quoteMessage.userId, newQuoteText);
      if (mounted) setState(() => quoteText = newQuoteText);
    }
  }

  @override
  void initState() {
    _init();
    quoteText = quoteTextMap[mid]?.text;
    super.initState();
  }

  String get mid => widget.message.quoteL2 ?? widget.message.quoteL1;

  @override
  Widget build(BuildContext context) {
    Widget text;
    if (quoteText == null) {
      text = Text("此消息加载中...".tr);
    } else {
      text = buildChild(quoteMessage);
    }
    setMesCount(widget.message);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        color: appThemeData.scaffoldBackgroundColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (!widget.message.isCircleMessage)
                  Container(
                    margin: const EdgeInsets.fromLTRB(0, 2, 6, 2),
                    width: 2,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .dividerTheme
                          .color
                          .withOpacity(0.25),
                      borderRadius: BorderRadius.circular(0.5),
                    ),
                  ),
                Flexible(
                    child: DefaultTextStyle(
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodyText1
                            .copyWith(fontSize: 14, height: 1.25),
                        maxLines: 2,
                        child: text)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          widget.child,
        ],
      ),
    );
  }

  Widget buildChild(MessageEntity quoteMessage) {
    /// 遇见过 quoteMessage == null
    if (quoteMessage?.isRecalled == true) {
      return Text(quoteRecalledText);
    } else if (quoteMessage?.deleted == 1) {
      return Text(quoteDeletedText);
    } else if (quoteText == quoteRecalledText ||
        quoteText == quoteDeletedText) {
      return Text(quoteText);
    } else {
      if (quoteMessage?.content is CircleShareEntity)
        return ShareQuoteWidget(
          userId: quoteMessage.userId,
          entity: quoteMessage,
        );

      return Text.rich(
        TextSpan(children: [
          WidgetSpan(
              child: RealtimeNickname(
            userId: quoteTextMap[mid].userId,
            style: const TextStyle(fontSize: 14),
            guildId: widget.message.guildId,
            showNameRule: ShowNameRule.remarkAndGuild,
          )),
          TextSpan(text: ": ${quoteText.breakWord}"),
        ]),
      );
    }
  }
}
