import 'package:fb_live_flutter/live/utils/theme/my_theme.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:fb_live_flutter/live/widget_common/image/sw_image.dart';
import 'package:flutter/material.dart';

class SwLogo extends StatelessWidget {
  final bool isCircle;
  final double? circleRadius;
  final double? borderRadius;
  final String? icon;
  final Widget? iconWidget;
  final double? iconWidth;
  final Color? iconColor;
  final Color? backgroundColor;
  final ClickEventCallback? onTap;

  const SwLogo(
      {this.isCircle = false,
      this.circleRadius,
      this.borderRadius,
      this.icon,
      this.iconWidget,
      this.iconWidth,
      this.iconColor,
      this.backgroundColor,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClickEvent(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isCircle)
            CircleAvatar(
              radius: circleRadius ?? (32.px / 2),
              backgroundColor:
                  backgroundColor ?? Colors.black.withOpacity(0.45),
            )
          else
            Container(
              height: 20.px,
              width: 20.px,
              decoration: BoxDecoration(
                  color: MyTheme.blueColor,
                  borderRadius: BorderRadius.circular(borderRadius ?? 3.px)),
            ),
          iconWidget ??
              SwImage(
                icon ?? 'assets/live/main/play_white.png',
                width: iconWidth ?? 10.px,
                color: iconColor,
              ),
        ],
      ),
    );
  }
}
