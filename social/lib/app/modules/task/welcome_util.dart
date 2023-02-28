import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/welcome_content.dart';
import 'package:im/widgets/channel_icon.dart';

class WelcomeUtil {
  static Future<void> welcomeInterface(String guildId) async {
    final guildInfo = ChatTargetsModel.instance?.getGuild(guildId);
    final List<WelcomeContentItem> items = [];

    if (guildInfo.isWelcomeOn == false || guildInfo.welcome.isEmpty) {
      return;
    }
    final gp = PermissionModel.getPermission(guildInfo.id);

    for (final c in guildInfo.channels) {
      final isPrivate = PermissionUtils.isPrivateChannel(gp, c.id);
      if (isPrivate) {
        continue;
      }
      for (final element in guildInfo.welcome) {
        if (c.id == element) {
          final item = WelcomeContentItem(
              ChannelIcon.getChannelTypeIcon(c.type), c.name, c.topic,
              guildId: guildId, channelId: c.id);
          items.add(item);
        }
      }
    }

    final bottomSheet = WelcomeContent(
      imageUrl: guildInfo.icon,
      title: "欢迎你，新朋友".tr,
      tips: "这是为你精心挑选的频道".tr,
      buttonText: "开启旅程".tr,
      items: items,
      buttonPress: () {
        Get.back();
        final guildId = ChatTargetsModel.instance.selectedChatTarget.id;
        DLogManager.getInstance().customEvent(
            actionEventId: 'introductory_ceremony',
            actionEventSubId: 'click_start_journey',
            extJson: {"guild_id": guildId});
      },
      showFireworks: true,
      showArrow: true,
      guildId: guildId,
      welcomeStyle: WelcomeStyle.Task,
    );

    if (OrientationUtil.portrait) {
      await Get.bottomSheet(bottomSheet, isScrollControlled: true);
    } else {
      await Get.dialog(
        UnconstrainedBox(
          child: Container(
            alignment: Alignment.center,
            width: 440,
            height: 724,
            child: bottomSheet,
          ),
        ),
        barrierDismissible: false,
      );
    }
  }
}
