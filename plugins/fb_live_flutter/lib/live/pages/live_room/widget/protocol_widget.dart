import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../utils/ui/frame_size.dart';

class ProtocolWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: RichText(
        text: TextSpan(
          children: <InlineSpan>[
            TextSpan(
                text: "点击开始直播即代表同意",
                style: TextStyle(
                    color: const Color(0xFF8F959E),
                    fontSize: FrameSize.px(14),
                    decoration: TextDecoration.none)),
            TextSpan(
              text: "《Fanbook直播协议》",
              style: TextStyle(
                  color: const Color(0xff1442CC),
                  fontSize: FrameSize.px(14),
                  decoration: TextDecoration.none),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  const String liveUrl =
                      'https://fanbook.idreamsky.com/live.html';
                  fbApi.pushHTML(context, liveUrl, title: '用户直播协议');
                },
            ),
          ],
        ),
      ),
    );
  }
}
