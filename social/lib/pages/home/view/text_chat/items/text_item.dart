import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide ImageInfo;
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/api/invite_api.dart';
import 'package:im/api/user_api.dart';
import 'package:im/app/modules/manage_guild/models/ban_type.dart';
import 'package:im/app/routes/app_pages.dart' as app_pages;
import 'package:im/common/extension/string_extension.dart';
import 'package:im/db/db.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/guild/container_image.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/guild_topic_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/bottom_bar/text_chat_bottom_bar.dart';
import 'package:im/pages/home/view/text_chat/items/components/expand_button.dart';
import 'package:im/pages/home/view/text_chat/items/live_card.dart';
import 'package:im/pages/tool/url_handler/invite_link_handler.dart';
import 'package:im/pages/tool/url_handler/link_handler_preset.dart';
import 'package:im/pages/tool/url_handler/live_link_handler.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/certification_icon.dart';
import 'package:im/widgets/link_preview.dart';

import '../../../../../global.dart';
import 'components/parsed_text_extension.dart';

typedef IsUnFoldTextItemCallback = bool Function(String string);
typedef UnFoldTextItemCallback = void Function(String string);

class TextItem extends StatefulWidget {
  final MessageEntity message;
  final bool sendByMyself;
  final int maxLine;
  final IsUnFoldTextItemCallback isUnFold;
  final UnFoldTextItemCallback onUnFold;
  final String quoteL1;

  /// ????????????????????????key: ?????????-???????????????????????????
  final String searchKey;

  /// ???true????????????url?????????, ?????????????????????????????????????????????????????????
  final bool pureText;

  /// ??????????????????
  final RefererChannelSource refererChannelSource;

  TextItem(
    this.message,
    this.isUnFold,
    this.onUnFold, {
    this.sendByMyself,
    this.maxLine = 15,
    this.quoteL1,
    this.searchKey,
    this.refererChannelSource,
    this.pureText = false,
  }) : super(key: ValueKey("${message.messageId}-${message.seq}"));

  @override
  _TextItemState createState() => _TextItemState();
}

Map<String, Future> _inviteCardFuture = {};
Map<String, Map> _inviteCardData; //????????????????????????cache
Map<String, Future> _liveCardFuture;
Map<String, Widget> _liveCardWidget;

Map<int, Map> _foldInfo;

void clearChatCardsHttpCache() {
  _inviteCardFuture.clear();
  _inviteCardData?.clear();

  _liveCardFuture?.clear();
  _liveCardWidget?.clear();
}

Future parseInviteUrl(String url) async {
  final String code = parseQueryKey(url);
  if (code == null) return null;

  Future f;
  if (_inviteCardFuture.containsKey(url)) {
    f = _inviteCardFuture[url];
  } else {
    f = () async {
      try {
        final Map inviteInfo = await InviteApi.getCodeInfo(code,
            autoRetryIfNetworkUnavailable: true);
        if (inviteInfo == null || inviteInfo.keys.toList().isEmpty)
          return {'result': false};
        final guildInfo = await GuildApi.getGuildInfo(
            guildId: inviteInfo['guild_id'], userId: Global.user.id);
        if (guildInfo == null) return {'result': false};
        UserInfo inviterUserInfo;
        if (Global.user.id != inviteInfo['inviter_id']) {
          final List<UserInfo> list =
              await UserApi.getUserInfo([inviteInfo['inviter_id']]);
          inviterUserInfo = list.first;
        }
        return {
          'result': true,
          'inviteInfo': inviteInfo,
          'guildInfo': guildInfo,
          'inviterUserInfo': inviterUserInfo,
          'c': code,
        };
      } catch (e) {
        return {'result': false};
      }
    }();
    _inviteCardFuture[url] = f;
  }
  return f;
}

String parseQueryKey(String url) {
  if (url == null || url.isEmpty) return null;
  final index = url.lastIndexOf('/') + 1;
  final qIndex = url.lastIndexOf('?');
  String key;
  if (index > 0 && index <= url.length) {
    final lastIndex =
        qIndex > index && qIndex < url.length ? qIndex : url.length;
    key = url.substring(index, lastIndex);
  }
  return key;
}

