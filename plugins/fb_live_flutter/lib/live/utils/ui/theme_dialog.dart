import 'package:fb_live_flutter/live/widget_common/dialog/sw_dialog.dart';
import 'package:flutter/cupertino.dart';

import 'frame_size.dart';

class ThemeDialog {
  static Future themeDialogDoubleItem(
    BuildContext? context, {
    String? title,
    String? text,
    String? okText,
    VoidCallback? onPressed,
    VoidCallback? onCancel,
    TextAlign? textAlign,
    String? cancelText,
  }) {
    return confirmSwDialog(
      context,
      onWillPop: () {
        return Future.value(false);
      },
      title: title ?? '',
      headTextStyle: TextStyle(
        fontSize: FrameSize.px(17),
        color: const Color(0xff1F2125),
        fontWeight: FontWeight.w600,
      ),
      headTopPadding: 30,
      headBottomPadding: 20,
      textBottomPadding: 29.5,
      text: text ?? '',
      textAlign: textAlign ?? TextAlign.left,
      contentStyle: const TextStyle(
        fontSize: 16,
        color: Color(0xff8F959E),
      ),
      okText: okText ?? '',
      okTextStyle: TextStyle(
        color: const Color(0xff6179F2),
        fontSize: 17.px,
        fontWeight: FontWeight.w500,
      ),
      cancelText: cancelText,
      cancelTextStyle: TextStyle(
        fontSize: 17.px,
        color: const Color(0xff1F2125),
      ),
      onPressed: onPressed,
      onCancel: onCancel,
    );
  }

  static Future themeDialogSingleItem(
    BuildContext? context, {
    String? title,
    String? text,
    String? okText,
    String? cancelText,
    VoidCallback? onPressed,
    VoidCallback? onCancel,
  }) {
    return confirmSwDialog(
      context,
      title: title ?? '',
      headTextStyle: TextStyle(
        fontSize: FrameSize.px(17),
        color: const Color(0xff1F2125),
        fontWeight: FontWeight.w600,
      ),
      headTopPadding: 30,
      headBottomPadding: 20,
      textBottomPadding: 29.5,
      text: text ?? '',
      type: 0,
      textAlign: TextAlign.left,
      contentStyle: const TextStyle(
        fontSize: 16,
        color: Color(0xff8F959E),
      ),
      okText: okText ?? '',
      okTextStyle: TextStyle(
        color: const Color(0xff6179F2),
        fontSize: 17.px,
        fontWeight: FontWeight.w500,
      ),
      cancelText: cancelText,
      cancelTextStyle: TextStyle(
        fontSize: 17.px,
        color: const Color(0xff1F2125),
      ),
      onPressed: onPressed,
      onCancel: onCancel,
      onWillPop: () async {
        return false;
      },
    );
  }
}
