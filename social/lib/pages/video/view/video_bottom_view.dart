import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/pages/video/model/video_room_controller.dart';
import 'package:im/pages/video/view/video_more_popup.dart';
import 'package:im/pages/video/view/video_room_member/videoroom_member_popup.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/widgets/dialog/center_tips_alter_widget.dart';
import 'package:just_throttle_it/just_throttle_it.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../icon_font.dart';

class VideoBottomView extends StatefulWidget {
  @override
  State<VideoBottomView> createState() => _VideoBottomViewState();
}

class _VideoBottomViewState extends State<VideoBottomView> {
  final VideoRoomController _videoRoomController =
      Get.find<VideoRoomController>(tag: VideoRoomController.sRoomId);
  double _screenWidth;

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = Get.mediaQuery.viewPadding.bottom;
    return GetBuilder<VideoRoomController>(
        tag: VideoRoomController.sRoomId,
        builder: (c) {
          return Stack(
            children: <Widget>[
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                bottom: c.hideToolbar.value ? -(56 + bottomPadding) : 0,
                curve: Curves.fastOutSlowIn,
                child: Container(
                  height: 56 + bottomPadding,
                  width: _screenWidth,
                  color: const Color(0xff1B1D1C),
                  child: Column(children: [
                    _buildToolbar(c.hideToolbar.value),
                  ]),
                ),
              )
            ],
          );
        });
  }

// 底部按钮栏
  Container _buildToolbar(bool hideToolbar) {
    const _textColor = Colors.white;
    return Container(
      height: 56,
      padding: const EdgeInsets.only(left: 24, right: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          //麦克风
          _buildOperationBtn(
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Obx(_buildMicView),
              sizeHeight2,
              Obx(() {
                return Text(
                    _videoRoomController.muted.value == MicrophoneType.noMute
                        ? '麦克风已开'
                        : '麦克风已关',
                    style: const TextStyle(color: _textColor, fontSize: 10));
              }),
            ]),
            onTap: _toggleMuted,
          ),
          // 摄像头
          _buildOperationBtn(
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Obx(() {
                return Icon(
                    _videoRoomController.enableVideo.value
                        ? IconFont.buffVideoCamera
                        : IconFont.buffVideoCameraOff,
                    color: _textColor,
                    size: 22);
              }),
              sizeHeight2,
              Obx(() {
                return Text(
                    _videoRoomController.enableVideo.value ? '摄像头已开' : '摄像头已关',
                    style: const TextStyle(color: _textColor, fontSize: 10));
              }),
            ]),
            onTap: _toggleCamera,
          ),
          // 共享
          _buildOperationBtn(
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Obx(_buildScreenShareView),
              sizeHeight2,
              Obx(() {
                return Text(
                    _videoRoomController.screenShareState.value ==
                            ScreenShareType.opened
                        ? '停止共享'.tr
                        : '共享屏幕'.tr,
                    style: const TextStyle(color: _textColor, fontSize: 10));
              }),
            ]),
            onTap: () {
              Throttle.milliseconds(1000, _toggleScreenShare);
            },
          ),
          //成员
          _buildOperationBtn(
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(IconFont.buffVideoMember, color: _textColor, size: 22),
              sizeHeight2,
              Obx(() {
                return Text("成员(${_videoRoomController.videoUserSum})",
                    style: const TextStyle(color: _textColor, fontSize: 10));
              }),
            ]),
            onTap: () {
              showBottomModal(
                context,
                backgroundColor: const Color(0xFFF5F5F8),
                showTopCache: false,
                cornerRadius: 10,
                margin: const EdgeInsets.all(0),
                // scrollSpec: const ScrollSpec(physics: AlwaysScrollableScrollPhysics()),
                builder: (c, s) => VideoroomMemberPopup(_videoRoomController),
              );
            },
          ),
          // 更多
          _buildOperationBtn(
            Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(IconFont.buffVideoMore, color: _textColor, size: 22),
                  sizeHeight2,
                  Text(
                    '更多',
                    style: TextStyle(color: _textColor, fontSize: 10),
                  ),
                ]),
            onTap: () {
              showVideoMorePopUp(context,
                  channelId: _videoRoomController.roomId);
            },
          )
        ],
      ),
    );
  }

// 通用工具按钮
  GestureDetector _buildOperationBtn(Widget widget, {Function onTap}) {
    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: Column(children: [
          const SizedBox(height: 10),
          SizedBox(width: 50, child: widget),
          const SizedBox(height: 8),
        ]));
  }

