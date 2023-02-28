import 'dart:async';
import 'dart:io';

import 'package:flutter_audio_manager/flutter_audio_manager.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/routes/app_pages.dart' as app_pages;
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_mixin.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/db/db.dart';
import 'package:im/hybrid/webrtc/room/audio_room.dart';
import 'package:im/hybrid/webrtc/room/base_room.dart';
import 'package:im/hybrid/webrtc/room_manager.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/widgets/segment_list/segment_member_list_data_model.dart';
import 'package:im/widgets/segment_list/segment_member_list_service.dart';
import 'package:oktoast/oktoast.dart';
import 'package:rxdart/rxdart.dart' as rx;
import 'package:synchronized/synchronized.dart';
import 'package:tuple/tuple.dart';
import 'package:wakelock/wakelock.dart';

import '../../global.dart';
import '../../loggers.dart';
import '../../routes.dart';

class AudioOutPutDevice {
  String name;
  int count;
}

///语音频道-状态<p>
///unJoined: 未加入(默认)；joining：加入中；joined：已加入；joinFail：加入失败；reconnect：加入后断网重连
enum JoinStatus { joining, joined, unJoined, joinFail, reconnect }

enum ButtonType { toggleOutPut, quit, toggleMicro }

class AudioRoomController extends GetxController with GuildPermissionListener {
  static const int headInfoObject = 1;
  static const int audioBarObject = 2;
  static const int userListObject = 3;
  static const int invitedButtonObject = 4;
  static const int channelSettingObject = 5;
  static const int invitedItemObject = 6;
  static const int muteMemberButtonObject = 6;
  static const int joinRoomButtonObject = 7;
  static const int kickMemberButtonObject = 8;

  Function(String data) onError;

  AudioRoom _audioRoom;

  /// 是否静音
  RxBool muted = RxBool(true);

  ///语音频道当前状态
  Rx<JoinStatus> joined = Rx<JoinStatus>(JoinStatus.unJoined);

  // 音频输出设备
  Rx<AudioInput> audioOutput = Rx<AudioInput>(const AudioInput("unknow", 0));

  String _roomName;

  String get roomName => _roomName;

  String _guildName;

  String get guildName => _guildName;

  String _guildId;

  String get guildId => _guildId;

  final String roomId;

  Timer joinStatusTimer;

  StreamSubscription _permissionChangeStreamSubscription;

  rx.PublishSubject<ButtonType> _stream;

  rx.PublishSubject<ButtonType> get stream => _stream;

  Lock lock = Lock();

  bool _isCloseAndDispose = false;

  /// 成员列表
  List<AudioUser> get users {
    // 加入状态，从webRTC取数据
    if (_audioRoom != null &&
        (joined.value == JoinStatus.joined ||
            joined.value == JoinStatus.reconnect)) {
      return _audioRoom.users;
    } else {
      final channel = Db.channelBox.get(roomId);
      if (channel != null && channel.active == true) {
        //未连接，从成员列表获取数据
        final SegmentMemberListDataModel dataModel = SegmentMemberListService.to
            .getDataModel(guildId, roomId, channel.type);
        dataModel.notify.listen((v) {
          if (joined.value == JoinStatus.unJoined) {
            update([userListObject]);
          }
        });
        return dataModel.memberSnapshot().map((e) {
          return AudioUser()
            ..userId = e.userId
            ..nickname = e.showName()
            ..avatar = e.avatar
            ..muted = false;
        }).toList();
      } else {
        return [];
      }
    }
  }

  static AudioRoomController to(String roomId) {
    if (roomId == null) return null;

    AudioRoomController c;
    try {
      c = Get.find<AudioRoomController>(tag: roomId);
    } catch (e, s) {
      logger.severe("audio room controller find tag $roomId error", e, s);
    }
    return c ??=
        Get.put<AudioRoomController>(AudioRoomController(roomId), tag: roomId);
  }

  AudioRoomController(this.roomId) : assert(roomId != null) {
    final channel = Db.channelBox.get(roomId);
    _roomName = channel.name;
    final guildTarget = ChatTargetsModel.instance.getGuild(channel.guildId);
    _guildId = channel.guildId;
    _guildName = guildTarget.name;
  }

  void ready() {
    if (_isCloseAndDispose == false) {
      final channel = Db.channelBox.get(roomId);
      GlobalState.mediaChannel.value = Tuple2(null, channel);
      joined.value = JoinStatus.joined;
    }
  }

