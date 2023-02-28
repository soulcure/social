import 'dart:async';

import 'package:get/get.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_mixin.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/hybrid/webrtc/room/base_room.dart';
import 'package:im/hybrid/webrtc/room/multi_video_room.dart';
import 'package:im/hybrid/webrtc/room_manager.dart';
import 'package:im/pages/home/home_page.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/dock.dart';
import 'package:im/pages/member_list/model/member_list_model.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';
import 'package:oktoast/oktoast.dart';
import 'package:wakelock/wakelock.dart';

import '../../../loggers.dart';

///视频频道-状态<p>
///unJoined: 未加入(默认)；joining：加入中；joined：已加入；joinFail：加入失败；reconnect：加入后断网重连
enum JoinStatus { joining, joined, unJoined, joinFail, reconnect }

enum ButtonType { toggleOutPut, quit, toggleMicro }

enum MicrophoneType { mute, noMute, muteBan }

enum MuteType { single, group }

enum ScreenShareType { normal, opened, ban }

enum HideScreenShareViewType { normal, open, hide }

class VideoRoomController extends GetxController with GuildPermissionListener {
  static const int headInfoObject = 1;
  static const int audioBarObject = 2;
  static const int userListObject = 3;
  static const int invitedButtonObject = 4;
  static const int channelSettingObject = 5;
  static const int invitedItemObject = 6;
  static const int muteMemberButtonObject = 6;
  static const int joinRoomButtonObject = 7;
  static const int kickMemberButtonObject = 8;
  static const int shareButtonObject = 9;

  static const int MAX_PUBLISHERS = 30;

  /// 房间id
  String _roomId;

  String get roomId => _roomId;

  String _roomName;

  String get roomName => _roomName;

  String _guildName;

  String get guildName => _guildName;

  String _guildId;

  String get guildId => _guildId;

  StreamSubscription _permissionChangeStreamSubscription;

  ///语音频道当前状态
  Rx<JoinStatus> joined = Rx<JoinStatus>(JoinStatus.unJoined);

  bool isJoining() => joined.value == JoinStatus.joining;

  /// 自己是否静音
  Rx<MicrophoneType> muted = MicrophoneType.mute.obs;

  /// 房间是否静音
  final roomMute = false.obs;

  /// 是否隐藏工具栏
  final hideToolbar = false.obs;

  /// 是否开启摄像头
  final enableVideo = false.obs;

  final isShowFullScreenShare = false.obs;

  /// 是否隐藏共享屏幕界面
  Rx<HideScreenShareViewType> hideScreenShareState =
      HideScreenShareViewType.normal.obs;

  bool isHideScreenShareView() =>
      hideScreenShareState.value == HideScreenShareViewType.open;

  /// 屏幕共享状态
  Rx<ScreenShareType> screenShareState = ScreenShareType.normal.obs;

  bool ignoring = false;

  // //是否开启屏幕共享
  // RxBool enableScreenShare = false.obs;
  //
  // /// 是否可以屏幕共享
  // RxBool isCanScreenShare = true.obs;

  ///成员人数
  RxInt get sum {
    return _videoRoom?.users?.length?.obs ?? 0.obs;
  }

  /// 成员列表
  List<VideoUser> get users {
    return _videoRoom?.users ?? [];
  }

  /// 成员人数（不包括屏幕共享流）
  RxInt get videoUserSum {
    final List<VideoUser> videoUsers = users
        .where((videoUser) => videoUser.userId != MultiVideoRoom.SCREEN_USER_ID)
        .toList();
    return videoUsers?.length?.obs ?? 1.obs;
  }

  /// 当前显示人的信息
  VideoUser currentUser;

  /// 双击全屏浏览的用户
  VideoUser browseUser;

  VideoUser screenShareFullUser;

  /// 自己
  VideoUser me;

  /// videoRoom controller
  MultiVideoRoom _videoRoom;

  Timer _timer;

  bool isNotifyListener = true;

