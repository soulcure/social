import 'package:flutter/material.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/utils/orientation_util.dart';

import 'landscape_menu_button.dart' as land;
import 'protrait_menu_button.dart' as pro;

enum MenuButtonType { pin, unpin, del, modify, modifyTopic }

class MenuButton extends StatelessWidget {
  final CirclePostDataModel postData;
  final Color iconColor;
  final Function(MenuButtonType type, {List param}) onRequestSuccess; // pro 独有
  final Function(int code, MenuButtonType type) onRequestError; // pro 独有
  final EdgeInsets padding;
  final double size;
  final AlignmentGeometry iconAlign;
  final CallbackBuilder callbackBuilder;

  const MenuButton({
    Key key,
    @required this.postData,
    this.onRequestSuccess,
    this.iconColor,
    this.onRequestError,
    this.padding,
    this.size = 16,
    this.iconAlign = Alignment.topRight,
    this.callbackBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OrientationUtil.landscape
        ? land.MenuButton(
            postData: postData,
            iconColor: iconColor,
            padding: padding,
            size: size,
            onRequestSuccess: onRequestSuccess,
            onRequestError: onRequestError,
          )
        : pro.MenuButton(
            postData: postData,
            iconColor: iconColor,
            size: size,
            onRequestSuccess: onRequestSuccess,
            onRequestError: onRequestError,
            padding: padding,
            iconAlign: iconAlign,
            callbackBuilder: callbackBuilder,
          );
  }
}

class CallbackBuilder {
  final Function onModifyCallback;

  CallbackBuilder({this.onModifyCallback});
}
