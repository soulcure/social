import 'package:fb_live_flutter/live/utils/theme/my_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../utils/ui/frame_size.dart';

///应用场景：
///
///

class SwTextRich extends StatelessWidget {
  final List<InlineSpan>? children;
  final String? text1;
  final String? text2;
  final Color? defColor;
  final Color? lightColor;
  final VoidCallback? onTap;

  const SwTextRich({
    this.children,
    this.text1,
    this.text2,
    this.defColor,
    this.lightColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text1 ?? '',
        style: TextStyle(
          fontSize: FrameSize.px(14),
          color: defColor ?? const Color(0xff8F959E),
        ),
        children: [
          TextSpan(
            text: text2 ?? '',
            style: TextStyle(
              color: lightColor ?? MyTheme.blueColor,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                if (onTap != null) onTap!();
              },
          ),
          ...?children,
        ],
      ),
    );
  }
}