  void _onEvent(RoomState state, [data]) {
    switch (state) {
      case RoomState.ready:
        lock.synchronized(ready);
        break;
      case RoomState.quited:
        joined.value = JoinStatus.unJoined;
        break;
      case RoomState.kickOut:
        {
          // 如果自己被移出，则退出房间
          if (joined.value == JoinStatus.joined) {
            final bool isSelf = data?.first;
            if (isSelf == true) {
              showToast('你已被移出语音频道'.tr);
              closeAndDispose();
            }
          }
          update([userListObject]);
        }
        break;
      case RoomState.leaved:
        {
          update([audioBarObject, userListObject]);
        }
        break;
      case RoomState.joined:
        {
          // 加入之后，同步下用户信息，尤其是角色数据
          if (data.runtimeType == List) {
            final List ids = data;
            if (ids != null && ids.isNotEmpty) {
              ids.forEach((element) {
                if (element.runtimeType == String) {
                  UserInfo.get(element);
                }
              });
            }
          }

          update([audioBarObject, userListObject]);
        }
        break;
      case RoomState.changed:
        update([audioBarObject, userListObject]);
        break;
      case RoomState.muted:
        {
          final bool mute = data?.first;
          if (mute == true) {
            muted.value = mute;
            showToast('已被设置临时静音'.tr);
          }
        }
        break;
      case RoomState.error:
        {
          onError?.call('发生错误：%s'.trArgs([data]));
          onError = null;
        }
        break;
      case RoomState.disconnected:
        final toastMsg = '音频被中断，请检查网络后重试'.tr;
        showToast(toastMsg);
        onError?.call(toastMsg);
        onError = null;
        break;
      case RoomState.reconnect:
        //点击按钮加入时，不设置reconnect状态，加入后重连才设置
        if (joined.value == JoinStatus.joined) {
          joined.value = JoinStatus.reconnect;
          update([userListObject]);
        }
        break;
      case RoomState.reconnectFail:
        joined.value = JoinStatus.joinFail;
        update([userListObject]);
        break;
      default:
        break;
    }
  }

  // 点击退出
  void toggleQuit() => closeAndDispose();

  // 点击麦克风
  Future toggleMicrophone({AudioUser user}) async {
    if (joined.value == JoinStatus.reconnect) {
      showToast('网络异常，请重试'.tr);
      return;
    }
    if (user == null || user.userId == Global.user.id) {
      // 关自己的
      final GuildPermission gp = PermissionModel.getPermission(guildId);
      final hasSpeakPermission =
          PermissionUtils.oneOf(gp, [Permission.SPEAK], channelId: roomId);
      if (hasSpeakPermission) {
        _audioRoom.muted = !muted.value;
        muted.value = _audioRoom.muted;
        showToast(_audioRoom.muted ? '麦克风已关闭'.tr : '麦克风已打开'.tr);
      } else {
        showToast('无开麦克风的权限'.tr);
      }
    } else {
      // 关别人的
      final GuildPermission gp = PermissionModel.getPermission(guildId);
      final hasMutePermission = PermissionUtils.oneOf(
          gp, [Permission.MUTE_MEMBERS],
          channelId: roomId);
      if (hasMutePermission) {
        if (user.muted == false) {
          await _audioRoom.muteUser(user, true);
          showToast("已将用户静音".tr);
        }
      }
    }
  }

  // 踢人
  void toggleKickOutUser(AudioUser user) {
    if (joined.value == JoinStatus.joined) _audioRoom?.kickOut(user);
  }

