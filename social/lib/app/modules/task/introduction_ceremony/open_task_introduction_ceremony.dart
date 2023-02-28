import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/task/introduction_ceremony/views/task_introduction_ceremony_view.dart';
import 'package:im/app/modules/task/task_util.dart';
import 'package:im/app/routes/app_pages.dart' as app_pages;
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/utils/orientation_util.dart';

class OpenTaskIntroductionCeremony {
  /// 打开入门仪式界面
  // static void openTaskInterface() {
  //   if (isOpenTaskInterface())
  //     Get.toNamed(app_pages.Routes.TASK_INTRODUCTION_CEREMONY);
  //   return;
  // }
  /// 打开入门仪式界面
  static bool openTaskInterface() {
    if (isOpenTaskInterface()) {
      if (OrientationUtil.portrait) {
        Get.toNamed(app_pages.Routes.TASK_INTRODUCTION_CEREMONY);
      } else {
        Get.dialog(
          UnconstrainedBox(
            child: SizedBox(
              width: 440,
              height: 724,
              child: TaskIntroductionCeremonyView(),
            ),
          ),
          barrierDismissible: false,
        );
      }

      return true;
    }
    return false;
  }

  /// 是否可以打开入门仪式界面
  static bool isOpenTaskInterface() {
    /// 判断是否有任务
    if (!TaskUtil.instance.isNewGuy.value) return false;
    final gt = ChatTargetsModel.instance.selectedChatTarget as GuildTarget;

    if (gt.runtimeType != GuildTarget) return false;

    if (gt == null || !gt.userPending) return false;

    return true;
  }
}
