import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/api/text_chat_api.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/config.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/text_chat/message_permisson_state.dart';
import 'package:im/pages/home/view/text_chat/message_tools.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/web_light_theme.dart';
import 'package:im/utils/emo_util.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/web/utils/show_web_tooltip.dart';
import 'package:im/widgets/mouse_hover_builder.dart';
import 'package:im/widgets/super_tooltip.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';

import 'items/components/message_reaction.dart';

void showWebEmojiDlg(BuildContext context,
    {MessageEntity message, bool isFromTopicPage}) {
  showWebTooltip(context, offsetY: 10, popupDirection: TooltipDirection.auto,
      builder: (context, done) {
    return Container(
        width: 388,
        height: 280,
        decoration: BoxDecoration(
          color: CustomColor(context).backgroundColor6,
        ),
        child: WebMessageHoverWrapper(
            message: message,
            onlyEmji: true,
            isFromTopicPage: isFromTopicPage,
            emojiCloseBack: () => done(null)));
  });
}

class WebMessageHoverWrapper extends StatefulWidget {
  final Widget child;
  final MessageEntity message;
  final VoidCallback relay;
  final bool shouldShowReply;
  final bool isFromTopicPage;
  final bool onlyEmji;
  final VoidCallback emojiCloseBack;

  const WebMessageHoverWrapper({
    this.child,
    this.message,
    this.relay,
    this.shouldShowReply = false,
    this.isFromTopicPage = false,
    this.onlyEmji = false,
    this.emojiCloseBack,
  });

  @override
  _WebMessageHoverWrapperState createState() => _WebMessageHoverWrapperState();
}

