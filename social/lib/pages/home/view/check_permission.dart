import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/global.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:permission_handler/permission_handler.dart';

// android ios 权限判断不同点，android 默认是 denied，ios默认是unknown
// android 拒绝后仍可以调起系统授权，ios只能弹窗提示到系统设置里修改权限
Future<bool> checkSystemPermissions({
  @required BuildContext context,
  @required List<Permission> permissions,
  // @required String rejectedTips,
  Function onRejectedCancel,
}) async {
  if (UniversalPlatform.isPc) return true;

  final res = await _checkSystemPermission(permissions);
  // 目前用到的权限集合，如需用到其他需添加对应名称
  final Map<Permission, String> _permissionName = {
    Permission.calendar: '日历',
    Permission.camera: '相机',
    Permission.contacts: '通讯录'.tr,
    Permission.location: '位置',
    Permission.microphone: '麦克风'.tr,
    Permission.phone: '电话',
    Permission.photos: '照片',
    Permission.storage: '存储',
    Permission.notification: '推送',
  };
  if (res == MissionResult.success) {
    return true;
  } else if (res == MissionResult.rejected) {
    final String rejectedPermissions =
        permissions.map((e) => _permissionName[e] ?? '').join('、'.tr);
    String rejectedTip;
    if (UniversalPlatform.isAndroid) {
      // rejectedTip =
      //     '请在手机的 "设置-应用-${Global.packageInfo.appName}"中开启$rejectedPermissions权限，以正常使用相关功能';
      rejectedTip = '请在手机的 "设置-隐私"选项中, 允许%s的%s权限，以正常使用相关功能'
          .trArgs([Global.packageInfo.appName, rejectedPermissions]);
    } else if (UniversalPlatform.isIOS) {
      rejectedTip = '请在手机的 "设置-隐私" 选项中，允许%s的%s权限，以正常使用相关功能'
          .trArgs([Global.packageInfo.appName, rejectedPermissions]);
    } else {
      rejectedTip =
          '请在手机的 "设置$nullChar" 中开启%s权限，以正常使用相关功能'.trArgs([rejectedPermissions]);
    }

    // 已拒绝的情况下不需要返回值，去系统设置页修改设置
    return showConfirmDialog(
      title: '提示'.tr,
      content: rejectedTip,
      onCancel: onRejectedCancel,
      onConfirm: () async {
        if (UniversalPlatform.isAndroid) {
          /// 安卓禁止后不再提示的情况
          if (await requestSystemPermissions(permissions) == false)
            await openAppSettings();
        } else {
          /// iOS权限被禁掉后,拉起手机权限设置
          await openAppSettings();
        }
        // MARK: 12/16/20 由于单独调用pop无法返回授权前的界面,所以调用 onRejectedCancel 来返回授权前界面
        onRejectedCancel();
        // Navigator.of(context).pop();
      },
    );
  } else {
    return requestSystemPermissions(permissions);
  }
}

enum MissionResult { success, fail, rejected }

/// 检查权限
Future<MissionResult> _checkSystemPermission(
    List<Permission> permissions) async {
  assert(permissions != null && permissions.isNotEmpty);

  // 检查权限
  final List<Future<PermissionStatus>> checkPermissions = [];
  permissions.forEach((item) {
    checkPermissions.add(item.status);
  });
  final List<PermissionStatus> res = await Future.wait(checkPermissions);

  // 是否授权成功
  bool isRejected = false;
  if (UniversalPlatform.isIOS) {
    final bool success = res.toList().every(
        (v) => v == PermissionStatus.granted || v == PermissionStatus.limited);
    if (success)
      return MissionResult.success;
    else
      isRejected = !res.toList().any((v) => v == PermissionStatus.denied);
  } else if (UniversalPlatform.isAndroid) {
    final bool success =
        res.toList().every((v) => v == PermissionStatus.granted);
    if (success)
      return MissionResult.success;
    else
      isRejected =
          res.toList().any((v) => v == PermissionStatus.permanentlyDenied);
  }
  if (isRejected) {
    return MissionResult.rejected;
  }
  return MissionResult.fail;
}

/// 申请授权
Future<bool> requestSystemPermissions(List<Permission> permissions) async {
  final Map<Permission, PermissionStatus> res = {};
  for (final permission in permissions) {
    res[permission] = await permission.request();
  }
  final authed = res.values
      .toList()
      .every((v) => v.toString() == 'PermissionStatus.granted');
  return authed;
}
