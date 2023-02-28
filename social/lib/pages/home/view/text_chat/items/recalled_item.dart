import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/rich_input_popup_tun.dart'
    if (dart.library.html) 'package:im/pages/home/view/text_chat/rich_editor/rich_input_popup.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:provider/provider.dart';

import '../../../../../global.dart';

enum RecalledMessageFormat {
  IRecallMyMessage,
  someoneRecallHisMessage,
  IRecallSomeonesMessage,
  someoneRecallMyMessage,
  someoneRecallAnotherOnesMessage,
}

class RecalledItem extends StatelessWidget {
  final MessageEntity message;

  const RecalledItem(this.message);

  static RecalledMessageFormat getRecalledMessageFormat(MessageEntity message) {
    final myMessage = message.userId == Global.user.id;
    final messageRecalledBySender = message.userId == message.recall;
    final recalledByMyself = message.recall == Global.user.id;

    if (myMessage && recalledByMyself) {
      return RecalledMessageFormat.IRecallMyMessage;
    }

    if (!myMessage && messageRecalledBySender) {
      return RecalledMessageFormat.someoneRecallHisMessage;
    }

    if (recalledByMyself && !messageRecalledBySender) {
      return RecalledMessageFormat.IRecallSomeonesMessage;
    }

    if (myMessage && !messageRecalledBySender && !recalledByMyself) {
      return RecalledMessageFormat.someoneRecallMyMessage;
    }

    if (!myMessage && !messageRecalledBySender && !recalledByMyself) {
      return RecalledMessageFormat.someoneRecallAnotherOnesMessage;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final child = _buildChild(context);
    if (child == null) return const SizedBox();
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 6.5),
        alignment: Alignment.center,
        child: child);
  }

  Widget _buildChild(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 12);

    switch (RecalledItem.getRecalledMessageFormat(message)) {
      case RecalledMessageFormat.IRecallMyMessage:
        return _buildIRecallMyMessage(context, style);
      case RecalledMessageFormat.someoneRecallHisMessage:
        return _buildSomeoneRecallHisMessage(context, style);
      case RecalledMessageFormat.IRecallSomeonesMessage:
        return _buildIRecallSomeonesMessage(context, style);
      case RecalledMessageFormat.someoneRecallMyMessage:
        return _buildSomeoneRecallMyMessage(context, style);
        break;
      case RecalledMessageFormat.someoneRecallAnotherOnesMessage:
        return _buildSomeoneRecallAnotherOnesMessage(context, style);
    }

    return null;
  }

  Widget _buildIRecallMyMessage(BuildContext context, TextStyle style) {
    // 横屏模式富文本消息暂时不支持重新编辑
    final shouldShow = message.content is TextEntity ||
        (message.content is RichTextEntity && OrientationUtil.portrait);
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: "你撤回了一条消息".tr),
        if (shouldShow)
          TextSpan(
              text: "  重新编辑".tr,
              style: TextStyle(color: primaryColor),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  final quote = message.quoteL2 ?? message.quoteL1;
                  MessageEntity reply;
                  if (quote != null) {
                    reply =
                        TextChannelController.to(channelId: message.channelId)
                            .messageList
                            .firstWhere((element) => element.messageId == quote,
                                orElse: () => null);
                  }
                  if (message.content is TextEntity) {
                    final content = message.content as TextEntity;
                    context.read<InputModel>().setValue(content.text,
                        requestFocus: true, reply: reply);
                  } else if (message.content is RichTextEntity) {
                    showRichInputPopup(
                      context,
                      originMessage: message,
                      reply: reply,
                      cacheKey: message.channelId,
                    );
                  }
                }),
      ]),
      style: style,
    );
  }

  WidgetSpan _buildNickname(String userId, TextStyle style) {
    return WidgetSpan(
      child: RealtimeNickname(
        userId: userId,
        style: style.copyWith(
            fontWeight: FontWeight.normal, color: Get.theme.primaryColor),
        tapToShowUserInfo: true,
        showNameRule: ShowNameRule.remarkAndGuild,
        maxLength: 16,
      ),
    );
  }

  Widget _buildSomeoneRecallHisMessage(BuildContext context, TextStyle style) {
    return Text.rich(
      TextSpan(children: [
        const TextSpan(text: nullChar),
        _buildNickname(message.userId, style),
        TextSpan(text: " 撤回了一条消息".tr),
      ]),
      style: style,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildIRecallSomeonesMessage(BuildContext context, TextStyle style) {
    if (Get.locale.languageCode == 'zh') {
      return Text.rich(
        TextSpan(children: [
          TextSpan(text: "你撤回了 ".tr),
          _buildNickname(message.userId, style),
          TextSpan(text: " 发的一条消息".tr),
        ]),
        style: style,
        textAlign: TextAlign.center,
      );
    }
    return Text.rich(
      TextSpan(children: [
        const TextSpan(text: "You withdrew a message sent by "),
        _buildNickname(message.userId, style),
      ]),
      style: style,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSomeoneRecallMyMessage(BuildContext context, TextStyle style) {
    return Text.rich(
      TextSpan(children: [
        const TextSpan(text: nullChar),
        _buildNickname(message.recall, style),
        TextSpan(text: " 撤回了你发的一条消息".tr),
      ]),
      style: style,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSomeoneRecallAnotherOnesMessage(
      BuildContext context, TextStyle style) {
    if (Get.locale.languageCode == 'zh') {
      return Text.rich(
        TextSpan(children: [
          _buildNickname(message.recall, style),
          TextSpan(text: " 撤回了 ".tr),
          _buildNickname(message.userId, style),
          TextSpan(text: " 发的一条消息".tr),
        ]),
        style: style,
        textAlign: TextAlign.center,
      );
    }

    return Text.rich(
      TextSpan(children: [
        const TextSpan(text: nullChar),
        _buildNickname(message.recall, style),
        const TextSpan(text: " withdrew a message sent by "),
        _buildNickname(message.userId, style),
      ]),
      style: style,
      textAlign: TextAlign.center,
    );
  }
}
