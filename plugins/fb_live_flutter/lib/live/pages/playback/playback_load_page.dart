import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../model/room_list_model.dart';
import '../../utils/ui/frame_size.dart';
import '../../utils/ui/ui.dart';
import '../../widget_common/flutter/my_scaffold.dart';
import '../live_room/widget/anchor_top_widgt.dart';
import 'widget/live_logo_background.dart';

class PlaybackLoadPage extends StatefulWidget {
  final RoomListModel roomModel;
  final bool isFromLive;
  final bool isFromList;
  final bool isNeedWakelock;

  const PlaybackLoadPage(
    this.roomModel, {
    this.isFromLive = false,
    this.isFromList = true,
    this.isNeedWakelock = true,
  });

  @override
  _PlaybackLoadPageState createState() => _PlaybackLoadPageState();
}

class _PlaybackLoadPageState extends State<PlaybackLoadPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      overlayStyle: SystemUiOverlayStyle.light,
      body: Stack(
        children: [
          LiveLogoBackground(widget.roomModel.roomLogo),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                Space(height: FrameSize.padTopH() * 1.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnchorTopView(
                      isBgColor: false,
                      isPlayBack: true,
                      imageUrl: widget.roomModel.roomLogo,
                      anchorName: widget.roomModel.okNickName,
                      anchorId: widget.roomModel.anchorId,
                      serverId: widget.roomModel.serverId,
                      likesCount: widget.roomModel.audienceCount,
                      isReplace: true,
                    ),
                    IconButton(
                      icon: Image.asset(
                        'assets/live/main/goods_close.png',
                        color: Colors.white,
                      ),
                      onPressed: Get.back,
                    ),
                  ],
                ),
                const Spacer(),
                const CircularProgressIndicator(backgroundColor: Colors.white),
                Space(height: 20.px),
                Text(
                  "正在生成回放视频\n大约需要5分钟\n请稍后重试…",
                  style: TextStyle(color: Colors.white, fontSize: 17.px),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                Space(height: FrameSize.padTopH() * 1.5),
              ],
            ),
          )
        ],
      ),
    );
  }
}
