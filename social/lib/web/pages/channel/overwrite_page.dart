import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/extension/widget_extension.dart';
import 'package:im/web/pages/channel/model/channel_permission_model.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';

class OverwritePage extends StatefulWidget {
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

class _OverwritePageState extends State<OverwritePage> {
  ThemeData _theme;
  ChannelPermissionModel _model;

  /// 可以修改的权限类型
  List<PermissionType> _permissionTypes;

  /// 是否圈子话题频道
  bool get isCirCleTopic =>
      widget.channel?.type == ChatChannelType.guildCircleTopic;

  @override
  void initState() {
    super.initState();
    _permissionTypes = _permissionTypesOfChannelType();
  }

  List<PermissionType> _permissionTypesOfChannelType() {
    final channelType = widget.channel.type;
    final List<PermissionType> list = [];
    if (!isCirCleTopic) list.add(PermissionType.general);
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

  @override
  Widget build(BuildContext context) {
    _model ??= Provider.of<ChannelPermissionModel>(context, listen: false);
    _theme = Theme.of(context);
    return Builder(builder: (
      context,
    ) {
      if (_model.editingOverwrite == null) {
        delay(() {
          showToast('该频道权限已被删除'.tr);
          Routes.pop(context);
        });
        return const SizedBox();
      }
      final List<Widget> slivers = [];
      canOverwritePermissions.entries.forEach((e) {
        // 去掉不相关的权限
        if (!_permissionTypes.contains(e.key)) return;

        final List<Permission> permissions = e.value
            .where((element) => !(_model.isEveryone &
                PermissionUtils.isEveryoneDisablePermission(element)))
            .toList();
        slivers.add(SliverToBoxAdapter(
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              _getClassifyText(e.key),
              style: _theme.textTheme.bodyText2
                  .copyWith(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ));
        slivers.addAll(permissions.map((e) => SliverToBoxAdapter(
              child: _buildItem(e),
            )));
      });
      return Scrollbar(
        child: CustomScrollView(
                physics: const ClampingScrollPhysics(), slivers: slivers)
            .addWebPaddingBottom(),
      );
    });
  }

  Widget _buildItem(Permission p) {
    final bool hasPermission =
        PermissionUtils.oneOf(_model.gp, [p], channelId: widget.channel.id);

    // // everyOne角色的 VIEW_CHANNEL 权限
    // final bool isEveryOneViewChannelPermission =
    //     p.value == Permission.VIEW_CHANNEL.value &&
    //         _model.overwrite.id == _model.gp.guildId;
    // // 公开频道的 VIEW_CHANNEL 权限
    // final bool isPubChannelViewChannelPermission =
    //     p.value == Permission.VIEW_CHANNEL.value &&
    //         !PermissionUtils.isPrivateChannel(_model.gp, widget.channelId);

    final bool disabled = !hasPermission;
    // ||
    // isEveryOneViewChannelPermission ||
    // isPubChannelViewChannelPermission

    const Widget divider = SizedBox(
      height: 32,
      width: 0.5,
      child: VerticalDivider(
        thickness: 0.5,
        color: Colors.white,
      ),
    );
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _theme.backgroundColor),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Row(children: <Widget>[
                  _buildPermissionButtons(
                      permission: p,
                      overwrite: _model.editingOverwrite,
                      builder: (value) => Opacity(
                            opacity: disabled ? 0.6 : 1,
                            child: Row(
                              children: <Widget>[
                                _buildIconButton(
                                  icon: Icons.close,
                                  selectedColor: const Color(0xFFF24848),
                                  selected: value == 0,
                                  onTap: disabled
                                      ? null
                                      : () =>
                                          _model.onChange(0, p, hasPermission),
                                ),
                                divider,
                                _buildIconButton(
                                  icon: Icons.edit,
                                  selectedColor: _theme.primaryColor,
                                  selected: value == -1,
                                  onTap: disabled
                                      ? null
                                      : () =>
                                          _model.onChange(-1, p, hasPermission),
                                ),
                                divider,
                                _buildIconButton(
                                  icon: Icons.check,
                                  selectedColor: const Color(0xFF3EB382),
                                  selected: value == 1,
                                  onTap: disabled
                                      ? null
                                      : () =>
                                          _model.onChange(1, p, hasPermission),
                                ),
                              ],
                            ),
                          ))
                ]),
              )
            ],
          ),
        ),
        Divider(
            indent: 16,
            endIndent: 16,
            color: const Color(0xFFDEE0E3).withOpacity(0.5))
      ],
    );
  }

  // 0 拒绝  -1 继承 1允许
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
    final specColor = const Color(0xFF8F959E).withOpacity(0.2);
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: 32,
        height: 32,
        color: selected
            ? (disabled ? selectedColor.withOpacity(0.4) : selectedColor)
            : specColor,
        child: GestureDetector(
          child: Icon(
            icon,
            size: 16,
            color: disabled ? Colors.white.withOpacity(0.4) : Colors.white,
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
      case PermissionType.voice:
        return '语音频道权限'.tr;
      case PermissionType.topic:
        return '话题权限'.tr;
      default:
        return '';
    }
  }
}
