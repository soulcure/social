import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget/view/dialog_top_bar.dart';

class ComplaintReceiveDialog extends StatefulWidget {
  final double height;
  final bool isAgain;

  const ComplaintReceiveDialog(this.height, this.isAgain);

  @override
  _ComplaintReceiveDialogState createState() => _ComplaintReceiveDialogState();
}

class _ComplaintReceiveDialogState extends State<ComplaintReceiveDialog> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: FrameSize.winWidth(),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20.px),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DialogTopBar(),
            Image.asset(
              'assets/live/main/complaint_top.png',
              width: 84.px,
            ),
            Text(
              !widget.isAgain ? '你的申诉已收到' : '你已提交过申诉申请',
              style: TextStyle(
                color: const Color(0xff1F2125),
                fontSize: 19.px,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '我们将尽快完成处理，请耐心等候结果。',
              style: TextStyle(color: const Color(0xff8F959E), fontSize: 15.px),
            ),
            SizedBox(
              width: 184.px,
              height: 40.px,
              child: CupertinoButton(
                borderRadius: BorderRadius.all(Radius.circular(20.px)),
                onPressed: RouteUtil.pop,
                padding: EdgeInsets.zero,
                color: const Color(0xFF198CFE),
                child: Text(
                  '确定',
                  style: TextStyle(color: Colors.white, fontSize: 16.px),
                ),
              ),
            ),
            Space(height: 10.px),
          ],
        ),
      ),
    );
  }
}
