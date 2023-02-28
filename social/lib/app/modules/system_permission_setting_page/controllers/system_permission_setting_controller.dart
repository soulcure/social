import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:im/api/entity/system_permission_bean.dart';
import 'package:im/pages/home/view/check_permission.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:permission_handler/permission_handler.dart';

/// 描述：系统隐私权限设置
///
/// author: seven.cheng
/// date: 2022/3/1 10:52 上午
class SystemPermissionSettingController extends GetxController {
  List<SystemPermissionBean> permissionList = [];

  @override
  void onInit() {
    super.onInit();
    _initData();
  }

  void _initData() {
    permissionList.add(SystemPermissionBean(
      permissionName: '相机权限'.tr,
      permissionType: Permission.camera,
      permissionContent: '用于拍照、录视频、扫一扫等'.tr,
    ));
    if (UniversalPlatform.isIOS) {
      // iOS 增加相册权限
      permissionList.add(SystemPermissionBean(
        permissionName: '相册权限'.tr,
        permissionType: Permission.photos,
        permissionContent: '用于发送或保存图片和视频'.tr,
      ));
    }
    permissionList.add(SystemPermissionBean(
      permissionName: '麦克风权限'.tr,
      permissionType: Permission.microphone,
      permissionContent: '用于发送语音消息及进行语音通话'.tr,
    ));
    permissionList.add(SystemPermissionBean(
      permissionName: '通知权限'.tr,
      permissionType: Permission.notification,
      permissionContent: '允许应用收到最新的消息提醒'.tr,
    ));

    if (UniversalPlatform.isAndroid) {
      // Android 特有的权限
      permissionList.add(SystemPermissionBean(
        permissionName: '存储权限'.tr,
        permissionType: Permission.storage,
        permissionContent: '用于发送或保存文件、图片和视频'.tr,
      ));
      permissionList.add(SystemPermissionBean(
        permissionName: '电话权限'.tr,
        permissionType: Permission.phone,
        permissionContent: '用于读取电话状态，保障账户安全'.tr,
      ));
      permissionList.add(SystemPermissionBean(
        permissionName: '悬浮窗权限'.tr,
        permissionType: Permission.systemAlertWindow,
        permissionContent: '允许应用在其他程序上覆盖显示'.tr,
      ));
    }

    updatePermissionEnable();
  }

  /// - 更新权限是否可用
  Future<void> updatePermissionEnable() async {
    permissionList.forEach((element) async {
      element.permissionEnable = await _checkPermissionIsEnable(element);
      update();
    });
  }

  /// - 检测权限是否开启
  Future<bool> _checkPermissionIsEnable(
      SystemPermissionBean permissionBean) async {
    final status = await permissionBean.permissionType.status;
    return status == PermissionStatus.granted;
  }

  /// - 跳转到应用权限设置界面
  void openPermissionSetting(
      BuildContext context, SystemPermissionBean permissionBean) {
    if (UniversalPlatform.isAndroid) {
      // 跳转到应用权限设置界面
      openAppSettings();
    } else if (UniversalPlatform.isIOS) {
      if (permissionBean.permissionEnable) {
        // 跳转到应用权限设置界面
        openAppSettings();
      } else {
        // 如果是ios，没有授权的权限，先进行授权弹窗，再进行设置页面的跳转
        checkSystemPermissions(
            context: context,
            permissions: [permissionBean.permissionType]).then((enable) {
          if (enable) {
            permissionBean.permissionEnable = true;
            update();
          }
        });
      }
    }
  }
}
