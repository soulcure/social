import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/default_tip_widget.dart';

class NoFriendWidget extends StatefulWidget {
  @override
  _NoFriendWidgetState createState() => _NoFriendWidgetState();
}

class _NoFriendWidgetState extends State<NoFriendWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        DefaultTipWidget(
          icon: IconFont.buffNaviFriends,
          text: '暂无好友'.tr,
          textSize: 20,
        ),
        sizeHeight12,
        Text(
          '快去添加同服务器的其他成员为好友吧'.tr,
          style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 14),
        ),
      ],
    );
  }
}
