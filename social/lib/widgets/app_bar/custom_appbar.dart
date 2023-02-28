import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';

import 'appbar_button.dart';

typedef AppbarTitleBuilder = Widget Function(TextStyle);
typedef AppbarLeadingBuilder = Widget Function(Icon);

class NullAppbar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: preferredSize,
      child: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(1);
}

class CustomAppbar extends StatelessWidget implements PreferredSizeWidget {
  /// 优先取leading
  final AppbarLeadingBuilder leadingBuilder;
  final IconData leadingIcon;
  // 覆盖返回事件, leadingBuilder != null,失效
  final VoidCallback leadingCallback;

  /// 标题
  final String title;
  final AppbarTitleBuilder titleBuilder;
  final List<AppbarButton> actions;

  final double leadWidth;
  final Color backgroundColor;
  final double elevation;
  final bool primary;

  const CustomAppbar({
    Key key,
    this.title,
    this.leadingBuilder,
    this.leadingIcon,
    this.leadingCallback,
    this.titleBuilder,
    this.backgroundColor,
    this.actions,
    this.leadWidth = 44,
    this.elevation = 0,
    this.primary = true,
  }) : super(
          key: key,
        );

  /// 左侧视图
  Widget _leading() {
    final icon = Icon(
      leadingIcon ?? IconFont.buffNavBarBackItem,
      size: 22,
    );
    return (leadingBuilder != null && leadingBuilder(icon) != null)
        ? leadingBuilder(icon)
        : IconButton(icon: icon, onPressed: leadingCallback ?? Get.back);
  }

  /// 标题视图
  Widget _title(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headline5;
    return Container(
      width: 188,
      alignment: Alignment.center,
      child: titleBuilder != null
          ? titleBuilder(titleStyle)
          : Text(
              title ?? '',
              style: titleStyle,
              overflow: TextOverflow.ellipsis,
            ),
    );
  }

  List<Widget> _actions() {
    if (actions == null || actions.isEmpty) return [];
    return [...actions, sizeWidth2];
  }

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: preferredSize,
      child: AppBar(
        primary: primary,
        leadingWidth: leadWidth,
        leading: _leading(),
        title: _title(context),
        centerTitle: true,
        actions: _actions(),
        toolbarHeight: preferredSize.height,
        automaticallyImplyLeading: false,
        backgroundColor: backgroundColor ?? Theme.of(context).backgroundColor,
        elevation: elevation,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(44);
}
