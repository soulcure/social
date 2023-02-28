import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/community/virtual_video_room/views/widget/bottom_menu.dart';
import 'package:im/community/virtual_video_room/views/widget/video_item_view.dart';
import 'package:im/hybrid/webrtc/room/base_room.dart';
import 'package:im/hybrid/webrtc/room/video_room.dart';
import 'package:im/hybrid/webrtc/room_manager.dart';
import 'package:im/hybrid/webrtc/tools/rtc_log.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/utils/utils.dart';
import 'package:oktoast/oktoast.dart';

import '../../../global.dart';
import '../../unity_bridge_with_webrtc.dart';

enum MyRoomState {
  unJoined,
  joining,
  joined,
  joinFail,
  exit,
}

enum VideoListSwitchState {
  smallOneRow,
  smallThreeRow,
  bigTwoMember,
  bigThreeMore,
}

class VirtualRoomParams {
  final String roomId;
  bool isMuted;

  /// 自己的状态
  bool isCameraOpen;
  bool isAllVideoMuted;
  bool isAllAudioMuted;

  VirtualRoomParams(this.roomId,
      {this.isMuted = true,
      this.isCameraOpen = false,
      this.isAllVideoMuted = false,
      this.isAllAudioMuted = false});
}

class VirtualRoomController extends GetxController {
  static const int userListObject = 1;

  static VirtualRoomController to() {
    VirtualRoomController c;
    try {
      c = Get.find<VirtualRoomController>();
    } catch (e) {
      print(e);
    }
    return c ??= Get.put<VirtualRoomController>(VirtualRoomController());
  }

  UnityBridgeWithWebRTC _unityBridgeController;
  ScrollController listScrollController = ScrollController();
  PageController threeRowPageController = PageController();

  VirtualRoomParams roomParams;

  /// 房间id
  // String roomId;

  /// videoRoom controller
  VideoRoom _videoRoom;

  /// 当前显示人的信息
  VideoUser currentUser;

  RxBool isVideoOn = true.obs;
  RxBool hideAll = false.obs;
  Rx<ArrowState> leftState = Rx<ArrowState>(ArrowState.off);
  Rx<ArrowState> rightState = Rx<ArrowState>(ArrowState.on);
  Rx<FullState> fullState = Rx<FullState>(FullState.toMin);
  Rx<VideoListSwitchState> videoListSwitchState =
      Rx<VideoListSwitchState>(VideoListSwitchState.smallOneRow);
  RxBool showVideoUi = false.obs;

  MyRoomState myRoomState = MyRoomState.unJoined;

  /// 加入房间
  Future<void> joinRoom(VirtualRoomParams roomParams,
      UnityBridgeWithWebRTC unityBridgeController) async {
    RtcLog.log('----------------------------------------- joinRoom');
    _initUiAndStatus();
    _unityBridgeController = unityBridgeController;
    this.roomParams = roomParams;
    myRoomState = MyRoomState.joining;
    final VideoRoom room = await RoomManager.create(
      RoomType.video,
      roomParams.roomId,
      RoomParams(
        userId: Global.user.id,
        nickname: Global.user.nickname,
        avatar: Global.user.avatar,
        enableCamera: roomParams.isCameraOpen,
        muted: roomParams.isMuted,
        deviceId: Global.deviceInfo.identifier,
      ),
    );

    _videoRoom = room;
    room.onEvent = _onEvent;

    await room.join();

    currentUser = _videoRoom.user;

    showVideoUi.value = true;
  }

  /// 离开房间
  Future<void> exitRoom([String msg]) async {
    RtcLog.log('----------------------------------------- exitRoom');
    showVideoUi.value = false;
    hideAll.value = false;
    _unityBridgeController = null;
    myRoomState = MyRoomState.exit;
    await _close(msg);
    GlobalState.hangUp();
  }

  /// 打开关闭摄像头
  bool toggleCamera() {
    roomParams.isCameraOpen = !roomParams.isCameraOpen;
    _videoRoom.enableCamera = roomParams.isCameraOpen;
    update([userListObject]);
    return roomParams.isCameraOpen;
  }

  /// 切换静音
  bool toggleMuted() {
    roomParams.isMuted = !roomParams.isMuted;
    _videoRoom.muted = roomParams.isMuted;
    update([userListObject]);
    if (!roomParams.isMuted) {
      _videoRoom?.changeToSpeaker();
    }
    return roomParams.isMuted;
  }

  /// 切换摄像头
  void switchCamera() {
    _videoRoom.switchCamera();
  }

  /// 打开关闭所有人的视频，不包括自己
  void muteAllVideo() {
    roomParams.isAllVideoMuted = !roomParams.isAllVideoMuted;
    _videoRoom?.users?.forEach((user) {
      if (Global.user.id != user.userId) {
        user.enableCamera = !roomParams.isAllVideoMuted;
        user.muteVideo(roomParams.isAllVideoMuted);
      }
    });
    update([userListObject]);
  }

