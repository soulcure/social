import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/role/role.dart';

class RoleIcon extends StatelessWidget {
  final Role role;
  final double size;
  const RoleIcon(this.role, {Key key, this.size = 30}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final roleIcon =
        role.managed ? IconFont.buffBotIconColor : IconFont.buffRoleIconColor;
    return Icon(roleIcon,
        size: size,
        color: role.color != 0
            ? Color(role.color)
            : Get.textTheme.bodyText1.color);
  }
}
