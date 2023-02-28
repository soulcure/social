import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/user_config.dart';
import 'package:im/api/user_api.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/guild_setting/circle/circle_setting/topic_name_editor_page.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/routes.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/show_action_sheet.dart';
import 'package:im/web/widgets/popup/web_popup.dart';
import 'package:im/widgets/share_link_popup/share_link_popup.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';

class SemicirclePainter extends CustomPainter {
  final Paint _painter = Paint();

  SemicirclePainter(Color color) {
    _painter
      ..style = PaintingStyle.fill
      ..color = color;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
        RRect.fromLTRBAndCorners(
          0,
          -4,
          4,
          4,
          topRight: const Radius.circular(3),
          bottomRight: const Radius.circular(3),
        ),
        _painter);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

Future<void> popChannelActions(
    BuildContext context, ChatChannel channel) async {
  switch (channel.type) {
    case ChatChannelType.guildCircleTopic:
      await popGuildTopicChannelAction(context, channel);
      break;
    default:
      await popNormalChannelAction(context, channel);
      break;
  }
}

Future popGuildTopicChannelAction(
    BuildContext context, ChatChannel channel) async {
  final GuildPermission gp = PermissionModel.getPermission(channel.guildId);
  final bool managePermission =
      PermissionUtils.oneOf(gp, [Permission.MANAGE_CIRCLES]);
  if (!managePermission) return;
  final index = OrientationUtil.portrait
      ? await showCustomActionSheet([
          Text(
            '频道设置'.tr,
            style: Get.textTheme.bodyText2,
          ),
        ])
      : await showWebSelectionPopup(Get.context,
          items: [if (managePermission) '频道设置'.tr], offsetY: 12);

  if (index == null) return;

  switch (index) {
    case 0:
      unawaited(jumpToCircleSettingPage(context, channel.guildId, channel.id));
      break;
    default:
      break;
  }
}

Future popNormalChannelAction(BuildContext context, ChatChannel channel) async {
  final GuildPermission gp = PermissionModel.getPermission(channel.guildId);
  final bool invitePermission = PermissionUtils.oneOf(
      gp, [Permission.CREATE_INSTANT_INVITE],
      channelId: channel.id);
  final bool managePermission = PermissionUtils.oneOf(
      gp, [Permission.MANAGE_CHANNELS, Permission.MANAGE_ROLES],
      channelId: channel.id);
  final bool isMuted = (Db.userConfigBox.get(UserConfig.mutedChannel) ?? [])
      .contains(channel.id);

  final List<String> actions = [
    if (invitePermission) "invite",
    if (managePermission) "manage",
    if (invitePermission || managePermission) "divider",
    "notification",
  ];
  final index = OrientationUtil.portrait
      ? await showCustomActionSheet([
          if (invitePermission)
            Text(
              '邀请好友'.tr,
              style: Get.textTheme.bodyText2,
            ),
          if (managePermission)
            Text(
              '频道设置'.tr,
              style: Get.textTheme.bodyText2,
            ),
          if (invitePermission || managePermission) null,
          Text(
            isMuted ? '开启消息提醒'.tr : '关闭消息提醒'.tr,
            style: Get.textTheme.bodyText2,
          )
        ])
      : await showWebSelectionPopup(context,
          items: [
            if (invitePermission) '邀请好友'.tr,
            if (managePermission) '频道设置'.tr
          ],
          offsetY: 12);

  // dismiss 时，index = null
  if (index == null) return;

  switch (actions[index]) {
    case "invite":
      showShareLinkPopUp(context, channel: channel);
      break;
    case "manage":
      unawaited(Routes.pushModifyChannelPage(context, channel));
      break;
    case "notification":
      final mutedChannels =
          (Db.userConfigBox.get(UserConfig.mutedChannel) ?? []).toList();
      if (isMuted) {
        mutedChannels.remove(channel.id);
      } else {
        mutedChannels.add(channel.id);
      }
      await UserApi.updateSetting(mutedChannels: mutedChannels);
      await UserConfig.update(mutedChannels: mutedChannels);
      showToast(isMuted ? '已开启频道消息提醒'.tr : '已关闭频道消息提醒'.tr);
      break;
    default:
      break;
  }
}
