import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/api/text_chat_api.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/app/modules/circle_detail/entity/circle_detail_message.dart';
import 'package:im/app/theme/app_colors.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/config.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/common.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/record_view/sound_play_manager.dart';
import 'package:im/pages/home/view/text_chat/items/components/message_reaction.dart';
import 'package:im/pages/topic/controllers/topic_controller.dart';
import 'package:im/pages/topic/topic_page.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/emo_util.dart';
import 'package:im/utils/im_utils/channel_util.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/widgets/cache_widget.dart';
import 'package:im/widgets/dialog/dmlist_dialog.dart';
import 'package:im/widgets/message_tooltip/message_tooltip.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:tuple/tuple.dart';

import 'message_permisson_state.dart';

class MessageTools extends StatefulWidget {
  final TooltipDirection direction;
  final MessageEntity message;
  final VoidCallback close;
  final VoidCallback relay;
  final bool onlyEmoji;

  final bool shouldShowReply;

  const MessageTools(this.direction,
      {@required this.message,
      this.close,
      this.relay,
      this.onlyEmoji = false,
      this.shouldShowReply = true});

  @override
  _MessageToolsState createState() => _MessageToolsState();

  static bool canReply({MessageEntity message}) {
    if (message.isRecalled || message.deleted == 1) return false;
    if (message.content is WelcomeEntity) return false;
    if (message.content is TopicShareEntity) return false;
    if (!message.isNormal) return false;
    if (message.isBlocked) return false;
    if (GlobalState.isDmChannel) return true;
    // todo web端的message.isDmMessage，无法真正判断是否是真正处于私聊，所以加此判断
    if (kIsWeb &&
        ChatTargetsModel.instance.selectedChatTarget ==
            ChatTargetsModel.instance.firstTarget) return true;
    if (message.isCircleMessage) {
      if (message.content?.messageState?.value != MessageState.sent)
        return false;
      return hasCirclePermission(
          guildId: message.guildId,
          permission: Permission.CIRCLE_REPLY,
          topicId: message.channelId);
    }
    if (!message.isDmMessage &&
        !PermissionUtils.oneOf(PermissionModel.getPermission(message.guildId),
            [Permission.SEND_MESSAGES], channelId: message.channelId))
      return false;
    return true;
  }
}

class _MessageToolsState extends MessagePermissionState<MessageTools> {
  final List<ReactionEntity> _emojiList = [];
  bool _expanded = false;
  bool _addReactionAllowed = true;
  ChatChannel _channel;
  List<Tuple3<String, IconData, VoidCallback>> _buttons;
  int _refreshKey = 0;

  @override
  MessageEntity get message => widget.message;

  @override
  String get guildId => GlobalState.selectedChannel?.value?.guildId;

  @override
  void initPermissionState() {
    ///这里需要调用父类方法，否则会出现父类中[_channel]对象无法初始化的情况，这里可以考虑统一[_channel]的初始化方法
    super.initPermissionState();
    if (EmoUtil.instance.curReaEmoList.isEmpty) {
      EmoUtil.instance.doInitial().then((value) {
        _emojiList.addAll(EmoUtil.instance.curReaEmoList);
        _refreshKey++;
        setState(() {});
      });
    } else
      _emojiList.addAll(EmoUtil.instance.curReaEmoList);

    ///移除围观表情
    final int index =
        _emojiList.indexWhere((e) => e.name == TopicController.emojiName);

    if (index >= 0) {
      _emojiList.removeAt(index);
    }

    _expanded = widget.onlyEmoji;
    _channel = ChannelUtil.instance.getChannel(widget.message.channelId);
    refresh(notify: false);
  }

