import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/global.dart';
import 'package:im/hybrid/webrtc/room/base_room.dart';
import 'package:im/hybrid/webrtc/room_manager.dart';
import 'package:im/pages/home/view/check_permission.dart';
import 'package:im/pages/video_call/model/video_model.dart';
import 'package:im/pages/video_call/view/video_face.dart';
import 'package:im/themes/const.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class VideoCalling extends StatefulWidget {
  final VideoModel model;

  const VideoCalling(this.model);

  @override
  _VideoCallingState createState() => _VideoCallingState();
}

class _VideoCallingState extends State<VideoCalling> {
  Future call;

  @override
  void initState() {
    call = _init();
    super.initState();
  }

  Future _init() async {
    return widget.model.call(widget.model.callUserId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: call,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          RoomManager.close();
          if (snapshot.error == RoomManager.premissError) {
            checkSystemPermissions(
              context: context,
              permissions: [Permission.microphone, Permission.camera],
              // rejectedTips: "请允许麦克风和摄像头权限",
            );
            return sizedBox;
          } else {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text("连接语音超时，请稍后重试！".tr),
                  sizeHeight20,
                  Text(snapshot.error.toString()),
                  sizeHeight20,
                  TextButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: Text("点击重试".tr),
                  ),
                ],
              ),
            );
          }
        } else {
          return ChangeNotifierProvider.value(
            value: widget.model,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Consumer<VideoModel>(
                  builder: (_, model, widget) {
                    // 我方视图
                    return InkWell(
                      onTap: () {
                        model.toggleToolBar();
                      },
                      child: model.currentUser == null ||
                              !model.currentUser.enableCamera ||
                              model.currentUser.video == null
                          ? const SizedBox(
                              width: double.infinity, height: double.infinity)
                          : RTCVideoView(
                            model.currentUser.video,
                            key: Key(model.currentUser.userId.toString()),
                            mirror: model.currentUser.userId ==
                                    Global.user.id &&
                                model.currentUser.useFrontCamera,
                          ),
                    );
                  },
                ),
                // 对方视图
                ValueListenableBuilder(
                  valueListenable: widget.model.waitingAnswer,
                  builder: (context, value, child) {
                    return FutureBuilder<UserInfo>(
                        future: UserInfo.get(widget.model.callUserId),
                        builder: (context, snapshot) {
                          return VideoFace(
                            RoomUser(
                              nickname: snapshot.data?.nickname ?? "",
                              avatar: snapshot.data?.avatar ?? "",
                            ),
                            value ? "等待对方接听..".tr : "呼叫中..".tr,
                          );
                        });
                  },
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
