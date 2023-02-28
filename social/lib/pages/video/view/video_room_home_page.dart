import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/hybrid/webrtc/room/multi_video_room.dart';
import 'package:im/pages/video/model/video_room_controller.dart';
import 'package:im/pages/video/view/video_bottom_view.dart';
import 'package:im/pages/video/view/video_page_browse.dart';
import 'package:im/pages/video/view/video_page_more.dart';
import 'package:im/pages/video/view/video_page_p2p.dart';
import 'package:im/pages/video/view/video_page_three.dart';
import 'package:im/pages/video/view/video_share_view.dart';
import 'package:im/pages/video/view/video_top_bar.dart';
import 'package:im/widgets/user_info/popup/user_info_popup.dart';

class VideoRoomHomePage extends StatefulWidget {
  final String roomId;
  final String channelName;

  VideoRoomHomePage(this.roomId, this.channelName)
      : super(key: Key(roomId.toString()));

  @override
  State<VideoRoomHomePage> createState() => _VideoRoomHomePageState();
}

class _VideoRoomHomePageState extends State<VideoRoomHomePage> {
  VideoRoomController _controller;
  double distance = 0; //距离
  double startPosition = 0; //开始位置

  // 背景
  Widget _buildBackground() {
    return Container(color: const Color(0xff000201));
  }

  //双击事件（全屏显示）
  void openBrowseVideoAction(VideoUser user) {
    _controller.browseVideo(user);
  }

  //双击事件（退出全屏显示）
  void exitBrowseVideoAction(VideoUser user) {
    _controller.exitBrowseVideo();
  }

  //长按事件（显示用户资料）
  void onLongPressAction(VideoUser user) {
    showUserInfoPopUp(
      context,
      userId: user.userId,
      videoId: user.id,
      guildId: user.guildId,
      channelId: widget.roomId,
      enterType: EnterType.fromVideo,
    );
  }

  //视频区域
  Widget videoWidget(VideoRoomController model) {
    if (model.browseUser != null) {
      //browseUser不为空，则进入全屏浏览界面
      return Obx(() {
        return VideoPageBrowse(
          model.browseUser,
          screenUser: model.screenShareFullUser,
          onExit: () {
            model.screenShareFullUser = null;
            model.isShowFullScreenShare.value = false;
          },
          isShowScreenUser: model.isShowFullScreenShare.value &&
              model.screenShareFullUser.avatar == model.browseUser.id,
          onDoubleTap: exitBrowseVideoAction,
          onLongPress: onLongPressAction,
        );
      });
    }

    //包含自己
    final List<VideoUser> users = model?.users ?? [];
    Widget widget;
    if (users.length <= 2) {
      //p2p的界面
      widget = VideoPageP2p(
        onDoubleTap: openBrowseVideoAction,
        onLongPress: onLongPressAction,
      );
    } else if (users.length == 3) {
      //3个成员的界面
      widget = VideoPageThree(
        onDoubleTap: openBrowseVideoAction,
        onLongPress: onLongPressAction,
      );
    } else {
      //超3个成员的界面
      widget = VideoPageMore(
        onDoubleTap: openBrowseVideoAction,
        onLongPress: onLongPressAction,
      );
    }

    return widget;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: const Color(0xFF000201),
      ),
      body: GetBuilder<VideoRoomController>(
          tag: widget.roomId,
          builder: (controller) {
            _controller = controller;
            return IgnorePointer(
              ignoring: _controller.ignoring,
              child: GestureDetector(
                onTap: () {
                  controller?.toggleToolbar();
                },
                onVerticalDragDown: (details) {
                  startPosition = details.localPosition.dy;
                },
                onVerticalDragUpdate: (details) {
                  distance = details.localPosition.dy - startPosition;
                },
                onVerticalDragEnd: (details) {
                  distance = distance.abs();
                  if (distance > 50) {
                    controller?.toggleToolbar();
                  }
                },
                child: Stack(
                  children: [
                    _buildBackground(),
                    videoWidget(controller),
                    Obx(() {
                      if (controller.screenShareState.value ==
                              ScreenShareType.opened &&
                          controller.hideScreenShareState.value ==
                              HideScreenShareViewType.open) {
                        return const VideoShareView();
                      } else {
                        return const SizedBox();
                      }
                    }),
                    VideoBottomView(),
                    VideoTopBar(_controller),
                  ],
                ),
              ),
            );
          }),
    );
  }
}
