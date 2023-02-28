import 'dart:async';
import 'package:zego_express_engine/zego_express_engine.dart' as zegoEngine;
import '../zego_ww_defines.dart';
import '../interface/zego_ww_engine.dart';
import '../zego_ww_web_defines.dart';

class ZegoWwEngineNative extends ZegoWwEngine {
  zegoEngine.ZegoExpressEngine? _engine;
  zegoEngine.ZegoExpressEngine? get engine {
    if (_engine != null) {
      return _engine;
    }
    _engine = zegoEngine.ZegoExpressEngine.instance;
    return _engine;
  }

  @override
  Future createEngine(appId,
      {String? server,
      String? appSign,
      bool? isTestEnv = true,
      ZegoScenario? scenario,
      bool? enablePlatformView}) async {
    assert(appId != null, "zego appId in mobile must not be null");
    assert(appSign != null, "zego appSign in mobile must not be null");
    assert(isTestEnv != null, "zego isTestEnv in mobile must not be null");
    assert(scenario != null, "zego scenario in mobile must not be null");
    final zegoEngine.ZegoScenario _scenario =
        enumFromMappingEnum(zegoEngine.ZegoScenario.values, scenario)!;
    await zegoEngine.ZegoExpressEngine.createEngine(
        appId, appSign!, isTestEnv!, _scenario,
        enablePlatformView: enablePlatformView);
    return true;
  }

  @override
  Future loginRoom(
      {required String roomId, required String token, required String userId, bool? userUpdate}) {
    final zegoEngine.ZegoRoomConfig roomConfig =
        zegoEngine.ZegoRoomConfig.defaultConfig();
    roomConfig.token = token;
    roomConfig.isUserStatusNotify = true;

    return zegoEngine.ZegoExpressEngine.instance.loginRoom(
      roomId,
      zegoEngine.ZegoUser.id(userId),
      config: roomConfig,
    );
  }

  @override
  createStream([source]) {
    // TODO: implement createStream
    throw UnimplementedError();
  }

  @override
  Future<int> createTextureRenderer(int width, int height) {
    return engine!.createTextureRenderer(width, height);
  }

  @override
  destroyStream(streamID) {
    // TODO: implement destroyStream
    throw UnimplementedError();
  }

  @override
  Future<bool> destroyTextureRenderer(int textureID) {
    return engine!.destroyTextureRenderer(textureID);
  }

  @override
  Future<void> enableAEC(bool enable) {
    return engine!.enableAEC(enable);
  }

  @override
  Future<void> enableAGC(bool enable) {
    return engine!.enableAGC(enable);
  }

  @override
  Future<void> enableANS(bool enable) {
    return engine!.enableANS(enable);
  }

  @override
  Future<void> enableBeautify(int featureBitmask,
      {ZegoPublishChannel? channel}) {
    return engine!.enableBeautify(
      featureBitmask,
      channel: enumFromMappingEnum(
        zegoEngine.ZegoPublishChannel.values,
        channel,
      ),
    );
  }

  @override
  Future<void> enableTransientANS(bool enable) {
    return engine!.enableTransientANS(enable);
  }

  @override
  Future<void> enableVirtualStereo(bool enable, int angle) {
    return engine!.enableVirtualStereo(enable, angle);
  }

  @override
  enumDevices() {
    // TODO: implement enumDevices
    throw UnimplementedError();
  }

  @override
  checkSystemRequirements() {
    // TODO: implement enumDevices
    throw UnimplementedError();
  }

  @override
  logoutRoom(String roomID) {
    return engine!.logoutRoom(roomID);
  }

  @override
  on(String eventName, Function object) {
    // TODO: implement on
    throw UnimplementedError();
  }

  @override
  Future<void> setAECMode(ZegoAECMode mode) {
    return engine!
        .setAECMode(enumFromMappingEnum(zegoEngine.ZegoAECMode.values, mode)!);
  }

  @override
  Future<void> setANSMode(ZegoANSMode mode) {
    return engine!
        .setANSMode(enumFromMappingEnum(zegoEngine.ZegoANSMode.values, mode)!);
  }

  @override
  Future<void> setAudioEqualizerGain(int bandIndex, double bandGain) {
    return engine!.setAudioEqualizerGain(bandIndex, bandGain);
  }

  @override
  Future<void> setBeautifyOption(ZegoBeautifyOption option,
      {ZegoPublishChannel? channel}) {
    assert(option != null);
    return engine!.setBeautifyOption(
      zegoEngine.ZegoBeautifyOption(
        option.polishStep!,
        option.whitenFactor!,
        option.sharpenFactor!,
      ),
      channel:
          enumFromMappingEnum(zegoEngine.ZegoPublishChannel.values, channel),
    );
  }

