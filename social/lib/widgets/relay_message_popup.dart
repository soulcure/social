import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/core/config.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/text_chat/items/topic_share_item.dart';
import 'package:im/pages/home/view/text_chat/text_chat_ui_creator.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/avatar.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:rich_input/rich_input.dart';

Future showRelayMessagePopup(
  BuildContext context, {
  UserInfo user,
  MessageEntity message,
}) {
  return showBottomModal(context,
      resizeToAvoidBottomInset: false,
      builder: (c, s) => RelayMessagePopup(
            user: user,
            message: message,
          ));
}

class RelayMessagePopup extends StatefulWidget {
  final UserInfo user;
  final MessageEntity message;

  const RelayMessagePopup({
    @required this.user,
    @required this.message,
  });

  @override
  _RelayMessagePopupState createState() => _RelayMessagePopupState();
}

class _RelayMessagePopupState extends State<RelayMessagePopup> {
  final _focusNode = FocusNode();
  final _controller = RichInputController();
  final _scrollController = ScrollController();

  final ValueNotifier _loading = ValueNotifier(false);
  Future _future;

  void jumpToBottom() {
    if (_scrollController.position != null && _focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 100)).then((value) {
        if (_scrollController.position.pixels !=
            _scrollController.position.maxScrollExtent)
          _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: kThemeChangeDuration,
              curve: Curves.easeIn);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _scrollController.animateTo(0,
            duration: kThemeChangeDuration, curve: Curves.easeIn);
      }
    });
    _controller.addListener(jumpToBottom);

    if (widget.message.content is TopicShareEntity) {
      // 话题item需要future builder
      _future = getTopicChildMessage(widget.message);
    }
  }

  Future<void> _sendMessage() async {
    _loading.value = true;
    if (widget.message.content is TopicShareEntity) {
      final MessageEntity message = await getTopicChildMessage(widget.message);
      if (message != null) {
        unawaited(sendMessgae(message, widget.user.userId));
        showToast('消息已发送'.tr);
      } else {
        showToast('消息发送失败'.tr);
      }
    } else {
      unawaited(sendMessgae(widget.message, widget.user.userId));
      showToast('消息已发送'.tr);
    }

    Get.back();
    Get.back();
    _loading.value = false;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.removeListener(jumpToBottom);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double bottom = getBottomViewInset() + 261;
    final keyboardBottom = max(MediaQuery.of(context).viewInsets.bottom,
        MediaQuery.of(context).viewPadding.bottom);
    if (keyboardBottom > bottom) {
      bottom = keyboardBottom + 8;
      jumpToBottom();
    } else {
      print('keyboardBottom < bottom');
    }
    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
      },
      child: Container(
        color: Theme.of(context).backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: Global.mediaInfo.size.height * 0.88),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 16, bottom: 16),
                          width: MediaQuery.of(context).size.width,
                          alignment: Alignment.center,
                          child: Text(
                            '发送给'.tr,
                            style: Theme.of(context)
                                .textTheme
                                .bodyText2
                                .copyWith(
                                    height: 1,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17),
                          ),
                        ),
                        Positioned(
                            top: 3,
                            right: 0,
                            child: Stack(
                              children: [
                                CupertinoButton(
                                  onPressed: _sendMessage,
                                  padding: const EdgeInsets.all(0),
                                  child: Text(
                                    '发送'.tr,
                                    style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        height: 1,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17),
                                  ),
                                ),
                                ValueListenableBuilder(
                                  valueListenable: _loading,
                                  builder: (context, loading, child) {
                                    if (loading) {
                                      return Positioned.fill(
                                          child: Container(
                                              color: CustomColor(context)
                                                  .backgroundColor6,
                                              child: DefaultTheme
                                                  .defaultLoadingIndicator()));
                                    } else {
                                      return const SizedBox();
                                    }
                                  },
                                )
                              ],
                            ))
                      ],
                    ),
                    SizedBox(
                      height: 52,
                      child: Row(
                        children: [
                          Avatar(
                            url: widget.user.avatar,
                            radius: 16,
                          ),
                          sizeWidth12,
                          Text(
                            widget.user.nickname,
                            style: Theme.of(context).textTheme.bodyText2,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: _buildContent(widget.message),
                    ),
                    sizeHeight20,
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 122),
                      child: RichInput(
                        selectionWidthStyle: BoxWidthStyle.max,
                        selectionHeightStyle: BoxHeightStyle.max,
                        enableSuggestions: false,
                        controller: _controller,
                        focusNode: _focusNode,
                        style: Theme.of(context).textTheme.bodyText2,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        maxLength: 5000,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          isDense: true,
                          counterText: "",
                          border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context)
                                      .disabledColor
                                      .withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(7),
                              gapPadding: 0),
                          fillColor: Theme.of(context).backgroundColor,
                          filled: true,
                          hintStyle: TextStyle(
                              color: Theme.of(context).disabledColor,
                              height: 1.35),
//                      hintText: hintText,
                        ),
//                    onEditingComplete: sendText,
                      ),
                    ),
                    SizedBox(
                      height: bottom,
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> sendMessgae(MessageEntity message, String toUserId) async {
    final channel = await DirectMessageController.to.createChannel(toUserId);
    if (channel == null) return;
    final tcController = TextChannelController.to(channelId: channel.id);
    switch (message.content.runtimeType) {
      case VoiceEntity:
        await tcController.sendContent(
          TextEntity(text: '[语音]'.tr),
          guildId: toUserId,
          channelType: ChatChannelType.dm,
        );
        break;
      case TextEntity:
        final text = await message.toNotificationString();
        await tcController.sendContent(
          TextEntity.fromString(text),
          guildId: toUserId,
          channelType: ChatChannelType.dm,
        );
        break;
      default:
        await tcController.sendContent(
          message.content,
          guildId: toUserId,
          channelType: ChatChannelType.dm,
        );
        break;
    }

    if (_controller.text != null && _controller.text.isNotEmpty) {
      unawaited(tcController.sendContent(
        TextEntity(text: _controller.text),
        guildId: toUserId,
        channelType: ChatChannelType.dm,
      ));
    }
  }

  Widget _buildContent(MessageEntity message) {
    Widget child;
    switch (message.content.runtimeType) {
      case VoiceEntity:
        child = Text(
          '[语音]'.tr,
          style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 17),
        );
        break;
      case TextEntity:
        final entity = message.content as TextEntity;
        if (entity.text.startsWith(Config.webLinkPrefix) ||
            (entity.urlList != null && entity.urlList.isNotEmpty)) {
          child = Container(
            alignment: Alignment.center,
            child: TextChatUICreator.createItemContent(message),
          );
        } else {
          child = FutureBuilder(
            future: message.toNotificationString(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return child = Text(
                  snapshot.data,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      .copyWith(fontSize: 17),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                );
              }
              return Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: DefaultTheme.defaultLoadingIndicator());
            },
          );
        }
        break;
      case ImageEntity:
      case VideoEntity:
        child = Container(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: TextChatUICreator.createItemContent(message),
          ),
        );
        break;
      case TopicShareEntity:
        return FutureBuilder(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final MessageEntity<MessageContentEntity> newMessage =
                  snapshot.data;
              if (newMessage != null &&
                  newMessage.content.runtimeType != TopicShareEntity) {
                return _buildContent(newMessage);
              }
            }
            return Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: DefaultTheme.defaultLoadingIndicator());
          },
        );
      default:
        child = TextChatUICreator.createItemContent(widget.message);
        break;
    }
    return AbsorbPointer(
      child: child,
    );
  }
}
