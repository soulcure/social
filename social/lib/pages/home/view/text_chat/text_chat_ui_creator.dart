import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/app/modules/circle_detail/entity/circle_detail_message.dart';
import 'package:im/app/modules/common_share_page/views/components/goods_share_item.dart';
import 'package:im/app/modules/mute/controllers/mute_listener_controller.dart';
import 'package:im/app/routes/app_pages.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/external_share/external_share_item.dart';
import 'package:im/pages/guild_setting/circle/circle_share/circle_share_item.dart';
import 'package:im/pages/guild_setting/task/task_card.dart';
import 'package:im/pages/home/json/document_entity.dart';
import 'package:im/pages/home/json/file_entity.dart';
import 'package:im/pages/home/json/message_card_entity.dart';
import 'package:im/pages/home/json/redpack_entity.dart';
import 'package:im/pages/home/json/task_entity.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/json/unsupported_entity.dart';
import 'package:im/pages/home/json/vote_entity.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/events.dart';
import 'package:im/pages/home/model/guild_topic_model.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/pages/home/model/stick_message_controller.dart';
import 'package:im/pages/home/view/gallery/gallery.dart';
import 'package:im/pages/home/view/record_view/sound_play_manager.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/pages/home/view/text_chat/items/components/reply_item.dart';
import 'package:im/pages/home/view/text_chat/items/old_rich_text_item.dart';
import 'package:im/pages/home/view/text_chat/items/recalled_item.dart';
import 'package:im/pages/home/view/text_chat/items/redpack_item.dart';
import 'package:im/pages/home/view/text_chat/items/rich_text_item.dart';
import 'package:im/pages/home/view/text_chat/items/topic_share_item.dart';
import 'package:im/pages/home/view/text_chat/items/video_item.dart'
    if (dart.library.js) 'package:im/pages/home/view/text_chat/items/video_item_web.dart';
import 'package:im/pages/home/view/text_chat/show_message_tooltip.dart';
import 'package:im/pages/home/view/text_chat/web_message_hover_wrapper.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/pages/main/select_text_dialog.dart';
import 'package:im/web/pages/member_list/user_info_profile.dart';
import 'package:im/web/pages/member_list/userinfo_context_menu.dart';
import 'package:im/web/widgets/context_menu_detector.dart';
import 'package:im/widgets/audio_player_manager.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/button/more_icon.dart';
import 'package:im/widgets/dialog/show_web_image_dialog.dart';
import 'package:im/widgets/loading_text.dart';
import 'package:im/widgets/mouse_hover_builder.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/share_link_popup/share_link_popup.dart';
import 'package:im/widgets/super_tooltip.dart';
import 'package:im/widgets/user_info/popup/user_info_popup.dart';
import 'package:im/widgets/user_info/realtime_nick_name.dart';
import 'package:im/widgets/user_role_card/role_badge.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:provider/provider.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../../../../global.dart';
import '../../../../icon_font.dart';
import '../../../../loggers.dart';
import '../../../../svg_icons.dart';
import 'items/call_item.dart';
import 'items/components/inline_keyboard.dart';
import 'items/components/message_reaction.dart';
import 'items/document_item.dart';
import 'items/file_item.dart';
import 'items/image_item.dart';
import 'items/message_card_item.dart';
import 'items/sticker_item.dart';
import 'items/text_item.dart';
import 'items/voice_item.dart';
import 'items/vote_item.dart';
import 'items/welcome_item.dart';

