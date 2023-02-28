import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/show_confirm_popup.dart';
import 'package:im/web/utils/confirm_dialog/message_box.dart';

//final Animatable<double> _dialogScaleTween = Tween<double>(begin: 1.3, end: 1)
//    .chain(CurveTween(curve: Curves.linearToEaseOut));

Future<bool> showConfirmDialog({
  String title,
  String content,
  String confirmText = '确定',
  TextStyle confirmStyle,
  String cancelText = '取消',
  TextStyle cancelStyle,
  Function onCancel,
  Function onConfirm,
  bool showCancelButton = true,
  bool barrierDismissible = false,
}) async {
  if (OrientationUtil.portrait)
    return showConfirmPopup(
        title: content ?? title,
        confirmText: confirmText.tr,
        confirmStyle: confirmStyle,
        cancelText: cancelText.tr,
        cancelStyle: cancelStyle,
        onConfirm: onConfirm,
        onCancel: onCancel,
        showCancelButton: showCancelButton);
  else
    return showWebMessageBox(
        title: title,
        content: content,
        confirmText: confirmText.tr,
        confirmStyle: confirmStyle,
        cancelText: cancelText.tr,
        onCancel: onCancel,
        onConfirm: onConfirm,
        showCancelButton: showCancelButton);
//  final theme = Theme.of(context);
//  final bool isDarkMode = theme.brightness == Brightness.dark;
//  return showGeneralDialog(
//      barrierLabel: '',
//      context: context,
//      barrierDismissible: barrierDismissible,
//      barrierColor: Colors.black.withOpacity(0.5),
//      transitionBuilder: _buildCupertinoDialogTransitions,
//      transitionDuration: const Duration(milliseconds: 250),
//      pageBuilder: (context, animation, secondaryAnimation) {
//        return Column(
//          mainAxisSize: MainAxisSize.min,
//          mainAxisAlignment: MainAxisAlignment.center,
//          children: [
//            Container(
//              constraints: BoxConstraints(
//                maxWidth: MediaQuery.of(context).size.width * 0.8,
//              ),
//              padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
//              decoration: BoxDecoration(
//                  color: theme.backgroundColor,
//                  borderRadius: BorderRadius.circular(dlgBorderRadius)),
//              child: Column(
//                children: <Widget>[
//                  Text(
//                    title,
//                    style: theme.textTheme.bodyText2.copyWith(
//                      fontSize: 18,
//                    ),
//                  ),
//                  Visibility(
//                      visible: isNotNullAndEmpty(content), child: sizeHeight24),
//                  if (content.isEmpty)
//                    const SizedBox()
//                  else
//                    Text(
//                      content,
//                      textAlign: TextAlign.center,
//                      style: theme.textTheme.bodyText2.copyWith(fontSize: 15),
//                    ),
//                  sizeHeight24,
//                  Row(
//                    children: <Widget>[
//                      if (showCancelButton)
//                        Expanded(
//                            child: SizedBox(
//                          width: 126,
//                          height: 36,
//                          child: FlatButton(
//                            onPressed: () {
//                              if (onCancel != null)
//                                onCancel();
//                              else
//                                Navigator.of(context).pop(false);
//                            },
//                            color: isDarkMode
//                                ? const Color(0xFF32353B)
//                                : Theme.of(context).scaffoldBackgroundColor,
//                            child: Text(
//                              cancelText,
//                              style: theme.textTheme.bodyText2,
//                            ),
//                          ),
//                        )),
//                      if (showCancelButton) sizeWidth10,
//                      Expanded(
//                          child: SizedBox(
//                        width: 126,
//                        height: 36,
//                        child: FlatButton(
//                          onPressed: () {
//                            if (onConfirm != null)
//                              onConfirm();
//                            else
//                              Navigator.of(context).pop(true);
//                          },
//                          color: const Color(0xFF6179F2),
//                          child: Text(
//                            confirmText,
//                            style: theme.textTheme.bodyText2
//                                .copyWith(color: Colors.white),
//                          ),
//                        ),
//                      ))
//                    ],
//                  )
//                ],
//              ),
//            )
//          ],
//        );
//      });
}

//Widget _buildCupertinoDialogTransitions(
//    BuildContext context,
//    Animation<double> animation,
//    Animation<double> secondaryAnimation,
//    Widget child) {
//  final CurvedAnimation fadeAnimation = CurvedAnimation(
//    parent: animation,
//    curve: Curves.easeInOut,
//  );
//  if (animation.status == AnimationStatus.reverse) {
//    return FadeTransition(
//      opacity: fadeAnimation,
//      child: child,
//    );
//  }
//  return FadeTransition(
//    opacity: fadeAnimation,
//    child: ScaleTransition(
//      scale: animation.drive(_dialogScaleTween),
//      child: child,
//    ),
//  );
//}

Future<bool> showTokenFailDialog(BuildContext context,
    {String alterInfo, String buttonText}) async {
  final content = alterInfo.hasValue ? alterInfo : '登录已过期，请尝试重新登录'.tr;
  final confirmText = buttonText ?? '重新登录'.tr;
  if (OrientationUtil.portrait)
    await showDialog(
      context: context,
      builder: (ctx) {
        return GestureDetector(
          onTap: Get.back,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Container(
                margin: const EdgeInsets.only(left: 40, right: 40),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(top: 24, bottom: 24),
                      child: Text(
                        '登录失败'.tr,
                        style: const TextStyle(
                            color: Color(0xff1F2125),
                            fontSize: 17,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Center(
                      child: Text(
                        content.tr,
                        style: const TextStyle(
                            color: Color(0xff6D6F73), fontSize: 15),
                      ),
                    ),
                    Container(
                      height: 0.5,
                      margin: const EdgeInsets.only(top: 24),
                      color: const Color(0xff8F959E),
                    ),
                    Container(
                      height: 52,
                      alignment: Alignment.center,
                      child: TextButton(
                          onPressed: Get.back,
                          child: Text(
                            buttonText.tr ?? '重新登录'.tr,
                            style: const TextStyle(
                                color: Color(0xff6179F2),
                                fontSize: 17,
                                fontWeight: FontWeight.bold),
                          )),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  else
    await showConfirmDialog(
        title: '登录失败'.tr,
        content: content.tr,
        confirmText: confirmText.tr,
        showCancelButton: false);
  return Future.value(true);
}
