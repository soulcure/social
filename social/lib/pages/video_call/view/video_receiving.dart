import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/hybrid/webrtc/room/base_room.dart';
import 'package:im/pages/video_call/model/video_model.dart';
import 'package:im/pages/video_call/view/video_face.dart';
import 'package:im/routes.dart';
import 'package:im/utils/sound_manager.dart';

class VideoReceiving extends StatefulWidget {
  final VideoModel model;
  const VideoReceiving(this.model);

  @override
  _VideoReceivingState createState() => _VideoReceivingState();
}

class _VideoReceivingState extends State<VideoReceiving> {
  bool _isClosed = false;
  AudioPlayer _player;

  @override
  void initState() {
    widget.model.onComplete = _close;
    _playSound();
    super.initState();
  }

  Future<void> _playSound() async {
    _player = await SoundManager.playSound("sound/call.mp3");
  }

  Future<void> _stopSound() async {
    if (_player != null) {
      await _player.stop();
      await _player.dispose();
    }
  }

  void _close() {
    if (!_isClosed) {
      _isClosed = true;
      _stopSound();
      widget.model.close("通话已拒绝".tr);
      Routes.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        FutureBuilder(
            future: UserInfo.get(widget.model.callUserId),
            builder: (context, snapshot) {
              return VideoFace(
                RoomUser(
                  nickname: snapshot.data?.nickname ?? "",
                  avatar: snapshot.data?.avatar ?? "",
                ),
                "来电..".tr,
              );
            }),
        _buildAnswer(context),
      ],
    );
  }

  Positioned _buildAnswer(context) {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          // 拒绝
          InkWell(
            onTap: () {
              _close();
              widget.model.answerCancel();
            },
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF2494A),
              ),
              child: const Icon(
                Icons.call_end,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          // 接听
          InkWell(
            onTap: () async {
              await _stopSound();
              // Future.delayed(Duration(seconds: 1), widget.model.answer);
              await widget.model.answer();
            },
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF29CC5F),
              ),
              child: const Icon(
                Icons.call,
                size: 40,
                color: Colors.white,
              ),
            ),
          )
        ],
      ),
    );
  }
}
