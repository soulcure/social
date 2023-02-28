import 'dart:async';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/ui/dialog_util.dart';
import 'package:flutter/material.dart';

import '../config/route_path.dart';
import 'frame_size.dart';

// ignore: must_be_immutable
class Loading extends StatelessWidget {
  static String msgContent = '加载中...';
  static Function? loadingMsgCancel;
  static int msgWidth = 150;
  static int msgHeight = 130;
  static Timer? _loadingTimer;
  static BuildContext? dialogContext;
  OverlayEntry? _overlayEntry;

  // 开启loadingTimer
  static void _startLoadingTimer(int timerDuring, bool openTimer,
      {Function? cb}) {
    if (!openTimer) {
      return;
    }
    cancelLoadingTimer();
    _loadingTimer = Timer.periodic(Duration(seconds: timerDuring), (timer) {
      cancelLoadingTimer();
      cb!();
    });
  }

  // 取消cancelLoading
  static void cancelLoadingTimer() {
    _loadingTimer?.cancel();
  }

  static void cleanContext() {
    if (dialogContext != null) {
      try {
        Navigator.of(dialogContext!).pop();
      } catch (e) {
        /// 【2022 02.25】
        ///  pop();
        fbApi.fbLogger.info("cleanContext中pop出现错误");
      }
      dialogContext = null;
    }
  }

  // 开始具备定时器的loading-toast
  static Future<Loading> timerToast(BuildContext context, String text,
      {int? width = 150,
      int? height = 130,
      int timerDuring = 20,
      bool openTimer = false,
      Function? cancel,
      Function? cb}) async {
    msgContent = text;
    loadingMsgCancel = cancel;
    msgWidth = width ?? msgWidth;
    msgHeight = height ?? msgHeight;
    cleanContext();
    final Loading _loading = Loading();
    final OverlayEntry entry = OverlayEntry(
      builder: (context) {
        return Loading();
      },
    );
    Overlay.of(context)!.insert(entry);
    if (openTimer) {
      _startLoadingTimer(timerDuring, openTimer, cb: cb);
    }
    return _loading.._overlayEntry = entry;
  }

  static Future<Loading> show(BuildContext context, String text,
      [Map? params]) async {
    msgContent = text;
    if (params != null) {
      msgWidth = params['width'] ?? msgWidth;
      msgHeight = params['height'] ?? msgHeight;
    }

    final Loading _loading = Loading();
    final OverlayEntry entry = OverlayEntry(
      builder: (context) {
        return Loading();
      },
    );
    Overlay.of(context)!.insert(entry);
    return _loading.._overlayEntry = entry;
  }

  static void showConfirmDialogNew(
    BuildContext? context, {
    VoidCallback? onPressed,
    VoidCallback? onCancel,
  }) {
    dialogContext = context;
    DialogUtil.netConnectionFailureTip(context,
        onCancel: onCancel, onPressed: onPressed);
  }

  static void connectionFailureTip(
    BuildContext? context,
    bool isAnchor, {
    VoidCallback? onPressed,
    VoidCallback? onCancel,
  }) {
    dialogContext = context;
    DialogUtil.connectionFailureTip(context, isAnchor,
        onPressed: onPressed, onCancel: onCancel);
  }

  /// 主播被禁播提示，放到这主要为了方便被closeLoading关闭
  static void liveWillClose(BuildContext? context, {VoidCallback? onPressed}) {
    dialogContext = context;
    if (RouteUtil.routeHasLive) {
      DialogUtil.liveWillClose(context, onPressed: onPressed);
    }
  }

  static void showConfirmDialog(
      BuildContext context, Map params, Function confirmCallback,
      {Function? cancelCallback}) {
    final String? title = params['title'];
    final String? content = params['content'];
    final String confirmText = params['confirmText'] ?? '确定';
    final String cancelText = params['cancelText'] ?? '取消';

    final bool cancelShow = params['cancelShow'] ?? true;
    dialogContext = context;
    showDialog(
      context: context,
      barrierDismissible: params['barrierDismissible'] ?? false,
      routeSettings: const RouteSettings(name: DialogRoutePath.confirmDialog),
      builder: (context) {
        return WillPopScope(
          onWillPop: () async {
            return false;
          },
          child: Center(
            child: Container(
              width: FrameSize.px(280),
              constraints: BoxConstraints(
                minHeight: FrameSize.px(180),
                maxHeight: FrameSize.px(220),
              ),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  Container(
                    height: FrameSize.px(63),
                    alignment: Alignment.center,
                    child: Text(title ?? "提示",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 17,
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.w600,
                            height: 1)),
                  ),
                  Expanded(
                    child: Container(
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.only(left: 28, right: 28),
                      child: Text(
                        content!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(0xFF8F959E),
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.normal,
                            height: 1.5,
                            fontSize: 16),
                      ),
                    ),
                  ),
                  Container(
                    height: FrameSize.px(1),
                    color: const Color(0x338F959E),
                  ),
                  SizedBox(
                    height: FrameSize.px(56),
                    child: cancelShow == false
                        ? GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              confirmFunc(confirmCallback);
                            },
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                confirmText,
                                style: const TextStyle(
                                  color: Color(0xFF6179F2),
                                  decoration: TextDecoration.none,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  cleanContext();
                                  if (cancelCallback != null) cancelCallback();
                                },
                                child: Container(
                                  constraints: BoxConstraints(
                                      maxWidth: FrameSize.px(139)),
                                  alignment: Alignment.center,
                                  child: Text(
                                    cancelText,
                                    style: const TextStyle(
                                        color: Color(0xFF8F959E),
                                        decoration: TextDecoration.none,
                                        fontWeight: FontWeight.normal,
                                        fontSize: 17),
                                  ),
                                ),
                              ),
                              Container(
                                width: FrameSize.px(1),
                                color: const Color(0x338F959E),
                              ),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  confirmFunc(confirmCallback);
                                },
                                child: Container(
                                  width: FrameSize.px(139),
                                  alignment: Alignment.center,
                                  child: Text(
                                    confirmText,
                                    style: const TextStyle(
                                      color: Color(0xFF6179F2),
                                      decoration: TextDecoration.none,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void confirmFunc(Function? confirmCallback) {
    cleanContext();
    if (confirmCallback != null) confirmCallback();
  }

  void dismiss() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    cancelLoadingTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(FrameSize.px(5)),
          ),
          width: FrameSize.px(msgWidth),
          height: FrameSize.px(msgHeight),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const CircularProgressIndicator(),
              Container(
                // width:168,
                margin: EdgeInsets.only(top: FrameSize.px(10)),
                child: loadingMsgCancel == null
                    ? Text(
                        msgContent,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          decoration: TextDecoration.none,
                          fontSize: FrameSize.px(14),
                          color: const Color(0xFF000000),
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : Column(
                        children: <Widget>[
                          Text(msgContent,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                decoration: TextDecoration.none,
                                fontSize: FrameSize.px(14),
                                color: const Color(0xFF000000),
                                fontWeight: FontWeight.w500,
                              )),
                          SizedBox(
                            height: FrameSize.px(14),
                          ),
                          GestureDetector(
                            onTap: () {
                              loadingMsgCancel!();
                            },
                            child: Text(
                              "退出再试",
                              style: TextStyle(
                                  decoration: TextDecoration.none,
                                  color: const Color(0xFF868686),
                                  fontSize: FrameSize.px(14)),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
