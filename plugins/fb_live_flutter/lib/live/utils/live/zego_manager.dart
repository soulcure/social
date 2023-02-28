import 'dart:io';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/net/api.dart';
import 'package:fb_live_flutter/live/utils/config/sp_key.dart';
import 'package:fb_live_flutter/live/utils/config/steam_info_config.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/other/float_plugin.dart';
import 'package:fb_live_flutter/live/utils/other/media_plugin.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_projection_creator/media_projection_creator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:replay_kit_launcher/replay_kit_launcher.dart';
import 'package:shared_preference_app_group/shared_preference_app_group.dart';
import 'package:wakelock/wakelock.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import '../../model/zego_token_model.dart';
import '../other/ios_screen_plugin.dart';

class ZegoManager {
  static ZegoPublishChannel screenChannel = ZegoPublishChannel.Aux;

  /// 拉流模式【字符串】
  static String? pullModeStr;
  static int? pullTimeStamp;

  //初始化即构SDK
  static Future createEngine(bool isAnchor) async {
    await Wakelock.enable(); //设置屏幕常亮
    final int appID = configProvider.liveAppId; // 请通过官网注册获取，
    final String appSign = configProvider.liveAppSign;
    final bool isTestEnv = fbApi.liveIsTestEnv();

    // IOS屏幕共享需要的配置
    if (Platform.isIOS) {
      await SharedPreferenceAppGroup.setAppGroup(configProvider.appGroupID);
    }

    // 进阶配置测试环境，不弹log toast
    final ZegoEngineConfig engineConfig = ZegoEngineConfig(null, {
      "enable_toast_on_test_env": "false",
    });
    await ZegoExpressEngine.setEngineConfig(engineConfig);

    // ZegoScenario.Live / ZegoScenario.Communication 不同的音量输出的问题
    /// ZegoScenario.Communication会导致观众也开启了麦克风
    /// 旧版使用的ZegoScenario.Live
    /// 【APP】观众端进入直播间，观众端也开启麦克风了，观众不需要
    ZegoScenario zegoScenario;

    /// [ZegoScenario.Communication]解决了iPhone13音频画面卡顿问题；
    /// 具体愿意与区别待上线后去了解，看文档及询问zego
    if (isAnchor && Platform.isIOS) {
      /// 【APP】IOS直播中再播放其他应用在返回直播间时会暂停
      zegoScenario = ZegoScenario.Communication;
    } else {
      zegoScenario = ZegoScenario.General;
    }

    /// 创建引擎
    // ignore: deprecated_member_use
    await ZegoExpressEngine.createEngine(
        appID, appSign, isTestEnv, zegoScenario,
        enablePlatformView: false);

    /// Developers need to write native Android code to access native ZegoExpressEngine
    if (Platform.isAndroid) {
      await ZegoExpressEngine.instance.enableCustomVideoCapture(true,
          config:
              ZegoCustomVideoCaptureConfig(ZegoVideoBufferType.SurfaceTexture),
          channel: screenChannel);
    }
  }

  // 登录房间
  static Future zegoLoginRoom(ZegoTokenModel zegoTokenModel) async {
    final ZegoUser user =
        ZegoUser.id(zegoTokenModel.userId ?? fbApi.getUserId()!);
    final ZegoRoomConfig config = ZegoRoomConfig.defaultConfig();
    config.token = zegoTokenModel.token!;
    config.isUserStatusNotify = true; // 监听房间必传
    final String? lastRoomId = fbApi.getSharePref(SpKey.lastRoomId);
    if (strNoEmpty(lastRoomId)) {
      try {
        await ZegoExpressEngine.instance.logoutRoom(lastRoomId!);
      } catch (e) {
        fbApi.fbLogger.warning('zego logout room failed');
      }
    }
    await fbApi.setSharePref(SpKey.lastRoomId, zegoTokenModel.roomId!);

    try {
      await ZegoExpressEngine.instance
          .loginRoom(zegoTokenModel.roomId!, user, config: config);
    } catch (e) {
      fbApi.fbLogger.warning('zego login room failed');
    }
  }

