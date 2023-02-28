import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/themes/const.dart';
import 'package:oktoast/oktoast.dart';

typedef FuncIconBuilder = Widget Function(BuildContext context, bool enable);

/// 成员列表页面，构建功能组件栏的item
class FunctionItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double iconSize;
  final FuncIconBuilder iconBuilder;
  final String label;
  final VoidCallback onTap;

  /// 功能不可用时，点击按钮的提示
  final String disableNotify;

  /// 功能是否可用，不可用时icon，文字置灰，点击按钮给出不可用提示
  final bool enable;

  const FunctionItem({
    Key key,
    this.icon,
    this.color,
    this.iconSize = 24,
    this.iconBuilder,
    this.label,
    this.onTap,
    this.enable = true,
    this.disableNotify = "暂无权限",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemColor =
        enable ? color ?? theme.textTheme.bodyText2.color : theme.disabledColor;
    Widget iconWidget;
    if (iconBuilder != null) {
      iconWidget = iconBuilder(context, enable);
    } else if (icon != null) {
      iconWidget = Icon(
        icon,
        size: iconSize,
        color: itemColor,
      );
    } else {
      iconWidget = SizedBox(width: iconSize, height: iconSize);
    }

    return Expanded(
      child: FadeButton(
        onTap: _onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            sizeHeight6,
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: itemColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTap() {
    if (enable && onTap != null) {
      onTap();
      return;
    }

    showToast(disableNotify.tr);
  }
}