  @override
  void refresh({bool notify = true}) {
    super.refresh(notify: notify);

    final message = widget.message;
    if (message.isCircleMessage) {
      _addReactionAllowed = message.canAddReaction &&
          message.isNormal &&
          message.content?.messageState?.value == MessageState.sent &&
          hasCirclePermission(
              guildId: message.guildId,
              permission: Permission.CIRCLE_REPLY,
              topicId: message.channelId);
    } else {
      _addReactionAllowed = message.canAddReaction &&
          message.isNormal &&
          !message.isBlocked &&
          !message.isIllegal &&
          (_channel.type == ChatChannelType.dm ||
              _channel.type == ChatChannelType.group_dm ||
              guildPermission == null ||
              PermissionUtils.oneOf(guildPermission, [Permission.ADD_REACTIONS],
                  channelId: _channel.id));
    }
    _buttons = _buildButtons();
    if (message.shareParentId != null && message.shareParentId.isNotEmpty) {
      _addReactionAllowed = true;
    }

    if (notify) {
      _refreshKey++;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // 优化性能，防止重复渲染
    return CacheWidget(
      cacheKey: _refreshKey,
      builder: () => AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        reverseDuration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SizeTransition(sizeFactor: animation, child: child),
          );
        },
        child: _emojiList.isEmpty
            ? Container(
                alignment: Alignment.center,
                height: 60,
                padding: const EdgeInsets.all(20),
                child: const FittedBox(child: CircularProgressIndicator()))
            : _messageToolsPanel(),
      ),
    );
  }

  Widget _toolItem(Tuple3<String, IconData, VoidCallback> button) {
    return FadeButton(
      onTap: () {
        // 是否需要参加入门仪式
        // if (OpenTaskIntroductionCeremony.openTaskInterface()) return;
        button.item3();
        widget.close();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          sizeHeight5,
          Icon(button.item2,
              size: 23, color: Theme.of(context).textTheme.bodyText2.color),
          sizeHeight5,
          Text(
            button.item1,
            style: Theme.of(context).textTheme.bodyText2.copyWith(fontSize: 12),
          )
        ],
      ),
    );
  }

  Widget _emojiItem(ReactionEntity emoji) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        //是否需要参加入门仪式
        // if (OpenTaskIntroductionCeremony.openTaskInterface()) return;
        widget.message.reactionModel.toggle(emoji.name);
        widget.close();
      },
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: EmoUtil.instance.getEmoIcon(emoji.name)),
    );
  }

  Widget _messageToolsPanel() {
    return ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: <Widget>[
        if (_addReactionAllowed) _expandedList(),
        if (!_expanded && !widget.onlyEmoji) _toolBar(),
      ],
    );
  }

  Widget _toolBar() {
    return GridView.builder(
      shrinkWrap: true,
      itemCount: _buttons.length,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        mainAxisExtent: 50,
        crossAxisCount: 6,
//        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        final item = _buttons[index];
        return _toolItem(item);
      },
    );
  }

  List<Tuple3<String, IconData, VoidCallback>> _buildButtons() {
    final content = widget.message.content;
    final isCircleMessage = widget.message.isCircleMessage;
    bool canDelete = true;
    if (isCircleMessage) {
      /// 检查是否可以删除圈子回复消息
      canDelete = widget.message.userId == Global.user?.id ||
          hasCircleManagePermission(guildId: widget.message.guildId);
    }
    return [
      if (widget.shouldShowReply &&
          MessageTools.canReply(message: widget.message))
        Tuple3("回复".tr, IconFont.buffChatMessage, widget.relay),
      if (canCopy)
        Tuple3("复制".tr, IconFont.buffChatCopy, () async {
          /// 复制功能先不启用文字范围选择功能
          /// 此功能和原生还有些差异：
          /// 1. 不能默认设置全选
          /// 2. 终止位置拉到起始位置前时不会自动交换位置
//          await Clipboard.setData(ClipboardData(
//              text: await content.toNotificationString(
//                  widget.message.guildId, widget.message.userId)));
          if (content is TextEntity)
            await Clipboard.setData(ClipboardData(text: content.text));
          if (content is StickerEntity)
            await Clipboard.setData(ClipboardData(text: content.name));
          if (content is RichTextEntity)
            await Clipboard.setData(ClipboardData(
                text: await content.toNotificationString(
                    guildId, widget.message.userId,
                    entire: true)));
          showToast('😀 复制成功'.tr);
        }),
      if (canForward)
        Tuple3("转发".tr, IconFont.buffChatForward, () {
          showShareDmListDialog(context, message: widget.message);
        }),
      if (canPin)
        Tuple3("Pin", IconFont.buffChatPin, () async {
          unawaited(TextChatApi.pinMessage(Global.user.id,
              widget.message.channelId, widget.message.messageId, true));
        }),
      if (canUnpin)
        Tuple3("Un-Pin", IconFont.buffChatUnpin, () async {
          final res = await showConfirmDialog(
            barrierDismissible: true,
            title: '取消Pin'.tr,
            content: '确定取消这条Pin？'.tr,
          );
          if (res == true) {
            unawaited(TextChatApi.pinMessage(Global.user.id,
                widget.message.channelId, widget.message.messageId, false));
          }
        }),
      if (canStick)
        Tuple3("置顶".tr, IconFont.buffChatStick, () async {
          final bool result = await TextChatApi.stickMessage(Global.user.id,
              widget.message.channelId, widget.message.messageId, true);
          if (result) {
            showToast('消息置顶成功'.tr);
          }
        }),
      if (canUnStick)
        Tuple3("取消置顶".tr, IconFont.buffChatUnstick, () async {
          final res = await showConfirmDialog(
            barrierDismissible: true,
            title: '取消置顶'.tr,
            content: '确定取消这条置顶吗？取消后，会话成员不会再看到这条置顶'.tr,
          );
          if (res == true) {
            unawaited(TextChatApi.stickMessage(Global.user.id,
                widget.message.channelId, widget.message.messageId, false));
          }
        }),
      if (canRecall)
        Tuple3("撤回".tr, IconFont.buffChatWithdraw, () async {
          final result = await showConfirmDialog(
            title: "撤回消息".tr,
            content: "是否撤回该消息？".tr,
          );
          if (result) {
            if (widget.message.localStatus != MessageLocalStatus.normal) {
              TextChannelController.to(channelId: widget.message.channelId)
                  .onMessageRecalled(widget.message.messageId, Global.user.id);
            } else {
              final lastState = widget.message.content.messageState.value;
              widget.message.content.deferredEnterWaitingState();
              await TextChatApi.recall(Global.user.id.toString(),
                      widget.message.messageId, widget.message.channelId)
                  .catchError((e) {
                widget.message.content.messageState.value = lastState;
              });
            }
          }
        }),
      if (canDelete)
        Tuple3("删除".tr, IconFont.buffChatDelete, () async {
          final result = await showConfirmDialog(
            title: isCircleMessage ? "确定删除此回复？".tr : "确定删除此消息？".tr,
            content: isCircleMessage ? null : "删除后，将不会出现在你的消息记录中！".tr,
            confirmText: "确定删除".tr,
            confirmStyle: appThemeData.textTheme.bodyText2.copyWith(
              color: redTextColor,
              fontSize: 17,
            ),
          );
          if (result == true) {
            if (isCircleMessage) {
              unawaited(CircleDetailController.to(
                postId: (widget.message as CommentMessageEntity).postId,
                videoFirst: true,
              ).deleteComment(widget.message));
              return;
            }
            TextChannelController.to(channelId: widget.message.channelId)
                .deleteMessage(widget.message.messageId);
            if (SoundPlayManager().message?.messageId ==
                widget.message.messageId) {
              unawaited(SoundPlayManager().forceStop());
            }

            ///fix 未读状态下，话题详情回复中 删除未读，导致计数未读一直在
            final String channelId = widget.message.channelId;
            final String messageId = widget.message.messageId;

            final int unread = ChannelUtil.instance.getUnread(channelId);
            if (unread > 0) {
              final String readId = Db.readMessageIdBox.get(channelId);

              ///删除消息的id 大于 已读消息id
              if (readId != null && messageId.compareTo(readId) >= 0) {
                ChannelUtil.instance.setUnread(channelId, unread - 1);
              }
            }
          }
        }),
      // if (widget.message.isDmMessage ||
      //     PermissionUtils.isGuildOwner(userId: Global.user.id))
      if (canLink)
        Tuple3("消息链接".tr, Icons.link, () async {
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
          showToast('😀 复制成功'.tr);
        }),

      if (canBack)
        Tuple3("定位消息".tr, Icons.logout, () async {
          final String guildId = widget.message.guildId;
          final String channelId = widget.message.channelId;
          final String messageId = widget.message.messageId;
          Get.back(result: TopicBackParam(guildId, channelId, messageId));
        }),
    ];
  }

  Widget _expandedList() {
    final emojiLen = _emojiList.length;
    final buttonLen = (_buttons.length ~/ 6 + 1) * 6;
    //  计算表情区域的最小和最大的展示高度
    final double minExpendHeight = (Get.width - 40) / 6;
    double maxExpendHeight = minExpendHeight * 4;
    if (minExpendHeight > 100) {
      maxExpendHeight = minExpendHeight * 2;
    }
    return Container(
      height: _expanded ? maxExpendHeight : minExpendHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 0.5,
            color: _expanded ? Colors.transparent : const Color(0xffE0E2E6),
          ),
        ),
      ),
      child: GridView.builder(
        physics: _expanded
            ? const BouncingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        itemCount: !_expanded
            ? 6
            : widget.onlyEmoji
                ? emojiLen
                : (emojiLen ~/ 6 + 1) * 6 + buttonLen,
        padding: const EdgeInsets.only(top: 5, bottom: 15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
//          childAspectRatio: 1.2,
        ),
        itemBuilder: (context, index) {
          final getIndex = index >= 6 && !widget.onlyEmoji ? index - 1 : index;

          if (index == 5 && !widget.onlyEmoji) {
            return GestureDetector(
                onTap: () {
                  _refreshKey++;
                  setState(() {
                    _expanded = !_expanded;
                  });
                },
                child: Transform.rotate(
                  angle: !_expanded ? 0 : pi,
                  child: Icon(
                    IconFont.buffTabMore,
                    size: 26,
                    color: Theme.of(context).textTheme.bodyText2.color,
                  ),
                ));
          }
          final lastEmojiIdx =
              widget.onlyEmoji ? _emojiList.length : _emojiList.length + 1;
          if (index + 1 <= lastEmojiIdx) {
            return _emojiItem(_emojiList[getIndex]);
          } else if (index + 1 <= (_emojiList.length ~/ 6 + 1) * 6) {
            return const SizedBox();
          } else if (index + 1 <=
              (_emojiList.length ~/ 6 + 1) * 6 + _buttons.length) {
            return _toolItem(
                _buttons[index - (_emojiList.length ~/ 6 + 1) * 6]);
          } else {
            return const SizedBox();
          }
        },
      ),
    );
  }

  @override
  void onPermissionStateChange() {
    refresh();
  }
}
