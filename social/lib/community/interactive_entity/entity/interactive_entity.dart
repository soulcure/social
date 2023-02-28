import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/community/interactive_entity/controllers/interactive_entity_controller.dart';
import 'package:im/pages/home/model/chat_index_model.dart';

enum InteractiveEntityType {
  ChannelDialog,
}

abstract class InteractiveEntity {
  InteractiveEntityType get type;

  bool get isFullScreen;

  Widget buildWidget(BuildContext context);

  bool get hasPermission {
    final gp = PermissionModel.getPermission(
        ChatTargetsModel.instance?.selectedChatTarget?.id);
    final hasPermission =
        PermissionUtils.oneOf(gp, [Permission.ADMIN, Permission.MANAGE_GUILD]);
    return hasPermission;
  }

  void sendToUnity(Map<String, String> data) {
    InteractiveEntityController.get()
        .unityBridgeController
        .sendToUnity("OnInteractiveMessage", jsonEncode(data));
  }
}
