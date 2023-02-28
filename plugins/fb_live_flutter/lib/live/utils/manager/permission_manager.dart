import 'package:permission_handler/permission_handler.dart';

enum PermissionType {
  createRoom,
}

class PermissionManager {
  PermissionManager();

  /*
   * 请求系统权限，让用户确认授权
   */
  static Future<bool> requestPermission(
      {PermissionType? type, bool useToast = true}) async {
    final List<Permission>? _permissionList = await permissionList(type);
    if (_permissionList == null ||
        (_permissionList is List && _permissionList.isEmpty)) {
      return true;
    }
    final Map<Permission, PermissionStatus> statuses =
        await _permissionList.request();

    for (final Permission key in statuses.keys) {
      if (statuses[key] == PermissionStatus.granted) {
        return true;
      } else if (statuses[key] == PermissionStatus.permanentlyDenied) {
        ///用户选择禁止且不在询问  *仅支持Android*
        return false;
      } else if (statuses[key] == PermissionStatus.denied) {
        ///用户拒绝访问
        return false;
      } else if (statuses[key] == PermissionStatus.restricted) {
        ///操作系统拒绝访问请求的功能。用户无法更改
        ///此应用程序的状态，可能是由于活动限制（如家长限制） *仅支持iOS*
        return false;
      } else if (statuses[key] != PermissionStatus.limited) {
        ///用户已授权此应用程序进行有限访问。
        ///*仅支持iOS（iOS14+）*
        return false;
      }
    }
    return true;
  }

  static Future<List<Permission>?> permissionList(PermissionType? type) async {
    final List<Permission> permissionList = [];
    if (type == PermissionType.createRoom) {
      if (!await Permission.camera.status.isGranted) {
        permissionList.add(Permission.camera);
      }
      if (!await Permission.microphone.status.isGranted) {
        permissionList.add(Permission.microphone);
      }
      return permissionList;
    }
    return null;
  }
}
