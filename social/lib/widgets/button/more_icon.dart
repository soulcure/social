import 'package:flutter/material.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/icon_font.dart';

class MoreIcon extends StatelessWidget {
  final double size;
  final Color color;

  const MoreIcon({this.size = 16, this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(
      IconFont.buffXiayibu,
      size: size ?? Theme.of(context).iconTheme.size,
      color: color ?? appThemeData.iconTheme.color.withOpacity(0.4),
    );
  }
}