  @override
  Future<void> setReverbAdvancedParam(ZegoReverbAdvancedParam param) {
    assert(param != null);
    return engine!.setReverbAdvancedParam(zegoEngine.ZegoReverbAdvancedParam(
      param.roomSize,
      param.reverberance,
      param.damping,
      param.wetOnly,
      param.wetGain,
      param.dryGain,
      param.toneLow,
      param.toneHigh,
      param.preDelay,
      param.stereoWidth,
    ));
  }

  @override
  Future<void> setReverbEchoParam(ZegoReverbEchoParam param) {
    assert(param != null);
    return engine!.setReverbEchoParam(zegoEngine.ZegoReverbEchoParam(
      param.inGain,
      param.outGain,
      param.numDelays,
      param.delay,
      param.decay,
    ));
  }

  @override
  Future<void> setReverbPreset(ZegoReverbPreset preset) {
    return engine!.setReverbPreset(
        enumFromMappingEnum(zegoEngine.ZegoReverbPreset.values, preset)!);
  }

  @override
  setRoomExtraInfo(String roomID, String key, String value) {
    return engine!.setRoomExtraInfo(roomID, key, value);
  }

  @override
  setVideoConfig(
      {ZegoVideoConfig? videoConfigNative,
      ZegoWebVideoConfig? videoConfigWeb,
      ZegoPublishChannel? channel}) {
    assert(videoConfigNative != null);
    return engine!.setVideoConfig(
      zegoEngine.ZegoVideoConfig(
        videoConfigNative!.captureWidth!,
        videoConfigNative.captureHeight!,
        videoConfigNative.encodeWidth!,
        videoConfigNative.encodeHeight!,
        videoConfigNative.bitrate!,
        videoConfigNative.fps!,
        enumFromMappingEnum(
            zegoEngine.ZegoVideoCodecID.values, videoConfigNative.codecID)!,
        2,
      ),
      channel:
          enumFromMappingEnum(zegoEngine.ZegoPublishChannel.values, channel),
    );
  }

  @override
  Future<void> setVoiceChangerParam(ZegoVoiceChangerParam param) {
    assert(param != null);
    return engine!.setVoiceChangerParam(zegoEngine.ZegoVoiceChangerParam(
      param.pitch,
    ));
  }

  @override
  Future<void> setVoiceChangerPreset(ZegoVoiceChangerPreset preset) {
    return engine!.setVoiceChangerPreset(
        enumFromMappingEnum(zegoEngine.ZegoVoiceChangerPreset.values, preset)!);
  }

  @override
  startPlayingStream(String streamID,
      {playOptionWeb, ZegoCanvas? canvas, ZegoPlayerConfig? configNative}) {
    zegoEngine.ZegoCanvas _canvas = zegoEngine.ZegoCanvas(
        canvas!.view!,
        enumFromMappingEnum(zegoEngine.ZegoViewMode.values, canvas.viewMode),
        canvas.backgroundColor);
    zegoEngine.ZegoPlayerConfig config = zegoEngine.ZegoPlayerConfig(
      enumFromMappingEnum(
          zegoEngine.ZegoStreamResourceMode.values, configNative!.resourceMode)!,
      configNative != null
          ? zegoEngine.ZegoCDNConfig(
              configNative.cdnConfig!.url!, configNative.cdnConfig!.authParam!)
          : null,
      streamID,
    );

    return engine!.startPlayingStream(streamID, canvas: _canvas, config: config);
  }

  @override
  startPublishingStream(String roomID,
      {localStream, ZegoWebPublishOption? webPublishOption}) {
    // TODO: implement startPublishingStream
    return engine!.startPublishingStream(roomID);
  }

  @override
  stopPlayingStream(String streamID) {
    return engine!.stopPlayingStream(streamID);
  }

  @override
  stopPublishingStream({String? streamID, ZegoPublishChannel? channel}) {
    return engine!.stopPublishingStream(
      channel:
          enumFromMappingEnum(zegoEngine.ZegoPublishChannel.values, channel),
    );
  }

  @override
  Future<bool> updateTextureRendererSize(int textureID, int width, int height) {
    return engine!.updateTextureRendererSize(textureID, width, height);
  }

  @override
  useVideoDevice(localStream, String deviceID) {
    // TODO: implement useVideoDevice
    throw UnimplementedError();
  }

  @override
  Future<void> startPreview({ZegoCanvas? canvas, ZegoPublishChannel? channel}) {
    return engine!.startPreview(
      canvas: zegoEngine.ZegoCanvas(
        canvas!.view!,
        enumFromMappingEnum(zegoEngine.ZegoViewMode.values, canvas.viewMode),
        canvas.backgroundColor,
      ),
      channel:
          enumFromMappingEnum(zegoEngine.ZegoPublishChannel.values, channel),
    );
  }

  @override
  Future<void> useFrontCamera(bool enable, {ZegoPublishChannel? channel}) {
    return engine!.useFrontCamera(
      enable,
      channel:
          enumFromMappingEnum(zegoEngine.ZegoPublishChannel.values, channel),
    );
  }

