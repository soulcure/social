import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:im/global.dart';
import 'package:im/hybrid/webrtc/room/video_room.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/avatar.dart';

class VideoCard extends StatelessWidget {
  final VideoUser user;
  const VideoCard(this.user);

  @override
  Widget build(BuildContext context) {
    if (user == null) return sizedBox;
    return user.enableCamera ? _buildVideo() : _buildCard(context);
  }

  Widget _buildVideo() {
    return SizedBox(
      width: 90,
      height: 138,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: RTCVideoView(
          user.video,
          key: Key(user.userId.toString()),
          mirror: user.userId == Global.user.id && user.useFrontCamera,
        ),
      ),
    );
  }

  Container _buildCard(BuildContext context) {
    return Container(
      width: 90,
      height: 138,
      decoration: BoxDecoration(
        color: Theme.of(context).backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: <Widget>[
          sizeHeight32,
          Avatar(
            url: user.avatar,
            radius: 24,
          ),
          sizeHeight32,
          Text(
            user.nickname,
            maxLines: 1,
            style: Theme.of(context).textTheme.bodyText2.copyWith(fontSize: 12),
          )
        ],
      ),
    );
  }
}
