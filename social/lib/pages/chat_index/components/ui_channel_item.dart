import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/app/controllers/audio_room_controller.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/config.dart';
import 'package:im/db/db.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/chat_index/components/guild_channel_list/landscape_guild_channel_list.dart';
import 'package:im/pages/home/components/live_status_icon.dart';
import 'package:im/pages/home/components/mute_icon.dart';
import 'package:im/pages/home/components/red_dot.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/im_utils/channel_util.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/web/utils/web_util/web_util.dart';
import 'package:im/widgets/channel_icon.dart';
import 'package:im/widgets/fb_ui_kit/widget/count_show_widget.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/segment_list/segment_member_list_service.dart';
import 'package:just_throttle_it/just_throttle_it.dart';
import 'package:provider/provider.dart';

import '../../../routes.dart';
import 'channel_list.dart';

class UIChannelItem extends StatefulWidget {
  final ChatChannel channel;

  @override
  _UIChannelItemState createState() => _UIChannelItemState();

  UIChannelItem(this.channel) : super(key: ValueKey(channel.id));

  static IconData getChannelTypeIcon(
    ChatChannelType channelType, {
    bool isSelected = false,
    bool isPrivate = false,
  }) {
    switch (channelType) {
      case ChatChannelType.dm:
      case ChatChannelType.guildText:
        if (isPrivate) {
          return IconFont.buffSimiwenzipindao;
        } else {
          return IconFont.buffWenzipindaotubiao;
        }
        break;
      case ChatChannelType.guildVoice:
        if (isPrivate) {
          return IconFont.buffChannelVoicePriv;
        } else {
          return IconFont.buffChannelMicLittle;
        }
        break;
      case ChatChannelType.guildVideo:
        if (isPrivate) {
          return IconFont.buffChannelVideoPriv;
        } else {
          return IconFont.buffChannelVideocamLittle;
        }
        break;
      case ChatChannelType.guildCategory:
        break;
      case ChatChannelType.guildLink:
        if (isPrivate) {
          return IconFont.buffChannelLinkPriv;
        } else {
          return IconFont.buffChannelLink;
        }
        break;
      case ChatChannelType.guildLive:
        if (isPrivate) {
          return IconFont.buffChannelLivePriv;
        } else {
          return IconFont.buffChannelLive;
        }
        break;
      case ChatChannelType.guildCircleTopic:
        return IconFont.buffChannelMessageSolid;
        break;
      default:
        break;
    }
    return null;
  }

