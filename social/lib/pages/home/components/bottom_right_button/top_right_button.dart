import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/components/bottom_right_button/top_right_button_controller.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/widgets/realtime_user_info.dart';

///消息公屏 右上角按钮
class TopRightButton extends StatelessWidget {
  final String channelId;

  const TopRightButton(this.channelId);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TopRightButtonController>(
        tag: channelId,
        builder: (c) {
          if (c.unreadNum <= 0) return const SizedBox();

          final color =
              c.atMessage == null ? primaryColor : const Color(0xFFFFFFFF);
          return Container(
            // width: 159,
            height: 40,
            decoration: BoxDecoration(
              color: c.atMessage == null
                  ? const Color(0xFFFFFFFF)
                  : Get.theme.primaryColor,
              // border: Border.all(color: const Color(0xFFE0E2E6), width: 0.5),
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(20)),
              border: Border.all(
                  color: appThemeData.dividerColor.withOpacity(0.2),
                  width: 0.5),
              boxShadow: [
                BoxShadow(
                    color: appThemeData.dividerColor.withOpacity(0.2 * 0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 2))
              ],
            ),
            child: FadeButton(
              onTap: c.jump,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(IconFont.buffChannelMsgUp, size: 16, color: color),
                  const SizedBox(width: 5),
                  if (c.atMessage == null)
                    _buildNumText(color, c)
                  else
                    ..._buildAt(color, c),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          );
        });
  }

  List<Widget> _buildAt(Color color, TopRightButtonController c) {
    return [
      RealtimeAvatar(userId: c.atMessage.userId, size: 20),
      const SizedBox(width: 8),
      Text(
        "有人@你".tr,
        maxLines: 1,
        style: TextStyle(fontSize: 14, color: color),
      ),
    ];
  }

  Text _buildNumText(Color color, TopRightButtonController c) {
    final value = c.unreadNum;
    return Text(
      "%s条新消息".trArgs([(value > 999 ? "999+" : value).toString()]),
      maxLines: 1,
      textAlign: TextAlign.right,
      style: TextStyle(fontSize: 14, color: color),
    );
  }
}