  // 主播推流设置
  static Future anchorPushStream(
      ZegoCanvas? previewCanvas, ZegoTokenModel? zegoTokenModel,
      {bool isMirror = false, bool isSetConfig = true}) async {
    // Start preview //推流预览
    if (isSetConfig) {
      await ZegoExpressEngine.instance.setVideoConfig(ZegoVideoConfig(
          720, 1280, 720, 1280, 25, 2000, ZegoVideoCodecID.Default, 2));
    }
    // 解决主播端与拉流端画面不一致的问题
    // 移动端不用这个主要是为了能继承预览页面设置的
    if (kIsWeb) {
      if (isMirror) {
        await ZegoExpressEngine.instance
            .setVideoMirrorMode(ZegoVideoMirrorMode.BothMirror);
      } else {
        await ZegoExpressEngine.instance
            .setVideoMirrorMode(ZegoVideoMirrorMode.NoMirror);
      }
    }

    // 设置音量
    await ZegoExpressEngine.instance.enableAGC(true);
    await ZegoExpressEngine.instance.setCaptureVolume(150);
    await ZegoExpressEngine.instance.startPreview(canvas: previewCanvas);
    await ZegoExpressEngine.instance
        .startPublishingStream("${zegoTokenModel?.roomId}_camera");
  }

  /*
  * 切换到正常直播
  * */
  static Future changeLive(LiveValueModel? liveValueModel) async {
    await ZegoExpressEngine.instance.enableCamera(true);
    await ZegoExpressEngine.instance
        .stopPublishingStream(channel: screenChannel);

    // 告诉拉流端关闭了屏幕共享，需要切换拉流视图模式
    await ZegoExpressEngine.instance.setStreamExtraInfo(sendSteamInfo(
        screenShare: false, mirror: false, liveValueModel: liveValueModel));
  }

  //切换为屏幕共享
  static Future changeScreenShare(ZegoTokenModel zegoTokenModel,
      {required VoidCallback start, required VoidCallback cancel}) async {
    final bool isPermissionGranted = await requestScreenSharePermission();
    if (!isPermissionGranted) {
      myFailToast('请开启权限');
    }

    // 安卓端设置token和roomId
    MediaPlugin.setToken();
    MediaPlugin.setRoomId(zegoTokenModel.roomId);
    MediaPlugin.setLiveHost(configProvider.liveHost);

    final int errorCode = await MediaProjectionCreator.createMediaProjection();
    if (errorCode != MediaProjectionCreator.ERROR_CODE_SUCCEED) {
      cancel();
      return false;
    }
    start();

    const int _w = 720;
    final int _h = 720 * FrameSize.winHeight() ~/ FrameSize.winWidth();

    await ZegoExpressEngine.instance.setVideoConfig(
      ZegoVideoConfig(_w, _h, _w, _h, 25, 2000, ZegoVideoCodecID.Default, 2),
      channel: screenChannel,
    );

    final String steamId = "${zegoTokenModel.roomId}_screen";
    await ZegoExpressEngine.instance
        .startPublishingStream(steamId, channel: screenChannel);
    await ZegoExpressEngine.instance.enableCamera(false);
    fbApi.fbLogger.info('屏幕共享流ID::$steamId');
  }

