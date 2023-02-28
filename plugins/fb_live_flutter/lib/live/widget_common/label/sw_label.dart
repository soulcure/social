import 'package:fb_live_flutter/live/utils/theme/my_theme.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:flutter/material.dart';

class SwLabel extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;

  const SwLabel(this.text, {this.backgroundColor, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 5.px),
      padding: EdgeInsets.all(4.px),
      decoration: BoxDecoration(
        color: backgroundColor ?? MyTheme.redColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.px,
          color: textColor ?? MyTheme.whiteColor,
        ),
      ),
    );
  }
}
