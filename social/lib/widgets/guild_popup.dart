import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/user_config.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/api/user_api.dart';
import 'package:im/app/modules/home/views/components/chat_index/guild_member_statistics.dart';
import 'package:im/app/modules/task/task_util.dart';
import 'package:im/app/routes/app_pages.dart' as get_pages;
import 'package:im/app/routes/app_pages.dart' as app_pages;
import 'package:im/app/theme/app_colors.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild/guild_nickname_page.dart';
import 'package:im/pages/guild/widget/guild_icon.dart';
import 'package:im/pages/guild_setting/guild/quit_guild.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/show_action_sheet.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/utils/show_confirm_popup.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/pages/setting/create_channel_cate_page.dart';
import 'package:im/web/pages/setting/dm_setting_page.dart';
import 'package:im/web/pages/setting/share_link_setting_page.dart';
import 'package:im/web/utils/show_dialog.dart';
import 'package:im/web/utils/show_web_tooltip.dart';
import 'package:im/web/widgets/button/web_hover_button.dart';
import 'package:im/widgets/link_tile.dart';
import 'package:im/widgets/share_link_popup/share_link_popup.dart';
import 'package:im/widgets/super_tooltip.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:tuple/tuple.dart';

import '../loggers.dart';
import 'certification_icon.dart';

Future<void> showGuildPopUp(
    BuildContext context, String guildId, ChatChannel channel) async {
  if (OrientationUtil.portrait)
    unawaited(showBottomModal(
      context,
      routeSettings:
          const RouteSettings(name: app_pages.Routes.BS_GUILD_SETTINGS),
      builder: (c, s) => GuildPopup(guildId, channel),
      backgroundColor: CustomColor(context).backgroundColor6,
      resizeToAvoidBottomInset: false,
    ));
  else {
    final gp = PermissionModel.getPermission(guildId);
    if (gp == null) return;
    final allowInvite =
        PermissionUtils.oneOf(gp, [Permission.CREATE_INSTANT_INVITE]);
    final allowManageGuild = PermissionUtils.oneOf(gp, [
      Permission.MANAGE_GUILD,
      Permission.MANAGE_ROLES,
      Permission.MANAGE_EMOJIS,
      Permission.MANAGE_CHANNELS
    ]);
    final allowManageChannels =
        PermissionUtils.oneOf(gp, [Permission.MANAGE_CHANNELS]);

    final res = await showWebTooltip<int>(
      context,
      maxWidth: 220,
      builder: (context, done) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            sizeHeight16,
            if (allowInvite)
              _buildHoverButton(context,
                  icon: IconFont.webSetupInvite,
                  title: '邀请好友'.tr,
                  index: 0,
                  done: done),
            if (allowManageGuild)
              _buildHoverButton(context,
                  icon: IconFont.webCircleSetUp,
                  title: '服务器设置'.tr,
                  index: 1,
                  done: done),
            if (allowManageChannels)
              _buildHoverButton(context,
                  icon: IconFont.webSetupAdd,
                  title: '创建频道'.tr,
                  index: 2,
                  done: done),
            if (allowManageChannels)
              _buildHoverButton(context,
                  icon: IconFont.webSetupClassify,
                  title: '创建频道分类'.tr,
                  index: 3,
                  done: done),
            if (allowInvite || allowManageGuild || allowManageChannels)
              Divider(
                indent: 16,
                endIndent: 16,
                color: CustomColor(context).disableColor.withOpacity(0.2),
              ),
            _buildHoverButton(context,
                icon: IconFont.webSetupPrivateChat,
                title: '私聊设置'.tr,
                index: 4,
                done: done),
            sizeHeight16,
          ],
        );
      },
    );
    switch (res) {
      case 0: // 邀请好友
        // todo 私信有没有问题?
        final channelId = GlobalState.selectedChannel.value?.id;
        if (channelId != null) {
          final GuildPermission gp = PermissionModel.getPermission(
              GlobalState.selectedChannel.value.guildId);
          final res = PermissionUtils.oneOf(
              gp,
              [
                Permission.CREATE_INSTANT_INVITE,
              ],
              channelId: GlobalState.selectedChannel.value?.id);
          if (!res) {
            showToast('当前频道没有创建邀请权限，请选择其他频道重试'.tr);
            return;
          }
        }
        showShareLinkSettingPage(context);
        break;
      case 1:
        unawaited(Routes.pushGuildSettingPage(context, guildId));
        break;
      case 2: // 创建频道
        final Tuple2 rtn = await Routes.pushChannelCreation(context, guildId);
        final c = rtn?.item1;
        if (c != null) {
          final m = ChatTargetsModel.instance.selectedChatTarget as GuildTarget;

          final index = m.channels.lastIndexWhere((e) =>
                  isNotNullAndEmpty(e.parentId) &&
                  e.type != ChatChannelType.guildCategory) +
              1;
          m.channelOrder.insert(index, c.id);
          m.addChannel(c,
              notify: true,
              initPermissions: rtn?.item2 as List<PermissionOverwrite>);
          unawaited(Db.channelBox.put(c.id, c));
        }
        break;
      case 3: // 创建频道分类
        unawaited(showAnimationDialog(
            context: context,
            builder: (_) => CreateChannelCatePage(
                  guildId: guildId,
                )));
        break;
      case 4: // 私聊设置
        unawaited(
            showAnimationDialog(context: context, builder: (_) => DmSetting()));
        break;
    }
  }
}

