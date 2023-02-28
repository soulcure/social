import 'package:flutter/material.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_util.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/bot_commands/shortcut_bar.dart';
import 'package:im/pages/guild_setting/circle/circle_share/circle_share_item.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/bottom_bar/text_chat_bottom_bar.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/realtime_user_info.dart';

class ImBottomBar extends TextChatBottomBar {
  //监听输入框焦点变化
  final Function(bool hasFocus) onFocusChange;

  const ImBottomBar(ChatChannel channel, {this.onFocusChange, Key key})
      : super(channel, key: key);

  @override
  ImBottomBarState createState() => ImBottomBarState();
}

class ImBottomBarState extends TextChatBottomBarState<ImBottomBar> {
  /// 保存输入框记录的ID
  String get recordId => isCircleDetailPage ? channel?.recipientId : channelId;

  @override
  void initState() {
    super.initState();
    _setInputTextRecord();
    focusNode.addListener(onFocusChange);
  }

  @override
  void dispose() {
    focusNode.removeListener(onFocusChange);
    super.dispose();
  }

  @override
  bool sendText() {
    if (super.sendText()) inputModel.reply = null;

    if (recordId.noValue) return false;
    final inputRecord = Db.textFieldInputRecordBox.get(recordId);
    if (inputRecord?.richContent != null) {
      Db.textFieldInputRecordBox
          .put(recordId, InputRecord(richContent: inputRecord.richContent));
    } else {
      Db.textFieldInputRecordBox.delete(recordId);
    }
    return true;
  }

  @override
  void sendVoice(String path, int second) {
    super.sendVoice(path, second);

    /// clear 必须在 send 之后
    _clearInput();
  }

  @override
  Future<void> sendMedia(List<String> identifier, {bool thumb}) async {
    await super.sendMedia(identifier, thumb: thumb);

    /// clear 必须在 send 之后
    /// 但是这导致了发送图片完成后才 clear
    _clearInput();
  }

  @override
  Widget getRelayUI() {
    final theme = Theme.of(context);
    final color = theme.disabledColor;
    final textStyle = TextStyle(color: color, fontSize: 14);
    final reply = inputModel.reply;
    if (reply.content is CircleShareEntity)
      return ShareReplyWidget(inputModel: inputModel);
    return Container(
      color: appThemeData.scaffoldBackgroundColor,
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        children: <Widget>[
          FadeButton(
            onTap: () => inputModel.reply = null,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.close, color: color, size: 16),
          ),
          SizedBox(
              height: 16,
              child: VerticalDivider(color: color.withOpacity(0.5))),
          const SizedBox(width: 12),
          RealtimeNickname(
            userId: reply.userId,
            style: textStyle,
            maxLength: 12,
            showNameRule: ShowNameRule.remarkAndGuild,
            breakWord: true,
          ),
          Flexible(
            child: FutureBuilder(
                future: reply.toNotificationString(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  return Text(
                    ": ${snapshot.data}".replaceAll("\n", " ").breakWord,
                    style: textStyle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  );
                }),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  @override
  Widget getShortcutBar() {
    return ShortcutBar(
      widget.channel,
      focusIndex: focusIndex,
      focusNode: inputModel.textFieldFocusNode,
    );
  }

  /// 从输入记录中恢复上次的输入内容
  void _setInputTextRecord() {
    if (recordId.noValue) return;
    final history = Db.textFieldInputRecordBox.get(recordId);
    if (history == null) {
      inputModel.setValue("");
    } else {
      // 设置输入框的记录内容
      void setRecord(MessageEntity reply) {
        if (UniversalPlatform.isIOS) {
          delay(() {
            if (mounted) inputModel.setValue(history.content, reply: reply);
          }, 100);
        } else {
          if (mounted) inputModel.setValue(history.content, reply: reply);
        }
      }

      if (isCircleDetailPage) {
        if (history.replyId.hasValue) {
          final c = CircleDetailController.to(
              postId: widget.channel.recipientId, videoFirst: true);
          c?.hasInitialized?.future?.then((_) {
            CircleDetailUtil.getCommentMessage(
              widget.channel.recipientId,
              history.replyId,
            ).then(setRecord);
          });
        } else {
          setRecord(null);
        }
      } else {
        final m = TextChannelController.to(channelId: recordId);

        /// bugly上报m.hasInitialized为空的错误 (https://bugly.qq.com/v2/crash-reporting/errors/58f80b9ee9/297042?pid=1)
        /// 加上问号先处理报错，hasInitialized为什么为空还需要排查。
        m.hasInitialized?.then((value) {
          MessageEntity reply;
          if (history.replyId != null) {
            reply = m.messageList.firstWhere(
                (element) => element.messageId == history.replyId,
                orElse: () => null);
          }
          setRecord(reply);
        });
      }
    }
  }

  void _clearInput() {
    if (inputModel.reply != null) {
      //如果输入框的内容未空,或者只有用户的艾特,则reply置空
      if (inputModel.inputController.data.noValue ||
          inputModel.inputController.data ==
              TextEntity.getAtString(inputModel.reply.userId, false)) {
        inputModel.reply = null;
      }
    }
  }

  void onFocusChange() {
    widget.onFocusChange?.call(focusNode.hasFocus);
  }
}
