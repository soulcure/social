/*
 * @FilePath       : /social/lib/pages/video/view/video_bar.dart
 * 
 * @Info           : 
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-01-06 15:57:25
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-04-26 17:56:58
 * 
 */
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:im/pages/home/home_page.dart';
import 'package:im/pages/video/model/video_room_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/widgets/circle_icon.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:provider/provider.dart';

class VideoBar extends StatefulWidget {
  final VideoRoomModel model;
  const VideoBar(this.model);

  @override
  _VideoBarState createState() => _VideoBarState();
}

class _VideoBarState extends State<VideoBar> {
  @override
  Widget build(BuildContext context) {
    if (VideoRoomModel.instance == null) {
      return const SizedBox();
    }
    return ChangeNotifierProvider.value(
      value: widget.model,
      child: Consumer<VideoRoomModel>(
        builder: (context, model, widget) {
          if (VideoRoomModel.networkError.value) return const SizedBox();
          Widget _child;
          if (model.currentShowVideo) {
            _child = ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: RTCVideoView(
                  model.currentUser.video,
                  key: Key(model.currentUser.userId.toString()),
                ));
          } else {
            _child = Column(mainAxisSize: MainAxisSize.min, children: [
              RealtimeAvatar(
                userId: model.currentUser.userId,
                size: 50,
              ),
              sizeHeight8,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  model.currentUser.nickname,
                  style: Theme.of(context).textTheme.bodyText2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            ]);
          }
          return GestureDetector(
            onTap: () =>
                RestoreMediaChannelViewNotification().dispatch(context),
            child: SizedBox(
              width: 90,
              height: 138,
              child: Stack(children: [
                Align(
                  child: _child,
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleIcon(
                      size: 12,
                      color: Colors.white,
                      backgroundColor: DefaultTheme.dangerColor,
                      icon: Icons.call_end,
                      onTap: () {
                        model.closeAndDispose("视频聊天已结束".tr);
                      }),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}
