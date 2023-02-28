import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';

class BotRequiredPermissions extends StatefulWidget {
  final int permissions;
  const BotRequiredPermissions({Key key, @required this.permissions})
      : super(key: key);

  @override
  _BotRequiredPermissionsState createState() => _BotRequiredPermissionsState();
}

class _BotRequiredPermissionsState extends State<BotRequiredPermissions> {
  List<String> _permissions;
  @override
  void initState() {
    _permissions = buffPermissions
        .where((element) => (widget.permissions & element.value) > 0)
        .map((e) => e.name1)
        .toList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        sizeHeight24,
        Text(
          '机器人所需权限'.tr,
          style: Get.textTheme.bodyText2
              .copyWith(fontSize: 20, fontWeight: FontWeight.w500),
        ),
        sizeHeight12,
        Text('添加机器人将授权机器人获得以下权限：'.tr,
            style: Get.textTheme.bodyText1
                .copyWith(color: const Color(0xFF5C6273))),
        sizeHeight24,
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 180),
          child: Column(
            children: _permissions.map(_buildPermissionItem).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionItem(String e) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor,
            ),
          ),
          sizeWidth12,
          Expanded(
            child: Text(
              e ?? '',
              style: Get.textTheme.bodyText2.copyWith(fontSize: 14),
            ),
          )
        ],
      ),
    );
  }
}
