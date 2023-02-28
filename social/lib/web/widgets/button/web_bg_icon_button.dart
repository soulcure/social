import 'package:flutter/material.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/web/extension/state_extension.dart';

class WebBgIconButton extends StatefulWidget {
  final IconData icon;
  final double radius;
  final Color color;
  final Color highlightColor;
  final Color backgroundColor;
  final Color highlightBackgroundColor;
  final double size;
  final Function onTap;
  // 是否校验表单元素（用于WebFormDetectorProvider下）
  final bool validForm;
  const WebBgIconButton({
    @required this.icon,
    this.radius = 16,
    this.color,
    this.backgroundColor,
    this.highlightColor,
    this.highlightBackgroundColor,
    this.size = 16,
    this.onTap,
    this.validForm = false,
  }) : assert(icon != null);
  @override
  _WebBgIconButtonState createState() => _WebBgIconButtonState();
}

class _WebBgIconButtonState extends State<WebBgIconButton> {
  bool _highlight = false;
  @override
  Widget build(BuildContext context) {
    final _color = widget.color ?? const Color(0xFF8F959E);
    final _backgroundColor =
        widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;
    final _highlightColor = widget.highlightColor ?? Colors.white;
    final _highlightBackgroundColor =
        widget.highlightBackgroundColor ?? primaryColor;
    return SizedBox(
      width: widget.radius * 2,
      height: widget.radius * 2,
      child: MaterialButton(
          elevation: 1,
          focusElevation: 1,
          hoverElevation: 1,
          highlightElevation: 1,
          onHighlightChanged: (val) {
            setState(() {
              _highlight = val;
            });
          },
          padding: EdgeInsets.zero,
          onPressed: () {
            if (widget.validForm) {
              if (formDetectorModel.changed.value) {
                formDetectorModel.animate();
                return;
              }
              widget.onTap?.call();
            }
          },
          highlightColor: _highlightBackgroundColor,
          color: _backgroundColor,
          shape: const CircleBorder(),
          child: Icon(
            Icons.close,
            size: widget.size,
            color: _highlight ? _highlightColor : _color,
          )),
    );
  }
}