class _WebMessageHoverWrapperState
    extends MessagePermissionState<WebMessageHoverWrapper> {
  final ValueNotifier _enterValue = ValueNotifier(false);
  final ValueNotifier _selectMoreValue = ValueNotifier(false);

  @override
  MessageEntity get message => widget.message;

  Widget _buildItem(BuildContext context, IconData data, VoidCallback callback,
      {IconData hoverData, bool selected = false}) {
    return GestureDetector(
      onTap: callback,
      child: MouseHoverBuilder(
        builder: (context, hover) {
          final color = hoverData != null && hover
              ? Theme.of(context).primaryColor
              : (selected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).iconTheme.color);
          return Container(
            width: 32,
            height: 32,
            color: Theme.of(context).backgroundColor,
            alignment: Alignment.center,
            child: Icon(
              hover ? (hoverData ?? data) : data,
              size: 16,
              color: color,
            ),
          );
        },
      ),
    );
  }

  Widget _expandedList(VoidCallback close) {
    Widget _emojiItem(ReactionEntity emoji) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          widget.message.reactionModel.toggle(emoji.name);
          close();
        },
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: EmoUtil.instance.getEmoIcon(emoji.name)),
      );
    }

    return Container(
      height: 200,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 0.5,
            color: Colors.transparent,
          ),
        ),
      ),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: emojiList.length,
        padding: const EdgeInsets.only(top: 5, bottom: 15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
        ),
        itemBuilder: (context, index) {
          return _emojiItem(emojiList[index]);
        },
      ),
    );
  }

  Widget _messageTools(BuildContext context, VoidCallback closeCallback) {
    Widget _buildItem(IconData icon, String text, VoidCallback callback) {
      return MouseHoverBuilder(
        builder: (context, selected) {
          return FadeBackgroundButton(
            tapDownBackgroundColor: Theme.of(context).disabledColor,
            onTap: callback,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              color: selected
                  ? const Color(0xffd3d7dc)
                  : Theme.of(context).backgroundColor,
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                  ),
                  sizeWidth10,
                  Text(
                    text,
                    style: Theme.of(context)
                        .textTheme
                        .bodyText2
                        .copyWith(fontSize: 12),
                  )
                ],
              ),
            ),
          );
        },
      );
    }

    final content = widget.message.content;
    print('content is TextEntity : $content ${content is TextEntity}');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canStick)
          _buildItem(IconFont.buffChatStick, '置顶'.tr, () async {
            final bool result = await TextChatApi.stickMessage(Global.user.id,
                widget.message.channelId, widget.message.messageId, true);
            if (result) {
              showToast('消息置顶成功'.tr);
            }
            closeCallback();
          }),
        if (canUnStick)
          _buildItem(IconFont.buffChatUnstick, '取消置顶'.tr, () async {
            final res = await showConfirmDialog(
              barrierDismissible: true,
              title: '取消置顶'.tr,
              content: '确定取消这条置顶吗？取消后，会话成员不会再看到这条置顶'.tr,
            );
            if (res == true) {
              unawaited(TextChatApi.stickMessage(Global.user.id,
                  widget.message.channelId, widget.message.messageId, false));
              closeCallback();
            }
          }),
        if (canCopy)
          _buildItem(IconFont.buffChatCopy, '复制'.tr, () async {
            if (content is TextEntity)
              await Clipboard.setData(ClipboardData(text: content.text));
            if (content is StickerEntity)
              await Clipboard.setData(ClipboardData(text: content.name));
            if (content is RichTextEntity)
              await Clipboard.setData(ClipboardData(
                  text: await content.toNotificationString(
                      guildId, widget.message.userId,
                      entire: true)));
            closeCallback();
          }),
        _buildItem(Icons.link, '消息链接'.tr, () async {
          final List<String> pathSegments = ["channels"];
          if (widget.message.isDmMessage) {
            pathSegments.add("@me");
          } else {
            pathSegments.add(widget.message.guildId);
          }
          pathSegments
            ..add(widget.message.channelId)
            ..add(widget.message.messageId);

          final uri = Uri(
            scheme: "https",
            host: Uri.parse(Config.webLinkPrefix).host,
            pathSegments: pathSegments,
          );
          await Clipboard.setData(ClipboardData(text: uri.toString()));
          showToast('复制成功'.tr);
          closeCallback();
        }),
        if (canBack)
          _buildItem(Icons.logout, '定位消息'.tr, () async {
            final String guildId = widget.message.guildId;
            final String channelId = widget.message.channelId;
            final String messageId = widget.message.messageId;

            final c = TextChannelController.to(channelId: channelId);
            await c.animationToMessageId(guildId, channelId, messageId);

            closeCallback();
          }),
        if (canPin)
          _buildItem(IconFont.buffChatPin, 'Pin', () {
            TextChatApi.pinMessage(Global.user.id, widget.message.channelId,
                widget.message.messageId, true);
            closeCallback();
          }),
        if (canUnpin)
          _buildItem(IconFont.buffChatPin, 'Un-Pin', () async {
            final res = await showConfirmDialog(
              barrierDismissible: true,
              title: '取消Pin'.tr,
              content: '确定取消这条Pin？'.tr,
            );
            if (res == true) {
              unawaited(TextChatApi.pinMessage(Global.user.id,
                  widget.message.channelId, widget.message.messageId, false));
            }
            closeCallback();
          }),
        if (canRecall)
          _buildItem(IconFont.buffChatWithdraw, '撤回'.tr, () async {
            final result = await showConfirmDialog(
              title: "撤回消息".tr,
              content: "是否撤回该消息？".tr,
            );
            if (result) {
              if (widget.message.localStatus != MessageLocalStatus.normal) {
                TextChannelController.to(channelId: widget.message.channelId)
                    .onMessageRecalled(
                        widget.message.messageId, Global.user.id);
              } else {
                final lastState = widget.message.content.messageState.value;
                widget.message.content.deferredEnterWaitingState();
                await TextChatApi.recall(Global.user.id.toString(),
                        widget.message.messageId, widget.message.channelId)
                    .catchError((e) {
                  widget.message.content.messageState.value = lastState;
                });
              }
              closeCallback();
            }
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onlyEmji) {
      return _expandedList(widget.emojiCloseBack);
    }

    final emojiItem = Builder(builder: (context) {
      return _buildItem(context, IconFont.buffChatEmoji, () {
        showWebTooltip(context,
            offsetY: 4,
            popupDirection: TooltipDirection.auto, builder: (context, done) {
          return Container(
              width: 388,
              height: 280,
              decoration: BoxDecoration(
                  color: CustomColor(context).backgroundColor6,
                  boxShadow: const [BoxShadow(blurRadius: 2)]),
              child: _expandedList(() => done(null)));
        });
      });
    });
    final GuildPermission gp = PermissionModel.getPermission(guildId);
    final extendUILength = 32 +
        8 +
        (MessageTools.canReply(message: widget.message) ? 33 : 0) +
        ((GlobalState.isDmChannel ||
                PermissionUtils.oneOf(gp, [Permission.ADD_REACTIONS]))
            ? 33
            : 0);

    final extendUI = Stack(
      children: [
        ValueListenableBuilder(
            valueListenable: _enterValue,
            builder: (context, value, child) {
              final sendSuccess = widget.message.content.messageState?.value ==
                  MessageState.sent;
              return (value && sendSuccess)
                  ? Container(
                      height: 32,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color:
                                  Theme.of(context).scaffoldBackgroundColor)),
                      child: Row(
                        children: [
                          if (GlobalState.isDmChannel && canReaction)
                            emojiItem
                          else if (canReaction)
                            ValidPermission(
                              permissions: [Permission.ADD_REACTIONS],
                              channelId: GlobalState.selectedChannel.value?.id,
                              builder: (val, _) {
                                if (!val) return const SizedBox();
                                return emojiItem;
                              },
                            ),
                          if (MessageTools.canReply(message: widget.message) &&
                              !widget.isFromTopicPage)
                            Padding(
                              padding: const EdgeInsets.only(left: 1),
                              child: _buildItem(context,
                                  IconFont.buffChatMessage, widget.relay,
                                  hoverData: IconFont.buffTopicReply),
                            ),
                          if (widget.message.content is! WelcomeEntity)
                            Padding(
                              padding: const EdgeInsets.only(left: 1),
                              child: ValueListenableBuilder(
                                  valueListenable: _selectMoreValue,
                                  builder: (context, selected, child) {
                                    return _buildItem(
                                        context, IconFont.buffMoreHorizontal,
                                        () {
                                      _selectMoreValue.value = true;
                                      showWebTooltip(context,
                                          popupDirection: widget.isFromTopicPage
                                              ? TooltipDirection.auto
                                              : TooltipDirection.rightTop,
                                          offsetX: 2,
                                          preferenceTop: false,
                                          builder: (context, done) {
                                        return Container(
                                          width: 90,
                                          decoration: webBorderDecoration,
                                          child: _messageTools(
                                              context, () => done(null)),
                                        );
                                      }).then((value) {
                                        _selectMoreValue.value = false;
                                      });
                                    }, selected: selected);
                                  }),
                            ),
                        ],
                      ),
                    )
                  : SizedBox(
                      height: 24,
                      width: extendUILength * 1.0,
                    );
            }),
        if (!widget.isFromTopicPage)
          const SizedBox(
            width: 120,
            height: 32,
          )
      ],
    );

    return MouseRegion(
        onEnter: (_) {
          _enterValue.value = true;
        },
        onExit: (_) {
          _enterValue.value = false;
        },
        child: !widget.isFromTopicPage
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[Flexible(child: widget.child), extendUI],
              )
            : ValueListenableBuilder(
                valueListenable: _enterValue,
                builder: (context, value, child) {
                  final sendSuccess =
                      widget.message.content.messageState.value ==
                          MessageState.sent;
                  return Container(
                    color: (value && sendSuccess)
                        ? Theme.of(context).scaffoldBackgroundColor
                        : Theme.of(context).backgroundColor,
                    child: Stack(
                      children: <Widget>[
                        widget.child,
                        Positioned(
                          top: 20,
                          right: 20,
                          child: extendUI,
                        )
                      ],
                    ),
                  );
                }));
  }
}
