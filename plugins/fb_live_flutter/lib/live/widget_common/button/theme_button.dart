import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';

class ThemeButtonWeb extends StatelessWidget {
  final String? text;
  final VoidCallback? onPressed;
  final Color? btColor;

  const ThemeButtonWeb({this.text, this.onPressed, this.btColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100.px,
      height: 32.px,
      decoration: BoxDecoration(
        border:
            Border.all(color: btColor ?? const Color(0xffDEE0E3), width: 1.px),
        borderRadius: BorderRadius.all(Radius.circular(4.px)),
      ),
      child: TextButton(
        onPressed: () {
          if (onPressed != null) {
            onPressed!();
          }
        },
        style: ButtonStyle(
          padding: MaterialStateProperty.all(EdgeInsets.zero),
          backgroundColor: MaterialStateProperty.all(btColor),
        ),
        child: Text(
          text ?? '文字',
          style: TextStyle(
              color: btColor != null ? Colors.white : const Color(0xff1F2125),
              fontSize: 14.px),
        ),
      ),
    );
  }
}
