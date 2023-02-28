import 'package:flutter/material.dart';
import 'package:im/utils/orientation_util.dart';

// 横屏模式滚动条组件，竖屏不显示
class PortraitScrollbar extends StatelessWidget {
  final Widget child;
  const PortraitScrollbar({@required this.child});
  @override
  Widget build(BuildContext context) {
    if (OrientationUtil.portrait) return child;
    return Scrollbar(
      child: child,
    );
  }
}
