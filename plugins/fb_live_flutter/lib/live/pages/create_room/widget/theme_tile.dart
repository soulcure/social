import 'package:flutter/material.dart';
import '../../../utils/ui/frame_size.dart';
import '../../../utils/func/utils_class.dart';

class ThemeTile extends StatelessWidget {
  final String text;

  const ThemeTile(this.text);

  @override
  Widget build(BuildContext context) {
    final cardHeight = 48.px;
    return Row(
      children: [
        Expanded(
          child: ThemeTileBackground(
            height: cardHeight,
            width: 20,
            padding: EdgeInsets.only(left: 12.px, right: 20.px),
            child: Text(
              text,
              style: TextStyle(
                  color: const Color(0xff1F2125), fontSize: FrameSize.px(14)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        SizedBox(width: FrameSize.px(12)),
        ThemeTileBackground(
          padding: EdgeInsets.symmetric(horizontal: 12.px),
          height: cardHeight,
          onTap: () => copyText(text, "复制成功"),
          child: Image.asset(
            'assets/live/main/copy.png',
            width: 18.px,
          ),
        )
      ],
    );
  }
}

class ThemeTileBackground extends StatelessWidget {
  final Widget child;
  final GestureTapCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const ThemeTileBackground({
    required this.child,
    this.onTap,
    this.padding,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: const Color(0xffF2F3F5),
          borderRadius: BorderRadius.all(Radius.circular(FrameSize.px(6))),
        ),
        child: child,
      ),
    );
  }
}