class _TextItemState extends State<TextItem> {
  Future _inviteCard;
  Future _liveCard;

  final ValueNotifier _pushBtnEnable = ValueNotifier(true);

  @override
  void initState() {
    _inviteCardData ??= {};
    _liveCardFuture ??= {};
    _liveCardWidget ??= {};
    _foldInfo ??= {};
    _parseInviteUrlIfNeed();
    super.initState();
  }

  //??????????????????
  void _parseInviteUrlIfNeed() {
    final data = widget.message.content as TextEntity;
    if (data.inviteList != null)
      _inviteCard = parseInviteUrl(data.inviteList.first);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.message.content as TextEntity;
    final messageId = widget.message.messageId;
    final isAllEmo = data.contentType & ContentMask.allEmoji != 0;
    final style = Theme.of(context).textTheme.bodyText2.copyWith(
          height: OrientationUtil.landscape ? 1.5 : 1.25,
          fontSize: isAllEmo && widget.searchKey.noValue
              ? (OrientationUtil.portrait ? 48 : 36)
              : 17,
        );

    /// ??????????????????????????????????????????????????????,?????????????????????????????????????????????????????????,????????????????????????????????????
    /// ????????????????????????????????????_foldInfo????????????TextEntity???????????????,
    /// ???????????????????????????????????????_foldInfo??????TextEntity????????????????????????.
    /// ????????????????????????????????????????????????,??????????????????????????????????????????????????????????????????
    final cachedIsFold = _foldInfo.containsKey(data.hashCode)
        ? _foldInfo[data.hashCode]["isFold"]
        : false;
    final isFold = !(widget.isUnFold?.call(messageId) ?? false) && cachedIsFold;

    final wrapMessage = _foldInfo.containsKey(data.hashCode)
        ? _foldInfo[data.hashCode]['wrapMessage']
        : false;

    final textWidget = _buildText(style,
        isParsedText: data.contentType != 0 || widget.searchKey.hasValue,
        cachedIsFold: isFold,
        cachedWrapMessage: wrapMessage,
        refererChannelSource: widget.refererChannelSource, onItemChanged: () {
      Future.delayed(const Duration(milliseconds: 10), () {
        if (mounted) setState(() {});
      });
    });
    // ???????????????????????????????????????????????????????????????????????????
    if (data.contentType == 0 ||
        (data.numUrls > 0 && (data.urlList?.first?.isMessageLink ?? false))) {
      // ??????????????????
      return _buildTextItem(isFold, wrapMessage, wrapMessage, textWidget);
    } else if (isAllEmo) {
      // ????????????EMOJI
      return _buildTextItem(isFold, false, wrapMessage, textWidget);
    } else if (data.urlList == null && data.inviteList == null) {
      // ????????????URL????????????????????????emoji+??????
      return _buildTextItem(isFold, wrapMessage, wrapMessage, textWidget);
    } else if (data.numUrls > 0 && !widget.pureText) {
      // ????????????????????????
      return _buildCard(data,
          child: _buildTextItem(
              isFold, data.numUrls > 1, wrapMessage, textWidget));
    } else {
      // ??????????????????????????????????????????
      return _buildTextItem(isFold, wrapMessage, wrapMessage, textWidget);
    }
  }

  Widget _buildTextItem(bool needFold, bool needWrapFoldWidget,
      bool needWrapOriginMessage, Widget child) {
    if (needFold) return _buildFoldWidget(child, needWrapFoldWidget, context);
    final item = widget.pureText
        ? AbsorbPointer(
            child: child,
          )
        : child;
    return needWrapOriginMessage ? _wrapInCard(item) : item;
  }

  Widget _buildFoldWidget(Widget child, bool isWrap, BuildContext context) {
    child = Stack(
      alignment: Alignment.bottomLeft,
      children: [
        AbsorbPointer(absorbing: widget.pureText, child: child),
        ExpandButton(
          bgColor: Get.theme.scaffoldBackgroundColor,
          onTap: () {
            widget.onUnFold?.call(widget.message.messageId);
            setState(() {});
          },
        ),
      ],
    );
    return isWrap ? _wrapInCard(child) : child;
  }

