import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:im/community/virtual_video_room/views/widget/user_icon_view.dart';
import 'package:im/community/virtual_video_room/views/widget/user_msg_view.dart';
import 'package:im/hybrid/webrtc/room/video_room.dart';

import '../../../../global.dart';

const double SMALL_VIDEO_ITEM_WIDTH = 82;
const double BIG_VIDEO_ITEM_WIDTH = 170;

class VideoItemView extends StatelessWidget {
  final VideoUser videoUser;
  final bool isSmallVideo;
  final int index;
  final Function(int index, bool isSmallVideo, VideoUser videoUser)
      onVideoItemClick;

  const VideoItemView(
      {Key key,
      this.index,
      this.videoUser,
      this.isSmallVideo,
      this.onVideoItemClick})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onVideoItemClick?.call(index, isSmallVideo, videoUser),
        child: Container(
          width: isSmallVideo ? SMALL_VIDEO_ITEM_WIDTH : BIG_VIDEO_ITEM_WIDTH,
          height: isSmallVideo ? SMALL_VIDEO_ITEM_WIDTH : BIG_VIDEO_ITEM_WIDTH,
          decoration: BoxDecoration(
            border: Border.all(
                color: videoUser.talking
                    ? const Color(0xFF3FD82E)
                    : Colors.transparent,
                width: 1.5),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(0.5),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
              child: Stack(
                children: [
                  if (videoUser.enableCamera && videoUser.video != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                      child: RTCVideoView(
                        videoUser.video,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        mirror: videoUser.userId == Global.user.id,
                      ),
                    ),
                  Positioned(
                      left: 2,
                      bottom: 2,
                      width: isSmallVideo
                          ? SMALL_VIDEO_ITEM_WIDTH - 3
                          : BIG_VIDEO_ITEM_WIDTH - 3,
                      child: UserMsgView(
                        isLoading: false,
                        isMute: videoUser.muted,
                        userName: videoUser.nickname,
                      )),
                  if (!videoUser.enableCamera || videoUser.video == null)
                    Center(
                        child: UserIconView(
                            isSmall: isSmallVideo,
                            imageFile: videoUser.unityImagePath))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
