import 'package:flutter/material.dart';

class SwListTileOld extends StatelessWidget {
  final EdgeInsetsGeometry? contentPadding;
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? rWidget;
  final GestureTapCallback? onTap;
  final Widget? trailing;
  final Decoration? decoration;
  final Border? inBorder;
  final Border? inTextBorder;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? inPadding;
  final EdgeInsetsGeometry? inTextPadding;
  final EdgeInsetsGeometry? margin;

  const SwListTileOld({
    this.contentPadding,
    this.leading,
    this.inTextBorder,
    this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.decoration,
    this.padding,
    this.inBorder,
    this.inPadding,
    this.inTextPadding,
    this.rWidget,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final body = Row(
      children: (leading != null
          ? [
              leading!,
              const SizedBox(width: 8),
            ]
          : [])
        ..addAll(inTextBorder == null
            ? [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      title ?? Container(),
                      subtitle ?? Container(),
                    ],
                  ),
                ),
                if (rWidget != null) rWidget! else Container(),
                const SizedBox(width: 4),
                if (trailing != null) trailing! else Container()
              ]
            : [
                Expanded(
                  child: Container(
                    padding: inTextPadding,
                    decoration: BoxDecoration(
                      border: inTextBorder,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (title != null) title! else Container(),
                              if (subtitle != null) subtitle! else Container(),
                            ],
                          ),
                        ),
                        if (rWidget != null) rWidget! else Container(),
                        const SizedBox(width: 4),
                        trailing ?? Container()
                      ],
                    ),
                  ),
                ),
              ]),
    );
    return Container(
      decoration: decoration,
      margin: margin,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 14),
      child: InkWell(
        onTap: onTap,
        child: inBorder != null
            ? Container(
                padding: inPadding,
                decoration: BoxDecoration(border: inBorder),
                child: body,
              )
            : body,
      ),
    );
  }
}
