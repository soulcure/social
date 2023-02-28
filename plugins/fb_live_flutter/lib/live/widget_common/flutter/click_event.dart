import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/utils/func/check.dart';
import 'package:just_throttle_it/just_throttle_it.dart';

typedef ClickEventCallback = Future<void> Function();

/*
* 防止同时多个事件
*
* 关键字：防多次点击、防点击
* */

/// 通用防重复【防多点】点击组件
class ClickEvent extends StatefulWidget {
  final Widget? child;
  final ClickEventCallback? onTap;

  const ClickEvent({this.onTap, this.child});

  @override
  State<ClickEvent> createState() => _ClickEventState();
}

class _ClickEventState extends State<ClickEvent> {
  /// 【2021 12.10】放到全局出现弹出对话框后，对话框内的内容不能点击
  bool isInkWellProcessing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        /// 防止多个事件一起点
        if (isTemporaryTapProcessing) {
          return;
        }
        isTemporaryTapProcessing = true;
        restoreTemporaryProcess(300);

        Throttle.milliseconds(1000, widget.onTap!);
      },
      child: widget.child ?? Container(),
    );
  }

  @override
  void dispose() {
    Throttle.clear(widget.onTap!);
    super.dispose();
  }
}

class ClickEvenGestureRecognizer extends TapGestureRecognizer {}
