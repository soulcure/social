import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/user_config.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/api/user_api.dart';
import 'package:im/app/modules/circle/models/circle_post_data_model.dart';
import 'package:im/app/modules/circle_detail/circle_detail_router.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/app/modules/direct_message/views/portrait_direct_message_view.dart';
import 'package:im/app/modules/direct_message/views/text_desc_widget.dart';
import 'package:im/app/modules/group_message/views/group_chat_icon.dart';
import 'package:im/app/modules/task/task_util.dart';
import 'package:im/app/routes/app_pages.dart' as get_pages;
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/future_extension.dart';
import 'package:im/common/extension/list_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/db/bean/dm_last_message_desc.dart';
import 'package:im/db/cicle_news_table.dart';
import 'package:im/db/db.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/circle_page.dart';
import 'package:im/pages/home/components/red_dot.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/in_memory_db.dart';
import 'package:im/pages/home/model/text_channel_util.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/pages/home/view/text_chat/text_chat_ui_creator.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/im_utils/channel_util.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/show_action_sheet.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/pages/main/main_model.dart';
import 'package:im/web/utils/show_web_tooltip.dart';
import 'package:im/web/widgets/context_menu_detector.dart';
import 'package:im/web/widgets/popup/web_popup.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/dialog/show_alert_dialog.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/shape/row_bottom_border.dart';
import 'package:im/widgets/super_tooltip.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:provider/provider.dart';

class Item extends StatefulWidget {
  final ChatChannel channel;

  ///?????????????????????(????????????,??????,??????,?????????)??????????????????????????????????????????????????????
  final VoidCallback refreshParent;

  const Item({Key key, this.channel, this.refreshParent}) : super(key: key);

  @override
  _ItemState createState() => _ItemState();
}

class _ItemState extends State<Item> {
  DmLastMessageDesc get desc =>
      InMemoryDb.getMessageList(widget.channel.id).latestMessageDesc;

  ///???????????????????????????
  bool isMuted = false;

  ///??????????????????????????????
  bool isOpenCircleDetail = false;

  String _getMessageTime(DmLastMessageDesc message) {
    if (message == null) return '';
    final dateTime = msgId2DateTime(message.messageId);
    if (OrientationUtil.portrait)
      return formatDate2Str(dateTime);
    else
      return lastMsgFormatDate2Str(dateTime);
  }

  @override
  void initState() {
    super.initState();
  }

  void updateIsMuted() {
    isMuted = (Db.userConfigBox.get(UserConfig.mutedChannel) ?? [])
        .contains(widget.channel.id);
  }

