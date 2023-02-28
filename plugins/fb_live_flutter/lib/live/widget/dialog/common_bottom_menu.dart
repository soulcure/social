import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';

class CommonBottomMenu extends StatefulWidget {
  final double height;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final String? text;

  const CommonBottomMenu(this.height, this.onConfirm, this.onCancel, this.text);

  @override
  _CommonBottomMenuState createState() => _CommonBottomMenuState();
}

class _CommonBottomMenuState extends State<CommonBottomMenu> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height + FrameSize.padBotH(),
      width: FrameSize.winWidth(),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              alignment: Alignment.center,
              height: 65.px,
              child: Text(
                widget.text ?? '确定要删除该条回放？',
                style:
                    TextStyle(color: const Color(0xff646A73), fontSize: 14.px),
              ),
            ),
            HorizontalLine(color: const Color(0xff8F959E).withOpacity(0.2)),
            SizedBox(
              height: 56.px,
              width: FrameSize.winWidth(),
              child: TextButton(
                onPressed: () {
                  RouteUtil.pop();
                  if (widget.onConfirm != null) widget.onConfirm!();
                },
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                ),
                child: Text(
                  '确定',
                  style: TextStyle(
                    color: const Color(0xff6179F2),
                    fontSize: 16.px,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            HorizontalLine(
              color: const Color(0xffF2F3F5),
              height: 8.px,
            ),
            SizedBox(
              height: 56.px,
              width: FrameSize.winWidth(),
              child: TextButton(
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                ),
                onPressed: () {
                  RouteUtil.pop();
                  if (widget.onCancel != null) widget.onCancel!();
                },
                child: Text(
                  '取消',
                  style: TextStyle(
                    color: const Color(0xff1F2125),
                    fontSize: 16.px,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const Space(height: 0),
          ],
        ),
      ),
    );
  }
}
