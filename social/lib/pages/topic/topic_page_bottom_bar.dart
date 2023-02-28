import 'package:flutter/material.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/bottom_bar/text_chat_bottom_bar.dart';

class TopicPageBottomBar extends TextChatBottomBar {
  final String messageId;

  const TopicPageBottomBar(this.messageId, ChatChannel channel, {Key key})
      : super(channel, key: key);

  @override
  TextChatBottomBarState<TextChatBottomBar> createState() =>
      TopicPageBottomBarState();
}

class TopicPageBottomBarState
    extends TextChatBottomBarState<TopicPageBottomBar> {
  @override
  String get richTextRedDotId => widget.messageId;
}
