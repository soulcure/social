import 'package:flutter/material.dart';

class MainInputBody extends StatefulWidget {
  const MainInputBody({
    this.child,
    this.color = Colors.transparent,
    this.decoration,
    this.onTap,
    this.padding,
    this.isOnlyCancelFocus = false,
  });

  final Widget? child;
  final Color color;
  final Decoration? decoration;
  final GestureTapCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final bool isOnlyCancelFocus;

  @override
  State<StatefulWidget> createState() => MainInputBodyState();
}

class MainInputBodyState extends State<MainInputBody> {
  @override
  Widget build(BuildContext context) {
    if (widget.isOnlyCancelFocus) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: widget.child,
      );
    }

    return widget.decoration != null
        ? Container(
            decoration: widget.decoration,
            height: double.infinity,
            width: double.infinity,
            padding: widget.padding,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                FocusScope.of(context).requestFocus(FocusNode());
                if (widget.onTap != null) {
                  widget.onTap!();
                }
              },
              child: widget.child,
            ),
          )
        : Container(
            color: widget.color,
            height: double.infinity,
            width: double.infinity,
            padding: widget.padding,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                FocusScope.of(context).requestFocus(FocusNode());
                if (widget.onTap != null) {
                  widget.onTap!();
                }
              },
              child: widget.child,
            ),
          );
  }
}
