import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/utils/show_action_sheet.dart';

Future<bool> showConfirmPopup({
  String title = '',
  String confirmText = '确定',
  TextStyle confirmStyle,
  String cancelText = '取消',
  TextStyle cancelStyle,
  Function onCancel,
  Function onConfirm,
  bool showCancelButton = true,
}) async {
  final index = await showCustomActionSheet(
    [
      if (confirmText.hasValue)
        Text(
          confirmText.tr,
          style: confirmStyle ??
              Get.theme.textTheme.bodyText2.copyWith(fontSize: 17),
        ),
    ],
    title: title.tr,
    onConfirm: onConfirm,
    onCancel: onCancel,
    cancelText: cancelText,
    cancelStyle: cancelStyle,
  );
  if (index == null) return null;
  return index >= 0;
}
