import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/pages/home/model/reaction_model.dart';
import 'package:im/pages/home/view/text_chat/items/components/reaction_detail.dart';
import 'package:im/pages/home/view/text_chat/show_message_tooltip.dart';
import 'package:im/pages/home/view/text_chat/web_message_hover_wrapper.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/emo_util.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/widgets/super_tooltip.dart';
import 'package:just_throttle_it/just_throttle_it.dart';
import 'package:provider/provider.dart';

class ReactionEntity {
  String name;
  String avatar;
  int count;
  bool me;
  String id;

  ReactionEntity(this.name,
      {this.avatar, this.count = 1, this.me = false, this.id});

  factory ReactionEntity.fromMap(Map<String, dynamic> item) {
    String name = item['name'] as String;
    try {
      name = Uri.decodeComponent(name);
    } catch (e) {
      print(e);
    }

    final int count = item['count'] as int ?? 1;

    bool curMe = false;
    final valueMe = item['me'];
    if (valueMe is bool) {
      curMe = valueMe;
    } else if (valueMe is int) {
      curMe = valueMe == 1;
    }

    final String avatar = item['avatar'];

    return ReactionEntity(
      name,
      avatar: avatar,
      count: count,
      me: curMe,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'avatar': avatar,
        'count': count,
        'me': me,
      };
}

class MessageReaction extends StatefulWidget {
  final ReactionModel model;
  final bool shouldShowUserInfo;
  final String quoteL1;
  final MessageEntity currentMessageEntity;

  const MessageReaction(this.model,
      {this.shouldShowUserInfo = false,
      this.quoteL1,
      this.currentMessageEntity});

