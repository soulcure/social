import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/hybrid/webrtc/room_manager.dart';
import 'package:im/pages/home/view/check_permission.dart';
import 'package:im/pages/video_call/model/video_model.dart';
import 'package:im/pages/video_call/view/video_calling.dart';
import 'package:im/pages/video_call/view/video_chatting.dart';
import 'package:im/pages/video_call/view/video_receiving.dart';
import 'package:im/pages/video_call/view/video_room_chatting.dart';
import 'package:im/pages/video_call/view/video_tool_view.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:pedantic/pedantic.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class VideoPage extends StatefulWidget {
  final String userId;
  final String roomId;
  final bool isCaller;
  final bool isVideo;
  final bool autoAnswer;
  final VideoModel oldModel;
  const VideoPage(
    this.userId,
    this.isCaller, {
    this.roomId,
    this.isVideo = false,
    this.autoAnswer = false,
    this.oldModel,
  });

  @override
  _VideoPageState createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  VideoModel _model;
  bool _inited = false;

  @override
  void initState() {
    if (widget.oldModel == null) {
      _model = VideoModel(widget.isVideo);
      _model.roomId = widget.roomId;
      _model.callUserId = widget.userId;
      _model.state =
          widget.isCaller ? VideoState.calling : VideoState.receiving;

      _init();
    } else {
      _inited = true;
      _model = widget.oldModel;
    }

    super.initState();
  }

  Future<void> _init() async {
    try {
      await _model.init();
    } catch (e) {
      if (e == RoomManager.premissError) {
        unawaited(checkSystemPermissions(
            context: context,
            permissions: const [Permission.microphone, Permission.camera],
            // rejectedTips: "请允许麦克风和摄像头权限",
            onRejectedCancel: () {
              Get.back();
              _close();
            }));
        return;
      }
    }

    if (widget.autoAnswer) {
      await _model.answer();
    }
    _inited = true;
    setState(() {});
  }

  void _close() {
    Routes.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return !_inited
        ? sizedBox
        : WillPopScope(
            onWillPop: () async {
              return false;
            },
            child: Scaffold(
              body: ChangeNotifierProvider.value(
                value: _model,
                child: Consumer<VideoModel>(
                  builder: (context, model, widget) {
                    return Stack(
                      children: <Widget>[
                        _getView(_model.state),
                        Visibility(
                          visible: model.state != VideoState.receiving,
                          child: SafeArea(child: VideoToolView(model)),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
  }

  Widget _getView(VideoState state) {
    switch (state) {
      case VideoState.calling:
        return VideoCalling(_model);
      case VideoState.receiving:
        return VideoReceiving(_model);
      case VideoState.chatting:
        return VideoChatting(_model);
      case VideoState.roomChatting:
        return VideoRoomChatting(_model);
      default:
        throw 'Unnkow state';
    }
  }
}
