import 'package:flutter/foundation.dart';
import 'interface/zego_ww_engine.dart';
import 'zego_ww_channel.dart'
    if (dart.library.html) 'web/zego_ww_channel.dart'
    if (dart.library.io) 'native/zego_ww_channel.dart';
import 'zego_ww_defines.dart';
import 'zego_ww_web_defines.dart';

class ZegoEngineManager {
  ZegoWwEngine? engine;

  static ZegoEngineManager? _manager;
  static final ZegoEngineManager? instance = _getInstance();

  static ZegoEngineManager? _getInstance() {
    if (_manager == null) {
      _manager = ZegoEngineManager();
      if (kIsWeb) {
        _manager!.engine = ZegoWwChannel.engine;
      } else {
        _manager!.engine = ZegoWwChannel.engine;
      }
    }
    return _manager;
  }

  static Future createEngine(appId,
      {String? server,
      String? appSign,
      bool isTestEnv = true,
      ZegoScenario? scenario,
      bool? enablePlatformView}) async {
    assert(instance!.engine != null,
        "instance.engine must not be null, please check again");
    return instance!.engine!.createEngine(
      appId,
      server: server,
      appSign: appSign,
      isTestEnv: isTestEnv,
      scenario: scenario,
      enablePlatformView: enablePlatformView,
    );
  }

  static Future loginRoom(
      {required String roomId,
      required String token,
      required String userId,
      required bool userUpdate}) {
    assert(instance!.engine != null,
        "instance.engine must not be null, please check again");
    return instance!.engine!.loginRoom(
      roomId: roomId,
      token: token,
      userId: userId,
      userUpdate: userUpdate,
    );
  }

  static useVideoDevice(dynamic localStream, String deviceID) {
    assert(instance!.engine != null,
        "instance.engine must not be null, please check again");
    return instance!.engine!.useVideoDevice(localStream, deviceID);
  }

  static useAudioDevice(dynamic localStream, String deviceID) {
    assert(instance!.engine != null,
        "instance.engine must not be null, please check again");
    return instance!.engine!.useAudioDevice(localStream, deviceID);
  }

  static enumDevices() {
    assert(instance!.engine != null,
        "instance.engine must not be null, please check again");
    return instance!.engine!.enumDevices();
  }

  static checkSystemRequirements() {
    assert(instance!.engine != null,
        "instance.engine must not be null, please check again");
    return instance!.engine!.checkSystemRequirements();
  }

  static dynamic createStream([source]) {
    assert(instance!.engine != null,
        "instance.engine must not be null, please check again");
    return instance!.engine!.createStream(source);
  }

  static dynamic setRoomExtraInfo(String roomID, String key, String value) {
    assert(instance!.engine != null,
        "instance.engine must not be null, please check again");
    return instance!.engine!.setRoomExtraInfo(roomID, key, value);
  }

  static setStreamExtraInfo(String extraInfo,
      {String? webStreamID, ZegoPublishChannel? nativeChannel}) {
    assert(instance!.engine != null,
        "instance.engine must not be null, please check again");
    return instance!.engine!.setStreamExtraInfo(extraInfo,
        webStreamID: webStreamID, nativeChannel: nativeChannel);
  }

  static setVideoConfig({
    /// 安卓/iOS-视频配置
    ZegoVideoConfig? videoConfigNative,

    /// web-视频配置
    ZegoWebVideoConfig? videoConfigWeb,
    ZegoPublishChannel? channel,
  }) {
    assert(instance!.engine != null,
        "instance.engine must not be null, please check again");
    return instance!.engine!.setVideoConfig(
      videoConfigNative: videoConfigNative,
      videoConfigWeb: videoConfigWeb,
      channel: channel,
    );
  }

  static dynamic startPublishingStream(String roomID,
      {dynamic /*MediaStream*/ localStream,
      ZegoWebPublishOption? webPublishOption}) {
    assert(instance!.engine != null,
        "instance.engine must not be null, please check again");
    return instance!.engine!.startPublishingStream(
      roomID,
      localStream: localStream,
      webPublishOption: webPublishOption,
    );
  }