  @override
  _MessageReactionState createState() => _MessageReactionState();
}

//Size _textSize(String text, TextStyle style) {
//  final TextPainter textPainter = TextPainter(
//      text: TextSpan(text: text, style: style),
//      maxLines: 1,
//      textDirection: TextDirection.ltr)
//    ..layout();
//  return textPainter.size;
//}

class _MessageReactionState extends State<MessageReaction> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return ObxValue<Rx<ReactionModel>>((model) {
        if (model.value.reactions.isEmpty) return sizedBox;

        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...(model.value?.reactions ?? []).map((reaction) {
//                  final channel = Provider.of<TextChatModel>(context).channel;
//                  if (channel.type == ChatChannelType.dm) {
//                    return _dmReactionItem(context,
//                        model: model,
//                        reaction: reaction,
//                        constraints: constraints);
//                  }
                return _channelReactionItem(context,
                    model: model.value, reaction: reaction);
              }),
              if (widget?.currentMessageEntity != null &&
                  widget.currentMessageEntity.canAddReaction)
                _reactIcon(model.value.messageId),
            ],
          ),
        );
      }, widget.model.updater);
    });
  }

  Widget _reactIcon(String messageId) {
    final message = widget?.currentMessageEntity;
    final child = Builder(
      builder: (context) {
        return _reactionWrapper(
          onTap: () async {
            // switch (ModalRoute.of(context).settings.name) {
            //   case get_pages.Routes.TOPIC_PAGE:
            //     message = Get.find<TopicController>().getMessage(messageId);
            //     break;
            //   case get_pages.Routes.CIRCLE_DETAIL:
            //     message = CircleDetailController.to()
            //         .getCommentMessage(BigInt.parse(messageId));
            //     break;
            //   default: // 默认查询消息表
            //     if (widget.currentMessageEntity.isCircleMessage) {
            //       message = CircleDetailController.to(
            //               postId: (widget.currentMessageEntity
            //                       as CommentMessageEntity)
            //                   .postId)
            //           .getCommentMessage(BigInt.parse(messageId));
            //     } else {
            //       message = TextChannelController.to(
            //               channelId: widget.model.channelId)
            //           .internalList
            //           .get(BigInt.parse(messageId));
            //     }
            //     break;
            // }
            if (message == null) return;
            if (OrientationUtil.portrait)
              showMessageTooltip(context, onlyEmoji: true, message: message,
                  reply: () {
                String defaultText = "";
                if (!message.isDmMessage && message.userId != Global.user.id)
                  defaultText = TextEntity.getAtString(message.userId, false);
                Provider.of<InputModel>(context, listen: false)
                    .setValue(defaultText, reply: message, requestFocus: true);
              });
            else
              showWebEmojiDlg(context,
                  message: message, isFromTopicPage: widget.quoteL1 != null);
          },
          child: Icon(
            IconFont.buffChatEmoji,
            size: 18,
            color: appThemeData.textTheme.caption.color,
          ),
        );
      },
    );
    if (GlobalState.isDmChannel)
      return child;
    else if (message?.isCircleMessage ?? false)
      return ValidPermission(
        guildId: message.guildId,
        permissions: [Permission.CIRCLE_REPLY],
        channelId: message.channelId,
        builder: (val, _) {
          if (!val) return const SizedBox();
          return child;
        },
      );
    else
      return ValidPermission(
        permissions: [Permission.ADD_REACTIONS],
        channelId: GlobalState.selectedChannel.value?.id,
        builder: (val, _) {
          if (!val) return const SizedBox();
          return child;
        },
      );
  }

  Widget _reactionWrapper({
    Widget child,
    GestureTapCallback onTap,
    GestureTapCallback onLongTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(5, kIsWeb ? 4 : 0, 5, 0),
        decoration: BoxDecoration(
          color: appThemeData.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(3),
        ),
        height: 24,
        child: child,
      ),
    );
  }

  Widget _channelReactionItem(
    BuildContext context, {
    @required ReactionModel model,
    @required ReactionEntity reaction,
  }) {
    final containSelf = reaction.me ?? false;
    return GestureDetector(
      ///防止重复快速点击表态，添加200ms防抖
      onTap: () => Throttle.milliseconds(200, model.toggle, [reaction.name]),
      onLongPress: () => showReactionUser(context, reaction),
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            border: containSelf
                ? Border.all(color: primaryColor.withOpacity(0.15), width: 0.5)
                : null,
            color: containSelf
                ? primaryColor.withOpacity(0.15)
                : CustomColor(context).globalBackgroundColor3,
            borderRadius: BorderRadius.circular(3),
          ),
          height: 24,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              EmoUtil.instance.getEmoIcon(reaction.name, size: 16),
              if (reaction.count > 1) ...[
                const SizedBox(width: 5),
                Text(
                  reaction.count.toString(),
                  style: Theme.of(context).textTheme.bodyText1.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                        color: containSelf
                            ? primaryColor
                            : Get.textTheme.bodyText1.color,
                      ),
                )
              ]
            ],
          )),
    );
  }

