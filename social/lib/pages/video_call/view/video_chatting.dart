import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:im/hybrid/webrtc/room/video_room.dart';
import 'package:im/pages/video_call/model/video_model.dart';
import 'package:im/pages/video_call/view/video_card.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/avatar.dart';
import 'package:provider/provider.dart';

import '../../../global.dart';

class VideoChatting extends StatefulWidget {
  final VideoModel model;
  const VideoChatting(this.model);

  @override
  _VideoChattingState createState() => _VideoChattingState();
}

class _VideoChattingState extends State<VideoChatting> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.model,
      child: Consumer<VideoModel>(
        builder: (context, model, _) {
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // 大视图
              InkWell(
                onTap: () {
                  model.toggleToolBar();
                },
                child: widget.model.currentUser == null
                    ? sizedBox
                    : widget.model.currentUser.enableCamera
                        ? RTCVideoView(
                          widget.model.currentUser.video,
                          key: Key(
                            widget.model.currentUser.userId.toString(),
                          ),

                          // dj added 使用原先render中设置的属性
                          mirror: model.currentUser.userId ==
                              Global.user.id &&
                              model.currentUser.useFrontCamera,
                          objectFit: RTCVideoViewObjectFit
                              .RTCVideoViewObjectFitCover,
                        )
                        : _buildMainFace(widget.model.currentUser),
              ),
              // 卡片
              Positioned(
                top: 120,
                right: 8,
                child: InkWell(
                  onTap: () {
                    model.switchVideo(widget.model.users[0]);
                  },
                  child: VideoCard(widget.model.users != null &&
                          widget.model.users.isNotEmpty
                      ? widget.model.users[0]
                      : null),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainFace(VideoUser user) {
    return Column(
      children: <Widget>[
        const Expanded(
          child: sizedBox,
        ),
        Expanded(
          flex: 2,
          child: Column(
            children: <Widget>[
              Avatar(
                url: user.avatar,
                radius: 80,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
