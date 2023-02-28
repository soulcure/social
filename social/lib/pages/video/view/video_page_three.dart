import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/hybrid/webrtc/room/multi_video_room.dart';
import 'package:im/pages/video/model/video_room_controller.dart';
import 'package:im/pages/video/view/video_room_item.dart';

class VideoPageThree extends StatefulWidget {
  final void Function(VideoUser user) onDoubleTap;
  final void Function(VideoUser user) onLongPress;

  const VideoPageThree({this.onDoubleTap, this.onLongPress, Key key})
      : super(key: key);

  @override
  State<VideoPageThree> createState() => _VideoPageThreeState();
}

class _VideoPageThreeState extends State<VideoPageThree> {
  final VideoRoomController _roomModel =
      Get.find<VideoRoomController>(tag: VideoRoomController.sRoomId);
  final double spacing = 5;

  @override
  void initState() {
    super.initState();
  }

  List<Widget> getRtcWidget() {
    final List<Widget> widgets = [];
    final int length = _roomModel?.users?.length ?? 0;
    for (int i = 0; i < length; i++) {
      final VideoUser videoUser = _roomModel?.users[i];
      double width = Get.width - spacing - spacing;
      width = (i == 0) ? width : (width - spacing) / 2;

      widgets.add(
        SizedBox(
          width: width,
          height: width,
          child: VideoRoomItem(
            videoUser,
            avatarSize: (i == 0) ? 156 : 88,
            onDoubleTap: () {
              widget.onDoubleTap?.call(videoUser);
            },
            onLongPress: () {
              widget.onLongPress?.call(videoUser);
            },
          ),
        ),
      );
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VideoRoomController>(
        tag: VideoRoomController.sRoomId,
        builder: (model) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            padding: EdgeInsets.fromLTRB(
                spacing,
                _roomModel.hideToolbar.value
                    ? Get.mediaQuery.padding.top + 5
                    : Get.mediaQuery.padding.top + 50 + 5,
                spacing,
                _roomModel.hideToolbar.value
                    ? 5
                    : 56 + Get.mediaQuery.viewPadding.bottom + 5),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: spacing,
              children: [...getRtcWidget()],
            ),
          );
        });
  }
}