  /// 文本聊天model
  // TextRoomModel textRoomModel;

  /// 判断主屏幕是否展示用户本人
  bool get isSelf => currentUser.id == me.id;

  bool get hasScreenShared {
    if (screenShareUser != null && screenShareUser.video != null) {
      print("[dj]hasScreenShared:true");
      return true;
    }
    print("[dj]hasScreenShared:false");
    return false;
  }

  VideoUser get screenShareUser {
    if (_videoRoom != null) {
      return _videoRoom.screenShareUser;
    }
    return null;
  }

  /// 本人开启视频或者其他人开启视频不显示video
  bool get currentShowVideo => currentUser != null && currentUser.enableCamera;

  ///????? 临时改，后续要去掉
  static String sRoomId;

  static VideoRoomController to(String roomId) {
    VideoRoomController c;
    try {
      c = Get.find<VideoRoomController>(tag: roomId);
    } catch (e, s) {
      logger.severe("audio room controller find tag $roomId error", e, s);
    }
    sRoomId = roomId;
    return c ??=
        Get.put<VideoRoomController>(VideoRoomController(roomId), tag: roomId);
  }

  Future<void> joinVideoRoom() async {
    logger.info('joinAudioRoom start roomId: $roomId, joined ${joined?.value}');
    //防止用户连续点击
    if (joined.value == JoinStatus.joining) return;

    // 加入房间，先退出旧房间
    final channelId = GlobalState.mediaChannel?.value?.item2?.id;
    if (channelId != null && channelId != roomId)
      try {
        final VideoRoomController oldCtl = Get.find<VideoRoomController>(
            tag: GlobalState.mediaChannel.value.item2.id);
        // if (oldCtl != null) await oldCtl.closeAndDispose(flag: 1);
        await oldCtl?.closeAndDispose();
      } catch (e, s) {
        logger.severe("join video room exception", e, s);
      }
    if (joined.value == JoinStatus.joined) return;

    await createRoomManager();

    joined.value = JoinStatus.joining;
    update([userListObject]);

    ///加入视频频道，设置5秒超时
    await _videoRoom.join().timeout(5.seconds, onTimeout: () async {
      ///超时后，有可能已经加入成功
      if (joined.value == JoinStatus.joined) return;
      joined.value = JoinStatus.joinFail;
      await closeAndDispose('网络异常，请重试'.tr);
      Get.back();
      throw '加入视频频道超时: $roomId';
    });
    //设置屏幕常亮
    await Wakelock.enable();
  }

  VideoRoomController(String roomId) : assert(roomId != null) {
    _roomId = roomId;
    // textRoomModel = TextRoomModel(_videoRoom.textRoom);
    final channel = Db.channelBox.get(roomId);
    _roomName = channel.name;
    final guildTarget = ChatTargetsModel.instance.getGuild(channel.guildId);
    _guildId = channel.guildId;
    _guildName = guildTarget.name;
  }

  RoomParams _params;

