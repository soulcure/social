import 'package:fb_live_flutter/live/model/room_list_model.dart';
import 'package:fb_live_flutter/live/pages/playback/playback_load_page.dart';
import 'package:fb_live_flutter/live/pages/playback/playback_normal_page.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:flutter/material.dart';

class PlaybackPage extends StatefulWidget {
  final RoomListModel roomModel;
  final bool isFromLive;
  final bool isFromList;
  final bool isNeedWakelock;

  const PlaybackPage(
    this.roomModel, {
    this.isFromLive = false,
    this.isFromList = true,
    this.isNeedWakelock = true,
  });

  @override
  _PlaybackPageState createState() => _PlaybackPageState();
}

class _PlaybackPageState extends State<PlaybackPage> {
  @override
  Widget build(BuildContext context) {
    if (strNoEmpty(widget.roomModel.replayUrl)) {
      return PlaybackNormalPage(
        widget.roomModel,
        isFromLive: widget.isFromLive,
        isFromList: widget.isFromList,
        isNeedWakelock: widget.isNeedWakelock,
      );
    } else {
      return PlaybackLoadPage(
        widget.roomModel,
        isFromLive: widget.isFromLive,
        isFromList: widget.isFromList,
        isNeedWakelock: widget.isNeedWakelock,
      );
    }
  }
}