class TextChatUICreator {
  static Widget newMessageDivider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9),
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: <Widget>[
          const Expanded(child: Divider(color: Color(0x78ED4245))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Text(
              "新消息".tr,
              style: const TextStyle(color: Color(0xFFED4245), fontSize: 12),
            ),
          ),
          const Expanded(child: Divider(color: Color(0x78ED4245))),
        ],
      ),
    );
  }

  static Widget loadingMessageDivider() {
    final color = Theme.of(Global.navigatorKey.currentContext).primaryColor;

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(child: Divider(indent: 12, endIndent: 12, color: color)),
          LoadingText(
            text: '加载中'.tr,
            style: TextStyle(color: color, fontSize: 12),
          ),
          Expanded(child: Divider(indent: 12, endIndent: 12, color: color)),
        ],
      ),
    );
  }

  static Widget buildUserInfoRow(BuildContext context, MessageEntity message,
      {String guildId}) {
    return GestureDetector(
//      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
        showUserInfoPopUp(
          context,
          userId: message.userId,
          guildId: guildId,
          channelId: message.channelId,
          showRemoveFromGuild:
              GlobalState.selectedChannel.value?.type != ChatChannelType.dm,
          enterType:
              GlobalState.selectedChannel.value?.type == ChatChannelType.dm
                  ? EnterType.fromDefault
                  : EnterType.fromServer,
        );
      },
      onLongPress: () async {
        final String channelId = message.channelId;
        final String guildId = message.guildId;
        final user = await UserInfo.get(message.userId);
        final name = user.showNameRule(channelId, guildId: guildId);
        context.read<InputModel>()
          ..add(message.userId, name, atRole: false, addDirectly: true)
          ..textFieldFocusNode.requestFocus();
      },
      child: UserInfo.consume(
        message.userId,
        child: Text(
          formatDate2Str(message.messageTime()),
          style: const TextStyle(
              color: Color(0xFF8F959E), fontSize: 12, height: 1),
        ),
        builder: (c, userInfo, child) {
          return Row(
            children: <Widget>[
              RealtimeAvatar(
                userId: userInfo.userId,
                size: 32,
              ),
              sizeWidth12,
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        if (userInfo.isBot) botMark,
                        RoleBadge(userInfo.userId, guildId ?? message.guildId,
                            message.channelId),
                        Flexible(
                            child: RealtimeNickname(
                          userId: userInfo.userId,
                          showGuildRoleColor: true,
                          style: const TextStyle(
                              color: Color(0xFF646a73),
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                          showNameRule: ShowNameRule.remarkAndGuild,
                        )),
                        sizeWidth8,
                      ],
                    ),
                    const SizedBox(height: 4),
                    child,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget buildUserInfoRow2(BuildContext context, String guildId,
      String guildName, MessageEntity message,
      {Widget content, bool disableOnTap = false}) {
    void onTap() {
      if (OrientationUtil.portrait) {
        FocusScope.of(context).unfocus();
        // 消息--选择一个聊天--点击用户头像--举报  会走这里
        // 从服务器 -- 频道 进来 -- 点击用户头像 -- 举报 也会走这里
        //所以这里需要判断要不要传 服务器ID 和 服务器名称
        showUserInfoPopUp(
          context,
          userId: message.userId,
          guildId: guildId,
          channelId: message.channelId,
          showRemoveFromGuild:
              GlobalState.selectedChannel.value?.type != ChatChannelType.dm,
          enterType:
              GlobalState.selectedChannel.value?.type == ChatChannelType.dm
                  ? EnterType.fromDefault
                  : EnterType.fromServer,
        );
      }
    }

    Future<void> onLongPress(BuildContext context) async {
      final String channelId = message.channelId;
      final user = await UserInfo.get(message.userId);
      final name = user.showNameRule(channelId);
      context.read<InputModel>()
        ..add(message.userId, name, atRole: false, addDirectly: true)
        ..textFieldFocusNode.requestFocus();
    }

    return UserInfo.consume(
      message.userId,
      child: Text(
        formatDate2Str(message.messageTime()),
        style:
            const TextStyle(fontSize: 13, height: 1, color: Color(0xFF8f959e)),
        strutStyle: const StrutStyle(forceStrutHeight: true),
      ),
      builder: (c, userInfo, child) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (OrientationUtil.portrait)
              GestureDetector(
                onTap: disableOnTap ? null : onTap,
                onLongPress: () => onLongPress(c),
                child: RealtimeAvatar(
                  userId: userInfo.userId,
                  size: 32,
                ),
              )
            else
              Builder(builder: (context) {
                return ContextMenuDetector(
                  onContextMenu: (e) =>
                      showUserInfoContextMenu(context, e, message.userId),
                  child: GestureDetector(
                      onTap: disableOnTap
                          ? null
                          : () {
                              if (GlobalState.selectedChannel.value?.guildId ==
                                  null) return;
                              showUserInfoProfile(
                                context,
                                userInfo.userId,
                                GlobalState.selectedChannel.value?.guildId,
                                offsetX: 8,
                                tooltipDirection: TooltipDirection.rightTop,
                              );
                            },
                      child: Avatar(
                        url: userInfo.avatar,
                        radius: 32 / 2,
                        widgetKey: ValueKey(userInfo.userId),
                      )),
                );
              }),
            sizeWidth12,
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      RoleBadge(
                          userInfo.userId, message.guildId, message.channelId),
                      Flexible(
                          child: GestureDetector(
                              onTap: disableOnTap ? null : onTap,
                              child: RealtimeNickname(
                                guildId: message.guildId,
                                userId: userInfo.userId,
                                // strutStyle: const StrutStyle(forceStrutHeight: true),
                                style: const TextStyle(
                                    color: Color(0xFF646a73),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    height: 1),
                                showGuildRoleColor: true,
                                strutStyle:
                                    const StrutStyle(forceStrutHeight: true),
                                showNameRule: ShowNameRule.remarkAndGuild,
                              ))),
                      if (userInfo.isBot == true) ...[
                        sizeWidth4,
                        botMark,
                      ],
                      const SizedBox(width: 6),
                      child,
                      sizeWidth12,
                    ],
                  ),
                  const SizedBox(height: 4),
                  content,
//                  if (message.isBlocked)
//                    Text(
//                      '消息已发出，但被对方拒收了'.tr,
//                      style: Theme.of(context)
//                          .textTheme
//                          .bodyText1
//                          .copyWith(fontSize: 14),
//                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// 创建仅包含内容的聊天 UI
  /// [context] 和 [messageList] 只有在需要预览图片、视频时需要传入
  static Widget createItemContent(
    MessageEntity message, {
    String quoteL1,
    int index,
    BuildContext context,
    UnFoldTextItemCallback onUnFold,
    IsUnFoldTextItemCallback isUnFold,
    Iterable<MessageEntity> messageList,
    String searchKey, //消息搜索的关键字key
    bool isPinMessage = false,
    RefererChannelSource refererChannelSource,
  }) {
    Widget _copyWrapper({@required Widget child}) {
      if (OrientationUtil.portrait) return child;
      return GestureDetector(
        onDoubleTap: () async {
          final content = message.content;
          String text;
          if (content is TextEntity)
            text = await content.toNotificationString(
                message.guildId, message.userId);
          if (content is StickerEntity) text = content.name;
          if (content is RichTextEntity)
            text = await content.toNotificationString(
                message.guildId, message.userId,
                entire: true);
          if (text != null)
            unawaited(showSelectTextDialog(context, content: text));
        },
        child: child,
      );
    }

    final content = message.content;
    switch (message.content.runtimeType) {
      case TextEntity:
        final textItem = TextItem(
          message,
          isUnFold,
          onUnFold,
          sendByMyself: message.userId == Global.user.id,
          quoteL1: quoteL1,
          searchKey: searchKey,
          refererChannelSource: refererChannelSource,
        );
        if (OrientationUtil.landscape)
          return _copyWrapper(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: textItem,
            ),
          );
        return textItem;
      case ImageEntity:
        Widget child = ImageItem(
          message,
          quoteL1: quoteL1,
          needRetry: true,
        );
        final data = message.content as ImageEntity;
        final identifier = data.asset?.identifier ?? data.localIdentify ?? '';
        bool inCache = false;
        if (identifier.isNotEmpty) {
          final byte = MultiImagePicker.fetchCacheThumbData(identifier) ?? [];
          inCache = byte.isNotEmpty;
        }

        child = GestureDetector(
            onTap: () {
              final bool res =
                  ((data.url != null && data.url.isNotEmpty) || inCache) &&
                      messageList != null;
              if (!res) return;

              if (OrientationUtil.portrait) {
                showGallery(ModalRoute.of(context).settings.name, message,
                    quoteL1: quoteL1, messages: messageList);
              } else
                showWebImageDialog(context,
                    url: data.url,
                    width: data.width * 1.0,
                    height: data.height * 1.0);
            },
            child: child);

        return child;
      case WelcomeEntity:
        return WelcomeItem(message);
      case CallEntity:
        return CallItem(message);
      case VoiceEntity:
        return VoiceItem(
          message,
          index: index,
          quoteL1: quoteL1,
          showReadStatus: !isPinMessage,
        );
      case VideoEntity:
        final data = message.content as VideoEntity;
        if (data.thumbHeight == null ||
            data.thumbWidth == null ||
            data.thumbUrl == null ||
            data.videoName == null) {
          logger.warning("不支持类型video：$message");
          return unSupportWidget(context);
        } else {
          final item = VideoItem(
            message,
            quoteL1: quoteL1,
          );
          return GestureDetector(
            onTap: () {
              final url = (message.content as VideoEntity)?.url ?? "";
              if (url.isEmpty) return;
              if (AudioPlayerManager.instance.isPlaying) {
                AudioPlayerManager.instance.stop();
              }
              SoundPlayManager().stop();
              showGallery(ModalRoute.of(context).settings.name, message,
                  quoteL1: quoteL1, messages: messageList);
            },
            child: item,
          );
        }
        break;
      case TopicShareEntity:
        return TopicShareItem(
          message: message,
          quoteL1: quoteL1,
        );
        break;
      case StickerEntity:
        return _copyWrapper(
          child: StickerItem(
            entity: content,
          ),
        );
        break;
      case CircleShareEntity:
        return CircleShareItem(
          entity: content,
          message: message,
        );
        break;
      case ExternalShareEntity:
        return ExternalShareItem(
          entity: content,
          message: message,
        );
        break;
      case RichTextEntity:
        return _copyWrapper(
          child: (message.content as RichTextEntity).v == 2
              ? RichTextItem(
                  message: message,
                  messageList: messageList,
                  isUnFold: isUnFold,
                  onUnFold: onUnFold,
                  searchKey: searchKey,
                )
              : OldRichTextItem(
                  message: message,
                  messageList: messageList,
                  isUnFold: isUnFold,
                  onUnFold: onUnFold,
                ),
        );
        break;
      case TaskEntity:
        return TaskCard(
          entity: content,
          message: message,
        );
        break;
      case VoteEntity:
        return VoteItem(
          entity: content,
          message: message,
        );
        break;
      case FileEntity:
        return FileItem(
          entity: content,
          message: message,
        );
        break;
      case GoodsShareEntity:
        return GoodsShareItem(
          entity: content,
          message: message,
        );
        break;
      case RedPackEntity:
        return RedPackItem(
          entity: content,
          message: message,
        );
        break;
      case MessageCardEntity:
        return MessageCardItem(message);
      case DocumentEntity:
        return DocumentItem(
          entity: content,
          message: message,
        );
        break;

      case UnSupportedEntity:
        return unSupportWidget(context,
            isCircleMessage: message.isCircleMessage);
        break;
      default:
        logger.warning("不支持类型：$message");
        return unSupportWidget(context);
    }
  }

  static Widget unSupportWidget(BuildContext context,
      {bool isCircleMessage = false}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
              color: const Color(0xff8F959E).withOpacity(0.3), width: 0.5),
          borderRadius: const BorderRadius.all(Radius.circular(8))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
            child: Text(
              '当前版本暂不支持查看此%s类型'.trArgs([if (isCircleMessage) '回复' else '消息']),
              style: const TextStyle(fontSize: 15, color: Color(0xff8F959E)),
            ),
          ),
          Container(
            color: const Color(0xff8F959E).withOpacity(0.2),
            height: 0.5,
            constraints: const BoxConstraints(maxWidth: 225),
          ),
          Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    IconFont.buffChatError,
                    color: Theme.of(context).primaryColor,
                    size: 12,
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  Text(
                    kIsWeb ? '请下载最新版手机客户端查看'.tr : '更新到最新版客户端查看'.tr,
                    style:
                        const TextStyle(color: Color(0xff8F959E), fontSize: 12),
                  )
                ],
              ))
        ],
      ),
    );
  }

  // static bool _hasPermission(String guildId, String channelId) {
  //   bool hasPermission = true;
  //   if (guildId != null && channelId != null) {
  //     final gp = PermissionModel.getPermission(guildId);
  //     if (gp != null) {
  //       hasPermission = PermissionUtils.isChannelVisible(gp, channelId);
  //     }
  //   }
  //   return hasPermission;
  // }

  // TODO 去掉 index
  static Widget createItem(
    BuildContext context,
    int index,
    Iterable<MessageEntity> list, {
    String guidId = '',
    bool shouldShowUserInfo,
    EdgeInsets padding,
    bool createQuote = true,
    String quoteL1,
    VoidCallback onTap,
    VoidCallback onOpenMenu,
    VoidCallback onCloseMenu,
    UnFoldTextItemCallback onUnFold,
    IsUnFoldTextItemCallback isUnFold,
    bool isFromTopicPage = false,
    bool isFromShareTopic = false,
    RefererChannelSource refererChannelSource,
    VoidCallback showTipErrorCallback,
  }) {
    final current = list.elementAt(index);
    bool isStickMessage = false;
    StickMessageController stickMessageController;
    if (current is! CommentMessageEntity) {
      stickMessageController =
          StickMessageController.to(channelId: current.channelId);
      isStickMessage =
          stickMessageController.stickMessageBean?.message?.messageId ==
              current.messageId;
    }

    bool showPinOrStickBgColor = (current.isPinned || isStickMessage) &&
        !isFromShareTopic &&
        !current.isRecalled;

    if (!showPinOrStickBgColor) showPinOrStickBgColor = current.isBacked;

    if (current.content == null) {
      logger.warning("不支持类型:createItem");
      return unSupportWidget(context);
    }
    final isCircleShare = current.content is CircleShareEntity;

    Widget item;
    if (current.isRecalled) {
      item = Padding(
          padding: const EdgeInsets.only(right: 56 - 24.0),
          child: RecalledItem(current));

      // ignore: invariant_booleans
    } else if (current.deleted == 1) {
      item = Text(
        "此消息已被删除".tr,
        style: const TextStyle(color: Color(0xFF8F959E)),
      );
    }
    // else if (isFromShareTopic &&
    //     !_hasPermission(current.guildId, current.channelId)) {
    //   item = Text(
    //     "该消息无权限查看".tr,
    //     style: TextStyle(color: Color(0xFF8F959E)),
    //   );
    // }
    else {
      item = TextChatUICreator.createItemContent(current,
          quoteL1: quoteL1,
          index: index,
          context: context,
          messageList: list,
          onUnFold: onUnFold,
          isUnFold: isUnFold,
          refererChannelSource: refererChannelSource);
    }

    if (isCircleShare && isFromShareTopic) {
      item = CircleShareItem(entity: current.content, message: current);
    }
    if (isParentTopic(current.messageId) &&
        !isFromTopicPage &&
        !isFromShareTopic &&
        !current.isRecalled &&
        !current.isCircleMessage) {
      item = buildParentTopic(item, context, current);
    }

    Widget content = Builder(builder: (_) {
      final bool showPingMark = current.isPinned &&
          !(current.isRecalled ||
              current.deleted == 1 ||
              current.isIllegal ||
              isFromShareTopic);

      final bool showStickMark = isStickMessage &&
          !(current.isRecalled ||
              current.deleted == 1 ||
              current.isIllegal ||
              isFromShareTopic);

      Widget contentWidget = item;
      if (current.deleted == 0 && !current.isRecalled) {
        if (createQuote && current.quoteL1.hasValue)
          contentWidget = ReplyItem(
            current,
            // 必须传入 key
            key: Key(current.quoteL2 ?? current.quoteL1),
            child: item,
          );
        if (current.replyMarkup?.inlineKeyboard != null) {
          contentWidget = _createInlineKeyboardWrapper(
            context,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 310),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  contentWidget,
                  const SizedBox(height: 16),
                  InlineKeyboard(current),
                ],
              ),
            ),
          );
        }
      }

      if (!isFromTopicPage &&
          OrientationUtil.landscape &&
          (!isFromShareTopic &&
              current.deleted == 0 &&
              !current.isRecalled &&
              current.content.messageState?.value != MessageState.waiting))
        contentWidget = WebMessageHoverWrapper(
            message: current,
            relay: () => replyMessage(context, current),
            isFromTopicPage: isFromTopicPage,
            child: contentWidget);

      final isTopicShare = current.content is TopicShareEntity ||
          contentWidget is TopicShareItem ||
          isFromShareTopic;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: current.isRecalled
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        mainAxisSize: isTopicShare ? MainAxisSize.min : MainAxisSize.max,
        children: <Widget>[
          /// 撤回的消息在话题详情页没有左边距，为了对齐，加上边距
          if (current.isRecalled) const SizedBox(width: 30),

          Flexible(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  contentWidget,
                  if (current.content is WelcomeEntity)
                    Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: MessageReaction(
                        current.reactionModel,
                        currentMessageEntity: current,
                        shouldShowUserInfo: shouldShowUserInfo,
                        quoteL1: quoteL1,
                      ),
                    )
                  else if (!current.isRecalled)
                    MessageReaction(
                      current.reactionModel,
                      currentMessageEntity: current,
                      shouldShowUserInfo: shouldShowUserInfo,
                      quoteL1: quoteL1,
                    ),
                  if (current.isBlocked)
                    Text(
                      '消息已发出，但被对方拒收了'.tr,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(fontSize: 14),
                    ),
                  if (showPingMark) ...[sizeHeight8, _buildPinnedMark(current)],
                  if (showStickMark) ...[
                    sizeHeight8,
                    _buildStickMark(current,
                        stickMessageController.stickMessageBean?.stickUserId)
                  ],
                ]),
          ),
          SizedBox(
            width: 24,
            child: current.content.messageState != null
                ? ObxValue(
                    (state) {
                      switch (state.value) {
                        case MessageState.waiting:
                          return UnconstrainedBox(
                            child: SizedBox.fromSize(
                              size: const Size.square(13),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).primaryColor),
                                strokeWidth: 1.5,
                              ),
                            ),
                          );
                        case MessageState.none:
                        case MessageState.sent:
                          return const SizedBox();
                        case MessageState.timeout:
                          return _buildMessageIndicator(context, current);
                        case MessageState.shield:
                          if (Global.user.id == current.userId)
                            return _buildMessageIndicator(context, current);
                          break;
                      }
                      return const SizedBox();
                    },
                    current.content.messageState,
                  )
                : const SizedBox(),
          ),
        ],
      );
    });

