import 'package:zego_ww/zego_ww.dart';

class ZegoSDKManager {
  /// 自定义消息
  static set onIMRecvCustomCommand(
      Function(String roomID, String command)? _onIMRecvCustomCommand) {
    ZegoEngineManager.onIMRecvCustomCommand = _onIMRecvCustomCommand;
  }

  /// 自定义消息获取
  static Function(String roomID, String command)? get onIMRecvCustomCommand {
    return ZegoEngineManager.instance!.engine!.onIMRecvCustomCommand;
  }

  /// 房间状态回调
  static set onRoomStateUpdate(
      Function(String roomID, ZegoRoomState? roomState, int errorCode,
              Map extendedData)?
          _onRoomStateUpdate) {
    ZegoEngineManager.onRoomStateUpdate = _onRoomStateUpdate;
  }

  /// 房间状态回调获取
  static Function(String roomID, ZegoRoomState? roomState, int errorCode,
      Map extendedData)? get onRoomStateUpdate {
    return ZegoEngineManager.instance!.engine!.onRoomStateUpdate;
  }

  /// 房间流发生变化回调
  static set onRoomStreamUpdate(
      Function(String roomID, ZegoUpdateType? updateType,
              List<ZegoStream> streamList, Map extendedData)?
          _onRoomStreamUpdate) {
    ZegoEngineManager.onRoomStreamUpdate = _onRoomStreamUpdate;
  }

  /// 房间流发生变化回调获取
  static Function(String roomID, ZegoUpdateType? updateType,
      List<ZegoStream> streamList, Map extendedData)? get onRoomStreamUpdate {
    return ZegoEngineManager.instance!.engine!.onRoomStreamUpdate;
  }

  /// 推流状态回调
  static set onPublisherStateUpdate(
      Function(String? streamID, ZegoPublisherState? state, int? errorCode,
              Map extendedData)?
          _onPublisherStateUpdate) {
    ZegoEngineManager.onPublisherStateUpdate = _onPublisherStateUpdate;
  }

  /// 推流状态回调获取
  static Function(String? streamID, ZegoPublisherState? state, int? errorCode,
      Map extendedData)? get onPublisherStateUpdate {
    return ZegoEngineManager.instance!.engine!.onPublisherStateUpdate;
  }

  /// 房间人数变化回调
  static set onRoomUserUpdate(
      Function(String roomID, ZegoUpdateType? updateType,
              List<ZegoUser> userList)?
          _onRoomUserUpdate) {
    ZegoEngineManager.onRoomUserUpdate = _onRoomUserUpdate;
  }

  /// 房间人数变化回调获取
  static Function(
          String roomID, ZegoUpdateType? updateType, List<ZegoUser> userList)?
      get onRoomUserUpdate {
    return ZegoEngineManager.instance!.engine!.onRoomUserUpdate;
  }

  /// 拉流状态回调
  static set onPlayerStateUpdate(
      Function(String? streamID, ZegoPlayerState? state, int? errorCode,
              Map extendedData)?
          _onPlayerStateUpdate) {
    ZegoEngineManager.onPlayerStateUpdate = _onPlayerStateUpdate;
  }

  /// 拉流状态回调
  static Function(String? streamID, ZegoPlayerState? state, int? errorCode,
      Map extendedData)? get onPlayerStateUpdate {
    return ZegoEngineManager.instance!.engine!.onPlayerStateUpdate;
  }

  /// 声浪监听回调
  static set onSoundLevelUpdate(
      Function(String? streamID, int? soundLevel, String? type)?
          _onSoundLevelUpdate) {
    ZegoEngineManager.onSoundLevelUpdate = _onSoundLevelUpdate;
  }

  /// 声浪监听回调
  static Function(String? streamID, int? soundLevel, String? type)?
      get onSoundLevelUpdate {
    return ZegoEngineManager.instance!.engine!.onSoundLevelUpdate;
  }

  /// 本地声浪监听回调
  static set onCapturedSoundLevelUpdate(
      Function(double soundLevel)? _onCapturedSoundLevelUpdate) {
    ZegoEngineManager.instance!.engine!.onCapturedSoundLevelUpdate =
        _onCapturedSoundLevelUpdate;
  }