  // 点击输出设备
  Future toggleAudioOutput() async {
    if (joined.value == JoinStatus.reconnect) {
      showToast('网络异常，请重试'.tr);
      return;
    }

    // 蓝牙，耳机为A组设备
    // 扬声器，听筒为B组设备
    // 初始时: 优先选择A组，优先选择前面的
    // 切换时: A组和B组内互切，如果互切不了，则选择组内切
    final availableInput = await FlutterAudioManager.getAvailableInputs();
    final currOutput = await FlutterAudioManager.getCurrentOutput();

    // 先用旧逻辑
    if (availableInput.length < 2) {
      if (currOutput.port == AudioPort.receiver) {
        audioOutput.value = const AudioInput("speaker", 2);
        await FlutterAudioManager.changeToSpeaker();
        return;
      } else {
        audioOutput.value = const AudioInput("receiver", 1);
        await FlutterAudioManager.changeToReceiver();
        return;
      }
    }

    final List<AudioInput> groupA = [];
    final List<AudioInput> groupB = [];
    // 先按索引排序，再分组，正好满足上面的优先级
    availableInput.sort(
        (item1, item2) => item1.port.index.compareTo(item2.port.index) * -1);
    availableInput.forEach((e) {
      switch (e.port) {
        case AudioPort.bluetooth:
        case AudioPort.headphones:
          groupA.add(e);
          break;
        case AudioPort.speaker:
        case AudioPort.receiver:
          groupB.add(e);
          break;
        default:
          break;
      }
    });
    var selectOutput =
        AudioInput("扬声器".tr, AudioPort.speaker.index); // 默认扬声器，这里赋值主要为了展示
    if (currOutput.port == AudioPort.bluetooth ||
        currOutput.port == AudioPort.headphones) {
      if (groupB.isNotEmpty) {
        selectOutput = groupB.first;
      } else {
        selectOutput = groupA.firstWhere(
            (element) => element.port != currOutput.port,
            orElse: () => null);
      }
    } else if (currOutput.port == AudioPort.speaker ||
        currOutput.port == AudioPort.receiver) {
      if (groupA.isNotEmpty) {
        selectOutput = groupA.first;
      } else {
        selectOutput = groupB.firstWhere(
            (element) => element.port != currOutput.port,
            orElse: () => null);
      }
    }

    // 仍然选不到能切的，则不切了
    logger.info("dj - currOutput: ${currOutput?.name}");
    logger.info("dj - selectOutput: ${selectOutput?.name}");
    if (selectOutput == null) return;

    switch (selectOutput.port) {
      case AudioPort.bluetooth:
        await FlutterAudioManager.changeToBluetooth();
        break;
      case AudioPort.headphones:
        await FlutterAudioManager.changeToHeadphones();
        break;
      case AudioPort.speaker:
        await FlutterAudioManager.changeToSpeaker();
        break;
      case AudioPort.receiver:
        await FlutterAudioManager.changeToReceiver();
        break;
      default:
        break;
    }
    final afterOutPut = await FlutterAudioManager.getCurrentOutput();
    logger.info("audio: after change to receiver: ${afterOutPut.name}");
  }

  // 进入webRTC房间
  Future<void> joinAudioRoom() async {
    logger.info('joinAudioRoom start roomId: $roomId, joined ${joined?.value}');
    //防止用户连续点击
    if (joined.value == JoinStatus.joining) return;

    // 加入房间，先退出旧房间
    final channelId = GlobalState.mediaChannel?.value?.item2?.id;
    if (channelId != null && channelId != roomId)
      try {
        final AudioRoomController oldCtl = Get.find<AudioRoomController>(
            tag: GlobalState.mediaChannel.value.item2.id);
        if (oldCtl != null) await oldCtl.closeAndDispose(flag: 1);
      } catch (e, s) {
        logger.severe("join audio room exception", e, s);
      }
    if (joined.value == JoinStatus.joined) return;

    final channel = Db.channelBox.get(roomId);
    final userLimit = channel.userLimit ?? 10;
    final AudioRoom room = await RoomManager.create(
        RoomType.audio,
        roomId,
        RoomParams(
          userId: Global.user.id,
          nickname: Global.user.nickname,
          avatar: Global.user.avatar,
          deviceId: Global.deviceInfo.identifier,
          guildId: _guildId,
          maxParticipants: userLimit,
          channelId: channel.id,
          roomId: roomId,
        ));
    _audioRoom = room;
    _isCloseAndDispose = false;
    room.onEvent = _onEvent;
    joined.value = JoinStatus.joining;
    update([userListObject]);

    ///加入语音频道，设置5秒超时
    await room.join().timeout(5.seconds, onTimeout: () async {
      ///超时后，有可能已经加入成功
      if (joined.value == JoinStatus.joined) return;
      joined.value = JoinStatus.joinFail;
      update([userListObject]);
      await _close(msg: '网络异常，请重试'.tr);
      throw '加入语音频道超时: $roomId';
    });
    //设置屏幕常亮
    await Wakelock.enable();

    ///ios平台默认是打开听筒的，所以做下切换
    if (Platform.isIOS) await FlutterAudioManager.changeToSpeaker();

    _initAudioOutput();
  }

  Future<void> _close({String msg}) async {
    if (_audioRoom != null) {
      if (msg.hasValue) showToast(msg);
    }
    await RoomManager.close();

    _audioRoom = null;
    onError = null;

    //设置屏幕常亮
    await Wakelock.disable();
  }