//    if (current.content is WelcomeEntity) {
//      return content;
//    }

    // 以下情况需要显示用户头像和名字等信息
    // 1. 是聊天的第一条
    // 2. 和上一条不是同一个用户说的话
    // 3. 和上一条被时间戳分隔
    if (shouldShowUserInfo) {
      /// UserInfo
      content = Padding(
          padding: const EdgeInsets.only(left: 12),
          child: TextChatUICreator.buildUserInfoRow2(
              context, guidId, 'guidName', current,
              content: content));
    }

    return MouseHoverBuilder(builder: (context, selected) {
      final isSelected = selected && !isFromTopicPage;
      return FadeBackgroundButton(
          padding: padding,
          alignment: null,
          backgroundColor: isSelected
              ? Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5)
              : (showPinOrStickBgColor
                  ? CustomColor.pinBackgroundColor
                  : Theme.of(context).scaffoldBackgroundColor.withOpacity(0)),
          tapDownBackgroundColor: showPinOrStickBgColor
              ? CustomColor.pinBackgroundColor
              : Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
          onTap: onTap,
          onLongPress: OrientationUtil.landscape
              ? () {}
              : () {
                  if (isFromShareTopic) return;
                  if (current.deleted == 1) return;
                  if (current.isRecalled || current.isTemporary) return;
                  if (current.content.messageState.value ==
                      MessageState.waiting) {
                    return;
                  }
                  // 欢迎频道没表态权限
                  if (current.content is WelcomeEntity &&
                      GlobalState.selectedChannel.value?.type ==
                          ChatChannelType.guildText &&
                      !PermissionUtils.oneOf(
                          Db.guildPermissionBox.get(current.guildId),
                          [Permission.ADD_REACTIONS],
                          channelId: current.channelId)) return;

                  if (onOpenMenu != null) onOpenMenu();
                  showMessageTooltip(context,
                      onlyEmoji: current.content is WelcomeEntity,
                      message: current,
                      reply: () => replyMessage(context, current),
                      showTipErrorCallback: showTipErrorCallback,
                      onClose: onCloseMenu);
                },
          child: content);
    });
  }

  static final Container botMark = makeTag("机器人".tr,
      appThemeData.primaryColor.withOpacity(0.1), appThemeData.primaryColor,
      fontWeight: FontWeight.w500);
  static final Container circleMark = makeTag("圈子".tr,
      const Color(0xff11CD75).withOpacity(0.15), const Color(0xff11CD75),
      fontWeight: FontWeight.w500);

  static Widget makeTag(String label, Color color, Color textColor,
      {double height = 16, double fontSize = 10, FontWeight fontWeight}) {
    return Container(
      /// todo alignment 和 padding 的修改，问题出现在 Web 端「机器人标签」，随着 Flutter 更新可以尝试去掉适配
      // ignore: avoid_redundant_argument_values
      alignment: kIsWeb ? null : Alignment.center,
      padding: kIsWeb
          ? const EdgeInsets.fromLTRB(2, 2, 2, 2)
          : const EdgeInsets.symmetric(horizontal: 4),
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: color,
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: fontSize,
              color: textColor,
              fontWeight: fontWeight,
              // 1.3 能让「机器人」三个字居中
              height: 1.3)),
    );
  }

  static Widget createStartItem(BuildContext context, ChatChannel channel) {
    if (channel.type == ChatChannelType.dm) {
      final anotherId = channel.recipientId ?? channel.guildId;

      Widget buildColorBlock(double width, Color color) {
        return Container(
          width: width,
          height: 4,
          decoration:
              ShapeDecoration(shape: const StadiumBorder(), color: color),
        );
      }

      return Column(
        children: <Widget>[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Wrap(
                direction: Axis.vertical,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 10,
                children: <Widget>[
                  buildColorBlock(12, const Color(0xFF47CC94)),
                  buildColorBlock(20, const Color(0xFFF2AA19)),
                  buildColorBlock(12, const Color(0xFF6179F2)),
                ],
              ),
              AvatarWidget(
                guildId: channel.guildId,
                channelId: channel.id,
                anotherId: anotherId,
              ),
              Wrap(
                direction: Axis.vertical,
                spacing: 10,
                children: <Widget>[
                  buildColorBlock(12, const Color(0xFF6179F2)),
                  buildColorBlock(20, const Color(0xFFF24848)),
                  buildColorBlock(12, const Color(0xFF47CC94)),
                ],
              )
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child:
                UserInfo.consume(anotherId, builder: (context, user, widget) {
              return Text(
                  "你和%s的对话从这里开始"
                      .trArgs([user?.showName(hideGuildNickname: true) ?? ""]),
                  style: TextStyle(color: Theme.of(context).disabledColor));
            }),
          ),
        ],
      );
    }

    final selectedTarget =
        ChatTargetsModel.instance.getChatTarget(channel.guildId);
    final bool isGuildOwner = selectedTarget is GuildTarget &&
        selectedTarget.ownerId == Global.user.id;

    final gp = PermissionModel.getPermission(channel.guildId);
    final bool isPrivate = PermissionUtils.isPrivateChannel(gp, channel.id);
    final isGroup = channel.type == ChatChannelType.group_dm;
    final name = isGroup ? '群聊'.tr : '频道'.tr;
    final isShowInviteItem =
        channel.type == ChatChannelType.guildText && isGuildOwner;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          height: 68,
          width: 68,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: appThemeData.scaffoldBackgroundColor,
          ),
          margin: const EdgeInsets.only(left: 12, bottom: 24),
          child: Icon(
            isGroup
                ? IconFont.buffWenzipindaotubiao
                : (isPrivate
                    ? IconFont.buffSimiwenzipindao
                    : IconFont.buffWenzipindaotubiao),
            color: const Color(0xFF1F2126),
            size: 36,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 12, bottom: 4),
          child: Text(
            '欢迎来到 #%s。'.trArgs([channel.name]),
            maxLines: 2,
            style: Theme.of(context).textTheme.headline4,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text("这是该%s的开始。".trArgs([name]),
              style: TextStyle(color: Theme.of(context).disabledColor)),
        ),
        if (isPrivate)
          channelManagerItem(context, channel)
        else if (isShowInviteItem)
          channelInviteItem(context, channel),
      ],
    );
  }

  /// 邀请好友卡片入口
  static Widget channelInviteItem(BuildContext context, ChatChannel channel) {
    return Padding(
        padding: const EdgeInsets.all(12),
        child: FadeButton(
          throttleDuration: const Duration(seconds: 1),
          onTap: () => showShareLinkPopUp(context, channel: channel),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(btnBorderRadius),
              color: Theme.of(context).scaffoldBackgroundColor),
          child: ListTile(
            title:
                Text('邀请好友'.tr, style: Theme.of(context).textTheme.headline5),
            subtitle: Text(
              '邀请客户/玩家/好友加入，立即互动'.tr,
              style: TextStyle(
                  fontWeight: FontWeight.w300,
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyText1.color),
            ),
            leading: WebsafeSvg.asset(
              SvgIcons.svgTextChatViewWelcome,
              width: 40,
              color: Theme.of(context).primaryColor,
            ),
            trailing: const MoreIcon(),
          ),
        ));
  }

  /// 管理频道访问入口
  static ValidPermission channelManagerItem(
      BuildContext context, ChatChannel channel) {
    return ValidPermission(
      permissions: [Permission.MANAGE_ROLES],
      builder: (value, isOwner) {
        if (!value) return const SizedBox();
        return GestureDetector(
          onTap: () => Get.toNamed(Routes.PRIVATE_CHANNEL_ACCESS_PAGE,
              arguments: channel),
          child: Container(
            margin:
                const EdgeInsets.only(left: 12, top: 24, right: 12, bottom: 12),
            padding: const EdgeInsets.only(left: 16, right: 16),
            height: 71,
            decoration: BoxDecoration(
              color: const Color(0xFF8D93A6).withOpacity(0.1),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        const Icon(IconFont.buffRoleIconChannelSetting),
                        sizeWidth6,
                        Text(
                          '管理频道访问'.tr,
                          style: const TextStyle(
                              color: Color(0xFF1F2126),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.17),
                        ),
                      ],
                    ),
                    sizeHeight6,
                    Text(
                      '添加或删除私密频道中的角色或用户。'.tr,
                      style: const TextStyle(
                          color: Color(0xFF5C6273), fontSize: 14),
                    ),
                  ],
                ),
                MoreIcon(color: const Color(0xFF5C6273).withOpacity(0.4))
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildMessageIndicator(
      BuildContext context, MessageEntity message) {
    final resendWidget = GestureDetector(
      onTap: () async {
        final res = await showConfirmDialog(
            title: '温馨提示'.tr,
            content: '确定重新发送此${message.isCircleMessage ? '回复' : '消息'}吗？'.tr);
        if (res == true) {
//          if (current.content.messageState.value == MessageState.shield) {
//            await TextChatApi.deleteMessage(
//                Global.user.id, current.channelId, current.messageId);
//          }
          if (message.isCircleMessage) {
            final cm = message as CommentMessageEntity;
            final c =
                CircleDetailController.to(postId: cm.postId, videoFirst: true);
            unawaited(c?.resend(cm));
          } else {
            ResendMessageNotification(message).dispatch(context);
          }
        }
      },
      child: const Icon(IconFont.buffOtherShareError,
          size: 20, color: Color(0xFFF24848)),
    );

    return ObxValue<Rx<MessageState>>(
      (state) {
        switch (state.value) {
          case MessageState.waiting:
            return SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
//                                backgroundColor: Theme.of(context).primaryColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor),
                strokeWidth: 1.5,
              ),
            );
          case MessageState.none:
          case MessageState.sent:
            return const SizedBox();
          case MessageState.timeout:
            return resendWidget;
          case MessageState.shield:
            if (Global.user.id == message.userId) return resendWidget;
            break;
        }
        return const SizedBox();
      },
      message.content.messageState,
    );
  }

  static Widget _buildPinnedMark(MessageEntity current) {
    return UserInfo.consume(current.pin, builder: (context, user, _) {
      final String nickname = user
          .showName(hideGuildNickname: GlobalState.isDmChannel)
          .takeCharacter(8);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            IconFont.buffChatPinFill,
            color: primaryColor,
            size: 12,
          ),
          sizeWidth2,
          Text(
              '%s Pin了这条消息，%s均可见'.trArgs([
                nickname,
                if (GlobalState.isDmChannel) "会话成员".tr else "频道成员".tr
              ]),
              style: TextStyle(color: primaryColor, fontSize: 12)),
        ],
      );
    });
  }

  static Widget _buildStickMark(MessageEntity current, String stickUserId) {
    return UserInfo.consume(stickUserId, builder: (context, user, _) {
      final String nickname = user
          .showName(hideGuildNickname: GlobalState.isDmChannel)
          .takeCharacter(8);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            IconFont.buffChatNotice,
            color: primaryColor,
            size: 12,
          ),
          sizeWidth2,
          Text('%s 置顶了这条消息'.trArgs([nickname]),
              style: TextStyle(color: primaryColor, fontSize: 12)),
        ],
      );
    });
  }

  static Widget _createInlineKeyboardWrapper(BuildContext context,
      {Widget child}) {
    return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDEE0E3)),
          color: Colors.white,
        ),
        child: child);
  }
}