  Widget _main({bool selectedFriend = false}) {
    final channel = widget.channel;
    final isSelected =
        widget.channel == GlobalState.selectedChannel.value && !selectedFriend;

    //1.6.53?????? recipientId????????????????????????userId, 1.6.53??????????????????guildId????????????????????????userId?????????guildId,????????????????????????
    //1.6.53????????????????????????hive???????????????????????????recipientId???null???1.6.53?????????????????????????????? userId = channel.recipientId
    final String userId = channel.recipientId ?? channel.guildId;

    return FadeBackgroundButton(
      tapDownBackgroundColor: OrientationUtil.portrait
          ? Theme.of(context).scaffoldBackgroundColor
          : Theme.of(context).backgroundColor,
      backgroundColor: (OrientationUtil.portrait || isSelected)
          ? Theme.of(context).backgroundColor
          : Theme.of(context).scaffoldBackgroundColor,
      onLongPress: () {
        if (UniversalPlatform.isAndroid) {
          _buildPopMenu(channel);
        }
      },
      onTap: () async {
        if (OrientationUtil.portrait) {
          ///????????????????????????????????????
          DirectMessageController.to.clearSearchText();
          if (channel.type == ChatChannelType.circlePostNews) {
            await TaskUtil.instance.reqTaskByGuildId(channel.id);
            unawaited(openCirclePost(channel)
                .then((_) => DirectMessageController.to.resetNoSearchUpdate()));
          } else {
            unawaited(Routes.pushDirectChatPage(channel).then((value) {
              DirectMessageController.to.resetNoSearchUpdate();
              widget.refreshParent?.call();
            }));
          }
        } else {
          MainRouteModel.instance.goBack();
          unawaited(ChatTargetsModel.instance
              .selectChatTarget(null, channel: widget.channel));
        }
      },
      child: Container(
        height: OrientationUtil.portrait ? 72 : 60,
        decoration: const ShapeDecoration(
          shape: RowBottomBorder(leading: 76),
        ),
        child: ValueListenableBuilder(
            valueListenable: Db.userInfoBox.listenable(keys: [userId]),
            builder: (context, box, widget) {
              if (channel.type == ChatChannelType.dm) {
                final user = box?.get(userId);
                if (user == null) {
                  if (userId.hasValue) {
                    UserInfo.get(userId);
                  }
                  return _defaultItemWidget(context);
                }
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sizeWidth16,
                  // ??????
                  DirectMessageWidget(channel: channel, isMuted: isMuted),
                  SizedBox(
                    width: OrientationUtil.portrait ? 12 : 10,
                  ),
                  // ?????? ??????
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ValueListenableBuilder<Box<ChatChannel>>(
                                  valueListenable: Db.channelBox
                                      .listenable(keys: [channel.id]),
                                  builder: (context, box, child) {
                                    final chatChannel = box.get(channel.id);
                                    return _nicknameWidget(chatChannel);
                                  },
                                ),
                              ),
                              ValueListenableBuilder<Box<DmLastMessageDesc>>(
                                  valueListenable: Db.dmLastDesc
                                      .listenable(keys: [channel.id]),
                                  builder: (context, _, __) {
                                    return Text(_getMessageTime(desc),
                                        style: TextStyle(
                                            color: const Color(0xFF8F959E),
                                            height: OrientationUtil.portrait
                                                ? 1.25
                                                : 1,
                                            fontSize: 12));
                                  }),
                            ],
                          ),
                          sizeHeight5,
                          ValueListenableBuilder<Box<DmLastMessageDesc>>(
                              valueListenable:
                                  Db.dmLastDesc.listenable(keys: [channel.id]),
                              builder: (context, _, __) {
                                return TextDescWidget(desc, channel, isMuted);
                              }),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
      ),
    );
  }

  Widget _nicknameWidget(ChatChannel channel) {
    final style = appThemeData.textTheme.bodyText2.copyWith(
      fontSize: OrientationUtil.portrait ? 17 : 14,
      height: OrientationUtil.portrait ? 1.25 : 1,
    );
    Widget typeName;
    if (channel?.type == ChatChannelType.group_dm) {
      typeName = Text(channel.name.hasValue ? channel.name : "?????????????????????".tr,
          style: style, overflow: TextOverflow.ellipsis, maxLines: 1);
    } else if (channel?.type == ChatChannelType.circlePostNews) {
      // print('getChat desc.name: ${channel.name}');
      //????????????????????????????????????????????????ID???#?????????
      typeName = ParsedText(
        style: style,
        text: (channel.name?.hasValue ?? false) ? channel.name : "??????".tr,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        parse: [
          ParsedTextExtension.matchAtText(
            context,
            textStyle: style,
            useDefaultColor: false,
            guildId: channel.recipientGuildId,
            tapToShowUserInfo: false,
          ),
          ParsedTextExtension.matchChannelLink(
            context,
            textStyle: style,
            tapToJumpChannel: false,
            hasBgColor: false,
            refererChannelSource: RefererChannelSource.CircleLink,
          ),
        ],
      );
    } else if (channel?.type == ChatChannelType.dm) {
      //1.6.53?????? recipientId????????????????????????userId, 1.6.53??????????????????guildId????????????????????????userId?????????guildId,????????????????????????
      //1.6.53????????????????????????hive???????????????????????????recipientId???null???1.6.53?????????????????????????????? userId = channel.recipientId
      final String userId = channel.recipientId ?? channel.guildId;
      typeName = RealtimeNickname(
        key: ValueKey(userId),
        userId: userId,
        style: style,
        showNameRule: ShowNameRule.remark,
        initName: channel.name,
      );
    }
    Widget typeW;
    if (channel?.type == ChatChannelType.dm) {
      final user = Db.userInfoBox.get(channel.recipientId ?? channel.guildId);
      if (user != null && user.isBot) typeW = TextChatUICreator.botMark;
    } else if (channel?.type == ChatChannelType.circlePostNews) {
      typeW = TextChatUICreator.circleMark;
    }
    typeName ??= const SizedBox();
    typeW ??= const SizedBox();
    final row = Row(
      children: [
        Flexible(child: typeName),
        sizeWidth5,
        typeW,
        sizeWidth5,
      ],
    );
    return row;
  }

