import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

Offset fromRight(Animation animation) {
  return Offset(1 - animation.value as double, 0);
}

Offset fromBottom(Animation animation) {
  return Offset(0, 1 - animation.value as double);
}

Future showQ1Dialog(BuildContext? context,
    {Widget? widget, Alignment? alignmentTemp}) {
  if (alignmentTemp == Alignment.centerRight) {
    return showRightDialog(context!, widget: widget);
  } else {
    return showBottomDialog(context!, widget: widget);
  }
}

Future showRightDialog(BuildContext context, {Widget? widget}) {
  return showGeneralDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.5),
    barrierLabel: "",
    barrierDismissible: true,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Material(
          type: MaterialType.transparency,
          child: UnconstrainedBox(
            child: widget,
          ));
    },
    transitionBuilder: (ctx, animation, _, child) {
      return MyFractional(
        translation: fromRight(animation),
        child: child,
      );
    },
  );
}

Future showBottomDialog(BuildContext context, {Widget? widget}) {
  /// 底部弹出的对话框不允许横屏打开，否则样式不对
  ///
  /// 【2022 01.06】
  /// 【APP】观众横屏点击分享或者礼物按钮，自动转换竖屏后不会弹起
  // if (FrameSize.isHorizontal()) {
  //   return Future.value();
  // }

  return showGeneralDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.5),
    barrierLabel: "",
    barrierDismissible: true,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          type: MaterialType.transparency,
          child: UnconstrainedBox(child: widget),
        ),
      );
    },
    transitionBuilder: (ctx, animation, _, child) {
      return FractionalTranslation(
        translation: fromBottom(animation),
        child: Container(
          margin: EdgeInsets.only(top: FrameSize.winHeight() * 0.1),
          child: child,
        ),
      );
    },
  );
}

class MyFractional extends FractionalTranslation {
  MyFractional({Widget? child, required Offset translation})
      : super(
          translation: translation,
          child: UnconstrainedBox(
            child: Container(
              alignment: Alignment.centerRight,
              margin: EdgeInsets.only(
                left:
                    FrameSize.winWidth() - (FrameSize.winWidth() * (375 / 812)),
              ),
              child: child,
            ),
          ),
        );
}

Future<void> showBottomSheetDialog(BuildContext context,
    {required Widget child}) async {
  final controller = SheetController();

  await showSlidingBottomSheet(
    context,
    builder: (context) {
      return SlidingSheetDialog(
        controller: controller,
        duration: const Duration(milliseconds: 300),
        snapSpec: const SnapSpec(
          initialSnap: 1,
          snappings: [0.9],
        ),
        scrollSpec: const ScrollSpec(
          showScrollbar: true,
        ),
        color: Colors.transparent,
        maxWidth: 500,
        minHeight: MediaQuery.of(context).size.height,
        extendBody: true,
        builder: (context, state) {
          return Material(type: MaterialType.transparency, child: child);
        },
      );
    },
  );
}

Future<void> showBottomSheetCommonDialog(BuildContext context,
    {required Widget child,
    double? height,
    double? initialSnap,
    bool resizeToAvoidBottomInset = true}) async {
  final controller = SheetController();

  await showSlidingBottomSheet(
    context,
    resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    builder: (context) {
      return SlidingSheetDialog(
        controller: controller,
        duration: const Duration(milliseconds: 300),
        snapSpec: SnapSpec(
          initialSnap: initialSnap ?? 1,
          snappings: [1.0, 1.0],
        ),
        scrollSpec: const ScrollSpec(
          physics: ClampingScrollPhysics(),
        ),
        color: Colors.transparent,
        maxWidth: 500,
        minHeight: height ?? MediaQuery.of(context).size.height,
        extendBody: true,
        builder: (context, state) {
          return Material(type: MaterialType.transparency, child: child);
        },
      );
    },
  );
}
