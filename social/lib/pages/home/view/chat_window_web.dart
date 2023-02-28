import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/components/red_dot.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_event.dart';
import 'package:im/pages/home/model/text_channel_util.dart';
import 'package:im/pages/member_list/member_list_window.dart';
import 'package:im/pages/member_list/model/member_list_route_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/web/pages/main/widgets/channel_notify_switchers.dart';
import 'package:im/web/widgets/button/web_icon_button.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/share_link_popup/share_link_popup.dart';
import 'package:im/widgets/top_status_bar.dart';
import 'package:im/ws/pin_handler.dart';

import '../../../icon_font.dart';
import '../../../routes.dart';

class ChatWindowScaffold extends StatefulWidget {
  final Widget child;

  final IconData channelIcon;

  final bool showMemberlist;

  const ChatWindowScaffold(this.channelIcon, this.child,
      {Key key, this.showMemberlist = true})
      : super(key: key);

  @override
  _ChatWindowScaffoldState createState() => _ChatWindowScaffoldState();
}

class _ChatWindowScaffoldState extends State<ChatWindowScaffold> {
  StreamSubscription _messageSubscription;

  @override
  void initState() {
    _messageSubscription = TextChannelUtil.instance.stream.listen(_onMessage);
    super.initState();
  }

  @override
  void dispose() {
    _messageSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: TopStatusController.to().showStatusUI,
      builder: (context, errorVisible, _) {
        Widget title;
        if (GlobalState.selectedChannel.value == null) {
          title = Text(
            "提示".tr,
            style: Theme.of(context)
                .textTheme
                .headline5
                .copyWith(fontWeight: FontWeight.normal),
          );
        } else {
          title = Row(
            children: <Widget>[
              if (widget.channelIcon != null) ...[
                sizeWidth8,
                Icon(
                  widget.channelIcon,
                  size: 24,
                  color: const Color(0xFFB6B9BF),
                ),
                sizeWidth8,
              ],
              Expanded(child: _buildTitle(context))
            ],
          );
        }

        final iconColor = Theme.of(context).iconTheme.color;
        final selectedChannel = GlobalState.selectedChannel.value;
        return Container(
          color: CustomColor(context).backgroundColor2,
          child: Column(
            children: <Widget>[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusScope.of(context).unfocus(),
                child: SizedBox(
                  height: 56,
                  child: Row(
                    children: <Widget>[
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(child: title),
                      if (GlobalState.selectedChannel.value.type !=
                              ChatChannelType.dm &&
                          widget.showMemberlist) ...[
                        Tooltip(
                            message: '通知'.tr,
                            child: ChannelNotifySwitchers(
                                GlobalState.selectedChannel.value.id)),
                        sizeWidth16,
                      ],
                      if (GlobalState.selectedChannel.value != null &&
                          widget.showMemberlist) ...[
                        if (GlobalState.selectedChannel.value.type !=
                                ChatChannelType.dm &&
                            GlobalState.selectedChannel.value.type !=
                                ChatChannelType.group_dm &&
                            OrientationUtil.landscape)
                          Tooltip(
                            message: '邀请'.tr,
                            child: ValidPermission(
                                channelId:
                                    GlobalState.selectedChannel.value?.id,
                                permissions: [Permission.CREATE_INSTANT_INVITE],
                                builder: (value, isOwner) {
                                  if (!value) return const SizedBox(height: 48);
                                  return Builder(builder: (context) {
                                    return WebIconButton(
                                      IconFont.webChatAdd,
                                      color: iconColor,
                                      hoverColor: Colors.black,
                                      highlightColor:
                                          Theme.of(context).primaryColor,
                                      size: 20,
                                      onPressed: () => showShareLinkPopUp(
                                          context,
                                          channel: GlobalState
                                              .selectedChannel.value),
                                    );
                                  });
                                }),
                          ),
                        sizeWidth4,
                        ValueListenableBuilder<Box<List<String>>>(
                          valueListenable: Db.pinMessageUnreadBox.listenable(
                              keys: [GlobalState.selectedChannel.value?.id]),
                          builder: (c, box, child) {
                            List unread;
                            if (kIsWeb) {
                              // web 首次取出数据是会抛出异常
                              try {
                                unread = box.get(GlobalState
                                        .selectedChannel.value?.id) ??
                                    [];
                              } catch (e) {
                                box.put(
                                    GlobalState.selectedChannel.value?.id, []);
                                unread = [];
                              }
                            } else {
                              unread = box.get(
                                      GlobalState.selectedChannel.value?.id) ??
                                  [];
                            }

                            if (GlobalState.selectedChannel.value.type !=
                                ChatChannelType.group_dm) {
                              return Tooltip(
                                message: 'Pin',
                                child: RedDotFill(
                                  unread.length,
                                  offset: const Offset(6, -5),
                                  borderColor:
                                      Theme.of(context).backgroundColor,
                                  child: WebIconButton(
                                    IconFont.webChatPin,
                                    color: iconColor,
                                    hoverColor: Colors.black,
                                    highlightColor:
                                        Theme.of(context).primaryColor,
                                    size: 20,
                                    onPressed: () => Routes.pushPinListPage(
                                        context,
                                        channel:
                                            GlobalState.selectedChannel.value),
                                  ),
                                ),
                              );
                            } else {
                              return sizeWidth2;
                            }
                          },
                        ),
                      ],
                      if (selectedChannel?.type ==
                          ChatChannelType.guildText) ...[
                        sizeWidth4,
                        Tooltip(
                          message: '搜索'.tr,
                          child: WebIconButton(IconFont.buffCommonSearch,
                              color: iconColor,
                              hoverColor: Colors.black,
                              highlightColor: Theme.of(context).primaryColor,
                              size: 20,
                              onPressed: () => Routes.pushSearchMessagePage(
                                  context, selectedChannel.guildId)),
                        ),
                      ],
                      sizeWidth24,
                    ],
                  ),
                ),
              ),
              if (!widget.showMemberlist) const Divider(),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: widget.child),
                    if (widget.showMemberlist) ...[
                      const VerticalDivider(
                        width: 1,
                      ),
                      MemberListWindow(
                        model: MemberListRouteModel.instance,
                      )
                    ]
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTitle(BuildContext context) {
    {
      TextStyle style = Theme.of(context).textTheme.headline5;
      if (kIsWeb) {
        style = style.copyWith(height: 2);
      }
      return GlobalState.selectedChannel.value.type == ChatChannelType.dm
          ? RealtimeNickname(
              userId: GlobalState.selectedChannel.value.recipientId ??
                  GlobalState.selectedChannel.value.guildId,
              showNameRule: ShowNameRule.remarkAndGuild,
              style: style,
            )
          : RealtimeChannelName(
              GlobalState.selectedChannel.value.id,
              style: style,
            );
    }
  }

// 处理pin消息红点
  void _onMessage(e) {
    void _removeMessage(String channelId, String messageId) {
      final pinUnreadList = Db.pinMessageUnreadBox.get(channelId) ?? [];
      pinUnreadList.remove(messageId);
      Db.pinMessageUnreadBox.put(channelId, pinUnreadList);
    }

    if (e is RecallMessageEvent) {
      _removeMessage(e.channelId, e.id);
    } else if (e is PinEvent) {
      final message = e.message;
      final entity = message.content as PinEntity;
      if (entity.action == 'unpin') {
        _removeMessage(message.channelId, entity.id);
      } else {
        if (message.userId == Global.user.id) return;
        final pinUnreadList =
            Db.pinMessageUnreadBox.get(message.channelId) ?? [];
        pinUnreadList.add(entity.id);
        Db.pinMessageUnreadBox.put(message.channelId, pinUnreadList);
      }
    }
  }
}
