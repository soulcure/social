import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/hybrid/webrtc/room/multi_video_room.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/video/model/video_room_controller.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/user_info/popup/user_info_popup.dart';

// ignore: must_be_immutable
class VideoroomMemberItem extends StatefulWidget {
  VideoRoomController roomModel;
  VideoUser videoUser;

  VideoroomMemberItem(this.roomModel, this.videoUser, {Key key})
      : super(key: key);

  @override
  State<VideoroomMemberItem> createState() => _VideoroomMemberItemState();
}

class _VideoroomMemberItemState extends State<VideoroomMemberItem> {
  bool isShowCameraBut() {
    final screenShareUserId = widget.roomModel?.screenShareUser?.id ?? '';
    if (screenShareUserId.isNotEmpty &&
            screenShareUserId == widget?.videoUser?.id ??
        '') {
      return true;
    }

    return widget.videoUser?.enableCamera ?? false;
  }

  // void _toggleMuted() {
  //   if (widget.videoUser.userId != widget.roomModel.me.userId) {
  //     widget.roomModel.toggleMicrophone(widget.videoUser.id);
  //   } else {
  //     widget.roomModel.toggleMuted();
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            showUserInfoPopUp(
              context,
              videoId: widget.videoUser?.id,
              userId: widget.videoUser.userId,
              guildId: widget.videoUser?.guildId,
              channelId: widget.videoUser.roomId,
              enterType: EnterType.fromVideo,
            );
          },
          child: Container(
            height: 56,
            color: Colors.white,
            child: GetBuilder<VideoRoomController>(
                tag: VideoRoomController.sRoomId,
                builder: (model) {
                  return Row(
                    children: [
                      const SizedBox(
                        width: 13,
                      ),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: (widget.videoUser?.talking ?? false) &&
                                      !(widget.videoUser?.muted ?? true)
                                  ? const Color(0xff00B34A)
                                  : Colors.white,
                              width: 1.5),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(19)),
                        ),
                        child: RealtimeAvatar(
                          userId: widget.videoUser.userId,
                          size: 32,
                          showBorder: false,
                        ),
                      ),
                      const SizedBox(
                        width: 13,
                      ),
                      Expanded(
                        child: RealtimeNickname(
                          userId: widget.videoUser.userId,
                          showNameRule: ShowNameRule.remarkAndGuild,
                          guildId: widget.videoUser?.guildId,
                          style: const TextStyle(
                              fontSize: 16,
                              height: 1.25,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF363940)),
                        ),
                      ),
                      Visibility(
                        visible: isShowCameraBut(),
                        child: const IconButton(
                          padding: EdgeInsets.all(11),
                          visualDensity: VisualDensity(
                              horizontal: VisualDensity.minimumDensity),
                          iconSize: 20,
                          icon: Icon(
                            IconFont.buffVideoCamera,
                            color: Color(0x99646A73),
                          ),
                          onPressed: null,
                          // onPressed: () {
                          //   if (widget.videoUser.userId ==
                          //       widget.roomModel.me.userId) {
                          //     widget.roomModel.toggleCamera();
                          //   }
                          // },
                        ),
                      ),
                      IconButton(
                        padding: const EdgeInsets.all(11),
                        visualDensity: const VisualDensity(
                            horizontal: VisualDensity.minimumDensity),
                        iconSize: 20,
                        icon: Icon(
                          (widget.videoUser.muted ?? true)
                              ? IconFont.buffVideoMicOff
                              : IconFont.buffVideoMic,
                          color: const Color(0x99646A73),
                        ),
                        onPressed: null,
                        // onPressed: () {
                        //   Throttle.milliseconds(1000, _toggleMuted);
                        // },
                      ),
                    ],
                  );
                }),
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.only(left: 64),
          child: Divider(
            height: 0.5,
            color: const Color(0xFF8F959E).withOpacity(0.2),
          ),
        ),
      ],
    );
  }
}