  Widget _defaultItemWidget(BuildContext context) {
    final color = Theme.of(context).dividerTheme.color;
    return Container(
        height: OrientationUtil.portrait ? 72 : 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: Theme.of(context).backgroundColor),
        child: Row(
          children: <Widget>[
            Container(
              width: OrientationUtil.portrait ? 48 : 40,
              height: OrientationUtil.portrait ? 48 : 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 10),
            Flexible(
                child: FractionallySizedBox(
              widthFactor: Random().nextDouble() * (0.666 - 0.333) + 0.333,
              child: Container(
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(12)),
                height: 24,
              ),
            )),
          ],
        ));
  }

  ///??????????????????
  Future<void> _buildPopMenu(ChatChannel channel) async {
    final actions = [
      Text(
        '?????????'.tr,
        style: Theme.of(context).textTheme.bodyText2,
      ),
    ];
    if (channel.type == ChatChannelType.group_dm ||
        channel.type == ChatChannelType.circlePostNews) {
      actions.add(Text(
        isMuted ? '??????????????????'.tr : '??????????????????'.tr,
        style: Theme.of(context).textTheme.bodyText2,
      ));
    }

    final res = await showCustomActionSheet(actions);
    if (res == 0) {
      await DirectMessageController.to.closeChannel(channel);
    } else if (res == 1) {
      final mutedChannels =
          (Db.userConfigBox.get(UserConfig.mutedChannel) ?? []).toList();
      if (isMuted) {
        mutedChannels.remove(channel.id);
      } else {
        mutedChannels.add(channel.id);
      }
      await UserApi.updateSetting(mutedChannels: mutedChannels);
      await UserConfig.update(mutedChannels: mutedChannels);
      showToast(isMuted ? '?????????????????????'.tr : '?????????????????????'.tr);
      DirectMessageController.to.updateUnread();

      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    updateIsMuted();
    if (OrientationUtil.portrait)
      return _main();
    else
      return ContextMenuDetector(
        onContextMenu: (e) {
          showWebTooltip(context,
              globalPoint: e.position,
              minimumOutSidePadding: 4,
              containsBackgroundOverlay: false,
              popupDirection: TooltipDirection.followMouse,
              builder: (context, done) {
            final channel = widget.channel;
            final items = ['?????????'];
            if (channel.type == ChatChannelType.group_dm) {
              if (isMuted) {
                items.add('????????????'.tr);
              } else {
                items.add('????????????'.tr);
              }
            }

            return SizedBox(
              width: 120,
              child: WebSelectionPopup(
                items: items,
                callBack: (value) async {
                  if (value == 0) {
                    await DirectMessageController.to.closeChannel(channel);
                  } else if (value == 1) {
                    final mutedChannels =
                        (Db.userConfigBox.get(UserConfig.mutedChannel) ?? [])
                            .toList();
                    if (isMuted) {
                      mutedChannels.remove(channel.id);
                    } else {
                      mutedChannels.add(channel.id);
                    }
                    await UserApi.updateSetting(mutedChannels: mutedChannels);
                    await UserConfig.update(mutedChannels: mutedChannels);
                    showToast(isMuted ? '?????????????????????' : '?????????????????????');
                    setState(() {});
                    TextChannelUtil.instance.stream
                        .add(NotifyWebSwitcherStream());
                  }
                  done(null);
                },
              ),
            );
          });
        },
        child: ChangeNotifierProvider.value(
          value: MainRouteModel.instance,
          child: Selector<MainRouteModel, bool>(
              selector: (_, model) =>
                  model.routes.last.route == get_pages.Routes.FRIEND_LIST_PAGE,
              builder: (context, v, child) {
                return ValueListenableBuilder(
                  valueListenable: GlobalState.selectedChannel,
                  builder: (_, __, ___) {
                    return _main(selectedFriend: v);
                  },
                );
              }),
        ),
      );
  }

  ///???????????????????????????
  Future openCirclePost(ChatChannel channel) async {
    try {
      if (isOpenCircleDetail) return;
      isOpenCircleDetail = true;
      final cId = channel.id;
      final obj = await CircleNewsTable.queryAtCircleNews(cId,
          firstId: Db.firstMessageIdBox.get(cId));

      // ????????????
      // obj.atMap[BigInt.parse('316552979329056768')] = '180646286339342336';
      // obj.atMap[BigInt.parse('316511112524726272')] = '171606038007513088';

      if (!ChatTargetsModel.instance.isJoinGuild(channel.recipientGuildId)) {
        await CommonTitleAlertDialog.show(Get.context, '??????????????????????????????????????????'.tr,
            title: '??????'.tr);
        unawaited(DirectMessageController.to.closeChannel(channel));
        isOpenCircleDetail = false;
        return;
      }
      if (obj.postIsDel) {
        await CommonTitleAlertDialog.show(Get.context, '?????????????????????'.tr,
            title: '??????'.tr);
        unawaited(DirectMessageController.to.closeChannel(channel));
        isOpenCircleDetail = false;
        return;
      }

      ///?????????????????????????????????????????????
      final list = ChatTargetsModel.instance.chatTargets;
      final guild = list?.firstWhere((e) => e.id == channel.recipientGuildId);
      if (guild is GuildTarget && guild.isBan) {
        await CommonTitleAlertDialog.show(Get.context, '?????????????????????????????????????????????'.tr,
            title: '??????'.tr);
        isOpenCircleDetail = false;
        return;
      }

      CircleDetailRouter.push(CircleDetailData(null,
          topPositionObj: obj,
          extraData: ExtraData(
              guildId: channel.recipientGuildId,
              postId: channel.recipientId,
              circleNewsChannelId: channel.id,
              lastCircleType: obj?.lastCircleType,
              extraType: ExtraType.fromDmList), onBack: (result) {
        Future.delayed(const Duration(milliseconds: 500)).then((_) {
          onBack(channel, result);
        });
      })).unawaited;
    } catch (e) {
      logger.info('openCirclePost onTap error: $e');
    }
    isOpenCircleDetail = false;
  }

  ///??????????????????-??????
  Future onBack(ChatChannel channel, Object result) async {
    try {
      if (result == null) return;
      if (result == 10 || result == 11 || result == 12) {
        unawaited(DirectMessageController.to.closeChannel(channel));
      } else if (result is CirclePostDataModel) {
        if (channel.recipientId != result.postId) return;
        //?????????????????????title?????????name
        final cName = result.postInfoDataModel?.title;
        if (cName.hasValue)
          ChannelUtil.instance.updateChannel(channel, name: cName);
        widget.refreshParent?.call();
      }
    } catch (e) {
      logger.info('openCirclePost onBack error: $e');
    }
  }
}

