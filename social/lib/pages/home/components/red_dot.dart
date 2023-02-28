import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/themes/default_theme.dart';

class RedDotListenable extends StatelessWidget {
  final ValueNotifier<int> valueListenable;
  final Widget child;
  final Color borderColor;

  final int maxValue;
  final String exceedText;
  final Alignment alignment;
  final Color color;
  final Color textColor;
  final EdgeInsetsGeometry padding;

  final Offset offset;
  final double size;
  final double fontSize;

  const RedDotListenable({
    this.child,
    this.valueListenable,
    this.color = DefaultTheme.dangerColor,
    this.textColor,
    this.padding,
    this.alignment = Alignment.topRight,
    this.borderColor,
    this.maxValue = 99,
    this.offset = Offset.zero,
    this.exceedText = "99+",
    this.size = 16,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final Widget redDot = ValueListenableBuilder<int>(
      valueListenable: valueListenable,
      builder: (context, val, _) {
        return RedDot(
          val,
          borderColor: borderColor,
          offset: offset,
          alignment: alignment,
          color: color,
          maxValue: maxValue,
          exceedText: exceedText,
          size: size,
          fontSize: fontSize,
          textColor: textColor,
          padding: padding,
          child: child,
        );
      },
    );

    return redDot;
  }
}

class MuteRedDotListenable extends StatelessWidget {
  final ValueNotifier<Unread> valueListenable;
  final Widget child;
  final Color borderColor;

  final int maxValue;
  final String exceedText;
  final Alignment alignment;
  final Color color;
  final Color textColor;
  final EdgeInsetsGeometry padding;

  final Offset offset;
  final double size;
  final double fontSize;

  const MuteRedDotListenable({
    this.child,
    this.valueListenable,
    this.color = DefaultTheme.dangerColor,
    this.textColor,
    this.padding,
    this.alignment = Alignment.topRight,
    this.borderColor,
    this.maxValue = 99,
    this.offset = Offset.zero,
    this.exceedText = "99+",
    this.size = 16,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final Widget redDot = ValueListenableBuilder<Unread>(
      valueListenable: valueListenable,
      builder: (context, val, _) {
        ///fix 暂时屏蔽红点+灰点逻辑
        if (val.normalUnread == 0 && val.muteUnread > 0) {
          return RedDot(
            val.muteUnread,
            borderColor: borderColor,
            offset: offset,
            alignment: alignment,
            color: const Color(0xFFbbbbbb),
            maxValue: maxValue,
            exceedText: exceedText,
            size: size,
            fontSize: fontSize,
            textColor: textColor,
            padding: padding,
            child: child,
          );
        } else {
          return RedDot(
            val.normalUnread,
            borderColor: borderColor,
            offset: offset,
            alignment: alignment,
            color: color,
            maxValue: maxValue,
            exceedText: exceedText,
            size: size,
            fontSize: fontSize,
            textColor: textColor,
            padding: padding,
            child: child,
          );
        }
      },
    );

    return redDot;
  }
}

class RedDot extends StatelessWidget {
  final Widget child;

  final int value;
  final int maxValue;
  final String exceedText;
  final Color textColor;
  final Color borderColor;
  final EdgeInsetsGeometry padding;
  final Alignment alignment;
  final Offset offset;
  final Color color;
  final bool borderVisiable;
  final double size;
  final double fontSize;

  const RedDot(
    this.value, {
    this.child,
    this.textColor,
    this.padding,
    this.color = DefaultTheme.dangerColor,
    this.offset = Offset.zero,
    this.borderColor,
    this.alignment = Alignment.topRight,
    this.maxValue = 99,
    this.exceedText = "99+",
    this.borderVisiable = false,
    this.size = 16,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final int val = max(value, 0);

    EdgeInsets _padding = val < 10
        ? EdgeInsets.zero
        : (padding ?? const EdgeInsets.symmetric(horizontal: 3));
    if (kIsWeb) {
      /// web下显示有误差，需要将内容网上移动2pt才能显示正常
      _padding = EdgeInsets.fromLTRB(
          _padding.left, _padding.top, _padding.right, _padding.bottom + 2);
    }
    final Widget widget = Container(
      constraints: BoxConstraints(minWidth: size),
      height: size,
      alignment: Alignment.center,
      padding: _padding,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 2), color: color),
      child: Text(
        val > maxValue ? exceedText : val.toString(),
        textAlign: TextAlign.center,
        style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            height: 1),
      ),
    );

