import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../utils/ui/frame_size.dart';

class RoomListNoDataView extends StatelessWidget {
  final bool? fbCanStartLive;
  final String? text;
  final bool isSpace;

  const RoomListNoDataView({
    Key? key,
    required this.fbCanStartLive,
    this.text,
    this.isSpace = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: FrameSize.px(!isSpace ? 0 : 200),
          ),
          Container(
            padding: EdgeInsets.all(FrameSize.px(32)),
            width: FrameSize.px(100),
            height: FrameSize.px(100),
            decoration: BoxDecoration(
                color: const Color(0x198F959E),
                borderRadius: BorderRadius.circular(FrameSize.px(50))),
            child: Image.asset(
              "assets/live/CreateRoom/live_icon.png",
              width: FrameSize.px(72),
              height: FrameSize.px(64),
            ),
          ),
          SizedBox(
            height: FrameSize.px(20),
          ),
          Text(
            text ?? "暂无直播",
            style: TextStyle(
                color: const Color(0xFF919499), fontSize: FrameSize.px(14)),
          ),
          SizedBox(
            height: FrameSize.px(200),
          ),
        ],
      ),
    );
  }
}