  @override
  Future<void> stopPreview({ZegoPublishChannel? channel}) {
    return engine!.stopPreview(
      channel:
          enumFromMappingEnum(zegoEngine.ZegoPublishChannel.values, channel),
    );
  }

  @override
  Future<void> destroyEngine() {
    return zegoEngine.ZegoExpressEngine.destroyEngine();
  }

  @override
  set onRoomStreamUpdate(
      Function(String roomID, ZegoUpdateType? updateType,
              List<ZegoStream> streamList, Map extendedData)?
          _onRoomStreamUpdate) {
    if (_onRoomStreamUpdate == null) {
      zegoEngine.ZegoExpressEngine.onRoomStreamUpdate = null;
      return;
    }

    zegoEngine.ZegoExpressEngine.onRoomStreamUpdate = (String roomID,
        zegoEngine.ZegoUpdateType updateType,
        List<zegoEngine.ZegoStream> streamList,
        Map<String, dynamic> extendedData) {
      List<ZegoStream> _streamList = [];
      for (zegoEngine.ZegoStream stream in streamList) {
        _streamList.add(ZegoStream(
          ZegoUser(stream.user.userID, stream.user.userName),
          stream.streamID,
          stream.extraInfo,
        ));
      }
      _onRoomStreamUpdate(
        roomID,
        enumFromMappingEnum(ZegoUpdateType.values, updateType),
        _streamList,
        extendedData,
      );
    };
  }

  @override
  set onRoomStateUpdate(
      Function(String roomID, ZegoRoomState? roomState, int errorCode,
              Map extendedData)?
          _onRoomStateUpdate) {
    if (_onRoomStateUpdate == null) {
      zegoEngine.ZegoExpressEngine.onRoomStateUpdate = null;
      return;
    }
    zegoEngine.ZegoExpressEngine.onRoomStateUpdate = (roomID,
        state,
        errorCode,
        extendedData) {
      _onRoomStateUpdate(
        roomID,
        enumFromMappingEnum(ZegoRoomState.values, state),
        errorCode,
        extendedData,
      );
    };
  }

  @override
  set onPlayerStateUpdate(
      Function(String streamID, ZegoPlayerState? state, int errorCode,
              Map extendedData)?
          _onPlayerStateUpdate) {
    if (_onPlayerStateUpdate == null) {
      zegoEngine.ZegoExpressEngine.onPlayerStateUpdate = null;
      return;
    }
    zegoEngine.ZegoExpressEngine.onPlayerStateUpdate = (String streamID,
        state,
        errorCode,
        extendedData) {
      _onPlayerStateUpdate(
        streamID,
        enumFromMappingEnum(ZegoPlayerState.values, state),
        errorCode,
        extendedData,
      );
    };
  }

  @override
  set onPublisherStateUpdate(
      Function(String streamID, ZegoPublisherState? state, int errorCode,
              Map extendedData)?
          _onPublisherStateUpdate) {
    if (_onPublisherStateUpdate == null) {
      zegoEngine.ZegoExpressEngine.onPublisherStateUpdate = null;
      return;
    }
    zegoEngine.ZegoExpressEngine.onPublisherStateUpdate = (String streamID,
        state,
        errorCode,
        extendedData) {
      _onPublisherStateUpdate(
        streamID,
        enumFromMappingEnum(ZegoPublisherState.values, state),
        errorCode,
        extendedData,
      );
    };
  }

  @override
  set onRoomUserUpdate(
      Function(
              String roomID, ZegoUpdateType? updateType, List<ZegoUser> userList)?
          _onRoomUserUpdate) {
    if (_onRoomUserUpdate == null) {
      zegoEngine.ZegoExpressEngine.onRoomUserUpdate = null;
      return;
    }

    zegoEngine.ZegoExpressEngine.onRoomUserUpdate = (roomID,
        updateType,
        userList) {
      final List<ZegoUser> _userList = [];
      for (final zegoEngine.ZegoUser user in userList) {
        _userList.add(ZegoUser(user.userID, user.userName));
      }
      _onRoomUserUpdate(
        roomID,
        enumFromMappingEnum(ZegoUpdateType.values, updateType),
        _userList,
      );
    };
  }

  @override
  setStreamExtraInfo(String extraInfo,
      {String? webStreamID, ZegoPublishChannel? nativeChannel}) {
    // TODO: implement setStreamExtraInfo
    return engine!.setStreamExtraInfo(extraInfo,
        channel: enumFromMappingEnum(
            zegoEngine.ZegoPublishChannel.values, nativeChannel));
  }

  @override
  Future<void> setSoundLevelDelegate(bool enable, [int interval = 1000]) {
    // TODO: implement setSoundLevelDelegate
    throw UnimplementedError();
  }

  @override
  Future setCaptureVolume(localStream, num volume) {
    // TODO: implement setCaptureVolume
    throw UnimplementedError();
  }

  @override
  dynamic useAudioDevice(localStream, String deviceID) {
    // TODO: implement useAudioDevice
    throw UnimplementedError();
  }
}
