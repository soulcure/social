import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/channel/channel_permission_model.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/button/more_icon.dart';
import 'package:im/widgets/user_info/realtime_nick_name.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:provider/provider.dart';

/// - 频道/圈子频道 权限管理
class ChannelPermissionPage extends StatefulWidget {
  String get channelId => channel.id;

  final ChatChannel channel;

  const ChannelPermissionPage(this.channel);

  @override
  _ChannelPermissionPageState createState() => _ChannelPermissionPageState();
}

class _ChannelPermissionPageState extends State<ChannelPermissionPage>
    with TickerProviderStateMixin {
  ThemeData _theme;
  ChannelPermissionModel _model;
  final double _lineHeight = 48;
  List<PermissionType> _permissionTypes;

  ///是否圈子频道
  bool get isCirCleTopic =>
      widget.channel?.type == ChatChannelType.guildCircleTopic;

  @override
  void initState() {
    _model = ChannelPermissionModel(context, widget.channel);
    _permissionTypes = _permissionTypesOfChannelType();
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
            return Scaffold(
              appBar: CustomAppbar(
                leadingBuilder: (icon) {
                  return _model.editing
                      ? IconButton(
                          icon: Icon(
                            IconFont.buffNavBarCloseItem,
                            size: icon.size,
                            color: icon.color,
                          ),
                          onPressed: _model.toggleEdit)
                      : null;
                },
                title: isCirCleTopic ? '圈子频道权限管理'.tr : '频道权限管理'.tr,
                actions: [
                  AppbarTextButton(
                      text: _model.editing ? '完成'.tr : '编辑'.tr,
                      onTap: _model.toggleEdit)
                ],
              ),
              body: ListView(
                children: <Widget>[
                  AnimatedCrossFade(
                    sizeCurve: Curves.easeInOut,
                    duration: const Duration(milliseconds: 300),
                    firstChild: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '可按角色分配权限，再对成员覆盖设置，覆盖关系：成员>角色>全体成员；当同个成员属于多个角色，只有一个角色允许这项权限，则结果是允许。'
                                .tr,
                            style: Theme.of(context)
                                .textTheme
                                .bodyText1
                                .copyWith(fontSize: 13),
                          ),
                        ),
                        _buildAddButton('添加角色'.tr, 1, _model.roleList),
                        Divider(
                          indent: 45,
                          thickness: 0.5,
                          color: Theme.of(context).scaffoldBackgroundColor,
                        ),
                        _buildAddButton('添加成员'.tr, 2, _model.memberList),
                      ],
                    ),
                    secondChild: const SizedBox(),
                    crossFadeState: !_model.editing
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                  ),
                  Column(
                    children: <Widget>[
                      _buildRoleList(_model.roleList),
                      _buildMemberList(_model.memberList),
                    ],
                  ),
                ],
              ),
            );
          });
        });
  }

  Widget _buildSubtitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Text(
        title,
        style: _theme.textTheme.bodyText1.copyWith(fontSize: 13),
      ),
    );
  }

  Widget _buildAddButton(
      String title, int type, List<PermissionOverwrite> overwrites) {
    final filterIds = overwrites.map((e) => e.id).toList();
    return FadeBackgroundButton(
      backgroundColor: _theme.backgroundColor,
      tapDownBackgroundColor: _theme.backgroundColor.withOpacity(0.5),
      onTap: () => _addOverwrite(type, filterIds),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          const Icon(Icons.add),
          sizeWidth8,
          Text(title),
        ],
      ),
    );
  }

  Widget _buildRoleList(List<PermissionOverwrite> overwrites) {
    return Visibility(
      visible: overwrites.isNotEmpty,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSubtitle('角色权限设置'.tr),
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) => _buildRoleItem(overwrites[index]),
            separatorBuilder: (context, index) => Divider(
              indent: 16,
              thickness: 0.5,
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            itemCount: overwrites.length,
          ),
        ],
      ),
    );
  }

  Widget _buildMemberList(List<PermissionOverwrite> overwrites) {
    return Visibility(
      visible: overwrites.isNotEmpty,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSubtitle('成员权限设置'.tr),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) =>
                _buildMemberItem(overwrites[index]),
            separatorBuilder: (context, index) => Divider(
              indent: 16,
              thickness: 0.5,
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            itemCount: overwrites.length,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleItem(PermissionOverwrite overwrite) {
    final bool isEveryone = overwrite.id == _model.gp.guildId;
    final channel = widget.channel;
    final permissionNum =
        _computePermissionNum(overwrite, isEveryone, channelType: channel.type);
    Color textColor = _theme.textTheme.bodyText2.color;
    final Role role = _model.gp.roles.firstWhere(
        (element) => element.id == overwrite.id,
        orElse: () => null);
    final int roleColorValue = role?.color;
    if (roleColorValue != 0 && roleColorValue != null)
      textColor = Color(roleColorValue);
    final bool isHigherRole =
        PermissionUtils.comparePosition(roleIds: [role.id]) == 1;
    final Color color1 = _theme.backgroundColor;
    Color color2 = _theme.backgroundColor.withOpacity(0.5);
    if (_model.editing) {
      color2 = _theme.backgroundColor;
    }
    return FadeBackgroundButton(
      backgroundColor: color1,
      tapDownBackgroundColor: color2,
      onTap: () {
        if (_model.editing) return;
        if (!isHigherRole) {
          showToast('只能设置比自己当前角色等级低的角色╮(╯▽╰)╭'.tr);
          return;
        }
        Routes.pushOverwritePage(context, overwrite, channel);
      },
      child: Container(
        alignment: Alignment.centerLeft,
        height: _lineHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: <Widget>[
            AnimatedCrossFade(
              duration: isEveryone
                  ? const Duration(milliseconds: 1) // 全体成员不添加任何动画
                  : const Duration(milliseconds: 500),
              sizeCurve: Curves.fastOutSlowIn,
              secondChild: ((isEveryone || !isHigherRole) && _model.editing)
                  ? const SizedBox()
                  : Row(
                      children: <Widget>[
                        GestureDetector(
                          onTap: () => _onDelete(overwrite),
                          child: const Icon(
                            Icons.remove_circle,
                            size: 20,
                            color: DefaultTheme.dangerColor,
                          ),
                        ),
                        sizeWidth10,
                      ],
                    ),
              firstChild: SizedBox(
                height: _lineHeight,
              ),
              crossFadeState: !_model.editing
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              layoutBuilder:
                  (topChild, topChildKey, bottomChild, bottomChildKey) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      key: bottomChildKey,
                      left: 50,
                      top: 0,
                      right: 0,
                      bottom: 0,
                      child: bottomChild,
                    ),
                    Positioned(
                      key: topChildKey,
                      child: topChild,
                    ),
                  ],
                );
              },
            ),
            Flexible(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            role?.name ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: _theme.textTheme.bodyText2
                                .copyWith(color: textColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!_model.editing && isHigherRole)
              Row(
                children: <Widget>[
                  Text(
                    '允许%s，继承%s，禁止%s'.trArgs([
                      permissionNum[0].toString(),
                      permissionNum[1].toString(),
                      permissionNum[2].toString()
                    ]),
                    style: _theme.textTheme.bodyText1.copyWith(fontSize: 15),
                  )
                ],
              ),
            if (!isHigherRole) const Icon(IconFont.buffChannelLock),
            if (!_model.editing && isHigherRole) const MoreIcon(),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberItem(PermissionOverwrite overwrite) {
    const double lineHeight = 48;
    final channel = widget.channel;
    final permissionNum =
        _computePermissionNum(overwrite, false, channelType: channel.type);
    final Color color1 = _theme.backgroundColor;
    Color color2 = _theme.backgroundColor.withOpacity(0.5);
    if (_model.editing) {
      color2 = _theme.backgroundColor;
    }
    return UserInfo.consume(
      overwrite.id,
      builder: (context, user, widget) {
        final bool isHigherRole =
            PermissionUtils.comparePosition(roleIds: user.roles ?? []) == 1;
        return FadeBackgroundButton(
          backgroundColor: color1,
          tapDownBackgroundColor: color2,
          onTap: () {
            if (_model.editing) return;
            if (!isHigherRole) {
              showToast('只能设置比自己当前角色等级低的成员╮(╯▽╰)╭'.tr);
              return;
            }
            Routes.pushOverwritePage(context, overwrite, channel);
          },
          child: Container(
            alignment: Alignment.centerLeft,
            height: lineHeight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: <Widget>[
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 500),
                  sizeCurve: Curves.fastOutSlowIn,
                  secondChild: (!isHigherRole && _model.editing)
                      ? const SizedBox()
                      : Row(
                          children: <Widget>[
                            GestureDetector(
                              onTap: () => _onDelete(overwrite),
                              child: const Icon(
                                Icons.remove_circle,
                                size: 20,
                                color: DefaultTheme.dangerColor,
                              ),
                            ),
                            sizeWidth10,
                          ],
                        ),
                  firstChild: const SizedBox(
                    height: lineHeight,
                  ),
                  crossFadeState: !_model.editing
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  layoutBuilder:
                      (topChild, topChildKey, bottomChild, bottomChildKey) {
                    return Stack(
                      children: <Widget>[
                        Positioned(
                          key: bottomChildKey,
                          left: 50,
                          top: 0,
                          right: 0,
                          bottom: 0,
                          child: bottomChild,
                        ),
                        Positioned(
                          key: topChildKey,
                          child: topChild,
                        ),
                      ],
                    );
                  },
                ),
                Flexible(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                          child: Row(
                        children: <Widget>[
                          Avatar(url: user.avatar, radius: 16),
                          sizeWidth10,
                          Expanded(
                            child: RealtimeNickname(
                              userId: user.userId,
                              style: _theme.textTheme.bodyText2,
                              guildId: _model.gp.guildId,
                              showNameRule: ShowNameRule.remarkAndGuild,
                            ),
                          ),
                        ],
                      )),
                    ],
                  ),
                ),
                if (!_model.editing && isHigherRole)
                  Row(
                    children: <Widget>[
                      Text(
                        '允许%s，继承%s，禁止%s'.trArgs([
                          permissionNum[0].toString(),
                          permissionNum[1].toString(),
                          permissionNum[2].toString()
                        ]),
                        style:
                            _theme.textTheme.bodyText1.copyWith(fontSize: 15),
                      )
                    ],
                  ),
                if (!isHigherRole) const Icon(IconFont.buffChannelLock),
                if (!_model.editing && isHigherRole) const MoreIcon(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addOverwrite(int type, List<String> filterIds) {
    Routes.pushAddOverwritePage(context, widget.channel, type, filterIds);
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

  List<PermissionType> _permissionTypesOfChannelType() {
    final channelType = widget.channel.type;
    final List<PermissionType> list = [];
    // if (!isCirCleTopic) list.add(PermissionType.general);
    list.add(PermissionType.general);
    switch (channelType) {
      case ChatChannelType.guildText:
        list.add(PermissionType.text);
        break;
      // case ChatChannelType.guildLive:
      //   list.add(PermissionType.live);
      //   break;
      case ChatChannelType.guildVoice:
        list.add(PermissionType.voice);
        break;
      case ChatChannelType.guildCircleTopic:
        list.add(PermissionType.topic);
        break;
      default:
        break;
    }
    return list;
  }

  List<int> _computePermissionNum(
      PermissionOverwrite overwrite, bool isEveryone,
      {ChatChannelType channelType = ChatChannelType.guildText}) {
    final List<Permission> allPermissions = [
      ...canOverwritePermissions.entries
          .where((e) => _permissionTypes.contains(e.key))
          .map((e) {
            if (isCirCleTopic && e.key == PermissionType.general) {
              return e.value.where((permission) {
                if (permission.value ==
                    Permission.CREATE_INSTANT_INVITE.value) {
                  return true;
                }
                return false;
              }).toList();
            }

            return e.value;
          })
          .reduce((value, e) => [...value, ...e])
          .where((e) =>
              !(isEveryone & PermissionUtils.isEveryoneDisablePermission(e))),
    ];

    final int allowNum = allPermissions
        .where((element) => element.value & overwrite.allows > 0)
        .length;
    final int denyNum = allPermissions
        .where((element) => element.value & overwrite.deny > 0)
        .length;
    final int inheritNum = allPermissions.length - allowNum - denyNum;
    return [allowNum, inheritNum, denyNum];
  }
}