// // 普通工具按钮
//   GestureDetector _buildCommonBtn(
//     IconData icon, {
//     IconData inactiveIcon,
//     bool active = true,
//     bool disabled = false,
//     Function onTap,
//   }) {
//     return _buildOperationBtn(
//       Icon(
//         disabled ? icon : (!active ? inactiveIcon : icon),
//         size: 27,
//         color: !disabled ? Colors.white : const Color(0xff9fa2a8),
//       ),
//       onTap: onTap,
//     );
//   }

  @override
  void dispose() {
    Throttle.clear(_toggleScreenShare);
    super.dispose();
  }

  void _toggleScreenShare() {
    _videoRoomController.toggleScreenShare();
  }

  ///麦克风状态
  Widget _buildMicView() {
    if (_videoRoomController.muted.value == MicrophoneType.mute) {
      return const Icon(IconFont.buffVideoMicOff,
          color: Colors.white, size: 22);
    } else if (_videoRoomController.muted.value == MicrophoneType.noMute) {
      return const Icon(IconFont.buffVideoMic, color: Colors.white, size: 22);
    } else if (_videoRoomController.muted.value == MicrophoneType.muteBan) {
      return const Icon(IconFont.buffVideoMicBan,
          color: Color(0xFFF24848), size: 22);
    } else {
      return const SizedBox();
    }
  }

  Future<void> _toggleMuted() async {
    //checkPermission(Permission.microphone);
    final bool isMicPermissionGranted = await requestMicrophonePermission();
    final bool isCameraPermissionGranted = await requestCameraPermission();
    if (!isMicPermissionGranted) {
      await CenterTipsAlterWidget.show(
          context, "需要获得麦克风权限", '请在设置中打开Fanbook的麦克风权限', openAppSettings);
    } else if (!isCameraPermissionGranted) {
      await CenterTipsAlterWidget.show(
          context, "需要获得相机权限", '请在设置中打开Fanbook的相机权限', openAppSettings);
    } else {
      await _videoRoomController.toggleMuted();
    }
  }

  Future<void> _toggleCamera() async {
    //checkPermission(Permission.camera);
    final bool isMicPermissionGranted = await requestMicrophonePermission();
    final bool isCameraPermissionGranted = await requestCameraPermission();
    if (!isMicPermissionGranted) {
      await CenterTipsAlterWidget.show(
          context, "需要获得麦克风权限", '请在设置中打开Fanbook的麦克风权限', openAppSettings);
    } else if (!isCameraPermissionGranted) {
      await CenterTipsAlterWidget.show(
          context, "需要获得摄像头权限", '请在设置中打开Fanbook的摄像头权限', openAppSettings);
    } else {
      await _videoRoomController.toggleCamera();
    }
  }

// 背景
  Widget _buildScreenShareView() {
    if (_videoRoomController.screenShareState.value == ScreenShareType.normal) {
      return const Icon(IconFont.buffVideoShare, color: Colors.white, size: 22);
    } else if (_videoRoomController.screenShareState.value ==
        ScreenShareType.opened) {
      return const Icon(IconFont.buffVideoShareOpened,
          color: Color(0xFFF24848), size: 22);
    } else if (_videoRoomController.screenShareState.value ==
        ScreenShareType.ban) {
      return const Icon(IconFont.buffVideoShareBan,
          color: Color(0xFFF24848), size: 22);
    } else {
      return const SizedBox();
    }
  }

  Future<bool> requestMicrophonePermission() async {
    final PermissionStatus microphoneStatus =
        await Permission.microphone.request();
    return microphoneStatus.isGranted;
  }

  Future<bool> requestCameraPermission() async {
    final PermissionStatus cameraStatus = await Permission.camera.request();
    return cameraStatus.isGranted;
  }

//判断是否有权限
//   void checkPermission(Permission permission) async {
//     PermissionStatus status = await permission.status;
//     print('检测权限$status');
//     if (status.isGranted) {
//       //权限通过
//       if (permission == Permission.microphone) {
//         _videoRoomController.toggleMuted();
//       } else if (permission == Permission.camera) {
//         _videoRoomController.toggleCamera();
//       }
//     } else if (status.isDenied) {
//       //权限拒绝， 需要区分IOS和Android，二者不一样
//       requestPermission(permission);
//     } else if (status.isPermanentlyDenied) {
//       //权限永久拒绝，且不在提示，需要进入设置界面
//       openAppSettings();
//     } else if (status.isRestricted) {
//       //活动限制（例如，设置了家长///控件，仅在iOS以上受支持。
//       openAppSettings();
//     } else {
//       //第一次申请
//       requestPermission(permission);
//     }
//   }
//
// //申请权限
//   void requestPermission(Permission permission) async {
//     PermissionStatus status = await permission.request();
//     print('权限状态$status');
//     if (!status.isGranted) {
//       openAppSettings();
//     }
//   }
}