  Widget _buildText(TextStyle style,
      // ignore: unused_element
      {bool outsideContainPadding,
      bool isParsedText,
      bool cachedIsFold,
      bool cachedWrapMessage,
      Function onItemChanged,
      RefererChannelSource refererChannelSource}) {
    final data = widget.message.content as TextEntity;
    // ???????????????????????????
    // ???????????????????????????????????????????????????????????????????????????
    final outsideContainPadding = widget.message.quoteL1 != null ||
        widget.message.quoteL2 != null ||
        isParentTopic(widget.message.messageId) ||
        ((data.numUrls == 1 && !widget.pureText) &&
            !(data.urlList?.first?.isMessageLink ?? false));

    return LayoutBuilder(builder: (context, size) {
      // ????????????????????????
      final textPainter = calculateTextHeight(
          context, data.text, style, size.maxWidth, widget.maxLine);
      final isLongText = textPainter.didExceedMaxLines;
      // ???????????????????????????????????????????????????????????????????????????
      final isFold =
          !(widget.isUnFold?.call(widget.message.messageId) ?? false) &&
              isLongText;
      // ?????????????????????item??????????????????????????????????????? ??????????????????????????????3???
      final isShareTopicChild = widget.message.shareParentId != null &&
          Get.currentRoute != app_pages.Routes.TOPIC_PAGE;
      final maxLines = isFold
          ? (isShareTopicChild ? 3 : widget.maxLine)
          : (isShareTopicChild ? 3 : 1000);
      // ????????????????????????????????????????????????????????? ??????????????????????????????
      final wrapMessage = isLongText && !outsideContainPadding;

      Widget textWidget;
      if (isParsedText) {
        /// ?????????????????????????????????????????????????????? TextPainter ????????????????????????????????????TextItem ??????????????????????????????????????????????????????
        /// ?????? Text ??????????????????????????????????????????????????????????????????????????? TextItem ??????????????????????????? layout???
        /// ?????????????????????????????????????????? Canvas + Painter ????????????????????????????????? Text ????????????????????????????????????????????? RichText ??? IM ???????????????????????????????????????????????? TextPainter ??????????????????

        textWidget = ParsedText(
          style: style.copyWith(
              height: isShareTopicChild && OrientationUtil.landscape
                  ? 1
                  : style.height),
          textScaleFactor: MediaQuery.of(context).textScaleFactor,
          maxLines: maxLines,
          overflow:
              isShareTopicChild ? TextOverflow.ellipsis : TextOverflow.fade,

          /// TODO(????????????)?????????????????????????????????????????????????????? emoji ????????? Text??????????????????????????????
          text: widget.pureText
              ? '${data.text}$nullChar\u{0000}'
              : '$nullChar${data.text}$nullChar\u{0000}',
          regexOptions: const RegexOptions(caseSensitive: false),
          parse: [
            if (data.contentType & ContentMask.cusEmo != 0 ||
                data.contentType & ContentMask.allEmoji != 0)
              ParsedTextExtension.matchCusEmoText(context, style.fontSize),
            if (data.contentType & ContentMask.urlLink != 0)
              ParsedTextExtension.matchURLText(context),
            if (data.contentType & ContentMask.channelLink != 0)
              ParsedTextExtension.matchChannelLink(context,
                  refererChannelSource: refererChannelSource),
            if (data.contentType & ContentMask.at != 0)
              ParsedTextExtension.matchAtText(context, textStyle: style),
            if (data.contentType & ContentMask.command != 0 && !widget.pureText)
              ParsedTextExtension.matchCommandText(
                context,
                (command) => _tapCommand(command, data.isCommandClickable()),
              ),
            if (widget.searchKey.hasValue && !widget.pureText)
              ParsedTextExtension.matchSearchKey(context, widget.searchKey,
                  style.copyWith(color: Get.theme.primaryColor)),
          ],
        );
      } else {
        textWidget = Text(data.text,
            maxLines: maxLines,
            overflow:
                isShareTopicChild ? TextOverflow.ellipsis : TextOverflow.fade,
            style: style);
      }

      if (_foldInfo[data.hashCode] == null ||
          cachedIsFold != isFold ||
          cachedWrapMessage != wrapMessage) {
        _foldInfo[data.hashCode] = {
          'isFold': isFold,
          'wrapMessage': wrapMessage
        };
        onItemChanged();
      }
      return ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: textPainter.preferredLineHeight * maxLines),
        child: textWidget,
      );
    });
  }

  void _tapCommand(String command, bool clickable) {
    if (!clickable) return;

    final content = widget.message.content as TextEntity;
    final atString = TextEntity.getAtString(widget.message.userId, false);
    final m = TextChannelController.to(channelId: widget.message.channelId);
    final sender = Db.userInfoBox.get(widget.message.userId);
    bool senderIsBot = false;
    if (sender != null && sender.isBot) senderIsBot = true;

    if (!senderIsBot &&
        content.contentType & ContentMask.command != 0 &&
        content.contentType & ContentMask.at != 0) {
      m.sendContent(
        TextEntity.fromString(
          content.text,
          isClickable: true,
          isHide: content.isHideCommand(),
        ),
      );
    } else {
      if (widget.message.isDmMessage)
        m.sendContent(TextEntity.fromString(command, isClickable: true));
      else
        m.sendContent(
          TextEntity.fromString(
            "$atString$command",
            isClickable: true,
            isHide: content.isHideCommand(),
          ),
        );
    }
    const ScrollToBottomNotification().dispatch(context);
  }

  LiveLinkInfo _parseLiveUrl(String url) {
    final linkInfo = LiveLinkHandler().parseParams(url);
    if (linkInfo == null) return null;

    Future f;
    if (_liveCardFuture.containsKey(url)) {
      f = _liveCardFuture[url];
    } else {
      f = JiGouLiveAPI.getRoomSimpleInfo(linkInfo.roomId);
      _liveCardFuture[url] = f;
    }
    _liveCard = f;
    return linkInfo;
  }

  Widget _buildInviteCard(Future future, {Widget child}) {
    final TextStyle ts12 =
        Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 14);
    final data = widget.message.content as TextEntity;

    final showUrl = !data.isPureLink;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: _wrapInCard(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Visibility(visible: showUrl, child: child),
            FutureBuilder(
              future: future,
              initialData: _inviteCardData[widget.message.messageId],
              builder: (context, snapshot) {
                if (snapshot.hasData)
                  _inviteCardData[widget.message.messageId] = snapshot.data;

                if (snapshot.hasData && snapshot.data['result'] == true) {
                  final inviteInfo = snapshot.data['inviteInfo'];
                  final guildInfo = snapshot.data['guildInfo'];
                  final inviterUserInfo = snapshot.data['inviterUserInfo'];
                  final inviteUserId = inviterUserInfo?.userId;
                  final showName = Db.remarkBox.get(inviteUserId ?? '')?.name ??
                      inviterUserInfo?.nickname ??
                      '';
                  final bool isSelf =
                      Global.user.id == inviteInfo['inviter_id'];
                  final String channelId = inviteInfo['channel_id'];
                  final int memberNum = guildInfo['memberNum'];
                  final String guildIcon = guildInfo['icon'];
                  final String guildName = guildInfo['name'];
                  final String authenticate =
                      guildInfo['authenticate']?.toString();
                  final bool joined = guildInfo['join'];
                  final banType =
                      BanTypeExtension.fromInt(guildInfo['banned_level'] ?? 0);
                  bool isExpire;
                  // ??????????????????????????????????????????????????????????????????UI???
                  if (joined) {
                    isExpire = false;
                  } else {
                    if (inviteInfo['number'] == '-1') {
                      isExpire = inviteInfo['expire_time'] == '0';
                    } else {
                      isExpire = inviteInfo['expire_time'] == '0' ||
                          inviteInfo['number'] == '0' ||
                          inviteInfo['is_used'] == '1';
                    }
                  }

                  String channelName = '';
                  final List<dynamic> channels = guildInfo['channels'] ?? [];
                  if (channels.isNotEmpty) {
                    if (channelId != null) {
                      for (final channel in channels) {
                        if ((channel['channel_id'] ?? '-1') == channelId) {
                          channelName = channel['name'];
                          break;
                        }
                      }
                    } else {
                      for (final channel in channels) {
                        if ((channel['type'] ?? -1) == 0) {
                          channelName = channel['name'];
                          break;
                        }
                      }
                    }
                  }
                  return ValueListenableBuilder(
                      valueListenable: _pushBtnEnable,
                      builder: (context, enable, child) {
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: enable && banType == BanType.normal
                              ? () => InviteLinkHandler(inviteInfo: inviteInfo)
                                  .handle(data.inviteList.single)
                              : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Visibility(
                                  visible: showUrl,
                                  child: Column(
                                    children: const [
                                      sizeHeight8,
                                      Divider(),
                                      sizeHeight8,
                                    ],
                                  )),
                              Row(
                                children: <Widget>[
                                  if (!isExpire)
                                    _buildGuildIcon(guildIcon, guildName)
                                  else
                                    Container(
                                      height: 48,
                                      width: 48,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).disabledColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        IconFont.buffChatLinkOff,
                                        size: 28,
                                        color: Colors.white,
                                      ),
                                    ),
                                  sizeWidth12,
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          isExpire ? '?????????????????????'.tr : guildName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText2
                                              .copyWith(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        CertificationIconWithText(
                                          profile: certificationProfileWith(
                                              authenticate),
                                          fontWeight: FontWeight.bold,
                                        ),
                                        if (isExpire)
                                          Text(
                                              isSelf
                                                  ? '???????????????????????????????????????'.tr
                                                  : '???%s????????????????????????'
                                                      .trArgs([showName ?? '']),
                                              style: ts12.copyWith(
                                                  fontWeight: FontWeight.w500))
                                        else if (isSelf || joined)
                                          Visibility(
                                            visible: channelName != null &&
                                                channelName.isNotEmpty,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  IconFont
                                                      .buffWenzipindaotubiao,
                                                  size: 16,
                                                  color: ts12.color,
                                                ),
                                                sizeWidth4,
                                                Expanded(
                                                  child: Text(
                                                    channelName,
                                                    style: ts12,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                )
                                              ],
                                            ),
                                          )
                                        else
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              Icon(
                                                IconFont.buffTabFriendList,
                                                size: 16,
                                                color: ts12.color,
                                              ),
                                              sizeWidth5,
                                              Text(
                                                  '%s ?????????'.trArgs(
                                                      [memberNum.toString()]),
                                                  style: ts12),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Visibility(
                                visible: !isExpire,
                                child: sizeHeight12,
                              ),
                              Visibility(
                                visible: !isExpire,
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 36,
                                  child: _buildJoinButton(
                                    enable,
                                    joined,
                                    banType: banType,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      });
                } else {
                  if (snapshot.hasData && snapshot.data['result'] == false) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Visibility(
                            visible: showUrl,
                            child: Column(
                              children: const [
                                sizeHeight8,
                                Divider(),
                                sizeHeight8,
                              ],
                            )),
                        Row(
                          children: <Widget>[
                            Container(
                              height: 48,
                              width: 48,
                              decoration: BoxDecoration(
                                color: Theme.of(context).disabledColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                IconFont.buffChatLinkOff,
                                size: 28,
                                color: Colors.white,
                              ),
                            ),
                            sizeWidth12,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  sizeHeight6,
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          '?????????????????????'.tr,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText2
                                              .copyWith(
                                                  fontSize: 17,
                                                  height: 1,
                                                  fontWeight: FontWeight.bold),
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    return Container(
                        height: 113,
                        width: 113,
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: DefaultTheme.defaultLoadingIndicator());
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinButton(bool enable, bool joined,
      {BanType banType = BanType.normal}) {
    final bool isBan = banType == BanType.frozen || banType == BanType.dissolve;

    String content;
    if (isBan) {
      content = '????????????????????????'.tr;
    } else {
      content = joined ? '????????????????????????????????????'.tr : '??????????????????'.tr;
    }

    bool canJoin = true;

    ///?????????????????????????????????????????????????????????
    if (joined || !enable || isBan) {
      ///????????????????????????
      canJoin = false;
    }

    final buttonStyle = TextButton.styleFrom(
      backgroundColor: MaterialStateColor.resolveWith((states) {
        if (canJoin) {
          return Theme.of(context).primaryColor;
        }
        return Theme.of(context).backgroundColor;
      }),
    );

    Color color;
    if (banType == BanType.frozen || banType == BanType.dissolve) {
      color = Theme.of(context).textTheme.bodyText1.color;
    } else if (enable && joined) {
      color = Theme.of(context).textTheme.bodyText1.color;
    } else {
      color = Colors.white;
    }
    final style = TextStyle(color: color);

    return TextButton(
      style: buttonStyle,
      onPressed: null,
      child: Text(
        content,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// ????????????????????????????????????![liveUrlInfo.hasPermission]?????????????????????????????????????????????
  Widget _buildLiveCard(Future future, LiveLinkInfo liveUrlInfo) {
    Widget cachedWidget = _liveCardWidget[liveUrlInfo.url ?? ''];
    if (cachedWidget == null) {
      cachedWidget = FutureBuilder(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data['code'] == 200 && snapshot.data['data'] != null) {
              final Map<String, dynamic> roomInfo = snapshot.data['data'];
              final LiveCardInfo cardInfo = LiveCardInfo(
                  roomCover: (roomInfo['roomLogo'] ?? '') as String,
                  roomTitle: (roomInfo['roomTitle'] ?? '') as String,
                  anchorAvatar: (roomInfo['avatarUrl'] ?? '') as String,
                  anchorNick: (roomInfo['nickName'] ?? '') as String,
                  status: (roomInfo['status'] ?? 0) as int);
              return GestureDetector(
                onTap: () {
                  _liveCardFuture?.clear();
                  _liveCardWidget?.clear();
                  LiveLinkHandler().handle(liveUrlInfo.url);
                },
                child: LiveCard(
                  status: LiveCardStatus.success,
                  cardInfo: cardInfo,
                ),
              );
            } else {
              return LiveCard(status: LiveCardStatus.failed);
            }
          } else {
            return LiveCard(status: LiveCardStatus.loading);
          }
        },
      );
      _liveCardWidget[liveUrlInfo.url ?? ''] = cachedWidget;
    }
    return cachedWidget;
  }

  Widget _buildGuildIcon(String icon, String name) {
    final size = 48 * Global.navigatorKey.currentContext.devicePixelRatio;
    return SizedBox(
      width: 48,
      height: 48,
      child: ContainerImage(isNotNullAndEmpty(icon) ? icon : Global.logoUrl,
          width: size, height: size, radius: 8, fit: BoxFit.contain),
    );
  }

  Widget _buildCard(TextEntity data, {Widget child}) {
    if (data.numUrls > 1) {
      return child;
    }

    // ??????????????????
    if (_inviteCard != null) {
      return _buildInviteCard(_inviteCard, child: child);
    }

    final url = data.urlList?.single;
    // ????????????
    final _liveUrlInfo = _parseLiveUrl(url);
    if (_liveCard != null && _liveUrlInfo != null) {
      return _buildLiveCard(_liveCard, _liveUrlInfo);
    }

    // ????????????????????????????????????
    if (data.urlList?.length == 1) {
      if (url.isMessageLink) {
        return child;
      }
      return LinkPreview(
        message: widget.message,
        url: url,
        messageId: widget.message.messageId,
        channelId: widget.message.channelId,
        onlyLink: data.text == url,
        onTap: () => LinkHandlerPreset.common.handle(url),
        quoteL1: widget.quoteL1,
        child: child,
      );
    }
    return const SizedBox();
  }

  Widget _wrapInCard(Widget child) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8)),
      child: child,
    );
  }
}
