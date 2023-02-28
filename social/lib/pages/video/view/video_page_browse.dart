import 'package:flutter/material.dart';
import 'package:im/hybrid/webrtc/room/multi_video_room.dart';
import 'package:im/pages/video/view/video_room_item.dart';

class VideoPageBrowse extends StatefulWidget {
  final VideoUser videoUser;
  final VideoUser screenUser;
  final void Function(VideoUser user) onDoubleTap;
  final void Function(VideoUser user) onLongPress;
  final void Function() onExit;
  final bool isShowScreenUser;

  const VideoPageBrowse(this.videoUser,
      {this.screenUser,
      this.onDoubleTap,
      this.onLongPress,
      this.onExit,
      this.isShowScreenUser = false,
      Key key})
      : super(key: key);

  @override
  State<VideoPageBrowse> createState() => _VideoPageBrowseState();
}

class _VideoPageBrowseState extends State<VideoPageBrowse> {
  @override
  Widget build(BuildContext context) {
    return videoWidget(widget.videoUser);
  }

  ///全屏
  Widget videoWidget(VideoUser videoUser) {
    if (videoUser == null) {
      //一般不会有这种情况
      return const SizedBox();
    }

    return Stack(
      children: [
        VideoRoomItem(
          videoUser,
          avatarSize: 184,
          isMainScreen: true,
          nameBoxMargin: const EdgeInsets.symmetric(horizontal: 12),
          onDoubleTap: () {
            widget.onDoubleTap?.call(videoUser);
          },
          onLongPress: () {
            widget.onLongPress?.call(videoUser);
          },
        ),
        if (widget.isShowScreenUser)
          VideoRoomItem(
            widget.screenUser,
            avatarSize: 184,
            isMainScreen: true,
            nameBoxMargin: const EdgeInsets.symmetric(horizontal: 12),
            onDoubleTap: () {
              widget.onDoubleTap?.call(videoUser);
            },
            onLongPress: () {
              widget.onLongPress?.call(videoUser);
            },
          ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
    widget.onExit?.call();
  }
}
