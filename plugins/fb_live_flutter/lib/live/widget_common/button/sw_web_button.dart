import 'package:fb_live_flutter/live/utils/theme/my_theme.dart';
import 'package:flutter/material.dart';

import '../../utils/ui/frame_size.dart';
import 'small_button.dart';

class SwBtImpl {
  final Color? bgColor;

  SwBtImpl({this.bgColor});
}

class SwWebButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isSpace; //右边是否有间隔
  final bool isBorder; //是否有边框
  final String? text; //按钮文字
  final Color? bgColor;
  final Color? textColor;
  final bool isPop;
  final double? width;
  final double? height;
  final bool isBold;

  const SwWebButton({
    Key? key,
    this.onPressed,
    this.isSpace = false,
    this.isBorder = false,
    this.text,
    this.bgColor,
    this.textColor,
    this.isPop = true,
    this.width,
    this.height,
    this.isBold = true,
  }) : super(key: key);

  @override
  _SwWebButtonState createState() => _SwWebButtonState();
}

class _SwWebButtonState extends State<SwWebButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.isSpace ? const EdgeInsets.only(right: 16) : null,
      decoration: widget.isBorder
          ? BoxDecoration(
              border: Border.all(
                color: const Color(0xffdee0e3),
                width: 1.px,
              ),
              borderRadius: BorderRadius.circular(4))
          : null,
      padding: EdgeInsets.zero,
      child: SmallButton(
        minWidth: widget.width ?? 88.px,
        minHeight: widget.height ?? 38.px,
        onPressed: () async {
          if (widget.isPop) Navigator.pop(context);
          if (widget.onPressed != null) {
            widget.onPressed!();
          }
        },
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(4),
        color: widget.bgColor,
        child: Text(
          widget.text ?? '确定',
          style: TextStyle(
            fontSize: FrameSize.px(14),
            color: widget.textColor == MyTheme.blackColor
                ? MyTheme.blackColor
                : MyTheme.whiteColor,
            fontWeight: widget.isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
