import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/routes/app_pages.dart' as app_pages;
import 'package:im/common/permission/permission.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/pages/guild/widget/guild_icon.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/button/more_icon.dart';
import 'package:im/widgets/certification_icon.dart';
import 'package:im/widgets/link_tile.dart';

import 'guild_edit_info_page.dart';

class GuildSettingPage extends StatefulWidget {
  final String guildId;

  const GuildSettingPage(this.guildId);

  @override
  _GuildSettingPageState createState() => _GuildSettingPageState();
}

class _GuildSettingPageState extends State<GuildSettingPage> {
  ThemeData _theme;
  GuildTarget target;

  @override
  void initState() {
    target = ChatTargetsModel.instance.getChatTarget(widget.guildId);
    target.addListener(_refresh);
    super.initState();
  }

  @override
  void dispose() {
    target.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _theme = Theme.of(context);
    return Scaffold(
      backgroundColor: _theme.scaffoldBackgroundColor,
      appBar: CustomAppbar(
        title: '服务器设置'.tr,
      ),
      body: ListView(
//        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ValidPermission(
              permissions: [
                Permission.MANAGE_GUILD,
              ],
              builder: (value, isOwner) {
                final canTap = value;
                return FadeBackgroundButton(
                  tapDownBackgroundColor:
                      _theme.backgroundColor.withOpacity(0.5),
                  backgroundColor: _theme.backgroundColor,
                  onTap: canTap
                      ? () {
                          Routes.push(
                              context,
                              GuildEditInfoPage(
                                guildId: widget.guildId,
                              ),
                              guildEditInfoRoute);
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GuildIcon(
                              target,
                              size: 80,
                              fontSize: 30,
                            ),
                            const Expanded(child: sizedBox),
                            if (!value) const SizedBox() else const MoreIcon()
                          ],
                        ),
                        sizeHeight16,
                        Row(
                          children: <Widget>[
                            if (certificationProfile != null)
                              CertificationIcon(
                                profile: certificationProfile,
                                margin: const EdgeInsets.only(right: 8),
                                showShadow: true,
                              ),
                            Expanded(
                              child: Text(
                                target.name,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              }),
          ValidPermission(
              permissions: [
                Permission.MANAGE_GUILD,
                // Permission.MANAGE_GUILD_EDIT
              ],
              builder: (value, isOwner) {
                if (!value) return const SizedBox();
                return _buildSubtitle('服务器'.tr);
              }),
//          ValidPermission(
//              permissions: [Permission.MANAGE_GUILD_EDIT],
//              builder: (value, isOwner) {
//                if (!value) return const SizedBox();
//                return LinkTile(
//                  context,
//                  Text(Permission.MANAGE_GUILD_EDIT.name1),
//                  onTap: () {
//                    Routes.pushGuildModifyPage(context, widget.guildId);
//                  },
//                );
//              }),
          ValidPermission(
              permissions: [Permission.MANAGE_GUILD],
              builder: (value, isOwner) {
                if (!value) return const SizedBox();

                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      LinkTile(
                        context,
                        Text(Permission.MANAGE_GUILD.name1.tr),
                        height: 56,
                        onTap: () {
                          Routes.pushGuildManagePage(context);
                        },
                      ),
                      LinkTile(
                        context,
                        Text('服务器数据'.tr),
                        height: 56,
                        onTap: () {
                          Routes.pushGuildOptDataPage(context, widget.guildId);
                        },
                      )
                    ]);

                // return LinkTile(
                //   context,
                //   Text(Permission.MANAGE_GUILD.name1),
                //   height: 56,
                //   onTap: () {
                //     Routes.pushGuildManagePage(context);
                //   },
                // );
              }),
          ValidPermission(
              permissions: [Permission.MANAGE_EMOJIS],
              builder: (value, isOwner) {
                if (!value) return const SizedBox();
                return LinkTile(
                  context,
                  Text(Permission.MANAGE_EMOJIS.name1.tr),
                  height: 56,
                  onTap: () {
                    Routes.pushGuildEmoManagePage(context, widget.guildId);
                  },
                );
              }),
          ValidPermission(
              permissions: [Permission.MANAGE_GUILD],
              builder: (value, isOwner) {
                if (!value) return const SizedBox();
                return LinkTile(
                  context,
                  Text("设置欢迎页".tr),
                  height: 56,
                  onTap: () {
                    Get.toNamed(app_pages.Routes.WELCOME_SETTING,
                        parameters: {"guild_id": widget.guildId ?? ''});
                  },
                );
              }),
          ValidPermission(
              permissions: [Permission.MANAGE_GUILD],
              builder: (value, isOwner) {
                if (!value) return const SizedBox();
                return LinkTile(
                  context,
                  Text("游客模式".tr),
                  height: 56,
                  onTap: () {
                    Get.toNamed(app_pages.Routes.GUEST,
                        parameters: {"guild_id": widget.guildId ?? ''});
                  },
                );
              }),
          ValidPermission(
            permissions: [Permission.MANAGE_CHANNELS],
            builder: (value, isOwner) {
              if (!value) return const SizedBox();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildSubtitle('频道'.tr),
                  LinkTile(
                    context,
                    Text(Permission.MANAGE_CHANNELS.name1.tr),
                    height: 56,
                    onTap: () {
                      Get.toNamed(app_pages.Routes.GUILD_CHANNEL_SETTINGS);
                    },
                  ),
                ],
              );
            },
          ),

          ValidPermission(
              permissions: [
                Permission.MANAGE_ROLES,
                Permission.MUTE,
              ],
              builder: (value, isOwner) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Visibility(
                      visible: value || isOwner,
                      child: _buildSubtitle('用户'.tr),
                    ),
                    ValidPermission(
                        permissions: [Permission.MANAGE_ROLES],
                        builder: (value, isOwner) {
                          if (!value) return const SizedBox();
                          return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                LinkTile(
                                  context,
                                  Text(Permission.MANAGE_ROLES.name1.tr),
                                  height: 56,
                                  onTap: () {
                                    Get.toNamed(
                                      app_pages.Routes.GUILD_ROLE_MANAGER,
                                      arguments: widget.guildId,
                                    );
                                  },
                                ),
                                LinkTile(
                                  context,
                                  Text('管理成员'.tr),
                                  height: 56,
                                  onTap: () {
                                    Routes.pushMemberManagePage(
                                        context, widget.guildId);
                                  },
                                ),
                                ValidPermission(
                                  permissions: [
                                    Permission.ADMIN,
                                  ],
                                  builder: (isAllowed, isOwner) {
                                    if (!isAllowed) return const SizedBox();
                                    return LinkTile(
                                      context,
                                      Text('管理邀请链接'.tr),
                                      height: 56,
                                      onTap: () {
                                        Routes.pushMemberManageInvitePage(
                                            context, widget.guildId);
                                      },
                                    );
                                  },
                                ),
                                LinkTile(
                                  context,
                                  Text('黑名单'.tr),
                                  height: 56,
                                  onTap: () {
                                    Routes.pushBlackListPage(
                                        context, widget.guildId);
                                  },
                                ),
                              ]);
                        }),
                    ValidPermission(
                        permissions: [Permission.MUTE],
                        builder: (value, isOwner) {
                          if (!value) return const SizedBox();
                          return LinkTile(
                            context,
                            Text('禁言名单'.tr),
                            height: 56,
                            onTap: () {
                              Get.toNamed(
                                app_pages.Routes.MUTE_LIST_PAGE,
                                arguments: {'guildId': widget.guildId},
                              );
                            },
                          );
                        }),
                  ],
                );
              }),

//          TextLinkTile(
//            context,
//            '角色'.tr,
//            onTap: () {
//              Routes.pushRoleManagePage(context, widget.guildId);
//            },
//          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 14),
      ),
    );
  }
}
