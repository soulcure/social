import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/position_button_controller.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/widgets/realtime_user_info.dart';

///圈子详情页-底部定位按钮
class BottomPositionButton extends StatelessWidget {
  final String postId;

  const BottomPositionButton(this.postId);

  @override
  Widget build(BuildContext context) {
    try {
      if (!Get.isRegistered<BottomPositionController>(tag: postId))
        return sizedBox;
    } catch (e) {
      debugPrint('getChat BottomPositionButton build: $e');
      return sizedBox;
    }
    return GetBuilder<BottomPositionController>(
        tag: postId,
        builder: (c) {
          return Obx(() {
            // debugPrint('getChat BottomPositionButton Obx');
            if (c.unreadAtUserId.value.noValue && c.unreadNum.value <= 0)
              return sizedBox;
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: c.jump,
              child: _buildAtOrNum(c),
            );
          });
        });
  }

  Widget _buildAtOrNum(BottomPositionController c) {
    final unreadId = c.unreadAtUserId.value;
    Widget widget;
    Color backgroundColor;
    if (unreadId.hasValue || c.unreadNum.value > 0) {
      String text;
      if (unreadId.noValue) {
        if (c.unreadNum.value > 99)
          text = "99+";
        else
          text = c.unreadNum.value.toString();
      } else {
        text = "@";
      }
      backgroundColor = primaryColor;
      widget = Text(
        text,
        style: appThemeData.textTheme.caption
            .copyWith(color: appThemeData.backgroundColor),
      );
    }

    return Container(
      margin: const EdgeInsets.all(12),
      alignment: Alignment.center,
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(
            color: appThemeData.dividerColor.withOpacity(0.25), width: 0.5),
        boxShadow: [
          BoxShadow(
              color: appThemeData.dividerColor.withOpacity(0.2 * 0.5),
              blurRadius: 12,
              offset: const Offset(0, 2))
        ],
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      child: widget,
    );
  }
}

/// * 圈子详情页 - 顶部定位按钮
class TopPositionButton extends StatelessWidget {
  final String postId;

  const TopPositionButton(this.postId);

  @override
  Widget build(BuildContext context) {
    try {
      if (!Get.isRegistered<TopPositionController>(tag: postId))
        return sizedBox;
    } catch (e) {
      debugPrint('getChat TopPositionController build: $e');
      return sizedBox;
    }

    return GetBuilder<TopPositionController>(
        tag: postId,
        builder: (c) {
          return Obx(() {
            // debugPrint('getChat BottomPositionButton Obx');
            if (c.unreadAtUserId.value.noValue) return sizedBox;
            return Container(
              height: 40,
              decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                        color: appThemeData.dividerColor,
                        blurRadius: 16,
                        offset: const Offset(0, 2))
                  ]),
              child: FadeButton(
                onTap: c.jump,
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(IconFont.webCircleUp,
                        size: 16, color: Colors.white),
                    const SizedBox(width: 5),
                    ..._buildAt(c),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            );
          });
        });
  }

  List<Widget> _buildAt(TopPositionController c) {
    final unreadId = c.unreadAtUserId.value;
    if (unreadId.noValue) return [sizedBox];
    return [
      RealtimeAvatar(userId: unreadId, size: 20),
      const SizedBox(width: 8),
      Text(
        "有人@你".tr,
        style: const TextStyle(fontSize: 14, color: Colors.white),
      ),
    ];
  }
}
