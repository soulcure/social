import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_mixin.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/channel/overwrite_model.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/user_info/realtime_nick_name.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:provider/provider.dart';

/// - 频道/圈子频道 权限覆盖设置
class OverwritePage extends StatefulWidget {
  String get channelId => channel.id;
  final ChatChannel channel;
  final String overwriteId;

  const OverwritePage({
    @required this.channel,
    @required this.overwriteId,
  });

  @override
  _OverwritePageState createState() => _OverwritePageState();
}

typedef PermissionJudgeBuilder = Widget Function(int value);

class _OverwritePageState extends State<OverwritePage>
    with GuildPermissionListener {
  ThemeData _theme;
  OverwriteModel _newModel;
  OverwriteModel _originModel;
  List<PermissionType> _permissionTypes;
  PermissionOverwrite originOverwrite;
  PermissionOverwrite newOverwrite;
  GuildPermission originGuildPermission;
  bool _loading = false;

  /// 是否圈子频道
  bool get isCirCleTopic =>
      widget.channel?.type == ChatChannelType.guildCircleTopic;

  @override
  void initState() {
    _newModel = OverwriteModel(context,
        overwriteId: widget.overwriteId, channel: widget.channel);
    _originModel = OverwriteModel(context,
        overwriteId: widget.overwriteId, channel: widget.channel);
    originOverwrite = _originModel.overwrite.copyWith(
        allows: _originModel.overwrite.allows,
        deny: _originModel.overwrite.deny);
    newOverwrite = _newModel.overwrite.copyWith(
        allows: _newModel.overwrite.allows, deny: _newModel.overwrite.deny);
    originGuildPermission = _originModel.guildPermission;

    _permissionTypes = _permissionTypesOfChannelType();

    addPermissionListener();

    super.initState();
  }

  @override
  void dispose() {
    _newModel.destroy();
    _originModel.destroy();
    disposePermissionListener();
    super.dispose();
  }

  @override
  String get guildPermissionMixinId =>
      ChatTargetsModel.instance.selectedChatTarget.id;

  @override
  void onPermissionChange() {
    final ChannelPermission channelPermission = guildPermission
        .channelPermission
        .firstWhere((element) => element.channelId == widget.channelId,
            orElse: () => null);
    final tempOverwrite = channelPermission?.overwrites?.firstWhere(
      (element) => element.id == widget.overwriteId,
      orElse: () => null,
    );
    setState(() {
      if (originOverwrite.allows != newOverwrite.allows ||
          originOverwrite.deny != newOverwrite.deny) {
        showToast('当前页面有修改，请重新编辑'.tr);

        originOverwrite.allows = tempOverwrite.allows;
        originOverwrite.deny = tempOverwrite.deny;
        newOverwrite.allows = tempOverwrite.allows;
        newOverwrite.deny = tempOverwrite.deny;
      } else {
        newOverwrite.allows = tempOverwrite.allows;
        newOverwrite.deny = tempOverwrite.deny;
      }
    });
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

  Future<bool> back() async {
    if (originOverwrite.allows != newOverwrite.allows ||
        originOverwrite.deny != newOverwrite.deny) {
      final res = await showConfirmDialog(
          title: '确定保存并退出？'.tr,
          confirmText: '确定'.tr,
          cancelText: '取消'.tr,
          confirmStyle: Theme.of(context)
              .textTheme
              .bodyText2
              .copyWith(fontSize: 16, color: primaryColor),
          barrierDismissible: true);
      if (res == null) return false;
      if (res == true) {
        await _onSave();
      } else {
        Get.back();
      }
    } else {
      Get.back();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    _theme = Theme.of(context);
    return WillPopScope(
      onWillPop: UniversalPlatform.isAndroid ? back : null,
      child: ChangeNotifierProvider.value(
          value: _newModel,
          builder: (context, snapshot) {
            return Consumer<OverwriteModel>(builder: (context, _model, _) {
              return Scaffold(
                appBar: CustomAppbar(
                  title: isCirCleTopic ? '圈子频道权限管理'.tr : '频道权限管理'.tr,
                  leadingCallback: () {
                    back();
                  },
                  actions: [
                    // if (newOverwrite.allows != originOverwrite.allows ||
                    //     newOverwrite.deny != originOverwrite.deny)
                    AppbarTextButton(
                      loading: _loading,
                      onTap: _onSave,
                      text: '保存'.tr,
                    )
                  ],
                ),
                body: Builder(builder: (
                  context,
                ) {
                  if (newOverwrite == null) {
                    delay(() {
                      showToast('该频道权限已被删除'.tr);
                      Routes.pop(context);
                    });
                    return const SizedBox();
                  }
                  return ListView(children: [
                    _buildTips(),
                    sizeHeight20,
                    _buildOverwriteName(),
                    ...canOverwritePermissions.entries.map((e) {
                      if (!_permissionTypes.contains(e.key)) return sizedBox;
                      List<Permission> permissions = e.value
                          .where((element) => !(_model.isEveryone &
                              PermissionUtils.isEveryoneDisablePermission(
                                  element)))
                          .toList();
                      if (isCirCleTopic && e.key == PermissionType.general) {
                        permissions = permissions
                            .where((element) => element.value == 1)
                            .toList();
                        permissions[0].desc2 = "拥有此权限的成员，可以通过分享的动态邀请好友加入服务器".tr;
                      }

                      /// 非文字频道和直播频道不需要显示直播权限开关
                      final type = widget.channel.type;
                      if (type != ChatChannelType.guildText &&
                          type != ChatChannelType.guildLive) {
                        permissions = permissions
                            .where((p) =>
                                p.value != Permission.CREATE_LIVE_ROOM.value)
                            .toList();
                      } else if (type == ChatChannelType.guildText) {
                        /// 全体成员频道不需要创建文档开关
                        permissions = permissions
                            .where((p) =>
                                p.value != Permission.CREATE_DOCUMENT.value)
                            .toList();
                      }
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                            child: Text(
                              _getClassifyText(e.key),
                              style: _theme.textTheme.bodyText1
                                  .copyWith(fontSize: 13),
                            ),
                          ),
                          ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) =>
                                  _buildItem(permissions[index]),
                              separatorBuilder: (context, index) => Divider(
                                    thickness: 0.5,
                                    indent: 16,
                                    color: const Color(0xFF8F959E)
                                        .withOpacity(0.15),
                                  ),
                              itemCount: permissions.length),
                        ],
                      );
                    }).toList()
                  ]);
                }),
              );
            });
          }),
    );
  }

  Widget _buildItem(Permission p) {
    final bool hasPermission =
        PermissionUtils.oneOf(_newModel.gp, [p], channelId: widget.channelId);
    // // everyOne角色的 VIEW_CHANNEL 权限
    // final bool isEveryOneViewChannelPermission =
    //     p.value == Permission.VIEW_CHANNEL.value &&
    //         newValue.id == _model.gp.guildId;
    // // 公开频道的 VIEW_CHANNEL 权限
    // final bool isPubChannelViewChannelPermission =
    //     p.value == Permission.VIEW_CHANNEL.value &&
    //         !PermissionUtils.isPrivateChannel(_model.gp, widget.channelId);

    final bool disabled = !hasPermission
        // ||
        // isEveryOneViewChannelPermission ||
        // isPubChannelViewChannelPermission
        ;

    const Widget divider = SizedBox(
      height: 32,
      width: 0.5,
      child: VerticalDivider(
        thickness: 0.5,
        color: Color(0xFFE0E2E6),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      color: _theme.backgroundColor,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  p.name2 ?? p.name1,
                  style: TextStyle(
                      color: _theme.textTheme.bodyText2.color
                          .withOpacity(disabled ? 0.6 : 1)),
                ),
                if (p.desc1.isNotEmpty) ...[
                  sizeHeight5,
                  Text(
                    p.desc2 ?? p.desc1,
                    style: TextStyle(
                        fontSize: 12,
                        color: _theme.textTheme.bodyText1.color
                            .withOpacity(disabled ? 0.6 : 1)),
                  )
                ] else
                  const SizedBox(),
              ],
            ),
          ),
          sizeWidth10,
          Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: const Color(0xFFE0E2E6),
                  width: 0.5,
                )),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Row(children: <Widget>[
                _buildPermissionButtons(
                    permission: p,
                    overwrite: newOverwrite,
                    builder: (value) => Opacity(
                          opacity: disabled ? 0.6 : 1,
                          child: Row(
                            children: <Widget>[
                              _buildIconButton(
                                icon: IconFont.buffChannelPermissionClose,
                                selectedColor: const Color(0xFFF24848),
                                selected: value == 0,
                                onTap: disabled
                                    ? null
                                    : () => _toggle(0, p, hasPermission),
                              ),
                              divider,
                              _buildIconButton(
                                icon: IconFont.buffChannelPermissionInherit,
                                selectedColor:
                                    const Color(0xFF8f959e).withOpacity(0.5),
                                selected: value == -1,
                                onTap: disabled
                                    ? null
                                    : () => _toggle(-1, p, hasPermission),
                              ),
                              divider,
                              _buildIconButton(
                                icon: IconFont.buffChannelPermissionOpen,
                                selectedColor: const Color(0xFF3EB382),
                                selected: value == 1,
                                onTap: disabled
                                    ? null
                                    : () => _toggle(1, p, hasPermission),
                              ),
                            ],
                          ),
                        ))
              ]),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _toggle(int val, Permission p, bool hasPermission) async {
    if (_loading) return;
    if (!hasPermission) {
      showToast('无法操作当前自己没有的权限'.tr);
      return;
    }

    // 拦截修改everyOne的频道可见性权限修改
    if (_newModel.isEveryone &&
        ((p.value & Permission.VIEW_CHANNEL.value) > 0)) {
      if (newOverwrite.deny & p.value & Permission.VIEW_CHANNEL.value > 0) {
        // 如果私密频道切公开，则需要展示二次确认
        final bool isConfirm = await showConfirmDialog(
          title: "确认将私密频道设为公开频道？".tr,
          content: "打开“查看频道”权限会将此频道转为公开频道，频道的消息将会对所有成员可见".tr,
        );
        if (isConfirm == null || !isConfirm) return;
      } else if (val == 0) {
        // 如果公开转私，则需要展示二次确认
        final bool isConfirm = await showConfirmDialog(
          title: "确认将公开频道设为私密频道？".tr,
          content: "关闭“查看频道”权限会将此频道转为私密频道，未赋予权限的角色和成员将无法查看".tr,
        );
        if (isConfirm == null || !isConfirm) return;
      }
    }

    setState(() {
      int newAllows = newOverwrite.allows;
      int newDeny = newOverwrite.deny;
      final int oldAllows = newOverwrite.allows;
      final int oldDeny = newOverwrite.deny;
      switch (val) {
        case 0:
          if (newOverwrite.deny & p.value > 0) return;
          if (newOverwrite.allows & p.value > 0) {
            newAllows = newOverwrite.allows & ~p.value;
            newDeny = newOverwrite.deny | p.value;
          } else {
            newDeny = newOverwrite.deny | p.value;
          }

          /// 临时用来计算权限
          final GuildPermission tempGuildPermission =
              PermissionModel.getPermission(originGuildPermission.guildId)
                  .deepCopy();

          final ChannelPermission channelPermission = tempGuildPermission
              .channelPermission
              .firstWhere((element) => element.channelId == widget.channelId,
                  orElse: () => null);
          final channelOverwrites = channelPermission?.overwrites?.firstWhere(
            (element) => element.id == widget.overwriteId,
            orElse: () => null,
          );

          channelOverwrites.allows = newAllows;
          channelOverwrites.deny = newDeny;
          final res = PermissionUtils.oneOf(tempGuildPermission, [p],
              channelId: widget.channelId);

          if (!res) {
            unawaited(showConfirmDialog(
              title: '不能修改此权限'.tr,
              confirmText: '我知道了'.tr,
              content: '一旦修改当前角色的该权限，可能将导致自己失去该权限。'.tr,
              showCancelButton: false,
            ));
            channelOverwrites.allows = oldAllows;
            channelOverwrites.deny = oldDeny;
            return;
          }

          break;
        case -1:
          if ((newOverwrite.deny & p.value) > 0) {
            newDeny = newOverwrite.deny & ~p.value;
          } else if (newOverwrite.allows & p.value > 0) {
            newAllows = newOverwrite.allows & ~p.value;
          }
          break;
        case 1:
          if (newOverwrite.allows & p.value > 0) return;
          if ((newOverwrite.deny & p.value) > 0) {
            newDeny = newOverwrite.deny & ~p.value;
            newAllows = newOverwrite.allows | p.value;
          } else {
            newAllows = newOverwrite.allows | p.value;
          }
          break;
        default:
      }

      newOverwrite = newOverwrite.copyWith(allows: newAllows, deny: newDeny);
    });
  }

  Widget _buildTips() {
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
              top: BorderSide(
            color: Color(0xFFE0E2E6),
            width: 0.5,
          ))),
      height: 81,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12),
            child: Row(
              children: [
                itemTipsWidget("选择".tr, IconFont.buffChannelPermissionOpen,
                    "：打开此权限；".tr, const Color(0xFF3EB382)),
                itemTipsWidget("选择".tr, IconFont.buffChannelPermissionClose,
                    "：关闭此权限。".tr, const Color(0xFFF24848)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 6),
            child: itemTipsWidget(
                "选择".tr,
                IconFont.buffChannelPermissionInherit,
                '：不单独设置此权限，以服务器中对应\n    角色权限设置为准。'.tr,
                const Color(0xFFE0E2E6)),
          ),
        ],
      ),
    );
  }

  Widget itemTipsWidget(String leadingString, IconData icon, String tailString,
      Color backgroundColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          leadingString,
          style: const TextStyle(
            color: Color(0xFF646A73),
            fontSize: 14,
          ),
        ),
        sizeWidth2,
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(1.5),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.white,
          ),
        ),
        Text(
          tailString,
          style: const TextStyle(
            color: Color(0xFF646A73),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildOverwriteName() {
    final overwrite = newOverwrite;
    Color textColor = _theme.textTheme.bodyText2.color;
    String displayName = '';
    if (overwrite.actionType == 'role') {
      final role = _newModel.gp.roles.firstWhere(
          (element) => element.id == overwrite.id,
          orElse: () => null);
      final int roleColorValue = role?.color;
      displayName = role?.name ?? '';
      if (roleColorValue != 0 && roleColorValue != null)
        textColor = Color(roleColorValue);
    }
    return Container(
      padding: const EdgeInsets.all(16),
      color: _theme.backgroundColor,
      child: Row(
        children: <Widget>[
          Expanded(
            child: (overwrite.actionType == 'user')
                ? RealtimeNickname(
                    userId: overwrite.id,
                    style:
                        _theme.textTheme.bodyText2.copyWith(color: textColor),
                  )
                : Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          displayName,
                          overflow: TextOverflow.ellipsis,
                          style: _theme.textTheme.bodyText2
                              .copyWith(color: textColor),
                        ),
                      ),
                    ],
                  ),
          ),
          sizeWidth10,
          if (isCirCleTopic)
            Text(
              '范围：%s'.trArgs([widget.channel?.name ?? '']),
              style: _theme.textTheme.bodyText1.copyWith(fontSize: 15),
            )
          else
            ChangeNotifierProvider.value(
                value: ChatTargetsModel.instance.selectedChatTarget,
                builder: (context, _) {
                  return Consumer<BaseChatTarget>(
                      builder: (context, target, _) {
                    final channel = (target as GuildTarget).channels.firstWhere(
                        (element) => element.id == widget.channelId,
                        orElse: () => null);
                    return Text(
                      '范围：%s'.trArgs([channel?.name ?? '']),
                      style: _theme.textTheme.bodyText1.copyWith(fontSize: 15),
                    );
                  });
                }),
        ],
      ),
    );
  }

  /// - 0 拒绝  -1 继承 1允许
  Widget _buildPermissionButtons(
      {@required Permission permission,
      @required PermissionOverwrite overwrite,
      @required PermissionJudgeBuilder builder}) {
    int value;
    if (permission.value & overwrite.deny > 0) {
      value = 0;
    } else if (permission.value & overwrite.allows > 0) {
      value = 1;
    } else {
      value = -1;
    }
    return builder(value);
  }

  Widget _buildIconButton(
      {@required IconData icon,
      Color selectedColor,
      bool selected = false,
      bool disabled = false,
      GestureTapCallback onTap}) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        color: selected ? selectedColor : Colors.white,
        width: 32,
        height: 32,
        child: GestureDetector(
          child: Icon(
            icon,
            size: 24,
            color: selected
                ? disabled
                    ? selectedColor
                    : Colors.white
                : selectedColor,
          ),
        ),
      ),
    );
  }

  String _getClassifyText(PermissionType type) {
    switch (type) {
      case PermissionType.general:
        return '通用权限'.tr;
      case PermissionType.text:
        return '文字频道权限'.tr;
      // case PermissionType.live:
      //   return '直播频道权限'.tr;
      case PermissionType.voice:
        return '语音频道权限'.tr;
      case PermissionType.topic:
        return '圈子频道权限'.tr;
      default:
        return '';
    }
  }

  Future<void> _onSave() async {
    final originAllows = originOverwrite.allows;
    final originDeny = originOverwrite.deny;

    try {
      _toggleLoading(true);

      originOverwrite.allows = newOverwrite.allows;
      originOverwrite.deny = newOverwrite.deny;
      await PermissionModel.updateOverwrite(newOverwrite,
          isCirclePermission: isCirCleTopic);

      _toggleLoading(false);
      Navigator.of(context).pop(newOverwrite);
    } catch (e) {
      originOverwrite.allows = originAllows;
      originOverwrite.deny = originDeny;
      newOverwrite.allows = originAllows;
      newOverwrite.deny = originDeny;
      _toggleLoading(false);
    }
  }

  void _toggleLoading(bool value) {
    setState(() {
      _loading = value;
    });
  }
}
