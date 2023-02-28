import 'dart:async';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/event_bus_model/refresh_room_list_model.dart';
import 'package:fb_live_flutter/live/model/live/obs_rsp_model.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/net/api.dart';
import 'package:fb_live_flutter/live/pages/create_room/create_param_page.dart';
import 'package:fb_live_flutter/live/pages/detection/detection_page_web.dart';
import 'package:fb_live_flutter/live/pages/live_room/room_middle_page.dart';
import 'package:fb_live_flutter/live/pages/preview/live_preview.dart';
import 'package:fb_live_flutter/live/utils/config/route_path.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/live/base_bloc.dart';
import 'package:fb_live_flutter/live/utils/manager/event_bus_manager.dart';
import 'package:fb_live_flutter/live/utils/manager/permission_manager.dart';
import 'package:fb_live_flutter/live/utils/manager/zego_sdk_manager.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wakelock/wakelock.dart';
import 'package:zego_ww/zego_ww.dart';

class DetectionBloc<e extends State<DetectionPage>> extends BaseAppCubit<int>
    with BaseAppCubitState {
  DetectionBloc() : super(0);

  dynamic localStream;

  final TextEditingController microphoneC = TextEditingController(text: '');
  final TextEditingController speakerC = TextEditingController(text: '');
  final TextEditingController cameraC = TextEditingController(text: '');

  // 摄像头画面宽度
  double viewWidth = (672 - 64.px) / 2;

  // 摄像头画面高度
  double get viewHeight {
    return viewWidth * 170 / 300;
  }

  //摄像头是否开启
  bool? isCamera = false;

  //麦克风是否开启
  bool? isMicrophone = false;

  //摄像头设备列表
  List? cameraList = [];

  //麦克风设备列表
  List? microphoneList = [];

  //扬声器设备列表
  List? speakersList = [];

  bool isTestSpeaker = false;
  bool isFlip = false;
  bool isExternal = false;

  double microphoneValue = 30;
  double speakerValue = 50;

  RxDouble localSoundLevel = 0.0.obs;

  ZegoWwMediaModel? _mediaModel;
  ZegoWwVideoView? videoView;

  Map? dataMap;

  RoomInfon? roomInfon; //房间信息对象

  int openType = 2; //服务器权限 暂时不需要
  int? shareType; //分享类型：0-不分享、1-分享

  String? imageUrl;
  String? roomTitle = "";
  BuildContext? context;

  final FBChatChannel? _liveChannel = fbApi.getCurrentChannel();

  final LiveValueModel liveValueModel = LiveValueModel();

  State<DetectionPage>? statePage;

  Future init(State<DetectionPage> state) async {
    roomTitle = state.widget.roomTitle;
    imageUrl = state.widget.roomLogo;
    context = state.context;
    statePage = state;

    await _initZegoExpressEngine();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async {
      await check();
    });
  }

  /*
  * Zego-设置麦克风声音
  * */
  Future? setCaptureVolume(num volume) {
    return ZegoSDKManager.setCaptureVolume(localStream, volume);
  }

  /*
  * 开启声浪监听
  * */
  void setSoundLevelDelegate() {
    ZegoEngineManager.instance!.engine!.setSoundLevelDelegate(true, 300);
  }

  /*
  * 选择麦克风
  * */
  void useAudioDevice(String deviceId) {
    ZegoEngineManager.instance!.engine!.useAudioDevice(localStream, deviceId);
  }

  /*
  * 选择摄像头设备
  * */
  void useVideoDevice(String deviceId) {
    ZegoEngineManager.instance!.engine!.useVideoDevice(localStream, deviceId);
  }

  /*
  * 创建流[屏幕共享-待完善]
  * */
  Future createStream() async {
    videoView = ZegoWwVideoView(
      onMediaModelCreated: (mediaModel) {
        _mediaModel = mediaModel;
      },
    );

    /// 延时操作
    await Future.delayed(Duration.zero);

    ZegoSDKManager.createStream().then(
      (value) {
        fbApi.fbLogger.info('createStream success');

        _mediaModel!.src = value;
        _mediaModel!.src.active ? _mediaModel!.play() : _mediaModel!.pause();
        _mediaModel!.muted = true;
        localStream = value;
      },
      onError: (e) {
        fbApi.fbLogger.warning('createStream error ${e.toString()}');
      },
    );
  }

  Future _initZegoExpressEngine() async {
    await Wakelock.enable(); //设置屏幕常亮
    final int appID = configProvider.liveAppId; // 请通过官网注册获取，

    await ZegoSDKManager.createEngine(
      appID,
      server: configProvider.liveWssUrl,
      appSign: '',
      enablePlatformView: false,
      scenario: ZegoScenario.General,
    );
  }

  Future checkDeviceLogic() async {
    final checkValue = await ZegoSDKManager.checkSystemRequirements();

    isCamera = checkValue.camera;
    isMicrophone = checkValue.microphone;

    //获取设备列表
    await ZegoSDKManager.enumDevices().then((enumDevices) {
      cameraList = enumDevices.cameras;
      microphoneList = enumDevices.microphones;
      speakersList = enumDevices.speakers;
    });

    cameraList!.forEach((element) {
      cameraC.text = element.deviceName;
    });
    microphoneList!.forEach((element) {
      if (element.deviceName.contains('默认')) {
        microphoneC.text = element.deviceName;
      }
    });
    speakersList!.forEach((element) {
      if (element.deviceName.contains('默认')) {
        speakerC.text = element.deviceName;
      }
    });
    onRefresh();
  }

  /// Check SystemRequirements, the type is [ZegoCapabilityDetection]
  Future check() async {
    await checkDeviceLogic();
    await createStream();
    setSoundLevelDelegate();

    ZegoSDKManager.onCapturedSoundLevelUpdate = (soundLevel) {
      localSoundLevel.value = soundLevel;
    };
    detectionBus.fire(DetectionPageEvent());
  }

  /*
  * 进入直播间
  * */
  Future interLive(BuildContext context) async {
    final checkDeviceResult = await checkDevice();

    if (checkDeviceResult) {
      await _createdLiveRoom();
    }
  }

  /*
  * 检测设备
  * */
  Future<bool> checkDevice() async {
    bool isOk = false;
    if (_mediaModel?.src == null) {
      myFailToast("你的本地画面流创建失败了，请重试");
    } else if (!strNoEmpty(microphoneC.text)) {
      myFailToast("你的麦克风异常，请重试");
    } else if (!strNoEmpty(speakerC.text)) {
      myFailToast("你的扬声器异常，请重试");
    } else if (!strNoEmpty(cameraC.text)) {
      myFailToast("你的摄像头异常，请重试");
    } else {
      isOk = true;
    }
    return isOk;
  }

  /*
  * 创建直播房间事件
  * */
  Future _createdLiveRoom() async {
    if (imageUrl == null) {
      final FBUserInfo userInfo = await fbApi.getUserInfo(fbApi.getUserId()!,
          guildId: roomInfon!.serverId);
      imageUrl = userInfo.avatar;
    }
    if (roomTitle == null ||
        roomTitle is! String ||
        (roomTitle is String && roomTitle!.trim().isEmpty)) {
      myFailToast("请填写直播间标题");
      return;
    }
    if (!kIsWeb) {
      if (!await PermissionManager.requestPermission(
          type: PermissionType.createRoom)) {
        // "获取权限失败";
        myFailToast('开启直播需要相机/录音权限，当前权限被禁用');
        return;
      }
    }

    // 创建开播请求
    await openLiveRoom();
  }

  /*
  * FBAPI--查询是否有音视频频道
  * */
  Future<bool> fbApiGetAVChannel() {
    final bool isInAVChannel = fbApi.inAVChannel();
    final Completer<bool> completer = Completer();

    // 有音视频线程
    if (isInAVChannel) {
      fbApi.exitAVChannel().then((_bool) {
        // 不同意退出
        if (!_bool) {
          // showToast('开直播需退出音视频频道',
          //     textPadding: EdgeInsets.fromLTRB(FrameSize.px(40),
          //         FrameSize.px(30), FrameSize.px(40), FrameSize.px(30)));
          // 返回上一层
          Navigator.pop(context!);
          EventBusManager.eventBus.fire(RefreshRoomListModel(true));
        } else {
          completer.complete(true);
        }
      });
    } else {
      completer.complete(true);
    }

    return completer.future;
  }

  /*
  * 发送开直播
  * */
  Future openLiveRoom() async {
    await fbApiGetAVChannel();

    final bool isCanStart = fbApi.canStartLive();

    // 无开播权限
    if (!isCanStart) {
      myFailToast('您暂无开播权限, 请联系管理员！');
      return;
    }

    // 敏感信息查询
    final boolValue = await fbApi.inspectLiveRoom(desc: roomTitle, tags: []);

    if (!boolValue) {
      myFailToast('您的直播间标题简介涉及敏感信息，请重新设置！');
      return;
    }

    await createdRoom(_liveChannel!, [], []);
  }

  Future createdRoom(FBChatChannel currentChannel, List<int> systemTags,
      List<String> userTags) async {
    final Map dataMap = await Api.createLiveRoom(
      currentChannel.guildId,
      currentChannel.guildName,
      currentChannel.id,
      currentChannel.name,
      roomTitle,
      imageUrl,
      systemTags,
      userTags,
      openType,
      shareType,
      isExternal,
      false,
      [],
    );
    if (dataMap["code"] == 200) {
      final String? roomId = dataMap["data"]["roomId"];
      if (isExternal) {
        final obsAddressValue = await Api.obsAddress(roomId!);
        if (obsAddressValue['code'] != 200) {
          myFailToast('创建失败，请重试');
          return;
        }
        liveValueModel.obsModel = ObsRspModel.fromJson(obsAddressValue['data']);
        liveValueModel.setObs(isExternal);
        if (!strNoEmpty(liveValueModel.obsModel?.url)) {
          myFailToast('obs地址为空，请重试');
          return;
        }
        await RouteUtil.push(
            context,
            CreateParamPage(roomId, imageUrl, currentChannel, liveValueModel),
            'createParamPage');
        return;
        // await createParamDialog(context);
      }

      /*
      * 跳转直播事件
      * */
      if (roomId != null) {
        if (kIsWeb) {
          liveValueModel.isAnchor = true;

          liveValueModel.setRoomInfo(
              roomId: roomId,
              serverId: currentChannel.guildId,
              channelId: currentChannel.id,
              roomLogo: imageUrl!,
              status: 2,
              liveType: 5,
              roomInfoObject: liveValueModel.roomInfoObject);

          await RouteUtil.push(
              context,
              RoomMiddlePage(
                isWebFlip: isFlip,
                liveValueModel: liveValueModel,
              ),
              "liveRoomWebContainer",
              isReplace: true);
        } else {
          liveValueModel.setRoomId(roomId);
          liveValueModel.setRoomLogo(imageUrl!);

          liveValueModel.isAnchor = true;

          await RouteUtil.push(
              context,
              LivePreviewPage(liveValueModel: liveValueModel),
              RoutePath.livePreviewPage,
              isReplace: true);
        }
      } else {
        myToast(dataMap["msg"]);
      }
    }
  }

  @override
  Future<void> close() {
    _destroy();
    return super.close();
  }

  void _destroy() {
    ZegoSDKManager.destroyStream(localStream);
    // 【web】web推流端开播时报错
    // ZegoSDKManager.logoutRoom(roomId);
  }
}
