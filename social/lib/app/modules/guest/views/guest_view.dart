import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/link_tile.dart';

import '../controllers/guest_controller.dart';

class GuestView extends GetView<GuestController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(
        title: '游客模式'.tr,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          LinkTile(
            context,
            Text(
              '游客模式'.tr,
            ),
            height: 56,
            showTrailingIcon: false,
            trailing: Transform.scale(
              scale: 0.9,
              alignment: Alignment.centerRight,
              child: ObxValue<RxBool>((v) {
                return CupertinoSwitch(
                    activeColor: Theme.of(context).primaryColor,
                    value: v.value,
                    onChanged: (v) {
                      controller.changeState();
                    });
              }, controller.isOpen),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Text(
              '开启后，新加入服务器的成员将处于「游客」状态，请添加Fanbot机器人配置「新成员验证」，完成管理者设置的验证步骤后，新成员将会被自动分配角色，成为正式成员'
                  .tr,
              style:
                  Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
