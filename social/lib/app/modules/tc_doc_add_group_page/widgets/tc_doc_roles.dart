import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/tc_doc_add_group_page/controllers/tc_doc_add_group_page_controller.dart';
import 'package:im/app/modules/tc_doc_add_group_page/entities/tc_doc_group.dart';
import 'package:im/app/modules/tc_doc_add_group_page/widgets/tc_doc_group_mixin.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/guild_setting/role/role_icon.dart';
import 'package:im/themes/const.dart';

class TcDocRoles extends StatefulWidget {
  final TcDocAddGroupPageController controller;

  const TcDocRoles(this.controller);

  @override
  State<TcDocRoles> createState() => _TcDocRolesState();
}

class _TcDocRolesState extends State<TcDocRoles>
    with AutomaticKeepAliveClientMixin, TcDocGroupMixin {
  List<Role> _roles = [];

  @override
  void initState() {
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      final GuildPermission gp =
          PermissionModel.getPermission(widget.controller.guildId);
      setState(() {
        _roles = widget.controller.filterRoles(gp.rolesExcludeEveryone);
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView.separated(
      itemBuilder: (c, i) {
        return _buildItem(_roles[i]);
      },
      separatorBuilder: (c, i) => const Divider(
        thickness: 0.5,
        indent: 44,
      ),
      itemCount: _roles.length,
    );
  }

  Widget _buildItem(Role role) {
    return GestureDetector(
      onTap: () {
        widget.controller.toggleSelect(role.id, TcDocGroupType.role);
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: appThemeData.backgroundColor,
        child: Row(
          children: <Widget>[
            ...buildLeading(widget.controller, role.id, TcDocGroupType.role),
            RoleIcon(role),
            sizeWidth12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    role.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Get.textTheme.bodyText2
                        .copyWith(fontSize: 16, height: 1.25),
                  ),
                  // sizeHeight6,
                  // Row(
                  //   children: [
                  //     const Icon(IconFont.buffMembersNum,
                  //         size: 12, color: Color(0xFF747F8D)),
                  //     sizeWidth4,
                  //     Text(
                  //       '${role?.memberCount?.toString() ?? 0} 位成员',
                  //       style: Get.textTheme.bodyText1.copyWith(fontSize: 12),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
