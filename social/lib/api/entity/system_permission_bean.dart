import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// - 手机系统权限的Bean
class SystemPermissionBean {
  String permissionName;
  Permission permissionType;
  String permissionContent;
  bool permissionEnable;

  SystemPermissionBean({
    @required this.permissionName,
    @required this.permissionType,
    this.permissionEnable = false,
    this.permissionContent,
  });
}
