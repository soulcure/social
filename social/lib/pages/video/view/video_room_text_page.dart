import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:im/themes/const.dart';

class VideoRoomTextPage extends StatefulWidget {
  // final TextRoomModel _textModel;
  //
  // const VideoRoomTextPage(this._textModel);

  @override
  _VideoRoomTextPageState createState() => _VideoRoomTextPageState();
}

class _VideoRoomTextPageState extends State<VideoRoomTextPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: <Widget>[
          sizeHeight10,
          Container(
            width: 48,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF646A73),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.volume_up,
                  size: 18,
                ),
                sizeWidth5,
                Text(
                  '聊天室'.tr,
                  style: Theme.of(context).textTheme.bodyText2,
                ),
              ],
            ),
          ),
          // Expanded(
          //   child: TextChatView(
          //     model: widget._textModel,
          //     bottomBar: TextChatBottomBar(widget._textModel.channel),
          //   ),
          // )
        ],
      ),
    );
  }
}