class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    Key key,
    @required this.guildId,
    @required this.channelId,
    @required this.anotherId,
  }) : super(key: key);

  final String guildId;
  final String channelId;
  final String anotherId;

  bool get dmMe => anotherId == Global.user.id;

  @override
  Widget build(BuildContext context) {
    if (dmMe) {
      return oneTalk(context);
    } else {
      return twoTalk(context);
    }
  }

  Widget oneTalk(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: RealtimeAvatar(
        userId: Global.user.id,
        size: 80,
        tapToShowUserInfo: true,
        guildId: guildId,
        channelId: channelId,
        showNftFlag: false,
      ),
    );
  }

  Widget twoTalk(BuildContext context) {
    return SizedBox(
      width: 168,
      height: 80 + 16.0,
      child: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8),
            child: RealtimeAvatar(
              userId: Global.user.id,
              size: 80,
              tapToShowUserInfo: true,
              guildId: guildId,
              channelId: channelId,
              showNftFlag: false,
            ),
          ),
          Positioned(
            left: 72,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).backgroundColor),
              alignment: Alignment.center,
              child: RealtimeAvatar(
                userId: anotherId,
                size: 80,
                tapToShowUserInfo: true,
                guildId: guildId,
                channelId: channelId,
                showNftFlag: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void replyMessage(BuildContext context, MessageEntity message) {
  if (MuteListenerController.to.isMuted && !GlobalState.isDmChannel) {
    // 是否被禁言
    showToast('你已被禁言，无法操作'.tr);
    return;
  }

  String defaultText = "";
  if (!message.isDmMessage && message.userId != Global.user.id)
    defaultText = TextEntity.getAtString(message.userId, false);
  final isCircleMessage = message.isCircleMessage;
  final gt = ChatTargetsModel.instance.selectedChatTarget;
  bool isShowKeyBoard = true;
  if (!isCircleMessage && gt != null && (gt as GuildTarget).userPending) {
    isShowKeyBoard = false;
  }

  /// gt.userPending 是为了解决完成任务后,键盘弹出导致页面错乱问题
  /// 原有代码 requestFocus: true
  context
      .read<InputModel>()
      .setValue(defaultText, reply: message, requestFocus: isShowKeyBoard);
}
