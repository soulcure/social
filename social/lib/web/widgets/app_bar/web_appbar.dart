import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/icon_font.dart';

class WebAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  final VoidCallback backAction;

  final Widget tailing;

  final double height;

  const WebAppBar(
      {this.title = '', this.backAction, this.tailing, this.height = 56});

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(height),
      child: AppBar(
        toolbarHeight: height,
        title: Text(
          title,
          style: Theme.of(context).textTheme.headline5,
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
        elevation: 0,
        shape: Border(
          bottom: BorderSide(color: Theme.of(context).dividerTheme.color),
        ),
        actions: [
          if (tailing != null) tailing,
          IconButton(
            onPressed: backAction ?? Get.back,
            icon: Icon(
              IconFont.buffNavBarCloseItem,
              color: Theme.of(context).disabledColor,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
