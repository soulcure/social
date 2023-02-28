import 'package:flutter/material.dart';
import 'package:im/hybrid/webrtc/room/base_room.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/avatar.dart';

class VideoFace extends StatelessWidget {
  final RoomUser user;
  final String tips;
  const VideoFace(this.user, this.tips);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Expanded(
          child: sizedBox,
        ),
        Expanded(
          flex: 3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Avatar(
                url: user.avatar,
                radius: 80,
              ),
              sizeHeight16,
              Text(
                user.nickname,
                style: Theme.of(context).textTheme.bodyText2,
              ),
              sizeHeight8,
              Text(
                tips,
                style: const TextStyle(
                  color: Color(0xFF8F959E),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