  static dynamic startPlayingStream(
    String streamID, {
    dynamic playOptionWeb,
    ZegoCanvas? canvas,
    ZegoPlayerConfig? configNative,
  }) {
    assert(instance!.engine != null,
        "instance.engine must not be null, please check again");
    return instance!.engine!.startPlayingStream(
      streamID,
      playOptionWeb: playOptionWeb,
      canvas: canvas,
      configNative: configNative,
    );
  }

  static stopPublishingStream({String? streamID, ZegoPublishChannel? channel}) {
    assert(instance!.engine != null,
        "instance.engine must not be null, please check again");
    return instance!.engine!.stopPublishingStream(
      streamID: streamID,
      channel: channel,
    );
  }

  static destroyStream(dynamic streamID) {
    assert(instance!.engine != null,
        "instance.engine must not be null, please check again");
    return instance!.engine!.destroyStream(streamID);
  }

  static stopPlayingStream(String streamID) {
    assert(instance!.engine != null,
        "instance.engine must not be null, please check again");
    return instance!.engine!.stopPlayingStream(streamID);
  }

  static logoutRoom(String roomID) {
    assert(instance!.engine != null,
        "instance.engine must not be null, please check again");
    return instance!.engine!.logoutRoom(roomID);
  }

  static setCaptureVolume(dynamic /*MediaStream*/ localStream, num volume) {
    assert(instance!.engine != null,
        "instance.engine must not be null, please check again");
    return instance!.engine!.setCaptureVolume(localStream, volume);
  }

  static on(String eventName, Object object) {
    assert(instance!.engine != null,
        "instance.engine must not be null, please check again");
    return instance!.engine!.on(eventName, object as Function);
  }

  static set onRoomStateUpdate(
      Function(String roomID, ZegoRoomState? roomState, int errorCode,
              Map extendedData)?
          _onRoomStateUpdate) {
    assert(instance!.engine != null,
        "instance.engine must not be null, please check again");
    instance!.engine!.onRoomStateUpdate = _onRoomStateUpdate;
  }

  static set onRoomStreamUpdate(
      Function(String roomID, ZegoUpdateType? updateType,
              List<ZegoStream> streamList, Map extendedData)?
          _onRoomStreamUpdate) {
    assert(instance!.engine != null,
        "instance.engine must not be null, please check again");
    instance!.engine!.onRoomStreamUpdate = _onRoomStreamUpdate;
  }

  static set onPublisherStateUpdate(
      Function(String? streamID, ZegoPublisherState? state, int? errorCode,
              Map extendedData)?
          _onPublisherStateUpdate) {
    assert(instance!.engine != null,
        "instance.engine must not be null, please check again");
    instance!.engine!.onPublisherStateUpdate = _onPublisherStateUpdate;
  }

  static set onRoomUserUpdate(
      Function(
              String roomID, ZegoUpdateType? updateType, List<ZegoUser> userList)?
          _onRoomUserUpdate) {
    assert(instance!.engine != null,
        "instance.engine must not be null, please check again");
    instance!.engine!.onRoomUserUpdate = _onRoomUserUpdate;
  }

  static set onSoundLevelUpdate(
      Function(String? streamID, int? soundLevel, String? type)?
          _onSoundLevelUpdate) {
    assert(instance!.engine != null,
        "instance.engine must not be null, please check again");
    instance!.engine!.onSoundLevelUpdate = _onSoundLevelUpdate;
  }

  static set onPlayerStateUpdate(
      Function(String? streamID, ZegoPlayerState? state, int? errorCode,
              Map extendedData)?
          _onPlayerStateUpdate) {
    assert(instance!.engine != null,
        "instance.engine must not be null, please check again");
    instance!.engine!.onPlayerStateUpdate = _onPlayerStateUpdate;
  }

  static set onIMRecvCustomCommand(
      Function(String roomID, String command)? _onIMRecvCustomCommand) {
    assert(instance!.engine != null,
        "instance.engine must not be null, please check again");
    instance!.engine!.onIMRecvCustomCommand = _onIMRecvCustomCommand;
  }
}
