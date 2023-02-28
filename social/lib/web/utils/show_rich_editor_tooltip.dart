import 'dart:async';

import 'package:flutter/material.dart';
import 'package:im/widgets/rich_editor_tooltip.dart';

class WebRichEditorToolTipManager {
  static WebRichEditorToolTipManager instance = WebRichEditorToolTipManager();

  List<RichEditorSuperTooltip> tips = [];

  bool _canClose = true;

  void disableClose() {
    _canClose = false;
  }

  void enableClose() {
    _canClose = true;
  }

  void append(RichEditorSuperTooltip tip) {
    tips.add(tip);
  }

  void clear() {
    if (!_canClose) return;
    if (tips.isEmpty) return;

    for (final RichEditorSuperTooltip tip in tips) {
      if (tip.isOpen) tip.close();
    }
    tips.clear();
  }
}

typedef WebTooltipBuilder<T> = Widget Function(BuildContext, Function(T));
Future<T> showWebRichEditorTooltip<T>(
  BuildContext context, {
  @required WebTooltipBuilder<T> builder,
}) {
  final Completer<T> _completer = Completer<T>();
  void done(T a) {
    if (!_completer.isCompleted) {
      _completer.complete(a);
    }
  }

  RichEditorSuperTooltip _toolTop;
  final Widget content = Material(child: builder(context, done));
  _toolTop = RichEditorSuperTooltip(
      arrowBaseWidth: 0,
      arrowLength: 0,
      arrowTipDistance: 0,
      borderWidth: 1,
      borderColor: const Color(0xff717D8D).withOpacity(0.1),
      shadowColor: const Color(0xff717D8D).withOpacity(0.1),
      outsideBackgroundColor: Colors.transparent,
      borderRadius: 4,
      content: content,
      onClose: () {
        if (!_completer.isCompleted) {
          _completer.complete(null);
        }
      });
  _toolTop.show(context);
  _completer.future.whenComplete(() {
    if (_toolTop.isOpen) _toolTop?.close();
  });
  Future.delayed(const Duration(milliseconds: 100)).then((value) {
    WebRichEditorToolTipManager.instance.append(_toolTop);
  });
  return _completer.future;
}
