import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/global.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:pedantic/pedantic.dart';

typedef VoidFutureCallBack = Future<void> Function();

class BottomActionItem {
  Widget child;
  VoidFutureCallBack onTap;
  BottomActionItem({@required this.child, this.onTap});
}

Future<int> showBottomActionSheet(BuildContext context,
    {String title = '',
    double height = 375,
    List<BottomActionItem> actionItems,
    bool showCancel = true,
    Color backgroundColor,
    bool showTopCache = true,
    bool showTopTitle = true,
    bool center = true}) async {
  // final _height = MediaQuery.of(context).padding.bottom + height;
  unawaited(HapticFeedback.selectionClick());
  final _theme = Theme.of(context);
  final List<Widget> _chldren = [];
  for (var i = 0; i < actionItems.length; i++) {
    _chldren.add(
      FadeBackgroundButton(
        onTap: () async {
          if (actionItems[i].onTap != null)
            await actionItems[i].onTap();
          else
            Navigator.of(context).pop(i);
        },
        backgroundColor: _theme.backgroundColor,
        tapDownBackgroundColor: _theme.selectedRowColor,
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: center ? Alignment.center : Alignment.centerLeft,
            height: 48,
            child: actionItems[i].child),
      ),
    );
    if (i != actionItems.length - 1) {
      _chldren.add(divider);
    }
  }

  final res = await showBottomModal(
    context,
    backgroundColor: backgroundColor,
    showTopCache: showTopCache,
    builder: (c, s) => Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            color: backgroundColor ?? _theme.scaffoldBackgroundColor,
          ),
          padding: EdgeInsets.only(bottom: Global.mediaInfo.padding.bottom),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {},
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Visibility(
                    visible: showTopTitle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 19, horizontal: 16),
                      child: Text(title, style: _theme.textTheme.bodyText2),
                    )),
                Visibility(
                    visible: !showTopTitle,
                    child: const SizedBox(width: 0, height: 0)),
                Visibility(visible: showTopCache, child: divider),
                Visibility(
                    visible: !showTopCache,
                    child: const SizedBox(width: 0, height: 0)),
                sizeHeight16,
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(btnBorderRadius),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(btnBorderRadius),
                    child: Column(
                      crossAxisAlignment: center
                          ? CrossAxisAlignment.center
                          : CrossAxisAlignment.start,
                      children: _chldren,
                    ),
                  ),
                ),
                Visibility(visible: showCancel, child: sizeHeight10),
                Visibility(
                    visible: showCancel,
                    child: Container(
                      height: 48,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(btnBorderRadius),
                      ),
                      child: FadeBackgroundButton(
                        borderRadius: btnBorderRadius,
                        onTap: () => Navigator.of(context).pop(-1),
                        backgroundColor: _theme.backgroundColor,
                        tapDownBackgroundColor: _theme.selectedRowColor,
                        child: Text(
                          '取消'.tr,
                          style: _theme.textTheme.bodyText2.copyWith(
                              color: _theme.textTheme.bodyText2.color),
                        ),
                      ),
                    )),
                sizeHeight24,
              ],
            ),
          ),
        ),
      ],
    ),
  );
  return res;
}
