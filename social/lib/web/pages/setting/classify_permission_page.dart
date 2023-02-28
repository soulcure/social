import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/pages/guild_setting/role/color_picker.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/themes/const.dart';
import 'package:im/web/extension/widget_extension.dart';
import 'package:im/web/pages/setting/model/role_manage_model.dart';
import 'package:im/widgets/custom_inputbox_web.dart';
import 'package:im/widgets/link_tile.dart';
import 'package:provider/provider.dart';

class ClassifyPermissionPage extends StatefulWidget {
  final String guildId;
  final Role role;
  const ClassifyPermissionPage({
    @required this.role,
    @required this.guildId,
  });

  @override
  _ClassifyPermissionPageState createState() => _ClassifyPermissionPageState();
}

class _ClassifyPermissionPageState extends State<ClassifyPermissionPage> {
  ThemeData _theme;
  RoleManageModel _model;
  ScrollController _scrollController;

  @override
  void initState() {
    _scrollController = ScrollController();
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _model ??= Provider.of<RoleManageModel>(context, listen: false);

    final role = _model.editingRole;
    if (role == null) return const SizedBox();
    _theme = Theme.of(context);
    Color getRoleColor(Role role) {
      return (role.color == 0 || role.color == null)
          ? _theme.textTheme.bodyText2.color
          : Color(role.color);
    }

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '角色名称'.tr,
                  style: _theme.textTheme.bodyText2,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: sizeHeight16,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: WebCustomInputBox(
                  fillColor: Colors.transparent,
                  controller: _model.nameController,
                  readOnly: _model.isEveryone,
                  hintText: '请输入角色名称'.tr,
                  textColor: getRoleColor(role),
                  maxLength: 30,
                  onChange: (val) {
                    _model.changeName(val);
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: sizeHeight24,
            ),
            if (!_model.isEveryone) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '角色颜色'.tr,
                    style: _theme.textTheme.bodyText2,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: sizeHeight12),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ColorPicker(
                    value: _model.editingRole.color,
                    crossAxisCount: 14,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 15,
                    onPickColor: _model.changeColor,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: sizeHeight12),
            SliverToBoxAdapter(child: _buildSubtitle('通用权限'.tr)),
            SliverList(
                delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildItem(_model.generalPermissions[index], index);
              },
              childCount: _model.generalPermissions.length,
            )),
            SliverToBoxAdapter(
              child: _buildSubtitle('文字频道权限'.tr),
            ),
            SliverList(
                delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildItem(_model.textPermissions[index], index);
              },
              childCount: _model.textPermissions.length,
            )),
            SliverToBoxAdapter(
              child: _buildSubtitle('语音频道权限'.tr),
            ),
            SliverList(
                delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildItem(_model.audioPermissions[index], index);
              },
              childCount: _model.audioPermissions.length,
            )),
            SliverToBoxAdapter(
              child: _buildSubtitle('圈子权限'.tr),
            ),
            SliverList(
                delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildItem(_model.circlePermissions[index], index);
              },
              childCount: _model.circlePermissions.length,
            )),
          ],
        ).addWebPaddingBottom(),
      );
  }

  Widget _buildSubtitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: _theme.textTheme.bodyText2
            .copyWith(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildItem(Permission p, int index) {
    final bool hasPermission =
        PermissionUtils.oneOf(_model.guildPermission, [p]);
    final bool disabled = !hasPermission;

    return Column(
      children: [
        LinkTile(
          context,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                p.name1,
                style: TextStyle(
                    fontSize: 14,
                    color: disabled
                        ? _theme.textTheme.bodyText2.color.withOpacity(0.4)
                        : _theme.textTheme.bodyText2.color),
              ),
              if (p.desc1.isNotEmpty) sizeHeight5,
              if (p.desc1.isNotEmpty)
                Text(
                  p.desc1,
                  style: _theme.textTheme.bodyText1.copyWith(fontSize: 12),
                )
            ],
          ),
          showTrailingIcon: false,
          trailing: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Opacity(
                opacity: disabled ? 0.4 : 1,
                child: Transform.scale(
                  scale: 0.7,
                  alignment: Alignment.topCenter,
                  child: CupertinoSwitch(
                      activeColor: Theme.of(context).primaryColor,
                      value: _model.editingRole.permissions & p.value != 0,
                      onChanged: (v) =>
                          _model.changePermission(v, p, hasPermission)),
                ),
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
}
