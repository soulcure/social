
import 'package:flutter/material.dart';

class WebIconButton extends StatefulWidget {

  final IconData icon;

  final VoidCallback onPressed;
  final double size;
  final Color color;
  final Color hoverColor;
  final Color highlightColor;
  final Color disableColor;
  final EdgeInsets padding;

  const WebIconButton(this.icon, {
    this.onPressed,
    this.size,
    this.color,
    this.hoverColor,
    this.highlightColor,
    this.disableColor,
    this.padding,
  });

  @override
  _WebIconButtonState createState() => _WebIconButtonState();
}

class _WebIconButtonState extends State<WebIconButton> {

  bool _hover = false;
  bool _highLight = false;

  Color get color {
    if (widget.onPressed == null)
      return widget.disableColor ?? Theme.of(context).disabledColor;
    if (_highLight)
      return widget.highlightColor ?? Theme.of(context).highlightColor;
    if (_hover)
      return widget.hoverColor ?? Theme.of(context).hoverColor;
    return widget.color ?? Theme.of(context).iconTheme.color;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? const EdgeInsets.all(8),
      child: InkResponse(
        onHover: (hover) => setState(() => _hover = hover),
        onHighlightChanged: (highLight) => setState(() => _highLight = highLight),
        onTap: widget.onPressed,
        child: Icon(
          widget.icon,
          color: color,
          size: widget.size ?? 24,
        ),
      ),
    );
  }
}
