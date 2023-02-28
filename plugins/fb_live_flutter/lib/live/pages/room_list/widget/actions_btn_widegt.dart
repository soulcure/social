import 'package:flutter/material.dart';

import '../../../utils/ui/frame_size.dart';
import 'create_room_button.dart';

class ActionsBtn extends StatelessWidget {
  final bool? fbCanStartLive;

  const ActionsBtn({Key? key, this.fbCanStartLive}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return fbCanStartLive!
        ? SizedBox(
            width: FrameSize.px(55),
            child: CreateRoomButton(
                title: '开播',
                size: Size(FrameSize.px(60), FrameSize.px(32)),
                circular: 4.px),
          )
        : Container();
  }
}