///??????
class DirectMessageWidget extends StatelessWidget {
  const DirectMessageWidget({
    Key key,
    @required this.channel,
    this.isMuted,
  }) : super(key: key);

  final ChatChannel channel;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<int>>(
        valueListenable:
            Db.numUnrealOfChannelBox.listenable(keys: [channel.id]),
        builder: (context, box, widget) {
          final int number = box.get(channel.id) ?? 0;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding:
                    EdgeInsets.only(top: OrientationUtil.portrait ? 12 : 10),
                child: getIcon(channel),
              ),
              Positioned(
                top: 8,
                right: -5,
                child: getRedDot(channel, number),
              ),
            ],
          );
        });
  }

  RedDot getRedDot(ChatChannel channel, int number) {
    ///?????????????????????????????????
    if (isMuted) {
      return RedDot(
        number,
        borderColor: Colors.white,
        color: const Color(0xFFbbbbbb),
        fontSize: 11,
      );
    } else {
      return RedDot(
        number,
        borderColor: Colors.white,
        fontSize: 11,
      );
    }
  }

  Widget getIcon(ChatChannel channel) {
    final double size = OrientationUtil.portrait ? 48 : 40;
    if (channel.type == ChatChannelType.group_dm) {
      final icons = channel.icons;
      return ClipOval(
          child: icons.noValue
              ? GroupChatIcon(
                  [DmGroupRecipientIcon(avatar: channel.icon)],
                  size: size,
                )
              : GroupChatIcon(icons, size: size));
    } else if (channel.type == ChatChannelType.circlePostNews) {
      ///???????????????????????????????????????????????????
      return Avatar(
        radius: size / 2,
        url: channel.icon,
      );
    } else {
      //1.6.53?????? recipientId????????????????????????userId, 1.6.53??????????????????guildId????????????????????????userId?????????guildId,????????????????????????
      //1.6.53????????????????????????hive???????????????????????????recipientId???null???1.6.53?????????????????????????????? userId = channel.recipientId
      final String userId = channel.recipientId ?? channel.guildId;
      return RealtimeAvatar(
        userId: userId,
        size: size,
      );
    }
  }
}
