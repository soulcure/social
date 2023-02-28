import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/components/bottom_right_button/bottom_right_button_controller.dart';
import 'package:im/themes/default_theme.dart';

// class BottomRightButtonEvent {
//   final MessageEntity message;
//   final int numUnread;
//   final int bottom;
//
//   // ignore: prefer_const_constructors
//   static BottomRightButtonEvent invisible = BottomRightButtonEvent();
//
//   // ignore: prefer_const_constructors
//   static BottomRightButtonEvent gotoBottom = BottomRightButtonEvent();
//
//   const BottomRightButtonEvent({this.message, this.numUnread, this.bottom});
// }

///消息公屏 右下角按钮: 包括向下箭头、未读数、艾特
class BottomRightButton extends StatelessWidget {
  // final void Function(BottomRightButtonEvent) onPressed;
  // final String label;
  // final BehaviorSubject<BottomRightButtonEvent> stream;
  //
  // final EdgeInsets padding;

  final String channelId;

  // const BottomRightButton(
  //     {this.label,
  //     this.onPressed,
  //     @required this.stream,
  //     this.padding = EdgeInsets.zero});

  const BottomRightButton(this.channelId);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BottomRightButtonController>(
        tag: channelId,
        builder: (c) {
          if (c.unreadNum == 0 && !c.isShowToBottom) return const SizedBox();

          Widget widget;
          Color backgroundColor;
          if (c.unreadNum > 0) {
            String text;
            if (c.atMessageId == null) {
              if (c.unreadNum > 99)
                text = "99+";
              else
                text = c.unreadNum.toString();
            } else {
              text = "@";
            }
            backgroundColor = primaryColor;
            widget = Text(
              text,
              style: appThemeData.textTheme.caption
                  .copyWith(color: appThemeData.backgroundColor),
            );
          } else if (c.isShowToBottom) {
            backgroundColor = appThemeData.backgroundColor;
            widget = RotatedBox(
              quarterTurns: 2,
              child: Icon(
                IconFont.buffChannelMsgUp,
                color: appThemeData.textTheme.bodyText1.color,
                size: 20,
              ),
            );
          }

          widget = Container(
            margin: const EdgeInsets.all(12),
            alignment: Alignment.center,
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              border: Border.all(
                  color: appThemeData.dividerColor.withOpacity(0.25),
                  width: 0.5),
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

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => c.jump(),
            child: widget,
          );
        });
  }
}
