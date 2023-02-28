import 'dart:async';

import 'package:flutter/material.dart';
import 'package:im/widgets/super_tooltip.dart';

class WebToolTipManager {

  static WebToolTipManager instance = WebToolTipManager();

  List<SuperTooltip> tips = [];

  bool _canClose = true;

  void disableClose() {
    _canClose = false;
  }

  void enableClose() {
    _canClose = true;
  }

  void append(SuperTooltip tip){
    tips.add(tip);
  }

  void clear() {
    if (!_canClose) return;
    if (tips.isEmpty) return;

    for (final SuperTooltip tip in tips) {
      if (tip.isOpen)
        tip.close();
    }
    tips.clear();
  }

}

typedef WebTooltipBuilder<T> = Widget Function(BuildContext, Function(T));
Future<T> showWebTooltip<T>(
  BuildContext context, {
  @required WebTooltipBuilder<T> builder,
  double offsetX = 0,
  double offsetY = 0,
  double minimumOutSidePadding = 10,
  Offset globalPoint,
  bool preferenceTop = true,
  // 传null则不限制
  double maxWidth = 400,
  TooltipDirection popupDirection = TooltipDirection.bottom,
  bool containsBackgroundOverlay = true, // 为True
}) {
  final Completer<T> _completer = Completer<T>();
  void done(T a) {
    _completer.complete(a);
  }

  SuperTooltip _toolTop;
  Widget content = Material(child: builder(context, done));
  if (!containsBackgroundOverlay) {
    content = MouseRegion(
      onEnter: (_) => WebToolTipManager.instance.disableClose(),
      onExit: (_) => WebToolTipManager.instance.enableClose(),
      onHover: (_) => WebToolTipManager.instance.disableClose(),
      child: content,
    );
  }
  _toolTop = SuperTooltip(
      maxWidth: maxWidth,
      arrowBaseWidth: 0,
      arrowLength: 0,
      arrowTipDistance: 0,
      borderWidth: 1,
      globalPoint: globalPoint,
      borderColor: const Color(0xff717D8D).withOpacity(0.1),
      shadowColor: const Color(0xff717D8D).withOpacity(0.1),
      outsideBackgroundColor: Colors.transparent,
      borderRadius: 4,
      offsetX: offsetX,
      offsetY: offsetY,
      preferenceTop: preferenceTop,
      minimumOutSidePadding: minimumOutSidePadding,
      content: content,
      popupDirection: popupDirection,
      containsBackgroundOverlay: containsBackgroundOverlay,
      onClose: () {
        if (!containsBackgroundOverlay)
          WebToolTipManager.instance.enableClose();
        if (!_completer.isCompleted) {
          _completer.complete(null);
        }
      });
  _toolTop.show(context);
  _completer.future.whenComplete(() {
    if (_toolTop.isOpen) _toolTop.close();
  });
  if (!containsBackgroundOverlay)
    Future.delayed(const Duration(milliseconds: 100)).then((value) {
      WebToolTipManager.instance.append(_toolTop);
    });
  return _completer.future;
}
