import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/app/modules/task/task_ws_util.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/widgets/dialog/action_confirm_dialog.dart';
import 'package:pedantic/pedantic.dart';

class UIChannelNoPermissionAlert {
  /// 用来防止多次弹出Dialog导致的黑色背景问题
  static bool isShowAlert = false;

  static Future<void> showNoPermissionAlert(
      {BuildContext context, VoidCallback onConfirm}) async {
    if (isShowAlert) return;
    bool isVisible = true;
    final channel = GlobalState.selectedChannel.value;

    /// - 清空用户服务器，通过点击单聊消息中的邀请私密频道卡片，但无查看权限进入
    /// channel这时为null
    final gp = PermissionModel.getPermission(channel?.guildId);
    isVisible = PermissionUtils.isChannelVisible(gp, channel?.id);

    if (!isVisible) {
      final currentContext = context ?? Global.navigatorKey.currentContext;

      /// 此处是用来特殊处理入门仪式任务
      if (TaskWsUtil.isOnTaskPage) {
        unawaited(HomeScaffoldController.to.gotoWindow(0));
        ChatTargetsModel.instance.selectedChatTarget.selectDefaultTextChannel();
        return;
      }

      /// TODO: 2021/12/24 与翁祥讨论确定弹出权限问题先跳转至Home页面，再显示权限弹窗，50版本后再统一修改
      isShowAlert = true;
      final v = await showDialog(
          context: currentContext,
          builder: (cxt) {
            return ActionConfirmDialog(
              title: "你没有权限访问此频道，请联系管理员".tr,
              onConfirm: () {
                Navigator.pop(cxt, true);
                onConfirm?.call();
                isShowAlert = false;
              },
            );
          },
          // NOTE: 2021/12/20 禁用触屏关闭窗口，外部调用需要通过返回获取是否已结束弹窗
          barrierDismissible: false);
      if (v == true) {
        GlobalState.selectedChannel.value = null;
        unawaited(HomeScaffoldController.to.gotoWindow(0));
        ChatTargetsModel.instance.selectedChatTarget.selectDefaultTextChannel();
        return;
      }
    }
  }
}