  /// 本地声浪监听回调
  static Function(double soundLevel)? get onCapturedSoundLevelUpdate {
    return ZegoEngineManager.instance!.engine!.onCapturedSoundLevelUpdate;
  }

  static Future createEngine(int appId,
      {required String server,
      required String appSign,
      bool isTestEnv = true,
      required ZegoScenario scenario,
      required bool enablePlatformView}) {
    return ZegoEngineManager.createEngine(
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
    return ZegoEngineManager.loginRoom(
        roomId: roomId, token: token, userId: userId, userUpdate: userUpdate);
  }

  /// 切换摄像头
  static dynamic useVideoDevice(
      // ignore: avoid_annotating_with_dynamic
      dynamic /*MediaStream*/ localStream,
      String deviceID) {
    return ZegoEngineManager.useVideoDevice(localStream, deviceID);
  }

  /// 切换麦克风
  static dynamic useAudioDevice(
      // ignore: avoid_annotating_with_dynamic
      dynamic /*MediaStream*/ localStream,
      String deviceID) {
    return ZegoEngineManager.useAudioDevice(localStream, deviceID);
  }

  static dynamic checkSystemRequirements() {
    return ZegoEngineManager.checkSystemRequirements();
  }

  static dynamic enumDevices() {
    return ZegoEngineManager.enumDevices();
  }

  // ignore: type_annotate_public_apis
  static dynamic createStream([source]) {
    return ZegoEngineManager.createStream(source);
  }

  static dynamic setRoomExtraInfo(String roomID, String key, String value) {
    return ZegoEngineManager.setRoomExtraInfo(roomID, key, value);
  }

  static dynamic setStreamExtraInfo(String extraInfo,
      {required String webStreamID,
      required ZegoPublishChannel nativeChannel}) {
    return ZegoEngineManager.setStreamExtraInfo(
      extraInfo,
      webStreamID: webStreamID,
      nativeChannel: nativeChannel,
    );
  }

  static dynamic setVideoConfig(
      {ZegoVideoConfig? videoConfigNative,
      ZegoWebVideoConfig? videoConfigWeb,
      ZegoPublishChannel? channel}) {
    return ZegoEngineManager.setVideoConfig(
      videoConfigNative: videoConfigNative,
      videoConfigWeb: videoConfigWeb,
      channel: channel,
    );
  }

  static dynamic startPublishingStream(String roomID,
      // ignore: avoid_annotating_with_dynamic
      {dynamic /*MediaStream*/ localStream,
      // ignore: avoid_annotating_with_dynamic
      required dynamic webPublishOption}) {
    return ZegoEngineManager.startPublishingStream(roomID,
        localStream: localStream, webPublishOption: webPublishOption);
  }

  static dynamic startPlayingStream(
    String streamID, {
    // ignore: avoid_annotating_with_dynamic
    dynamic playOptionWeb,
    ZegoCanvas? canvas,
    ZegoPlayerConfig? configNative,
  }) {
    return ZegoEngineManager.startPlayingStream(
      streamID,
      playOptionWeb: playOptionWeb,
      canvas: canvas,
      configNative: configNative,
    );
  }

  static dynamic stopPublishingStream(
      {required String streamID, ZegoPublishChannel? channel}) {
    return ZegoEngineManager.stopPublishingStream(
      streamID: streamID,
      channel: channel,
    );
  }

  // ignore: avoid_annotating_with_dynamic
  static dynamic destroyStream(dynamic /*MediaStream*/ streamID) {
    return ZegoEngineManager.destroyStream(streamID);
  }

  static dynamic stopPlayingStream(String streamID) {
    return ZegoEngineManager.stopPlayingStream(streamID);
  }

  static dynamic logoutRoom(String roomID) {
    return ZegoEngineManager.logoutRoom(roomID);
  }

  static dynamic setCaptureVolume(
      // ignore: avoid_annotating_with_dynamic
      dynamic /*MediaStream*/ localStream,
      num volume) {
    return ZegoEngineManager.setCaptureVolume(localStream, volume);
  }

  static dynamic on(String eventName, Object object) {
    return ZegoEngineManager.on(eventName, object);
  }
}
