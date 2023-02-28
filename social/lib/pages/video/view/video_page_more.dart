import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/hybrid/webrtc/room/multi_video_room.dart';
import 'package:im/pages/video/model/video_room_controller.dart';
import 'package:im/pages/video/view/video_room_item.dart';

class VideoPageMore extends StatefulWidget {
  final void Function(VideoUser user) onDoubleTap;
  final void Function(VideoUser user) onLongPress;

  const VideoPageMore({this.onDoubleTap, this.onLongPress, Key key})
      : super(key: key);

  @override
  State<VideoPageMore> createState() => _VideoPageMoreState();
}

class _VideoPageMoreState extends State<VideoPageMore> {
  final VideoRoomController _roomModel =
      Get.find<VideoRoomController>(tag: VideoRoomController.sRoomId);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VideoRoomController>(
        tag: VideoRoomController.sRoomId,
        builder: (model) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            padding: EdgeInsets.fromLTRB(
                5,
                _roomModel.hideToolbar.value
                    ? Get.mediaQuery.padding.top + 5
                    : Get.mediaQuery.padding.top + 50 + 5,
                5,
                _roomModel.hideToolbar.value
                    ? 8
                    : 56 + Get.mediaQuery.viewPadding.bottom + 8),
            //const EdgeInsets.all(5),
            child: GridView.builder(
                padding: EdgeInsets.zero,
                itemCount: _roomModel?.users?.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 5, crossAxisSpacing: 5),
                itemBuilder: (context, index) {
                  final VideoUser videoUser = _roomModel?.users[index];
                  return VideoRoomItem(
                    videoUser,
                    onDoubleTap: () {
                      widget.onDoubleTap?.call(videoUser);
                    },
                    onLongPress: () {
                      widget.onLongPress?.call(videoUser);
                    },
                  );
                }),
          );
        });
  }
}
