import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/db/db.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/member_list/model/member_list_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/web/extension/widget_extension.dart';
import 'package:im/web/pages/channel/overwrite_page.dart';
import 'package:im/web/utils/show_web_tooltip.dart';
import 'package:im/web/widgets/button/web_hover_button.dart';
import 'package:im/web/widgets/web_form_detector/web_form_detector_model.dart';
import 'package:im/widgets/avatar.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:provider/provider.dart';

import 'model/channel_permission_model.dart';

class ChannelPermissionPage extends StatefulWidget {
  final ChatChannel channel;

  const ChannelPermissionPage(this.channel);

  @override
  _ChannelPermissionPageState createState() => _ChannelPermissionPageState();
}

class _ChannelPermissionPageState extends State<ChannelPermissionPage>
    with TickerProviderStateMixin {
  ThemeData _theme;
  ChannelPermissionModel _model;

  @override
  void initState() {
    _model = ChannelPermissionModel(context, widget.channel);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Provider.of<WebFormDetectorModel>(context, listen: false)
          .setCallback(onReset: _model.onReset, onConfirm: _model.onConfirm);
    });
    super.initState();
  }

  @override
  void dispose() {
    _model.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _theme = Theme.of(context);
    return ChangeNotifierProvider.value(
        value: _model,
        builder: (context, snapshot) {
          return Consumer<ChannelPermissionModel>(
              builder: (context, model, widget) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 180,
                  child: Scrollbar(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: CustomScrollView(
                        physics: const ClampingScrollPhysics(),
                        slivers: <Widget>[
                          SliverToBoxAdapter(
                            child: Row(
                              children: [
                                Text(
                                  '角色/成员'.tr,
                                  style: _theme.textTheme.bodyText2.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                                spacer,
                                Builder(
                                  builder: (context) {
                                    return GestureDetector(
                                      onTap: () {
                                        pickRoleOrMember(context);
                                      },
                                      child: Icon(
                                        Icons.add_circle_outline,
                                        color:
                                            CustomColor(context).disableColor,
                                        size: 18,
                                      ),
                                    ).clickable();
                                  },
                                )
                              ],
                            ),
                          ),
                          const SliverToBoxAdapter(
                            child: sizeHeight16,
                          ),
                          SliverList(
                            delegate: SliverChildListDelegate(
                              _buildRoleOrMemberList(
                                  [..._model.roleList, ..._model.memberList]),
                            ),
                          ),
                        ],
                      ).addWebPaddingBottom(),
                    ),
                  ),
                ),
                Expanded(
                    child: OverwritePage(
                  channel: _model.channel,
                  overwriteId: _model.editingOverwrite.id,
                ))
              ],
            );
          });
        });
  }

  List<Widget> _buildRoleOrMemberList(List<PermissionOverwrite> overwrites) {
    final List<Widget> widgetList = [];
    overwrites.forEach((e) {
      switch (e.actionType) {
        case 'user':
          widgetList.add(_buildMemberItem(e));
          break;
        case 'role':
          widgetList.add(_buildRoleItem(e));
          break;
      }
      widgetList.add(const SizedBox(height: 2));
    });
    return widgetList;
  }

  Color getRoleColor(Role role, bool isSelected) {
    // if (isSelected) {
    //   return (role.color == 0 || role.color == null)
    //       ? _theme.textTheme.bodyText2.color
    //       : Colors.white;
    // }
    return (role.color == 0 || role.color == null)
        ? _theme.textTheme.bodyText2.color
        : Color(role.color);
  }

  Color getRoleBgColor(Role role) {
    return const Color(0xFFDEE0E3);
  }

  Widget _buildRoleItem(PermissionOverwrite overwrite) {
    Color color;
    Color hoverColor;
    Color textColor;
    final Role role = _model.gp.roles.firstWhere(
        (element) => element.id == overwrite.id,
        orElse: () => null);
    final bool isEveryone = overwrite.id == _model.gp.guildId;
    final isSelected = _model.editingOverwrite.id == overwrite.id;
    if (isSelected) {
      color = hoverColor = getRoleBgColor(role);
    } else {
      color = Colors.transparent;
      hoverColor = getRoleBgColor(role).withOpacity(0.5);
    }
    textColor = getRoleColor(role, isSelected);

    final bool isHigherRole =
        PermissionUtils.comparePosition(roleIds: [role.id]) == 1;

    return WebHoverButton(
      height: 35,
      color: color,
      hoverColor: hoverColor,
      borderRadius: 4,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      onTap: () {
        if (!isHigherRole) {
          showToast('只能设置比自己当前角色等级低的角色╮(╯▽╰)╭'.tr);
          return;
        }
        _model.toggleOverwrite(overwrite.id);
      },
      builder: (isHover, child) {
        final showDeleteIcon =
            isHigherRole && !isEveryone && (isSelected || isHover);
        return Row(
          children: <Widget>[
            Expanded(
              child: Text(
                role?.name ?? '',
                overflow: TextOverflow.ellipsis,
                style: _theme.textTheme.bodyText2.copyWith(color: textColor),
                maxLines: 1,
              ),
            ),
            spacer,
            if (!isHigherRole)
              Icon(
                IconFont.buffChannelLock,
                size: 16,
                color: CustomColor(context).disableColor,
              ),
            if (showDeleteIcon)
              GestureDetector(
                onTap: () => _onDelete(overwrite),
                child: const Icon(
                  IconFont.buffCommonDeleteRed,
                  size: 16,
                  color: DefaultTheme.dangerColor,
                ),
              )
          ],
        );
      },
    );
  }

  Widget _buildMemberItem(PermissionOverwrite overwrite) {
    Color color;
    Color hoverColor;
    final isSelected = _model.editingOverwrite.id == overwrite.id;
    if (isSelected) {
      color = hoverColor = const Color(0xFFDEE0E3);
    } else {
      color = Colors.transparent;
      hoverColor = const Color(0xFFDEE0E3).withOpacity(0.5);
    }
    return UserInfo.consume(
      overwrite.id,
      builder: (context, user, widget) {
        final bool isHigherRole =
            PermissionUtils.comparePosition(roleIds: user.roles) == 1;
        return WebHoverButton(
          height: 35,
          color: color,
          hoverColor: hoverColor,
          borderRadius: 4,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          onTap: () {
            if (!isHigherRole) {
              showToast('只能设置比自己当前角色等级低的成员╮(╯▽╰)╭'.tr);
              return;
            }
            _model.toggleOverwrite(overwrite.id);
          },
          builder: (isHover, child) {
            final showDeleteIcon = isHigherRole && (isSelected || isHover);
            return Row(
              children: <Widget>[
                Avatar(url: user.avatar, radius: 12),
                sizeWidth10,
                Expanded(
                  child: Text(
                    user.nickname,
                    overflow: TextOverflow.ellipsis,
                    style: _theme.textTheme.bodyText2,
                  ),
                ),
                if (!isHigherRole)
                  Icon(
                    IconFont.buffChannelLock,
                    size: 14,
                    color: CustomColor(context).disableColor,
                  ),
                if (showDeleteIcon)
                  GestureDetector(
                    onTap: () => _onDelete(overwrite),
                    child: const Icon(
                      IconFont.buffCommonDeleteRed,
                      size: 16,
                      color: DefaultTheme.dangerColor,
                    ),
                  )
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _onDelete(PermissionOverwrite overwrite) async {
    final overwriteName = await _model.getOverwriteName(overwrite.id);
    final String content = overwrite.actionType == 'user'
        ? '确定将 %s 删除？删除后，在该频道下，该成员的权限将按角色重新计算，一旦删除不可撤销。'.trArgs([overwriteName])
        : '确定将 %s 删除？删除后，在该频道下，该角色的权限将继承服务器，一旦删除不可撤销。'.trArgs([overwriteName]);
    final res = await showConfirmDialog(
      title: '删除%s'.trArgs([overwriteName]),
      content: content,
    );
    if (res) {
      unawaited(_model.removeOverwrite(overwrite));
    }
  }

  Future pickRoleOrMember(BuildContext context) async {
    final overwrite = await showWebTooltip<PermissionOverwrite>(context,
        offsetX: -75,
        offsetY: 15,
        builder: (context, done) => _buildPickList(done));
    if (overwrite == null) return;
    await PermissionModel.updateOverwrite(overwrite);
  }

  Widget _buildPickList(Function done) {
    Color _getRoleColor(Role role) {
      return (role.color == 0 || role.color == null)
          ? _theme.textTheme.bodyText2.color
          : Color(role.color);
    }

    final roles = PermissionModel.getPermission(
            ChatTargetsModel.instance.selectedChatTarget.id)
        .roles
        .where((role) => !_model.roleList.map((e) => e.id).contains(role.id));
    final members = MemberListModel.instance.fullList
        .where((user) => !_model.memberList.map((e) => e.id).contains(user));
    final List<Widget> items = [];
    items.add(Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Text(
        '角色'.tr,
        style: _theme.textTheme.bodyText1.copyWith(fontSize: 12),
      ),
    ));
    items.add(divider);
    items.addAll(roles.map((e) {
      final hasPermission =
          PermissionUtils.comparePosition(roleIds: [e.id]) == 1;
      final noPermissionTip = '😑 只能设置比自己当前角色等级低的角色'.tr;
      return WebHoverButton(
          align: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          hoverColor: Theme.of(context).disabledColor.withOpacity(0.2),
          borderRadius: 4,
          onTap: () {
            if (!hasPermission) {
              showToast(noPermissionTip);
              return;
            }
            final overwrite = PermissionOverwrite(
                id: e.id,
                channelId: widget.channel.id,
                guildId: _model.gp.guildId,
                actionType: 'role',
                allows: 0,
                deny: 0,
                name: e.name);
            done(overwrite);
          },
          child: Row(
            children: [
              Expanded(
                child: Text(
                  e.name,
                  style: _theme.textTheme.bodyText2
                      .copyWith(fontSize: 14, color: _getRoleColor(e)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              spacer,
              if (!hasPermission)
                const Icon(
                  IconFont.buffChannelLock,
                  size: 14,
                )
            ],
          ));
    }));
    items.add(Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Text(
        '成员'.tr,
        style: _theme.textTheme.bodyText1.copyWith(fontSize: 12),
      ),
    ));
    items.add(divider);
    items.addAll(members.map(Db.userInfoBox.get).map((e) {
      bool hasPermission;
      if (PermissionUtils.isGuildOwner(userId: e.userId)) {
        hasPermission = false;
      } else {
        hasPermission = PermissionUtils.comparePosition(roleIds: e.roles) == 1;
      }
      final noPermissionTip = '😑 只能设置比自己当前角色等级低的成员'.tr;
      return WebHoverButton(
          align: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          borderRadius: 4,
          hoverColor: Theme.of(context).disabledColor.withOpacity(0.2),
          onTap: () {
            if (!hasPermission) {
              showToast(noPermissionTip);
              return;
            }
            final overwrite = PermissionOverwrite(
                id: e.userId,
                channelId: widget.channel.id,
                guildId: _model.gp.guildId,
                actionType: 'user',
                allows: 0,
                deny: 0,
                name: e.nickname);
            done(overwrite);
          },
          child: Row(
            children: [
              Expanded(
                child: Text(
                  e.nickname,
                  style: _theme.textTheme.bodyText2.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!hasPermission)
                const Icon(
                  IconFont.buffChannelLock,
                  size: 14,
                )
            ],
          ));
    }));
    return Scrollbar(
      child: Container(
          width: 180,
          constraints: const BoxConstraints(maxHeight: 400),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: ListView(
            physics: const ClampingScrollPhysics(),
            shrinkWrap: true,
            children: items,
          )),
    );
  }
}