Widget _buildHoverButton(BuildContext context,
    {@required IconData icon,
    @required String title,
    @required int index,
    @required Function(int) done}) {
  final color = Theme.of(context).textTheme.bodyText2.color;
  return WebHoverButton(
      hoverColor: Theme.of(context).disabledColor.withOpacity(0.2),
      onTap: () {
        done(index);
      },
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          sizeWidth12,
          Text(title ?? '',
              style: TextStyle(
                  color: color, fontSize: 14, fontWeight: FontWeight.w400))
        ],
      ));
}

class GuildPopup extends StatefulWidget {
  final String guildId;
  final ChatChannel channel;

  const GuildPopup(this.guildId, this.channel);

  @override
  _GuildPopupState createState() => _GuildPopupState();
}

const divider = Divider(
  thickness: 0.5,
  indent: 16,
);

class _GuildPopupState extends State<GuildPopup> {
  final Color specColor = const Color(0xff737780).withOpacity(0.2);
  GuildTarget guild;
  ValueNotifier<UserInfo> user;
  int memberNum = 0;

  /// - 是否正在退出服务器，接口防抖动
  bool isQuitGuild = false;

  // ThemeData _theme;

  @override
  void initState() {
    () async {
      guild = ChatTargetsModel.instance.selectedChatTarget;
    }();

    super.initState();
  }

