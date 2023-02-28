import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/app/theme/app_colors.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/global.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/guild_setting/guild/quit_guild.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/personal/personal_page.dart';
import 'package:im/utils/show_action_sheet.dart';
import 'package:im/utils/show_confirm_popup.dart';
import 'package:oktoast/oktoast.dart';

class FrozenOperationWidget extends StatelessWidget {
  ///是否为服务器所有者
  bool get isOwner {
    final target = ChatTargetsModel.instance.selectedChatTarget;
    return target is GuildTarget && target.ownerId == Global?.user?.id;
  }

  ///按键title
  String get title {
    if (isOwner) {
      return '联系我们'.tr;
    } else {
      return '退出服务器'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeButton(
        width: 184,
        height: 36,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: appThemeData.dividerColor,
        ),
        onTap: onClick,
        child: Text(title,
            style: TextStyle(
              fontSize: 14,
              color: Get.theme.primaryColor,
            )));
  }

  Future<void> onClick() async {
    final target = ChatTargetsModel.instance.selectedChatTarget;
    if (isOwner) {
      ///服务器owner 才进入意见反馈
      await feedback.call();
    } else {
      ///退出服务器dialog
      final index = await showCustomActionSheet([
        Text(
          '退出服务器'.tr,
          style: appThemeData.textTheme.bodyText2
              .copyWith(color: const Color(0xFFF24848)),
        ),
      ]);
      if (index == null) return;

      switch (index) {
        case 0:
          unawaited(showConfirmPopup(
              title: '退出服务器后不会通知服务器成员，且不会再接收服务器消息'.tr,
              confirmText: "确定退出服务器".tr,
              confirmStyle: appThemeData.textTheme.bodyText2.copyWith(
                color: redTextColor,
                fontSize: 17,
              ),
              onConfirm: () async {
                try {
                  await GuildApi.quitGuild(Global.user.id, target.id);
                  showToast("已退出服务器「%s」".trArgs([target.name]),
                      duration: const Duration(seconds: 3));
                  quitGuild(target);
                } catch (e) {
                  logger.warning('quit Guild failed: ${e.toString()}');
                }
              }));
          break;
        default:
          break;
      }
    }
  }
}