  /// 打开关闭所有其他人的音频，不包括自己
  void muteAllAudio() {
    roomParams.isAllAudioMuted = !roomParams.isAllAudioMuted;
    _videoRoom?.users?.forEach((user) {
      if (Global.user.id != user.userId)
        user.muteAudio(roomParams.isAllAudioMuted);
    });
    update([userListObject]);
  }

  /// 销毁 controller
  Future<void> destroy() async {
    final delResult = await Get.delete<VirtualRoomController>();
    debugPrint('getChat audio - closeAndDispose end - delResult:$delResult');
  }

  void onBottomVideoClick(bool isVideoOn) {
    print('--isVideoOn = $isVideoOn');
    this.isVideoOn.value = !isVideoOn;
    muteAllVideo();
  }

  void onBottomLeftClick() {
    print('--onLeftClick');
    if (videoListSwitchState.value == VideoListSwitchState.smallOneRow) {
      final index = listScrollController.offset ~/ (SMALL_VIDEO_ITEM_WIDTH + 4);
      print('index = $index');
      listScrollController.animateTo((index - 1) * (SMALL_VIDEO_ITEM_WIDTH + 4),
          duration: const Duration(milliseconds: 200), curve: Curves.linear);
    } else if (videoListSwitchState.value ==
        VideoListSwitchState.smallThreeRow) {
      threeRowPageController.animateToPage(
          threeRowPageController.page.toInt() - 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.linear);
      Timer(const Duration(milliseconds: 250), () {
        if (threeRowPageController.position.atEdge &&
            threeRowPageController.page == 0) {
          leftState.value = ArrowState.off;
          rightState.value = ArrowState.on;
        }
      });
    }
  }

  void onBottomRightClick() {
    if (videoListSwitchState.value == VideoListSwitchState.smallOneRow) {
      final index = listScrollController.offset ~/ (SMALL_VIDEO_ITEM_WIDTH + 4);
      print('index = $index');
      listScrollController.animateTo((index + 1) * (SMALL_VIDEO_ITEM_WIDTH + 4),
          duration: const Duration(milliseconds: 200), curve: Curves.linear);
    } else if (videoListSwitchState.value ==
        VideoListSwitchState.smallThreeRow) {
      threeRowPageController.animateToPage(
          threeRowPageController.page.toInt() + 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.linear);
      Timer(const Duration(milliseconds: 250), () {
        if (threeRowPageController.position.atEdge &&
            threeRowPageController.page > 0) {
          rightState.value = ArrowState.off;
          leftState.value = ArrowState.on;
        }
      });
    }
  }

  void onBottomFullClick(FullState state) {
    print('--onFullClick $state');
    if (state == FullState.toMin) {
      videoListSwitchState.value = VideoListSwitchState.smallOneRow;
      if (users.length > 4) {
        leftState.value = ArrowState.off;
        rightState.value = ArrowState.on;
      } else {
        leftState.value = ArrowState.unVisible;
        rightState.value = ArrowState.unVisible;
      }
    } else if (state == FullState.toFull) {
      videoListSwitchState.value = VideoListSwitchState.smallThreeRow;
      if (users.length < 13) {
        leftState.value = ArrowState.unVisible;
        rightState.value = ArrowState.unVisible;
      } else {
        leftState.value = ArrowState.off;
        rightState.value = ArrowState.on;
      }
    }

    fullState.value =
        state == FullState.toMin ? FullState.toFull : FullState.toMin;
  }

  void onBottomHideAllClick(bool isHideAll) {
    hideAll.value = !isHideAll;
    update([userListObject]);
  }

  void onBottomDisplayAllClick() {
    hideAll.value = false;
    update([userListObject]);
  }

  void onVideoItemClick(int index, bool isSmallVideo, VideoUser videoUser) {
    if (isSmallVideo) {
      if (users.length > 2) {
        final tempVideoUser = videoUser;
        users.removeAt(index);
        users.insert(0, tempVideoUser);
      }

      if (users.length == 2) {
        videoListSwitchState.value = VideoListSwitchState.bigTwoMember;
      } else if (users.length >= 3) {
        videoListSwitchState.value = VideoListSwitchState.bigThreeMore;
      }
    } else {
      if (users.length > 4) {
        fullState.value = FullState.toFull;
      }
      videoListSwitchState.value = VideoListSwitchState.smallOneRow;
    }

    update([userListObject]);
  }

  /// test start
  // List<VideoUser> get users => _users;
  /// test end

  /// 成员列表
  List<VideoUser> get users => _videoRoom?.users;

  ///当前房间人数
  int get userLength => users?.length ?? 0;

  /// test start
  List<VideoUser> get makeUsers {
    if (users.isNotEmpty) return users;
    for (int i = 0; i < 25; i++) {
      final VideoUser user = VideoUser.from2();
      user.userId = '$i';
      user.nickname = '$i汝青霄 ';
      user.muted = false;
      user.enableCamera = true;
      user.talking = 0 == i % 2;
      // user.talking = true;
      user.useFrontCamera = true;
      users.add(user);
    }

    if (users.length <= 4) {
      leftState.value = ArrowState.unVisible;
      rightState.value = ArrowState.unVisible;
      fullState.value = FullState.unVisible;
    } else {
      leftState.value = ArrowState.off;
      rightState.value = ArrowState.on;
      fullState.value = FullState.toFull;
    }

    return users;
  }

