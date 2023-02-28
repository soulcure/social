import 'dart:convert';

import 'package:im/common/permission/permission_model.dart' as fb;
import 'package:im/common/permission/permission_utils.dart' as fb;
import 'package:im/common/permission/permission.dart' as fb;
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/community/unity_bridge_controller.dart';
import 'package:im/core/config.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/check_permission.dart';
import 'package:permission_handler/permission_handler.dart';

class UnityBridgeWithCommon extends UnityBridgeWithPartial {
  int _paddingTop = 0;
  int _paddingBottom = 0;

  UnityBridgeWithCommon(UnityBridgeController controller) : super(controller) {
    _paddingTop =
        (Get.mediaQuery.padding.top * Get.mediaQuery.devicePixelRatio).ceil();
    _paddingBottom =
        (Get.mediaQuery.padding.bottom * Get.mediaQuery.devicePixelRatio)
            .ceil();
  }

  @override
  Future<void> destroy() async {}

  @override
  bool handleUnityMessage(
      String messageId, String method, Map<String, String> parameters) {
    switch (method) {
      case "GetEnv":
        unityBridgeController.unityCallback(messageId, {
          "env": Config.env.toString(),
          "channel": Config.channel ?? "",
          "parameters":
              (ChatTargetsModel.instance?.selectedChatTarget as GuildTarget)
                      .virtualParameters ??
                  ""
        });
        break;
      case "GetCurrentGuildId":
        unityBridgeController.unityCallback(messageId,
            {"guildId": ChatTargetsModel.instance?.selectedChatTarget?.id});
        break;
      case "GetUserData":
        _getUserData(messageId);
        break;
      case "GetMediaPadding":
        unityBridgeController.unityCallback(messageId, {
          "top": _paddingTop.toString(),
          "bottom": _paddingBottom.toString()
        });
        break;
      case "RequestPermission":
        _requestPermission(messageId, parameters["permissionName"]);
        break;
      case "GetUsersName":
        _getUsersName(messageId, parameters["userIds"]);
        break;
      default:
        return false;
    }
    return true;
  }

  void _getUserData(String messageId) {
    final gp = fb.PermissionModel.getPermission(
        ChatTargetsModel.instance?.selectedChatTarget?.id);
    final hasPermission = fb.PermissionUtils.oneOf(
        gp, [fb.Permission.ADMIN, fb.Permission.MANAGE_GUILD]);

    unityBridgeController.unityCallback(messageId, {
      "token": Config.token ?? '',
      "userId": Global.user.id ?? '',
      "userName": Global.user.username ?? '',
      "nickName": Global.user.nickname ?? '',
      "owner": hasPermission ? '1' : '0',
    });
  }

  Future<void> _getUsersName(String messageId, String userIds) async {
    final List<String> ids = List<String>.from(jsonDecode(userIds));
    final Map<String, String> names = <String, String>{};
    final List<Future<UserInfo>> futures = <Future<UserInfo>>[];
    for (int i = 0; i < ids.length; i++) {
      futures.add(UserInfo.get(ids[i]));
    }
    final results = await Future.wait(futures);
    for (int i = 0; i < results.length; i++) {
      names[results[i].userId] = results[i]?.showName() ?? '';
    }
    unityBridgeController
        .unityCallback(messageId, {"userNames": jsonEncode(names)});
  }

  Future<void> _requestPermission(
      String messageId, String permissionName) async {
    final List<Permission> permissions = <Permission>[];
    if (permissionName.contains("camera")) {
      permissions.add(Permission.camera);
    }
    if (permissionName.contains("microphone")) {
      permissions.add(Permission.microphone);
    }
    if (permissions.isNotEmpty) {
      final bool isGranted = await checkSystemPermissions(
        context: unityBridgeController.context,
        permissions: permissions,
      );
      unityBridgeController
          .unityCallback(messageId, {"isGranted": isGranted ? "1" : "0"});
    } else {
      unityBridgeController.unityCallback(messageId, {"isGranted": "0"});
    }
  }
}
