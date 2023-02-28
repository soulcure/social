import 'package:flutter/material.dart';

/// icon text
class IconText extends StatelessWidget {
  final String text;
  final Widget icon;
  final double iconSize;
  final Axis direction;

  /// icon padding
  final EdgeInsetsGeometry padding;
  final TextStyle style;
  final int maxLines;
  final bool softWrap;
  final TextOverflow overflow;
  final TextAlign textAlign;
  final GestureTapCallback onTap;

  const IconText(this.text,
      {Key key,
      this.icon,
      this.iconSize,
      this.direction = Axis.vertical,
      this.style,
      this.maxLines,
      this.softWrap,
      this.padding,
      this.textAlign,
      this.onTap,
      this.overflow = TextOverflow.ellipsis})
      : assert(direction != null),
        assert(overflow != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final _style = DefaultTextStyle.of(context).style.merge(style);
    final widget = icon == null
        ? Text(text ?? '', style: _style)
        : text == null || text.isEmpty
            ? (padding == null ? icon : Padding(padding: padding, child: icon))
            : buildRichText(_style);
    return InkWell(
      onTap: onTap,
      child: widget,
    );
  }

  Widget buildRichText(TextStyle style) {
    return RichText(
      text: TextSpan(style: style, children: [
        WidgetSpan(
            child: IconTheme(
          data: IconThemeData(
              size: iconSize ??
                  (style == null || style.fontSize == null
                      ? 16
                      : style.fontSize + 1),
              color: style?.color),
          child: padding == null
              ? icon
              : Padding(
                  padding: padding,
                  child: icon,
                ),
        )),
        TextSpan(text: direction == Axis.horizontal ? text : "\n$text"),
      ]),
      maxLines: maxLines,
      softWrap: softWrap ?? true,
      overflow: overflow ?? TextOverflow.clip,
      textAlign: textAlign ??
          (direction == Axis.horizontal ? TextAlign.start : TextAlign.center),
    );
  }
}
