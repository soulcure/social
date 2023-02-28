import 'package:flutter/material.dart';
import 'package:im/app/theme/app_theme.dart';

/// 一些消息体的卡片包围盒，例如富文本消息和动态卡片拥有的外框
class MessageCard extends StatelessWidget {
  final Widget child;
  final double height;
  final BoxConstraints constraints;

  const MessageCard({
    Key key,
    this.child,
    this.height,
    this.constraints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const borderRadius = 8.0;

    return Container(
      constraints: constraints,
      foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
              width: 0.5, color: appThemeData.dividerColor.withOpacity(0.2))),
      height: height,
      child: ClipRRect(
        // 内圆角需要比外圆角一点点，大概是边框粗度，才能够让背景和边框吻合
        borderRadius: BorderRadius.circular(borderRadius - 1),
        child: child,
      ),
    );
  }
}
