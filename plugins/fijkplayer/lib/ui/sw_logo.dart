import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SwLogo extends StatelessWidget {
  final double? circleRadius;
  final double? borderRadius;
  final String? icon;
  final double? iconWidth;
  final Color? iconColor;
  final Color? backgroundColor;
  final Function? onTap;

  const SwLogo(
      {this.circleRadius,
      this.borderRadius,
      this.icon,
      this.iconWidth,
      this.iconColor,
      this.backgroundColor,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (onTap != null) onTap!();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: circleRadius ?? (32 / 2),
            backgroundColor: backgroundColor ?? Colors.black.withOpacity(0.45),
          ),
          Image.asset(
            icon ?? 'assets/live/main/play_white.png',
            width: iconWidth ?? 10,
            color: iconColor,
          ),
        ],
      ),
    );
  }
}