//  Widget _dmReactionItem(BuildContext context,
//      {@required ReactionModel model,
//      @required ReactionEntity reaction,
//      @required BoxConstraints constraints}) {
//    // 单个用户名最大宽度
//    final double nameMaxWidth = constraints.maxWidth * 0.6;
//    int breakIdx = -1;
//    for (var i = 0; i < reaction.users.length; i++) {
//      final userId = reaction.users[i];
//      final user = Db.userInfoBox.get(userId);
//      final double userWidth = reaction.users.getRange(0, i + 1).map((v) {
//        final width = _textSize(user == null ? "" : '${user.nickname}, ',
//                const TextStyle(fontSize: 12))
//            .width;
//        return width >= nameMaxWidth ? nameMaxWidth : width;
//      }).reduce((a, b) => a + b);
//      final double suffixWidth = _textSize(
//              '...还有 ${reaction.users.length - i}人',
//              const TextStyle(fontSize: 12))
//          .width;
//      if (userWidth + suffixWidth >= constraints.maxWidth - 30 - 16) {
//        breakIdx = i;
//        break;
//      }
//    }
//    final List<Widget> nameList = [];
//    if (breakIdx == -1) {
//      reaction.users.forEach((v) {
//        final user = Db.userInfoBox.get(v);
//
//        nameList.add(
//          GestureDetector(
//              onTap: () {
//                FocusScope.of(context).unfocus();
//                showUserInfoPopUp(context, v, showRemoveFromGuild: true);
//              },
//              child: ConstrainedBox(
//                constraints: BoxConstraints(maxWidth: nameMaxWidth),
//                child: Text(
//                  user == null ? "" : user.nickname,
//                  overflow: TextOverflow.clip,
//                  maxLines: 1,
//                  style: Theme.of(context)
//                      .textTheme
//                      .bodyText2
//                      .copyWith(fontSize: 12),
//                ),
//              )),
//        );
//        nameList.add(
//          Text(
//            ', ',
//            style: Theme.of(context).textTheme.bodyText2.copyWith(fontSize: 12),
//          ),
//        );
//      });
//      nameList.removeAt(nameList.length - 1);
//    } else {
//      reaction.users.getRange(0, breakIdx).forEach((v) {
//        final user = Db.userInfoBox.get(v);
//
//        nameList.add(GestureDetector(
//          onTap: () => showUserInfoPopUp(context, v),
//          child: ConstrainedBox(
//            constraints: BoxConstraints(maxWidth: nameMaxWidth),
//            child: Text(
//              user.nickname,
//              overflow: TextOverflow.clip,
//              maxLines: 1,
//              style: const TextStyle(fontSize: 12),
//            ),
//          ),
//        ));
//        nameList.add(
//          const Text(
//            ', ',
//            style: TextStyle(fontSize: 12),
//          ),
//        );
//      });
//      nameList.add(GestureDetector(
//        onTap: () => showReactionUser(context, reaction),
//        child: Text(
//          '...还有 ${reaction.users.length - breakIdx}人',
//          style: const TextStyle(fontSize: 12),
//        ),
//      ));
//    }
//    return Container(
//        decoration: BoxDecoration(
//          color: CustomColor(context).globalBackgroundColor3,
//          borderRadius: BorderRadius.circular(12),
//        ),
//        height: 24,
//        child: Padding(
//          padding: const EdgeInsets.symmetric(vertical: 2),
//          child: Row(
//            mainAxisSize: MainAxisSize.min,
//            children: <Widget>[
//              GestureDetector(
//                onTap: () => model.toggle(reaction.emoji),
//                child: Container(
//                  padding: const EdgeInsets.only(left: 5),
//                  alignment: Alignment.center,
//                  width: 30,
//                  child: EmoUtil.instance
//                      .getEmoIcon(reaction.emoji.name, size: 18),
//                ),
//              ),
//              SizedBox(
//                  height: 12,
//                  width: 1,
//                  child: VerticalDivider(
//                    color: Theme.of(context).disabledColor.withOpacity(0.3),
//                  )),
//              Padding(
//                padding: const EdgeInsets.symmetric(horizontal: 8),
//                child: Row(
//                  children: nameList,
//                ),
//              )
//            ],
//          ),
//        ));
//  }

  void showReactionUser(BuildContext context, ReactionEntity reaction) {
    final RenderBox renderBox = context.findRenderObject();
    final offset = renderBox.localToGlobal(Offset.zero);

    if (OrientationUtil.landscape) {
      SuperTooltip(
        popupDirection: TooltipDirection.followMouse,
        globalPoint: offset,
        content: Material(
          ///fix : 话题详情页长按查看表态详情报错
          child: Container(
              width: 400,
              decoration: BoxDecoration(
                  color: CustomColor(context).backgroundColor6,
                  boxShadow: const [BoxShadow(blurRadius: 2)]),
              child: ReactionDetail(widget.model, reaction)),
        ),
      ).show(context);
    } else {
      FocusScope.of(context).unfocus();
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        showBottomModal(context,
            builder: (c, s) => ReactionDetail(widget.model, reaction,
                key: ValueKey(widget.model.messageId)),
            backgroundColor: Theme.of(context).backgroundColor);
      });
    }
  }
}
