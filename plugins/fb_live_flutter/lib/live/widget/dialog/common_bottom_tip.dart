import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget/button/bottom_dialog_button.dart';

class CommonBottomTip extends StatefulWidget {
  final double height;
  final VoidCallback? onNotAgain;
  final VoidCallback? onNow;
  final String? text;

  const CommonBottomTip(this.height, this.onNotAgain, this.onNow, this.text);

  @override
  _CommonBottomTipState createState() => _CommonBottomTipState();
}

class _CommonBottomTipState extends State<CommonBottomTip> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: FrameSize.winWidth(),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 40.px),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '提示',
              style: TextStyle(
                  color: const Color(0xff1F2125),
                  fontSize: 18.px,
                  fontWeight: FontWeight.w600),
            ),
            Text(
              widget.text ?? '请勿使用耳机！配戴耳机将导致观众听不到游戏声音。您的手机仅支持麦克风收录游戏外放声音。',
              style: TextStyle(color: const Color(0xff8F959E), fontSize: 15.px),
            ),
            BottomDialogButton(
                onNotAgain: widget.onNotAgain, onNow: widget.onNow),
            const Space(height: 0),
          ],
        ),
      ),
    );
  }
}