  //切换为屏幕共享
  static Future changeScreenShareIos(ZegoTokenModel? zegoTokenModel) async {
    // setParamsForCreateEngine【设置引擎参数】START
    await SharedPreferenceAppGroup.setInt(
        'ZG_SCREEN_CAPTURE_APP_ID', configProvider.liveAppId);
    await SharedPreferenceAppGroup.setString(
        'ZG_SCREEN_CAPTURE_APP_SIGN', configProvider.liveAppSign);
    await SharedPreferenceAppGroup.setBool(
        "ZG_SCREEN_CAPTURE_IS_TEST_ENV", fbApi.liveIsTestEnv());
    await SharedPreferenceAppGroup.setInt("ZG_SCREEN_CAPTURE_SCENARIO", 0);
    // setParamsForCreateEngine【设置引擎参数】END

    /// 具体看[ZegoScenario]
    await SharedPreferenceAppGroup.setBool(
        "ZG_SCREEN_CAPTURE_ONLY_CAPTURE_VIDEO", false);

    // setParamsForVideoConfig【设置视频参数】Start
    final double pixelRatio = FrameSize.pixelRatio() / 2;
    await SharedPreferenceAppGroup.setInt(
        "ZG_SCREEN_CAPTURE_VIDEO_SIZE_WIDTH", (720 * pixelRatio).toInt()); //720
    await SharedPreferenceAppGroup.setInt(
        "ZG_SCREEN_CAPTURE_VIDEO_SIZE_HEIGHT",
        ((720 * FrameSize.winHeight() ~/ FrameSize.winWidth()) * pixelRatio)
            .toInt()); //1280
    await SharedPreferenceAppGroup.setInt(
        "ZG_SCREEN_CAPTURE_SCREEN_CAPTURE_VIDEO_FPS", 25);
    await SharedPreferenceAppGroup.setInt(
        "ZG_SCREEN_CAPTURE_SCREEN_CAPTURE_VIDEO_BITRATE_KBPS", 2000);
    // setParamsForVideoConfig【设置视频参数】END

    // setParamsForStartLive【设置开始直播参数】START
    await SharedPreferenceAppGroup.setString(
        "ZG_SCREEN_CAPTURE_USER_ID", "${zegoTokenModel!.userId}_screen");
    await SharedPreferenceAppGroup.setString(
        "ZG_SCREEN_CAPTURE_USER_NAME", "${zegoTokenModel.userId}_screen");
    await SharedPreferenceAppGroup.setString(
        "ZG_SCREEN_CAPTURE_ROOM_ID", zegoTokenModel.roomId);
    await SharedPreferenceAppGroup.setString(
        "ZG_SCREEN_CAPTURE_STREAM_ID", "${zegoTokenModel.roomId}_screen");
    // setParamsForStartLive【设置开始直播参数】END

    // 开启捕捉屏幕能力
    await ReplayKitLauncher.launchReplayKitBroadcast(
        configProvider.extensionName);
    await IosScreenPlugin.startGetData();
  }

  //屏幕共享权限
  static Future<bool> requestScreenSharePermission() async {
    final PermissionStatus microphoneStatus =
        await Permission.microphone.request();
    return microphoneStatus.isGranted;
  }

  // 用户拉流设置
  static Future<void> audiencePullStream(
      ZegoCanvas? previewCanvas, String steamId) async {
    ZegoStreamResourceMode? resourceMode;
    try {
      /// 拉流模式储存配置，在本地1小时缓存过期后再拉流。
      final nowTimeStamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final pullTimestamp = pullTimeStamp ?? 0;
      final lessHour = (nowTimeStamp - pullTimestamp) < 3600;
      if (strNoEmpty(pullModeStr) && lessHour) {
        if (pullModeStr == 'RTC') {
          resourceMode = ZegoStreamResourceMode.OnlyRTC;
        } else {
          resourceMode = ZegoStreamResourceMode.OnlyL3;
        }
      } else {
        /// APP端拉流模式增加了一个配置接口，先从接口读取配置，如何接口读取失败则采用默认配置RTC
        final mode = await Api.zegoPlayMode();
        if (mode['code'] == 200 && mode['data']['mode'] != null) {
          /// 这个接口可以加个本地缓存策略，不用每次进直播间都调用这个接口
          /// 内存存储，每次新打开app且拉流才请求
          pullModeStr = mode['data']['mode'];

          /// 拉流模式传给原生端
          MediaPlugin.setPullModeStr(pullModeStr);

          pullTimeStamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          if (pullModeStr == 'RTC') {
            resourceMode = ZegoStreamResourceMode.OnlyRTC;
          } else {
            resourceMode = ZegoStreamResourceMode.OnlyL3;
          }
        }
      }
    } catch (e) {
      fbApi.fbLogger.warning(
          'get pullMode failed，use default: ZegoStreamResourceMode.OnlyRTC，details:${e.toString()}');
    }

    /// 播放配置
    final ZegoPlayerConfig playConfig = ZegoPlayerConfig.defaultConfig();

    // 拉流模式设置
    playConfig.resourceMode = resourceMode ?? ZegoStreamResourceMode.OnlyRTC;

    /// 设置特殊信息
    await ZegoExpressEngine.instance.enableAGC(true);
    await ZegoExpressEngine.instance.setCaptureVolume(150);

    /// 只拉屏幕流
    // const String screenEndWith = "_screen";
    /// 只拉摄像头流
    // const String cameraEndWith = "_camera";
    /// 拼装出的流id结果
    // final String resultSteamId = "$steamId$screenEndWith";
    /// 直接使用房间id
    final String resultSteamId = steamId;

    /// 开始拉流
    await ZegoExpressEngine.instance.startPlayingStream(resultSteamId,
        canvas: previewCanvas, config: playConfig);
  }