  /// test end

  /// 判断主屏幕是否展示用户本人
  bool get isSelf => currentUser.userId == Global.user.id;

  VirtualRoomController() {
    myRoomState = MyRoomState.unJoined;
  }

  void _initUiAndStatus() {
    videoListSwitchState.value = VideoListSwitchState.smallOneRow;
    leftState.value = ArrowState.unVisible;
    rightState.value = ArrowState.unVisible;
    fullState.value = FullState.unVisible;
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    print('------------------------- onInit');

    _initUiAndStatus();

    /// test start
    // makeUsers;
    // showVideoUi.value = true;
    /// test end

    listScrollController.addListener(() {
      print('offset =  ${listScrollController.offset}');
      if (listScrollController.offset > 0) {
        leftState.value = ArrowState.on;
      } else {
        leftState.value = ArrowState.off;
      }

      ///滑动到最后一个item
      if (listScrollController.position.atEdge &&
          listScrollController.offset > 0) {
        rightState.value = ArrowState.off;
      } else {
        rightState.value = ArrowState.on;
      }
    });

    threeRowPageController.addListener(() {
      if (threeRowPageController.position.atEdge &&
          threeRowPageController.page == 0) {
        leftState.value = ArrowState.off;
      } else {
        leftState.value = ArrowState.on;
      }

      if (threeRowPageController.position.atEdge &&
          threeRowPageController.page > 0) {
        rightState.value = ArrowState.off;
      } else {
        rightState.value = ArrowState.on;
      }
    });
  }

  @override
  void onClose() {
    print('---------- virtualRoomController onClose');
    listScrollController.dispose();
    threeRowPageController.dispose();
  }

  void _onEvent(RoomState state, [data]) {
    print('getChat -- onEvent state = $state, length：$userLength, $data');
    switch (state) {

      ///自己初始化完成
      case RoomState.inited:
        update([userListObject]);
        _updateUnityImage();
        break;

      ///别人加入房间
      case RoomState.joined:
        if (users.length >= 3 &&
            videoListSwitchState.value == VideoListSwitchState.bigTwoMember) {
          videoListSwitchState.value = VideoListSwitchState.bigThreeMore;
        }
        _onUpdateUi();
        update([userListObject]);
        if (roomParams.isAllAudioMuted) {
          _videoRoom?.users?.forEach((user) {
            if (Global.user.id != user.userId)
              user.muteAudio(roomParams.isAllAudioMuted);
          });
        }
        if (roomParams.isAllVideoMuted) {
          _videoRoom?.users?.forEach((user) {
            if (Global.user.id != user.userId) {
              user.enableCamera = !roomParams.isAllVideoMuted;
              user.muteVideo(roomParams.isAllVideoMuted);
            }
          });
        }
        _updateUnityImage();
        break;
      case RoomState.changed:
        update([userListObject]);
        break;
      case RoomState.leaved:
        if (data == currentUser) {
          currentUser = _videoRoom.user;
        }
        if (userLength < 2 &&
            videoListSwitchState.value == VideoListSwitchState.bigTwoMember) {
          videoListSwitchState.value = VideoListSwitchState.smallOneRow;
        }
        if (userLength < 5 &&
            videoListSwitchState.value == VideoListSwitchState.smallThreeRow) {
          videoListSwitchState.value = VideoListSwitchState.smallOneRow;
        }
        _onUpdateUi();
        update([userListObject]);
        break;
      case RoomState.error:
        myRoomState = MyRoomState.joinFail;
        exitRoom();
        break;
      case RoomState.disconnected:
        break;
      case RoomState.inRoomStatus:
        myRoomState =
            (data as bool) ? MyRoomState.joined : MyRoomState.joinFail;
        break;
      case RoomState.roomFull:
        update([userListObject]);
        break;
      default:
        break;
    }
  }

  Future<void> _updateUnityImage() async {
    for (final VideoUser user in _videoRoom?.users) {
      if (user.unityImagePath == null) {
        user.unityImagePath =
            await _unityBridgeController.getUserPhoto(user.userId);
        update([userListObject]);
      }
    }
  }

  ///更新控制栏：左右箭头、切换列表视图
  void _onUpdateUi() {
    if (userLength <= 4) {
      leftState.value = ArrowState.unVisible;
      rightState.value = ArrowState.unVisible;
      fullState.value = FullState.unVisible;
    } else {
      leftState.value = ArrowState.off;
      rightState.value = ArrowState.on;
      fullState.value = FullState.toFull;
    }
  }

  /// 关闭房间
  Future<void> _close([String msg]) async {
    _videoRoom = null;
    if (isNotNullAndEmpty(msg)) showToast(msg);
    await RoomManager.close();
  }
}