  Future<void> createRoomManager() async {
    _params = RoomParams(
      userId: Global.user.id,
      nickname: Global.user.nickname,
      avatar: Global.user.avatar,
      deviceId: Global.deviceInfo.identifier,
      publishers: MAX_PUBLISHERS,
      guildId: _guildId,
    );
    final MultiVideoRoom room = await RoomManager.create(
      RoomType.video,
      _roomId,
      _params,
      isMultiRoom: true,
    );
    _videoRoom = room;

    _videoRoom.onEvent = _onEvent;
    // textRoomModel = TextRoomModel(_videoRoom.textRoom);
    _videoRoom.onScreenShared = _onShareEvent;
    currentUser = _videoRoom.user;
    me = _videoRoom.user;

    addPermissionListener();
    _permissionChangeStreamSubscription =
        PermissionModel.allChangeStream.listen((value) {
      update([kickMemberButtonObject]); // 自己权限变化导致的UI更新已经处理。这里需要处理因比较权限导致的UI更新。
    });
  }

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    super.onClose();
    ignoring = false;
    logger.info('======================= onClose ====================');
  }

  void _onEvent(RoomState state, [data]) {
    switch (state) {
      case RoomState.ready:
        joined.value = JoinStatus.joined;
        break;
      case RoomState.joined:
      case RoomState.changed:
        MemberListModel.instance.mediaUsers = _videoRoom.users;
        // 'localTalkingChanged'
        if (data is String && data == "localTalkingChanged") {
          final id = "${me.id}_talkingChanged";
          update([id]);
        } else {
          update();
        }
        break;
      case RoomState.leaved:
        if (data == currentUser) {
          currentUser = _videoRoom.user;
        }
        if ((data as VideoUser).userId == MultiVideoRoom.SCREEN_USER_ID) {
          if (browseUser != null) {
            screenShareFullUser = data;

            /// 如果在这个用户摄像头的全屏状态下，提示关闭
            if (isShowFullScreenShare.value &&
                screenShareFullUser.avatar == browseUser.id) {
              showToast('该用户已关闭屏幕共享'.tr);
            }

            /// 如果刚好在看全屏状态的屏幕分享，需要退出全屏
            if (!isShowFullScreenShare.value &&
                screenShareFullUser.id == browseUser.id) {
              exitBrowseVideo();
            }
            isShowFullScreenShare.value = false;
          }
        }

        if ((data as VideoUser)?.id == browseUser?.id) {
          exitBrowseVideo();
        } else {
          update();
        }

        // MemberListModel.instance.setMemberList(
        //     GlobalState.selectedChannel.value?.guildId,
        //     ChatChannelType.guildVideo,
        //     _videoRoom.users.map((e) => e.userId));
        break;
      case RoomState.error:
        // if (onError != null) {
        //   onError('发生错误：%s'.trArgs([data.toString()]));
        //   onError = null;
        // }

        showToast('发生错误：%s'.trArgs([data.toString()]));

        break;
      case RoomState.disconnected:
        // if (onError != null) {
        //   onError('视频被中断，请检查网络后重试'.tr);
        //   onError = null;
        // }
        showToast('视频被中断，请检查网络后重试'.tr);
        break;
      case RoomState.reconnectFail:
        joined.value = JoinStatus.joinFail;
        closeAndDispose();
        Get.offAll(HomePage());
        break;
      case RoomState.kickOut:
        // 如果自己被移出，则退出房间
        if (joined.value == JoinStatus.joined) {
          final bool isSelf = data?.first;
          if (isSelf == true) {
            showToast('你已被移出视频频道'.tr);
            closeAndDispose();
            Get.offAll(HomePage());
          }
        }
        update();
        //update([userListObject]);
        break;
      case RoomState.muted:
        String strShow;
        final bool mute = data?.first;
        final MuteType muteType = data?.last;
        if (muteType == MuteType.single) {
          strShow = "管理员已将你闭麦";
        } else {
          strShow = "管理员已开启全员闭麦";
        }
        if (mute == true) {
          muted.value = MicrophoneType.mute;
          showToast(strShow.tr);
        }
        break;
      case RoomState.roomFull:
        showToast("无法开启，会话名额已满");

        /// data 是摄像头推流还是屏幕分享 true:摄像头， false:屏幕分享
        if (data) {
          enableVideo.value = false;
        } else {
          closeScreenShare();
        }
        break;

      ///自己离开调用
      case RoomState.quited:
        joined.value = JoinStatus.unJoined;
        break;

      ///有屏幕共享用户进来，此时刚好全屏
      case RoomState.screenUserAdd:
        if (browseUser != null) {
          isShowFullScreenShare.value = true;
          screenShareFullUser = data;
          if (screenShareFullUser.avatar == browseUser.id) {
            showToast('该用户已开启屏幕共享'.tr);
          }
        }
        break;
      default:
        break;
    }
  }

  void _onShareEvent(mediaStream) {
    if (mediaStream == null) {
      return;
    }
    _shareRefresh();
  }

  void _shareRefresh() {
    if (screenShareState.value == ScreenShareType.normal) {
      screenShareState.value = ScreenShareType.opened;
      hideScreenShareState.value = HideScreenShareViewType.open;
      //update([shareButtonObject]);
    }
  }

  Future<void> toggleScreenShare() async {
    if (screenShareState.value == ScreenShareType.normal) {
      final mediaStream = await _videoRoom.publishSharedScreenInRoom(
          "screenShare", _videoRoom.roomId, "test");
      if (mediaStream == null) {
        showToast("Fanbook没有取得录屏权限，请开启".tr);
        return;
      }
      _shareRefresh();
    } else if (screenShareState.value == ScreenShareType.opened) {
      await _videoRoom.closeSharedScreenInRoom();
      screenShareState.value = ScreenShareType.normal;
      hideScreenShareState.value = HideScreenShareViewType.normal;
      //update([shareButtonObject]);
    }
  }

  /// 打开屏幕共享
  Future<void> openScreenShare() async {
    if (screenShareState.value == ScreenShareType.normal) {
      final mediaStream = await _videoRoom.publishSharedScreenInRoom(
          "screenShare", _videoRoom.roomId, "test");
      if (mediaStream == null) {
        showToast("Fanbook没有取得录屏权限，请开启".tr);
        return;
      }
      if (enableVideo.value == true) {
        enableVideo.value = false;
        showToast("已开始屏幕共享，摄像头已关闭".tr);
      }
      _shareRefresh();
    }
  }

  /// 关闭屏幕共享
  Future<void> closeScreenShare() async {
    if (screenShareState.value == ScreenShareType.opened) {
      await _videoRoom.closeSharedScreenInRoom();
      screenShareState.value = ScreenShareType.normal;
      hideScreenShareState.value = HideScreenShareViewType.normal;
      //update([shareButtonObject]);
    }
  }

  //全员闭麦
  void muteRoom() {
    _videoRoom.muteRoom(true);
    showToast("全员闭麦成功".tr);
  }

  /// 房间静音
  void toggleRoomMute() {
    final bool res = !roomMute.value;
    roomMute.value = res;
    _videoRoom.muteRoomAudio(res);
    if (res) {
      showToast("静音成功".tr);
    } else {
      showToast("取消静音成功".tr);
    }
  }

  /// 踢人
  void toggleKickOutUser(String id) {
    _videoRoom?.kickOut(id);
    showToast("移除成功".tr);
    if (browseUser?.id == id) {
      exitBrowseVideo();
    }
  }

  ///关用户成员的麦克风
  Future toggleMicrophone(String id) async {
    if (joined.value == JoinStatus.reconnect) {
      showToast('网络异常，请重试'.tr);
      return;
    }
    final GuildPermission gp = PermissionModel.getPermission(guildId);
    final hasMutePermission =
        PermissionUtils.oneOf(gp, [Permission.MUTE_MEMBERS], channelId: roomId);
    if (hasMutePermission) {
      await _videoRoom?.muteUser(id, true);
      showToast("已闭麦该成员".tr);
    }
    update();
  }

  /// 打开关闭摄像头
  Future<void> toggleCamera() async {
    ignoring = true;
    update();
    final bool res = !enableVideo.value;
    enableVideo.value = res;
    try {
      await _videoRoom.setEnableCamera(res);
    } catch (e) {
      logger.info('setEnableCamera e = ', e);
    }
    ignoring = false;
    update();
  }

  /// 切换摄像头
  Future<void> switchCamera() async {
    isNotifyListener = false;
    _videoRoom.enabledLocalVideoTrack(false);
    await _videoRoom.switchCamera();

    if (UniversalPlatform.isAndroid) {
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 400), () {
        isNotifyListener = true;
        update();
        _videoRoom.enabledLocalVideoTrack(true);
        _timer?.cancel();
      });
    } else {
      isNotifyListener = true;
      update();
      _videoRoom.enabledLocalVideoTrack(true);
    }
  }

  /// 切换自己的麦克风
  Future<void> toggleMuted() async {
    if (joined.value == JoinStatus.reconnect) {
      showToast('网络异常，请重试'.tr);
      return;
    }
    ignoring = true;
    update();
    final GuildPermission gp = PermissionModel.getPermission(guildId);
    final hasSpeakPermission =
        PermissionUtils.oneOf(gp, [Permission.SPEAK], channelId: roomId);
    if (hasSpeakPermission) {
      bool res;
      if (muted.value == MicrophoneType.mute) {
        muted.value = MicrophoneType.noMute;
        res = false;
      } else if (muted.value == MicrophoneType.noMute) {
        muted.value = MicrophoneType.mute;
        res = true;
      }
      // _videoRoom.muted = res;
      showToast(_videoRoom.muted ? '麦克风已打开'.tr : '麦克风已关闭'.tr);
      try {
        await _videoRoom.mute(res);
      } catch (e) {
        logger.info("--toggleMuted = ", e);
      }
    } else {
      showToast('无开麦克风的权限'.tr);
    }
    ignoring = false;
    update();
  }

  /// 切换主屏幕
  void switchVideo(VideoUser user) {
    currentUser = user;
    update();
  }

  void browseVideo(VideoUser user) {
    browseUser = user;
    update();
  }

  void exitBrowseVideo() {
    browseUser = null;
    update();
  }

  /// 工具栏显示隐藏
  void toggleToolbar() {
    hideToolbar.value = !hideToolbar.value;
    update();
  }

  /// 屏幕共享显示隐藏
  void hideShareScreen() {
    hideScreenShareState.value = HideScreenShareViewType.hide;
    update();
  }

  /// 关闭房间
  Future<void> _close([String msg]) async {
    _timer?.cancel();
    _videoRoom = null;
    if (isNotNullAndEmpty(msg)) showToast(msg);
    await RoomManager.close();
  }

  /// 关闭+页面销毁
  Future<void> closeAndDispose([String msg]) async {
    disposePermissionListener();
    isShowFullScreenShare.value = false;
    hideScreenShareState.value = HideScreenShareViewType.normal;
    enableVideo.value = false;
    screenShareFullUser = null;
    await _permissionChangeStreamSubscription?.cancel();

    _timer?.cancel();
    await Wakelock.disable();
    // if (instance == null) return;
    await _close(msg);
    GlobalState.hangUp();
    Dock.noUpdateDock = false;

    //如果不是切语音频道,退出登录 导致的退出，则回到首页
    // if (flag != 1 && flag != 2 && flag != 3 && flag != 4)
    //   Get.until((route) =>
    //   (route?.settings?.name?.hasValue ?? false) &&
    //       (route.settings.name.startsWith(app_pages.Routes.HOME) ||
    //           route.settings.name.startsWith(loginRoute) ||
    //           route.settings.name.startsWith(liveCreateRoom)));

    final delResult = await Get.delete<VideoRoomController>(tag: roomId);
    logger.info('close video room end - delResult:$delResult');
  }

  int getAudioLevel() {
    return 0;
  }

  @override
  String get guildPermissionMixinId => guildId;

  @override
  void onPermissionChange() {
    final GuildPermission gp = PermissionModel.getPermission(guildId);
    final hasSpeakPermission =
        PermissionUtils.oneOf(gp, [Permission.SPEAK], channelId: roomId);
    if (!hasSpeakPermission) {
      muted.value = MicrophoneType.muteBan;
    }

    final hasConnectPermission =
        PermissionUtils.oneOf(gp, [Permission.CONNECT], channelId: roomId);
    if (joined.value == JoinStatus.joined && !hasConnectPermission)
      _close("无进入房间权限".tr);

    final hasViewChannelPermission =
        PermissionUtils.isChannelVisible(gp, roomId);
    if (!hasViewChannelPermission) closeAndDispose("无权限查看此频道".tr);

    update([channelSettingObject]);
  }
}
