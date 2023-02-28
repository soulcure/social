import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:im/db/db.dart';
import 'package:im/hybrid/webrtc/room/multi_video_room.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/video/model/video_room_controller.dart';
import 'package:im/pages/video/view/video_room_member/videoroom_member_item.dart';
import 'package:im/pages/video/view/video_room_member/videoroom_member_last_item.dart';
import 'package:im/widgets/share_link_popup/share_link_popup.dart';
import 'package:get/get.dart';

// ignore: must_be_immutable
class VideoroomMemberPopup extends StatefulWidget {
  VideoRoomController roomModel;
  final Function(int) callback;

  VideoroomMemberPopup(this.roomModel, {this.callback, Key key})
      : super(key: key);

  @override
  State<VideoroomMemberPopup> createState() => _VideoroomMemberPopupState();
}

class _VideoroomMemberPopupState extends State<VideoroomMemberPopup> {
  List<VideoUser> getVideoUsers() {
    final List<VideoUser> videoUsers = widget.roomModel?.users
        ?.where(
            (videoUser) => videoUser?.userId != MultiVideoRoom?.SCREEN_USER_ID)
        ?.toList();
    return videoUsers ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          _buildHead(context),
          _buildUserList(context),
        ],
      ),
    );
  }

  Widget _buildHead(BuildContext context) {
    return Container(
      color: const Color(0xffF5F6FA),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: GetBuilder<VideoRoomController>(
                tag: VideoRoomController.sRoomId,
                builder: (model) {
                  return Text(
                    '成员(${getVideoUsers().length})'.tr,
                    style: TextStyle(
                        color: Theme.of(context).iconTheme.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  );
                }),
          ),
          IconButton(
            padding: const EdgeInsets.all(16),
            iconSize: 22,
            icon: Icon(
              IconFont.buffInviteUser,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: _addMember,
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(BuildContext context) {
    return SizedBox(
      height: 316,
      child: GetBuilder<VideoRoomController>(
          tag: VideoRoomController.sRoomId,
          builder: (model) {
            return ListView.builder(
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                if (index == getVideoUsers().length) {
                  return GestureDetector(
                    onTap: _addMember,
                    child: const VideoroomMemberLastItem(),
                  );
                } else {
                  final VideoUser videoUser = getVideoUsers()[index];
                  return VideoroomMemberItem(widget.roomModel, videoUser);
                }
              },
              itemCount: getVideoUsers().length + 1,
            );
          }),
    );
  }

  void _addMember() {
    final channel = Db.channelBox.get(widget.roomModel.roomId);
    showShareLinkPopUp(context, channel: channel);
  }
}