  Future<void> closeAndDisposeLock({String msg, int flag = 0}) async {
    logger.info('close audio room roomId:$roomId, msg:$msg flag:$flag');
    _deInitAudioOutput();
    await _close(msg: msg);
    _isCloseAndDispose = true;
    GlobalState.hangUp();

    //如果不是切语音频道,退出登录 导致的退出，则回到首页
    if (flag != 1 && flag != 2 && flag != 3 && flag != 4)
      Get.until((route) =>
          (route?.settings?.name?.hasValue ?? false) &&
          (route.settings.name.startsWith(app_pages.Routes.HOME) ||
              route.settings.name.startsWith(loginRoute) ||
              route.settings.name.startsWith(liveCreateRoom)));

    final delResult = await Get.delete<AudioRoomController>(tag: roomId);
    logger.info('close audio room end - delResult:$delResult');
  }

  /// 关闭+页面销毁
  Future<void> closeAndDispose({String msg, int flag = 0}) async {
    await lock.synchronized(() {
      closeAndDisposeLock(msg: msg, flag: flag);
    });
  }

  void _initAudioOutput() {
    Future.delayed(const Duration(seconds: 1), () async {
      await FlutterAudioManager.getCurrentOutput().then((value) {
        return audioOutput.value = value;
      });
    });

    FlutterAudioManager.setListener(() async {
      Future.delayed(Duration(seconds: Platform.isAndroid ? 5 : 0), () async {
        audioOutput.value = await FlutterAudioManager.getCurrentOutput();
        logger.info("audio: changed to ${audioOutput.value.name}");
      });
    });
  }

  void _deInitAudioOutput() {
    FlutterAudioManager.setListener(null);
  }

  @override
  void onInit() {
    super.onInit();
    _initPublishSubject();
    addPermissionListener();
    Db.channelBox.listenable(keys: [roomId]).addListener(onChannelChanged);
    _permissionChangeStreamSubscription =
        PermissionModel.allChangeStream.listen((value) {
      update([kickMemberButtonObject]); // 自己权限变化导致的UI更新已经处理。这里需要处理因比较权限导致的UI更新。
    });
  }

  void _initPublishSubject() {
    _stream = rx.PublishSubject();
    _stream.debounceTime(const Duration(milliseconds: 250)).listen(
      (buttonType) {
        if (buttonType == ButtonType.toggleOutPut) {
          toggleAudioOutput();
        } else if (buttonType == ButtonType.quit) {
          toggleQuit();
        } else {
          toggleMicrophone();
        }
      },
    );
  }

  void onChannelChanged() {
    if (Db.channelBox.containsKey(roomId)) {
      // 正常变更
      final channel = Db.channelBox.get(roomId);
      _roomName = channel.name;
    } else {
      // 频道删除
      final msg = (joined.value == JoinStatus.joined) ? "语音聊天已结束".tr : "";
      closeAndDispose(msg: msg);
    }
    update([headInfoObject, userListObject]);
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    _stream.close();
    disposePermissionListener();
    Db.channelBox.listenable(keys: [roomId]).removeListener(onChannelChanged);
    _permissionChangeStreamSubscription?.cancel();
  }

  @override
  String get guildPermissionMixinId => guildId;

  @override
  void onPermissionChange() {
    final GuildPermission gp = PermissionModel.getPermission(guildId);
    final hasSpeakPermission =
        PermissionUtils.oneOf(gp, [Permission.SPEAK], channelId: roomId);
    if (!hasSpeakPermission && muted.value == false) {
      _audioRoom.muted = true;
      muted.value = true;
    }

    final hasConnectPermission =
        PermissionUtils.oneOf(gp, [Permission.CONNECT], channelId: roomId);
    if (joined.value == JoinStatus.joined && !hasConnectPermission)
      _close(msg: "无进入房间权限".tr);

    final hasViewChannelPermission =
        PermissionUtils.isChannelVisible(gp, roomId);
    if (!hasViewChannelPermission) closeAndDispose(msg: "无权限查看此频道".tr);

    update([
      kickMemberButtonObject,
      joinRoomButtonObject,
      muteMemberButtonObject,
      channelSettingObject
    ]);
  }

  ///退出服务器时，需要退出语音频道
  static void onQuitGuild(String guildId) {
    if (GlobalState.mediaChannel?.value?.item2?.guildId == guildId) {
      try {
        final c = Get.find<AudioRoomController>(
            tag: GlobalState.mediaChannel.value.item2.id);
        //先注销权限监听，防止toast权限提示
        c.disposePermissionListener();
        c.closeAndDispose();
      } catch (e, s) {
        logger.severe("on quit guild", e, s);
      }
    }
  }
}
