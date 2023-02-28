import 'package:get/get.dart';
import 'package:im/app/modules/system_permission_setting_page/controllers/system_permission_setting_controller.dart';

/// 描述：系统隐私权限设置
///
/// author: seven.cheng
/// date: 2022/3/1 10:52 上午
class SystemPermissionSettingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SystemPermissionSettingController>(
      () => SystemPermissionSettingController(),
    );
  }
}
