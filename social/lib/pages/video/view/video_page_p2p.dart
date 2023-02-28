import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/hybrid/webrtc/room/multi_video_room.dart';
import 'package:im/pages/video/model/video_room_controller.dart';
import 'package:im/pages/video/view/video_room_item.dart';

class VideoPageP2p extends StatefulWidget {
  final void Function(VideoUser user) onDoubleTap;
  final void Function(VideoUser user) onLongPress;

  const VideoPageP2p({this.onDoubleTap, this.onLongPress, Key key})
      : super(key: key);

  @override
  State<VideoPageP2p> createState() => _VideoPageP2pState();
}

class _VideoPageP2pState extends State<VideoPageP2p> {
  final VideoRoomController _roomModel =
      Get.find<VideoRoomController>(tag: VideoRoomController.sRoomId);

  @override
  void initState() {
    super.initState();
  }

  ///获取主屏幕的用户
  VideoUser getMainVideoUser() {
    if (_roomModel.isSelf) {
      return _roomModel.me;
    } else {
      final List<VideoUser> users = _roomModel?.users;
      VideoUser mainVideoUser;
      for (int i = 0; i < users.length; i++) {
        final VideoUser user = users[i];
        if (user.id != _roomModel.me.id) {
          mainVideoUser = user;
          break;
        }
      }
      return mainVideoUser;
    }
  }

  ///获取小视频的用户
  VideoUser getSmallVideoUser() {
    if (_roomModel.isSelf) {
      final List<VideoUser> users = _roomModel?.users;
      VideoUser smallVideoUser;
      for (int i = 0; i < users.length; i++) {
        final VideoUser user = users[i];
        if (user.id != _roomModel.me.id) {
          smallVideoUser = user;
          break;
        }
      }
      return smallVideoUser;
    } else {
      return _roomModel.me;
    }
  }

  ///主屏幕
  Widget mainVideoWidget() {
    final VideoUser mainVideoUser = getMainVideoUser();

    if (mainVideoUser == null) {
      //一般不会有这种情况
      return const SizedBox();
    }

    return VideoRoomItem(
      mainVideoUser,
      avatarSize: 184,
      isMainScreen: true,
      nameBoxMargin: const EdgeInsets.symmetric(horizontal: 12),
      onDoubleTap: () {
        widget.onDoubleTap?.call(mainVideoUser);
      },
      onLongPress: () {
        widget.onLongPress?.call(mainVideoUser);
      },
    );
  }

  Widget smallVideoWidget() {
    final VideoUser smallVideoUser = getSmallVideoUser();
    if (smallVideoUser == null) {
      //只有自己一个人的时候，没有小视频
      return const SizedBox();
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      top: _roomModel.hideToolbar.value
          ? Get.mediaQuery.padding.top + 12
          : Get.mediaQuery.padding.top + 50 + 12,
      right: 12,
      width: 90,
      height: 138,
      curve: Curves.fastOutSlowIn,
      child: VideoRoomItem(
        smallVideoUser,
        avatarSize: 48,
        nameBoxMargin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        nameFontSize: 11,
        micAndNameSpac: 2,
        onDoubleTap: () {
          widget.onDoubleTap?.call(smallVideoUser);
        },
        onLongPress: () {
          widget.onLongPress?.call(smallVideoUser);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VideoRoomController>(
        tag: VideoRoomController.sRoomId,
        builder: (model) {
          return Stack(
            children: [
              mainVideoWidget(),
              smallVideoWidget(),
            ],
          );
        });
  }
}
