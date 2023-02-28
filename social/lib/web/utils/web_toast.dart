import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

/// show toast with [msg],
ToastFuture showWebToast(
  String msg, {
  BuildContext context,
  Duration duration,
  ToastPosition position,
  TextStyle textStyle,
  EdgeInsetsGeometry textPadding =
      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  Color backgroundColor,
  double radius = 4.0,
  VoidCallback onDismiss,
  TextDirection textDirection,
  bool dismissOtherToast,
  TextAlign textAlign,
  OKToastAnimationBuilder animationBuilder,
  Duration animationDuration,
  Curve animationCurve,
}) {
  final theme = _ToastTheme.of(context);
  textStyle ??= theme.textStyle;
  textAlign ??= theme.textAlign;
  textPadding ??= theme.textPadding;
  position ??= theme.position;
  backgroundColor ??= theme.backgroundColor;
  radius ??= theme.radius;
  textDirection ??= theme.textDirection;

  final Widget widget = Container(
    margin: const EdgeInsets.all(50),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(radius),
    ),
    padding: textPadding,
    child: Text(
      msg.tr,
      style: textStyle,
      textAlign: textAlign,
    ),
  );

  return showToastWidget(
    widget,
    animationBuilder: animationBuilder,
    animationDuration: animationDuration,
    context: context,
    duration: duration,
    onDismiss: onDismiss,
    position: position,
    dismissOtherToast: dismissOtherToast,
    textDirection: textDirection,
    animationCurve: animationCurve,
  );
}

class _ToastTheme extends InheritedWidget {
  final TextStyle textStyle;

  final Color backgroundColor;

  final double radius;

  final ToastPosition position;

  final bool dismissOtherOnShow;

  final bool movingOnWindowChange;

  final TextDirection textDirection;

  final EdgeInsets textPadding;

  final TextAlign textAlign;

  final bool handleTouch;

  final OKToastAnimationBuilder animationBuilder;

  final Duration animationDuration;

  final Curve animationCurve;

  final Duration duration;

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => true;

  const _ToastTheme({
    this.textStyle,
    this.backgroundColor = Colors.black,
    this.radius,
    this.position,
    this.dismissOtherOnShow = true,
    this.movingOnWindowChange = true,
    this.textPadding,
    this.textAlign = TextAlign.center,
    this.textDirection,
    this.handleTouch,
    Widget child,
    this.animationBuilder = _defaultBuildAnimation,
    this.animationDuration = _defaultAnimDuration,
    this.animationCurve = Curves.easeIn,
    this.duration = _defaultDuration,
  }) : super(child: child);

  static _ToastTheme of(BuildContext context) => defaultTheme;
}

const TextStyle _defaultTextStyle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.normal,
  color: Colors.white,
);

const _ToastTheme defaultTheme = _ToastTheme(
  radius: 10,
  textStyle: _defaultTextStyle,
  position: ToastPosition.center,
  textDirection: TextDirection.ltr,
  handleTouch: false,
  child: SizedBox(),
);

Widget _defaultBuildAnimation(BuildContext context, Widget child,
    AnimationController controller, double percent) {
  return Opacity(
    opacity: percent,
    child: child,
  );
}

const _defaultDuration = Duration(
  milliseconds: 2300,
);

const _defaultAnimDuration = Duration(milliseconds: 250);