  /*
  * 处理小窗口点进来【恢复到直播间】
  *
  * 1。从系统后台进程恢复；
  * 2。从其他页面恢复；
  * */
  static Future<void> handleFloat(
      {VoidCallback? onComplete, bool isPreview = false}) async {
    if (kIsWeb || (!Platform.isAndroid)) {
      return;
    }
    if (!(await FloatPlugin.isShowFloat)!) {
      return;
    }
    if (onComplete != null) {
      onComplete();
    }

    /// 如果回到app的时候是直播页面才取消悬浮窗显示【对话框不在判断条件内】
    /// 修复【APP】观看直播时点主播头像看回放，弹出浮窗权限提醒。打开浮窗权限返回APP内小窗口自动消失；
    /// 修复打开分享页面显示悬浮窗后离开app再恢复，小窗消失；
    /// 修复打开回放页面显示悬浮窗后离开app再恢复，小窗消失；
    ///
    /// 由于预览页面用到了需要加个参数，是否预览，不是预览的情况下才需要判断[RouteUtil.routeIsLive]，
    /// 默认isPreview为false【默认不是预览】
    ///
    /// 影响范围：
    /// 预览【AppLifecycleState.resumed】，普通直播【AppLifecycleState.resumed】、obs【AppLifecycleState.resumed】
    if (RouteUtil.routeIsLive && !isPreview) {
      await FloatPlugin.dismiss();
    }
  }

  //注销即构SDK
  static Future<void> destroyEngine(
      {required bool isAnchor,
      required int? textureID,
      required String roomId}) async {
    if (isAnchor) {
      await ZegoExpressEngine.instance.stopPublishingStream(); //停止推流
      ZegoExpressEngine.onPublisherStateUpdate = null;
      ZegoExpressEngine.onRoomStateUpdate = null;
      if (Platform.isAndroid) {
        await MediaProjectionCreator.destroyMediaProjection();
      }
    } else {
      await ZegoExpressEngine.instance.stopPlayingStream(roomId); //停止拉流
      ZegoExpressEngine.onRoomStateUpdate = null;
      ZegoExpressEngine.onRoomUserUpdate = null;
      ZegoExpressEngine.onPlayerStateUpdate = null;
    }
    if (!kIsWeb && Platform.isIOS) {
      await ReplayKitLauncher.finishReplayKitBroadcast(
          configProvider.broadcastNotificationName);
      await IosScreenPlugin.stopGetData();
    }
    //停止本地预览
    await ZegoExpressEngine.instance.stopPreview();
    //销毁预览容器
    if (textureID != null) {
      await ZegoExpressEngine.instance.destroyTextureRenderer(textureID);
    }
    //登出房间
    await ZegoExpressEngine.instance.logoutRoom(roomId);
    //注销
    await ZegoExpressEngine.destroyEngine();
    await Wakelock.disable();
  }
}