  // 是否为需要加粗的语音频道。条件太复杂，写成函数
  static bool isBoldVoiceChannel(ChatChannel channel) {
    // 有我在聊天的语音频道，才要加粗 不看active
    if (channel.type == ChatChannelType.guildVoice &&
        GlobalState.mediaChannel.value?.item2?.id == channel.id) {
      try {
        final AudioRoomController c =
            Get.find<AudioRoomController>(tag: channel.id);
        if (c != null && c.joined.value == JoinStatus.joined) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }
}

class _UIChannelItemState extends State<UIChannelItem> {
  bool _tapDown = false;
  bool _hover = false;

  @override
  void dispose() {
    Throttle.clear(onTap);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channel = widget.channel;

    if (channel.type == ChatChannelType.unsupported) return const SizedBox();

    return ValueListenableBuilder(
        valueListenable: GlobalState.selectedChannel,
        builder: (context, selectedChannel, _) {
          final isSelected =
              GlobalState.selectedChannel.value?.id == channel.id;
          if (OrientationUtil.portrait) {
            return buildContent(
              context,
              channel,
              isSelected,
              onLongPress: popChannelActions,
            );
          } else {
            return Listener(
              onPointerDown: (e) {
                if (e.kind == PointerDeviceKind.mouse && e.buttons == 2) {
                  WebConfig.disableContextMenu();
                }
              },
              onPointerMove: (e) {
                LandscapeGuildChannelList.dragging = true;
              },
              onPointerUp: (e) {
                LandscapeGuildChannelList.dragging = false;
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) async {
                  if (!mounted) return;
                  if (!LandscapeGuildChannelList.dragging) {
                    LandscapeGuildChannelList.rebuildStream.add(false);
                  }
                  setState(() {
                    _hover = true;
                  });
                },
                onExit: (_) {
                  if (!mounted) return;
                  setState(() {
                    _hover = false;
                  });
                },
                child: buildContent(
                  context,
                  channel,
                  isSelected,
                ),
              ),
            );
          }
        });
  }

  Widget buildContent(
      BuildContext context, ChatChannel channel, bool isSelected,
      {Function(BuildContext context, ChatChannel channel) onLongPress}) {
    BoxDecoration decoration;

    final backgroundColor = appThemeData.dividerColor.withOpacity(.15);
    final borderRadius = BorderRadius.circular(5);

    if (OrientationUtil.portrait) {
      if (isSelected || _tapDown) {
        decoration = BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
        );
      }
    } else {
      if (isSelected || _hover) {
        decoration = BoxDecoration(
          color: isSelected ? Colors.white : backgroundColor,
          borderRadius: borderRadius,
        );
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        setState(() {
          _tapDown = true;
        });
      },
      onTapCancel: () {
        setState(() {
          _tapDown = false;
        });
      },
      onTapUp: (_) {
        setState(() {
          _tapDown = false;
        });
      },
      onTap: () => Throttle.milliseconds(300, onTap, [channel]),
      onLongPress: onLongPress == null
          ? null
          : () => onLongPress?.call(context, channel),
      child: Column(
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.fromLTRB(0, 1, 0, 1),
            child: ChannelUtil.instance.listen2(
              [channel.id],
              () {
                return ValueListenableBuilder<Box<ChatChannel>>(
                  valueListenable: Db.channelBox.listenable(keys: [channel.id]),
                  builder: (c, box, child) {
                    final numUnread =
                        ChannelUtil.instance.getUnread(channel.id);
                    final isBold = isSelected ||
                        !(numUnread == 0) ||
                        UIChannelItem.isBoldVoiceChannel(channel);
                    final style = (isBold || numUnread > 0)
                        ? appThemeData.textTheme.bodyText2
                            .copyWith(fontWeight: FontWeight.w500)
                        : appThemeData.textTheme.bodyText2
                            .copyWith(color: appThemeData.disabledColor);

                    final gp = PermissionModel.getPermission(channel.guildId);
                    final bool isPrivate =
                        PermissionUtils.isPrivateChannel(gp, channel.id);
                    // 横屏 频道设置按钮
                    final bool managePermission = PermissionUtils.oneOf(gp,
                        [Permission.MANAGE_CHANNELS, Permission.MANAGE_ROLES],
                        channelId: channel.id);
                    final bool showLandscapeChannelSetupIcon =
                        OrientationUtil.landscape && managePermission && _hover;
                    return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: decoration,
                        child: Row(children: <Widget>[
                          const SizedBox(width: 4),

                          // 频道icon标识
                          ChannelIcon(channel.type,
                              private: isPrivate, size: 16, color: style.color),
                          sizeWidth8,

                          // 频道名称
                          Expanded(
                            child: RealtimeChannelName(
                              channel.id,
                              style: style,
                            ),
                          ),

                          // 横屏下尾部标识列表
                          if (showLandscapeChannelSetupIcon) ...[
                            GestureDetector(
                              onTap: () {
                                Routes.pushChannelSetupPage(channel);
                              },
                              child: Icon(
                                IconFont.webCircleSetUp,
                                size: 14,
                                color:
                                    Theme.of(context).textTheme.bodyText2.color,
                              ),
                            ),
                            const SizedBox(width: 6),

                            // 竖屏下尾部标识列表
                          ] else ...[
                            if (channel.canShowRedDot) ...[
                              _buildRetDot(channel, numUnread),
                              sizeWidth4,
                            ],
                            if (channel.canShowLiveIcon)
                              LiveStatusIcon(channel),
                            MuteIcon(channel.id),
                          ],
                          // 语音频道仅且必需显示人数标识
                          if (channel.type == ChatChannelType.guildVoice)
                            _buildCountShow(channel),
                        ]));
                  },
                );
              },
            ),
          ),
          _buildOutShowUsers(context, channel),
        ],
      ),
    );
  }

  Widget _buildCountShow(ChatChannel cl) {
    final channel = Db.channelBox.get(cl.id);
    if (channel == null || channel.userLimit < 0) return const SizedBox();
    final isLogin = Config.token != null;
    final dataModel = SegmentMemberListService.to.getDataModel(
        cl.guildId, cl.id, cl.type,
        autoCreate: channel.active && isLogin, initWithPersistenceData: false);
    if (dataModel == null || channel.active != true) {
      return CountShowWidget(0, channel.userLimit);
    } else {
      final int data = dataModel.memberCount;
      if (data < 0 || channel.userLimit < 0) return const SizedBox();
      return CountShowWidget(dataModel.memberCount, channel.userLimit);
    }
  }

  ///语音频道用户列表展示
  Widget _buildOutShowUsers(BuildContext context, ChatChannel cl) {
    if (cl.type != ChatChannelType.guildVoice) return const SizedBox();

    return ValueListenableBuilder<Box<ChatChannel>>(
      valueListenable: Db.channelBox.listenable(keys: [cl.id]),
      builder: (c, box, child) {
        final channel = box.get(cl.id);
        if (channel?.active != true) return const SizedBox();

        final isLogin = Config.token != null;
        final dataModel = SegmentMemberListService.to.getDataModel(
            channel.guildId, channel.id, channel.type,
            autoCreate: isLogin, initWithPersistenceData: false);
        if (dataModel == null) return const SizedBox();

        return ObxValue<RxInt>((data) {
          if (data.value < 0) return const SizedBox();
          final isLogin = Config.token != null;
          final listDM = SegmentMemberListService.to.getDataModel(
              channel.guildId, channel.id, channel.type,
              autoCreate: isLogin, initWithPersistenceData: false);
          if (listDM == null) return const SizedBox();
          final List<String> ids =
              listDM.memberSnapshot().map((e) => e.userId).toList();
          if (ids.isEmpty) return const SizedBox();
          return Container(
            padding: const EdgeInsets.only(left: 36, right: 12),
            height: 40,
            child: LayoutBuilder(builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              int maxCnt = maxWidth ~/ (24 + 8);
              if (maxCnt > 7) maxCnt = 7;
              var showIds = ids;
              if (showIds.length > maxCnt) showIds = ids.sublist(0, maxCnt);
              return Row(
                children: showIds.map((uid) {
                  return RealtimeAvatar(
                    userId: uid,
                    size: 24,
                  );
                }).toList(),
              );
            }),
          );
        }, dataModel.notify);
      },
    );
  }

  Widget _buildRetDot(ChatChannel channel, int numUnread) {
    return Center(
        child: ChannelUtil.instance.listenAtNum(channel.id, () {
      //未读艾特的消息数量
      int numAtMe = 0;
      if (numUnread > 0) {
        numAtMe = ChannelUtil.instance.getAtMessageBean(channel.id).num;
      }
      final hotChatList = ChannelUtil.getHotChatFriendList(channel.id) ?? [];
      if (numAtMe > 0)
        return OvalDot(numAtMe,
            beforeText: '@',
            color: Theme.of(context).primaryColor,
            alignment: Alignment.center);
      else if (numUnread > 0 &&
          hotChatList.isNotEmpty &&
          channel.type != ChatChannelType.guildCircleTopic)
        return _buildHotChatFriends(hotChatList);
      else
        return RedDot(
          numUnread,
          color: appThemeData.dividerColor.withOpacity(.5),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        );
    }));
  }

  Widget _buildHotChatFriends(List friendList) {
    final List<Widget> widgetList = [];
    for (final friendId in friendList) {
      widgetList.add(Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white),
            color: Colors.white,
          ),
          child: RealtimeAvatar(userId: friendId.toString(), size: 20)));
    }

    final List<Widget> _list = [];
    for (var i = 0; i < widgetList.length; i++) {
      _list.add(Positioned(
        right: i * 14.0,
        child: widgetList[i],
      ));
    }
    return SizedBox(
      height: 22,
      width: 60,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Stack(alignment: Alignment.centerLeft, children: _list),
          ),
        ],
      ),
    );
  }

  void onTap(ChatChannel channel) {
    ///切换频道时，振动一次; 语音频道是底部弹窗，自己会振动
    if (UniversalPlatform.isMobileDevice &&
        channel?.type != ChatChannelType.guildVoice)
      HapticFeedback.lightImpact();
    final gt = Provider.of<BaseChatTarget>(context, listen: false);
    gt.setSelectedChannel(channel, notify: true, context: context);

    /// 通过频道列表进入频道
    DLogManager.getInstance().customEvent(
        actionEventId: 'click_enter_chatid',
        actionEventSubId: channel.id ?? '',
        actionEventSubParam: '1',
        pageId: 'page_chitchat_chat',
        extJson: {"guild_id": channel.guildId});
  }
}
