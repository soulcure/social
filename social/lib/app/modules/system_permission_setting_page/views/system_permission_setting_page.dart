import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:im/api/entity/system_permission_bean.dart';
import 'package:im/app/modules/system_permission_setting_page/controllers/system_permission_setting_controller.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/button/more_icon.dart';

import '../../../../icon_font.dart';

/// 描述：系统隐私权限设置
///
/// author: seven.cheng
/// date: 2022/3/1 10:47 上午
class SystemPermissionSettingPage extends StatefulWidget {
  const SystemPermissionSettingPage({Key key}) : super(key: key);

  @override
  _SystemPermissionSettingState createState() =>
      _SystemPermissionSettingState();
}

class _SystemPermissionSettingState extends State<SystemPermissionSettingPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed &&
        Get.isRegistered<SystemPermissionSettingController>()) {
      GetInstance()
          .find<SystemPermissionSettingController>()
          .updatePermissionEnable();
    }
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(
        backgroundColor: Colors.white,
        title: '隐私权限设置'.tr,
        leadingIcon: IconFont.buffNavBarBackItemNew,
      ),
      backgroundColor: appThemeData.scaffoldBackgroundColor,
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return GetBuilder<SystemPermissionSettingController>(builder: (controller) {
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: appThemeData.dividerColor),
            child: Text(
              '为了提供更好的用户体验，Fanbook会在特定的使用场景下向你申请对应的系统权限。'.tr,
              style: Get.textTheme.bodyText1.copyWith(
                fontSize: 14,
                color: appThemeData.disabledColor,
              ),
            ),
          ),
          sizeHeight12,
          Expanded(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              children: controller.permissionList
                  .map((e) => _buildPermissionItem(e, controller))
                  .toList(),
            ),
          ),
        ],
      );
    });
  }

  /// - 构建每条item
  Widget _buildPermissionItem(SystemPermissionBean permissionBean,
      SystemPermissionSettingController controller) {
    return GestureDetector(
      onTap: () {
        // 跳转到应用权限设置界面
        controller.openPermissionSetting(context, permissionBean);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  permissionBean.permissionName,
                  style: appThemeData.textTheme.bodyText2,
                ),
                Expanded(child: Container()),
                Text(
                  permissionBean.permissionEnable ? '已开启' : '去设置',
                  style: Get.textTheme.bodyText1.copyWith(
                    color: Get.theme.disabledColor.withOpacity(0.75),
                    fontSize: 15,
                  ),
                ),
                const MoreIcon(),
              ],
            ),
            if (permissionBean.permissionContent != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                child: Text(
                  permissionBean.permissionContent,
                  style: Get.textTheme.bodyText1.copyWith(
                    color: Get.theme.disabledColor,
                    fontSize: 14,
                  ),
                ),
              )
            else
              Container(),
          ],
        ),
      ),
    );
  }
}
