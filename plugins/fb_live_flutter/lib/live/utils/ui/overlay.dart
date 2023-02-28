import 'dart:io';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/utils/other/float/float_mode.dart';
import 'package:flutter/material.dart';

import 'draggable_widget.dart';
import 'frame_size.dart';

class OverlayView {
  static double viewHeight = FrameSize.px(138.5); //浮窗中画面的高
  static OverlayEntry? overlayEntry;

  static void showOverlayEntry({
    required BuildContext context,
    final bool showSmallWindowNeedDelay = false,
    required final LiveValueModel liveValueModel,
  }) {
    floatWindow.closeFloatUI(false);

    /// 一定要延时，否则：
    /// "iOS主播退桌面，然后回直播间，立刻切小窗口，小窗口消失"
    Future.delayed(Duration(milliseconds: showSmallWindowNeedDelay ? 50 : 0))
        .then((value) {
      overlayEntry = OverlayEntry(builder: (context) {
        return DraggableView(liveValueModel);
      });

      /// Android已经改全局浮窗了
      if (Platform.isIOS) {
        //往Overlay中插入插入OverlayEntry
        Overlay.of(context, rootOverlay: true)!.insert(overlayEntry!);
      }
    });
  }

  static void removeOverlayEntry([bool isDismiss = true]) {
    if (overlayEntry != null) {
      try {
        overlayEntry?.remove();
      } catch (e) {
        fbApi.fbLogger.warning('removeOverlayEntry failed');
      }
      overlayEntry = null;
    }
  }
}
