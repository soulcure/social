import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoadingProgress {
  static void start(
    BuildContext context, {
    Color barrierColor = Colors.transparent,
    String barrierLabel,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    bool barrierDismissible = true,
    RouteSettings routeSettings,
    Widget widget,
    Color color = Colors.transparent,
    BorderRadiusGeometry borderRadius,
    String gifOrImagePath,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      useSafeArea: useSafeArea,
      barrierLabel: barrierLabel,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => barrierDismissible,
          child: Center(
            child: widget ??
                Container(
                  width: MediaQuery.of(context).size.width / 4,
                  padding:
                      EdgeInsets.all(MediaQuery.of(context).size.width / 13),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: borderRadius ??
                        const BorderRadius.all(
                          Radius.circular(12),
                        ),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: gifOrImagePath != null
                        ? Image.asset(gifOrImagePath)
                        : const CircularProgressIndicator(),
                  ),
                ),
          ),
        );
      },
    );
  }

  static void stop(BuildContext context, [bool rootNavigator = true]) {
    return Navigator.of(context, rootNavigator: rootNavigator).pop();
  }

  static Widget loadingWidget({String message}) {
    message ??= '加载中，请稍后'.tr;
    final double width = message.length * 15.0 + 4 * 20.0;
    final bgColor = Get.theme.textTheme.headline1.color.withOpacity(0.95);
    return Material(
      borderRadius: const BorderRadius.all(
        Radius.circular(10),
      ),
      child: Container(
        width: width,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.all(
            Radius.circular(5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 20),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14,
                    height: 1.25,
                    color: Colors.white,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
}
