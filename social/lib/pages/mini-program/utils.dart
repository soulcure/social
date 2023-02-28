import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/db/db.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

import 'class.dart';

Future<Map<String, dynamic>> showAuthModal(
  BuildContext topContext, {
  Widget Function(BuildContext, SheetController) contentBuilder,
  EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
  Function onConfirm,
  Function onCancel,
}) async {
  Widget _button({Color backgroundColor, @required child, Function onPressed}) {
    return SizedBox(
      width: 120,
      height: 40,
      child: TextButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(backgroundColor),
        ),
        onPressed: onPressed,
        child: DefaultTextStyle(
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.normal,
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _footer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 50, bottom: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _button(
              backgroundColor: const Color(0xFFEDEDED),
              onPressed: onCancel,
              child: Text(
                '取消'.tr,
                style: TextStyle(color: primaryColor),
              )),
          sizeWidth16,
          _button(
            backgroundColor: primaryColor,
            onPressed: onConfirm,
            child: Text(
              '允许'.tr,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  final controller = SheetController();
  return showSlidingBottomSheet(topContext, builder: (context) {
    return SlidingSheetDialog(
      padding: padding,
      controller: controller,
      duration: const Duration(milliseconds: 350),
      cornerRadius: 10,
      scrollSpec: const ScrollSpec(physics: NeverScrollableScrollPhysics()),
      color: Colors.white,
      isDismissable: false,
      snapSpec: const SnapSpec(snappings: [1]),
      dismissOnBackdropTap: false,
      builder: (context, state) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              contentBuilder?.call(context, controller),
              _footer(context),
            ],
          ),
        );
      },
    );
  });
}

bool getAuthSetting(String appId, MpAuthScope scope) {
  final key = _getAuthSettingKey(appId);
  final authSetting = Db.mpAuthSettingBox.get(key);
  if (authSetting == null) return false;
  return authSetting.contains(scope.toString());
}

void updateAuthSetting(String appId, MpAuthScope scope) {
  final key = _getAuthSettingKey(appId);
  final authSetting = Db.mpAuthSettingBox.get(key);
  if (authSetting == null) {
    Db.mpAuthSettingBox.put(key, [scope.toString()]);
  } else {
    Db.mpAuthSettingBox.put(key, [...authSetting, scope.toString()]);
  }
}

String _getAuthSettingKey(String appId) {
  final uri = Uri.parse(appId);
  return '${uri.scheme}://${uri.host}${uri.path}';
}