    Widget badge = Offstage(
        offstage: val == 0,
        child: borderColor == null
            ? widget
            : Container(
                transform: Matrix4.translationValues(
                    alignment.x * 3, alignment.y * 3, 0),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: borderColor,
                ),
                child: widget,
              ));

    if (borderVisiable) {
      badge = Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).backgroundColor,
        ),
//        alignment: Alignment.center,
        child: badge,
      );
    }

    if (child == null) {
      return badge;
    }
    return UnconstrainedBox(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: alignment,
        children: [
          child,
          Positioned(left: offset.dx, top: offset.dy, child: badge),
        ],
      ),
    );
  }
}

class RedDotFill extends StatelessWidget {
  final Widget child;
  final int value;
  final Color borderColor;
  final Alignment alignment;
  final Offset offset;
  final Color color;
  final double radius;

  const RedDotFill(
    this.value, {
    this.child,
    this.radius = 4,
    this.color = DefaultTheme.dangerColor,
    this.offset = Offset.zero,
    this.borderColor,
    this.alignment = Alignment.topRight,
  });

  @override
  Widget build(BuildContext context) {
    final int val = max(value, 0);
    final Widget widget = Offstage(
        offstage: val == 0,
        child: Container(
          transform: Matrix4.translationValues(offset.dx, offset.dy, 0),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: borderColor,
          ),
//        alignment: Alignment.center,
          child: Container(
            width: radius * 2,
            height: radius * 2,
            alignment: Alignment.center,
            padding: val < 10
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8), color: color),
          ),
        ));

    return UnconstrainedBox(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: alignment,
        children: [
          child,
          Align(alignment: alignment, child: widget),
        ],
      ),
    );
  }
}

class RedDotFillListenable extends StatelessWidget {
  final ValueNotifier<int> valueListenable;
  final Widget child;
  final Alignment alignment;
  final Color color;
  final Color borderColor;
  final Offset offset;

  const RedDotFillListenable({
    this.child,
    this.valueListenable,
    this.color = DefaultTheme.dangerColor,
    this.borderColor,
    this.alignment = Alignment.topRight,
    this.offset = Offset.zero,
  });

  @override
  Widget build(BuildContext context) {
    final Widget redDot = ValueListenableBuilder<int>(
      valueListenable: valueListenable,
      builder: (context, val, _) {
        return RedDot(
          val,
          offset: offset,
          alignment: alignment,
          color: color,
          borderColor: borderColor,
          child: child,
        );
      },
    );

    return redDot;
  }
}

///椭圆形 数字显示
class OvalDot extends StatelessWidget {
  final int value;
  final int maxValue;
  final String exceedText;
  final Alignment alignment;
  final Offset offset;
  final Color color;

  //数字前后的显示文本
  final String beforeText;

  const OvalDot(this.value,
      {this.color = DefaultTheme.dangerColor,
      this.offset = Offset.zero,
      this.alignment = Alignment.topRight,
      this.maxValue = 99,
      this.exceedText = "99+",
      this.beforeText = ""});

  @override
  Widget build(BuildContext context) {
    final int val = max(value, 0);
    final Widget widget = Container(
      constraints: const BoxConstraints(minWidth: 16),
      height: 16,
      alignment: Alignment.center,
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
      decoration:
          BoxDecoration(borderRadius: BorderRadius.circular(8), color: color),
      child: Text(
        val > maxValue ? beforeText + exceedText : beforeText + val.toString(),
        style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1),
      ),
    );
    return Offstage(offstage: val == 0, child: widget);
  }
}
