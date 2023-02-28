import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:im/db/db.dart';
import 'package:im/hybrid/webrtc/room/multi_video_room.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/video/model/video_room_controller.dart';
import 'package:im/widgets/realtime_user_info.dart';

class VideoRoomItem extends StatefulWidget {
  final VideoUser videoUser;
  final double avatarSize;
  final bool isMainScreen;
  final EdgeInsets nameBoxMargin;
  final double nameFontSize;
  final double micAndNameSpac;
  final GestureTapCallback onDoubleTap;
  final GestureLongPressCallback onLongPress;

  const VideoRoomItem(this.videoUser,
      {this.avatarSize = 88,
      this.isMainScreen = false,
      EdgeInsets nameBoxMargin,
      this.nameFontSize = 12,
      this.micAndNameSpac = 4,
      this.onDoubleTap,
      this.onLongPress,
      Key key})
      : nameBoxMargin = nameBoxMargin ?? const EdgeInsets.all(8),
        super(key: key);

  @override
  State<VideoRoomItem> createState() => _VideoRoomItemState();
}

class _VideoRoomItemState extends State<VideoRoomItem> {
  final VideoRoomController _roomModel =
      Get.find<VideoRoomController>(tag: VideoRoomController.sRoomId);

  // void _toggleMuted() {
  //   if (widget.videoUser.userId != _roomModel.me.userId) {
  //     _roomModel.toggleMicrophone(widget.videoUser.id);
  //   } else {
  //     _roomModel.toggleMuted();
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    double bottomV = widget.nameBoxMargin?.bottom ?? 8;
    if (widget.isMainScreen) {
      bottomV = _roomModel.hideToolbar.value
          ? Get.mediaQuery.padding.top
          : Get.mediaQuery.viewPadding.bottom + 56 + 8;
    }

    return GestureDetector(
      onDoubleTap: widget.onDoubleTap,
      onLongPress: widget.onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          color: widget.isMainScreen
              ? const Color(0xff000201)
              : const Color(0xff202020),
          child: Stack(
            children: [
              rtcVideo(widget.videoUser, widget.avatarSize),

              /// 说话状态的描边
              GetBuilder<VideoRoomController>(
                  id: "${widget.videoUser?.id}_talkingChanged",
                  tag: VideoRoomController.sRoomId,
                  builder: (model) {
                    return Container(
                      decoration: BoxDecoration(
                          border: (widget.videoUser?.talking ?? false) &&
                                  !(widget.videoUser?.muted ?? true) &&
                                  !widget.isMainScreen
                              ? Border.all(
                                  color: const Color(0xff00B34A), width: 2)
                              : null,
                          borderRadius: BorderRadius.circular(4)),
                    );
                  }),

              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                left: widget.nameBoxMargin?.left ?? 8,
                right: widget.nameBoxMargin?.right ?? 8,
                bottom: bottomV,
                curve: Curves.fastOutSlowIn,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(2, 2, 4, 2),
                      color: const Color(0x99000201),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            getIconData(),
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: widget.micAndNameSpac),
                          Flexible(
                            child: Text(
                              getShowName(widget.videoUser?.userId),
                              textAlign: TextAlign.left,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: widget.nameFontSize),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData getIconData() {
    if (widget.videoUser?.flag == "screen_share" ||
        widget.videoUser?.userId == "screenshared") {
      return IconFont.buffVideoShare;
    } else {
      return (widget.videoUser?.muted ?? true)
          ? IconFont.buffVideoMicOff
          : IconFont.buffVideoMic;
    }
  }

  String getShowName(String userId) {
    if (userId?.isEmpty ?? true) {
      return '';
    }

    return Db?.userInfoBox?.get(userId)?.showName() ??
        widget.videoUser?.nickname;
  }

  Widget rtcVideo(VideoUser mainVideoUser, double avatarSize) {
    final bool isVideo =
        (mainVideoUser != null && mainVideoUser.enableCamera) &&
            mainVideoUser.video != null;
    Widget widget;
    if (isVideo) {
      widget = RTCVideoView(
        mainVideoUser.video,
        objectFit: this.widget.isMainScreen
            ? RTCVideoViewObjectFit.RTCVideoViewObjectFitContain
            : RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        key: Key(mainVideoUser.userId.toString()),
        mirror: _roomModel.isSelf && mainVideoUser.useFrontCamera,
      );
    } else {
      widget = Container(
        alignment: Alignment.center,
        child: RealtimeAvatar(
          userId: mainVideoUser?.userId,
          size: avatarSize,
        ),
      );
    }

    return widget;
  }
}
