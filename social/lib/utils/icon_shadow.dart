import 'dart:ui';
import 'package:flutter/material.dart';

class IconShadowWidget extends StatelessWidget {
  final Icon icon;
  final bool showShadow;
  final Color shadowColor;

  const IconShadowWidget(this.icon, {this.showShadow = true, this.shadowColor});

  @override
  Widget build(BuildContext context) {
    const double opacity = 0.3;
    const double dimens = 2;
    Color _shadowColor = icon.color;
    if (shadowColor != null) _shadowColor = shadowColor;
    final List<Widget> list = [];
    if (showShadow) {
      list.addAll([
        Positioned(
          top: dimens,
          child: IconTheme(
              data: const IconThemeData(
                opacity: opacity,
              ),
              child: Icon(icon.icon,
                  key: icon.key,
                  color: _shadowColor,
                  size: icon.size,
                  semanticLabel: icon.semanticLabel,
                  textDirection: icon.textDirection)),
        ),
      ]);
    }

    list.add(ClipRect(
        child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 0.9, sigmaY: 0.9),
      child: IconTheme(data: const IconThemeData(opacity: 1), child: icon),
    )));

    list.add(IconTheme(data: const IconThemeData(opacity: 1), child: icon));

    return Stack(
      alignment: Alignment.center,
      children: list,
    );
  }
}
