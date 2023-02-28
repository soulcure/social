import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

typedef WebHoverButtonBuilder = Widget Function(bool isHover, Widget child);

class WebHoverButton extends StatefulWidget {
  final Widget child;
  final WebHoverButtonBuilder builder;
  final Alignment align;
  final EdgeInsets padding;
  final double width;
  final double height;
  final double borderRadius;
  final Color color;
  final Color hoverColor;
  final BoxBorder border;
  final GestureTapCallback onTap;
  final GestureLongPressCallback onLongPress;
  final SystemMouseCursor cursor;

  const WebHoverButton({
    Key key,
    this.child,
    this.builder,
    this.align = Alignment.center,
    this.padding = const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    this.width,
    this.height,
    this.borderRadius = 0,
    this.color,
    this.hoverColor,
    this.border,
    this.onTap,
    this.onLongPress,
    this.cursor = SystemMouseCursors.click,
  }) : super(key: key);

  @override
  _WebHoverButtonState createState() => _WebHoverButtonState();
}

class _WebHoverButtonState extends State<WebHoverButton> {
  bool _isHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (p) {
        if (mounted)
          setState(() {
            _isHover = true;
          });
      },
      onExit: (p) {
        if (mounted)
          setState(() {
            _isHover = false;
          });
      },
      child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.onTap,
          child: Container(
            alignment: widget.align,
            width: widget.width,
            height: widget.height,
            padding: widget.padding,
            decoration: BoxDecoration(
                color: _isHover ? widget.hoverColor : widget.color,
                border: widget.border,
                borderRadius: widget.borderRadius == 0
                    ? null
                    : BorderRadius.circular(widget.borderRadius)),
            child: widget.builder == null
                ? widget.child
                : widget.builder.call(_isHover, widget.child),
          )),
    );
  }
}