  Widget _item(IconData iconData, String content,
      {VoidCallback onTap, bool enable = true}) {
    return Flexible(
      child: FadeButton(
        height: 79,
        onTap: enable ? onTap : null,
        child: Column(
          children: [
            sizeHeight16,
            Icon(
              iconData,
              color: enable
                  ? appThemeData.textTheme.bodyText2.color
                  : Theme.of(context).disabledColor,
            ),
            sizeHeight8,
            Text(
              content,
              style: TextStyle(
                  color: enable
                      ? appThemeData.textTheme.bodyText2.color
                      : Theme.of(context).disabledColor,
                  fontSize: 12),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // 服务器基本信息
            SizedBox(
              height: 104,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    sizeWidth16,
                    GuildIcon(
                      guild,
                      size: 72,
                      fontSize: 30,
                    ),
                    sizeWidth12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          sizeHeight12,
                          Text(
                            guild.name ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          sizeHeight4,
                          Row(
                            children: [
                              if (certificationProfile != null) ...[
                                CertificationIconWithText(
                                  profile: certificationProfile,
                                  // textColor: const Color(0xff6179F2),
                                  // fillColor: const Color(0xff6179F2).withOpacity(0.15),
                                  showBg: false,
                                  textColor: appThemeData.iconTheme.color,
                                  fontSize: 13,
                                  padding: const EdgeInsets.all(0),
                                ),
                                Container(
                                  width: 1,
                                  height: 13,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  color: appThemeData.iconTheme.color
                                      .withOpacity(0.4),
                                ),
                              ],
                              GuildMemberStatistics(
                                guildId: widget.guildId,
                                textStyle: TextStyle(
                                  color: appThemeData.iconTheme.color,
                                  fontSize: 13,
                                ),
                                needDot: false,
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    IconButton(
                        onPressed: () async {
                          final contents = [
                            if (guild.ownerId != Global.user.id) '退出服务器',
                            '举报服务器'
                          ];
                          final index = await showCustomActionSheet([
                            if (guild.ownerId != Global.user.id)
                              Text(
                                '退出服务器'.tr,
                                style: appThemeData.textTheme.bodyText2
                                    .copyWith(color: const Color(0xFFF24848)),
                              ),
                            Text(
                              '举报服务器'.tr,
                              style: appThemeData.textTheme.bodyText2,
                            )
                          ]);
                          if (index == null) return;
                          switch (contents[index]) {
                            case '退出服务器':
                              unawaited(showConfirmPopup(
                                  title: '退出服务器后不会通知服务器成员，且不会再接收服务器消息'.tr,
                                  confirmText: "确定退出服务器".tr,
                                  confirmStyle:
                                      appThemeData.textTheme.bodyText2.copyWith(
                                    color: redTextColor,
                                    fontSize: 17,
                                  ),
                                  onConfirm: () async {
                                    // 接口防抖动
                                    if (isQuitGuild) return;
                                    isQuitGuild = true;

                                    final guild = ChatTargetsModel.instance
                                        .getChatTarget(widget.guildId);
                                    try {
                                      await GuildApi.quitGuild(
                                          Global.user.id, widget.guildId);
                                      showToast(
                                          "已退出服务器「%s」".trArgs([guild.name]),
                                          duration: const Duration(seconds: 3));
                                      quitGuild(guild);
                                    } catch (e) {
                                      logger.warning(
                                          'quit Guild failed: ${e.toString()}');
                                    }
                                    isQuitGuild = false;
                                  }));
                              break;
                            case '举报服务器':
                              unawaited(
                                Routes.pushToTipOffPage(
                                  context,
                                  guildId: ChatTargetsModel
                                      .instance.selectedChatTarget.id,
                                  accusedUserId: guild.id,
                                  accusedName: guild.name,
                                  complaintType: 1,
                                ), /**/
                              );
                              break;
                          }
                        },
                        icon: const Icon(IconFont.buffMoreHorizontal)),
                    sizeWidth4,
                  ],
                ),
              ),
            ),
            // 机器人、邀请、消息通知、服务器设置
            Row(
              children: [
                ///文档权限
                if (!TaskUtil.instance.isNewGuy.value)
                  _item(IconFont.buffDocument, '在线文档'.tr, onTap: () {
                    if (context.isPortrait) Get.back();
                    delay(() {
                      Routes.pushGuildDocument(guild.id);
                    });
                  }),
                ValidPermission(
                  permissions: [
                    Permission.CREATE_INSTANT_INVITE,
                  ],
                  builder: (isAllowed, isOwner) {
                    return _item(IconFont.buffModuleMenuOpen, '邀请',
                        enable: isAllowed, onTap: () {
                      if (context.isPortrait) Get.back();
                      final channelId = GlobalState.selectedChannel.value?.id;
                      if (channelId != null) {
                        final GuildPermission gp =
                            PermissionModel.getPermission(
                                GlobalState.selectedChannel.value?.guildId);
                        final res = PermissionUtils.oneOf(
                          gp,
                          [
                            Permission.CREATE_INSTANT_INVITE,
                          ],
                        );
                        if (!res) {
                          showToast('当前频道没有创建邀请权限，请选择其他频道重试'.tr);
                          return;
                        }
                      }
                      showShareLinkPopUp(context,
                          channel: widget.channel,
                          direction: TooltipDirection.right,
                          margin: const EdgeInsets.only(left: 204));
                    });
                  },
                ),
                _item(IconFont.buffChannelNotice, '消息通知', onTap: () {
                  if (context.isPortrait) Get.back();
                  Routes.pushNotificationManagerPage();
                }),
                ValidPermission(
                  permissions: [
                    Permission.MANAGE_GUILD,
                    // Permission.MANAGE_GUILD_EDIT,
                    Permission.MANAGE_ROLES,
                    Permission.MANAGE_EMOJIS,
                    Permission.MANAGE_CHANNELS,
                  ],
                  builder: (isAllowed, isOwner) {
                    if (!isAllowed) return const SizedBox();
                    return _item(IconFont.buffSetting, '设置', onTap: () {
                      if (context.isPortrait) Get.back();
                      Routes.pushGuildSettingPage(context, widget.guildId);
                    });
                  },
                ),
              ],
            ),
            Container(
              color: CustomColor(context).backgroundColor7,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: <Widget>[
                  sizeHeight12,
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      children: <Widget>[
                        ValidPermission(
                            permissions: [Permission.MANAGE_CHANNELS],
                            builder: (value, isOwner) {
                              if (!value) return const SizedBox();
                              return LinkTile(
                                context,
                                Text(
                                  '管理频道'.tr,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 16),
                                ),
                                height: 52,
                                onTap: () {
                                  if (context.isPortrait) Get.back();
                                  Get.toNamed(
                                      app_pages.Routes.GUILD_CHANNEL_SETTINGS);
                                },
                              );
                            }),
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.only(left: 16),
                          child: const Divider(
                            height: 0.5,
                          ),
                        ),

                        ValidPermission(
                          permissions: [
                            Permission.ADMIN,
                          ],
                          builder: (isAllowed, isOwner) {
                            if (!isOwner) return const SizedBox();
                            return LinkTile(
                              context,
                              Text(
                                '机器人'.tr,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w400, fontSize: 16),
                              ),
                              height: 52,
                              onTap: () {
                                if (context.isPortrait) Get.back();
                                Get.toNamed(get_pages.Routes.BOT_MARKET_PAGE);
                              },
                            );
                          },
                        ),
//                        Divider(
//                          color: Theme.of(context).scaffoldBackgroundColor,
//                        ),
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.only(left: 16),
                          child: const Divider(
                            height: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  sizeHeight16,
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      children: <Widget>[
                        LinkTile(
                          context,
                          Row(
                            // crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '我在本服务器昵称'.tr,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w400, fontSize: 16),
                              ),
                              getGuildNickname(widget.guildId),
                            ],
                          ),
                          onTap: () {
                            if (context.isPortrait) Get.back();
                            showBottomModal(
                              context,
                              routeSettings: const RouteSettings(
                                  name: guildNicknameSettingRoute),
                              builder: (c, s) => GuildNicknameSettingPage(
                                guildId: widget.guildId,
                              ),
                              backgroundColor:
                                  CustomColor(context).backgroundColor6,
                              resizeToAvoidBottomInset: false,
                            ).then((value) {
                              showGuildPopUp(
                                  Get.context, widget.guildId, widget.channel);
                            });
                          },
                        ),
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.only(left: 16),
                          child: const Divider(
                            height: 0.5,
                          ),
                        ),
                        LinkTile(
                          context,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                '允许别人私信我'.tr,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w400, fontSize: 16),
                              ),
                            ],
                          ),
                          height: 52,
                          showTrailingIcon: false,
                          trailing: ValueListenableBuilder<Box>(
                              valueListenable: Db.userConfigBox.listenable(
                                  keys: [UserConfig.restrictedGuilds]),
                              builder: (context, box, w) {
                                final isRestricted =
                                    ((box.get(UserConfig.restrictedGuilds) ??
                                            []) as List)
                                        .contains(ChatTargetsModel
                                            .instance.selectedChatTarget?.id);
                                return Transform.scale(
                                  scale: 0.7,
                                  alignment: Alignment.centerRight,
                                  child: CupertinoSwitch(
                                      activeColor:
                                          Theme.of(context).primaryColor,
                                      value: !isRestricted,
                                      onChanged: _onRestrictedChange),
                                );
                              }),
                        ),
//                        Divider(
//                          color: Theme.of(context).scaffoldBackgroundColor,
//                        ),
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.only(left: 16),
                          child: const Divider(
                            height: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                      visible: guild.ownerId != Global.user.id,
                      child: const SizedBox(height: 17)),
                  SizedBox(
                    height: getBottomViewInset(),
                  )
                ],
              ),
            )
          ],
        ),
      ],
    );
  }

  ///设置-是否允许私聊
  Future<void> _onRestrictedChange(bool v) async {
    if (!v) {
      ///增加确认弹窗
      final result = await showConfirmDialog(title: '关闭后，服务器所有成员将无法私信你'.tr);
      if (!result) return;
    }

    final List<String> restrictedGuilds =
        ((await Db.userConfigBox.get(UserConfig.restrictedGuilds) ?? [])
                as List)
            .cast<String>();
    final String guildId = ChatTargetsModel.instance.selectedChatTarget.id;
    if (v) {
      restrictedGuilds.remove(guildId);
    } else if (!v && !restrictedGuilds.contains(guildId)) {
      restrictedGuilds.add(guildId);
    }
    await UserApi.updateSetting(restrictedGuilds: restrictedGuilds);
    unawaited(
        Db.userConfigBox.put(UserConfig.restrictedGuilds, restrictedGuilds));
  }

  Widget getGuildNickname(String guildId) {
    final user = Db.userInfoBox.get(Global.user.id);
    final guildName = user?.guildNickname(guildId) ?? '';
    if (guildName.isEmpty) return sizedBox;
    return Text(
      guildName,
      style: TextStyle(
        color: CustomColor(context).disableColor,
        fontSize: 14,
      ),
    );
  }
}
