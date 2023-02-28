import 'dart:async';
import 'dart:html';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import '../zego_ww_defines.dart';

import '../zego_ww_web_defines.dart';
import 'zego_web_sdk_js.dart';
import '../interface/zego_ww_engine.dart';

class ZegoWwEngineWeb extends ZegoWwEngine {
  ZegoExpressEngine? _engine;
  dynamic _appId;
  String? _server;

  bool get debug {
    bool _debug = false;
    assert(() {
      _debug = true;
      return true;
    }());
    return _debug;
  }

  ZegoExpressEngine? get engine {
    if (_engine != null) {
      return _engine;
    }
    if (_appId != null && _server != null) {
      _engine = ZegoExpressEngine(_appId, _server);
    }
    return _engine;
  }

  @override
  Future createEngine(appId,
      {String? server,
      String? appSign,
      bool? isTestEnv = true,
      ZegoScenario? scenario,
      bool? enablePlatformView}) async {
    assert(appId != null, "zego appId in web must not be null");
    assert(server != null, "zego server in web must not be null");
    _appId = appId;
    _server = server;
    _engine = ZegoExpressEngine(appId, server);
    _engine!.setDebugVerbose(false);
    debugPrint("web -- 创建引擎成功");
    debugPrint("web -- getVersion -- ${_engine!.getVersion()}");
    return true;
  }

  @override
  Future loginRoom(
      {String? roomId, String? token, String? userId, bool? userUpdate}) {
    assert(engine != null,
        "ZegoExpressEngine is null, please invoke method createEngine to init ZegoExpressEngine");

    var jsPromise = engine!.loginRoom(
      roomId,
      token,
      WebUser(
        userID: userId,
        userName: userId,
      ),
      ZegoJSConfig(
        userUpdate: true,
      ),
    );

    return promiseToFuture(jsPromise);
  }

  @override
  createStream([source]) {
    var jsPromise = engine!.createStream(source);
    return promiseToFuture(jsPromise);
  }

  @override
  Future<int> createTextureRenderer(int width, int height) {
    // TODO: implement createTextureRenderer
    throw UnimplementedError();
  }

  @override
  destroyStream(streamID) {
    assert(streamID is MediaStream, "streamID must is class of MediaStream");
    engine!.destroyStream(streamID);
    return Future<void>.value();
  }

  @override
  Future<bool> destroyTextureRenderer(int textureID) {
    // TODO: implement destroyTextureRenderer
    throw UnimplementedError();
  }

  @override
  Future<void> enableAEC(bool enable) {
    // TODO: implement enableAEC
    throw UnimplementedError();
  }

  @override
  Future<void> enableAGC(bool enable) {
    // TODO: implement enableAGC
    throw UnimplementedError();
  }

  @override
  Future<void> enableANS(bool enable) {
    // TODO: implement enableANS
    throw UnimplementedError();
  }

  @override
  Future<void> enableBeautify(int featureBitmask,
      {ZegoPublishChannel? channel}) {
    // TODO: implement enableBeautify
    throw UnimplementedError();
  }

  @override
  Future<void> enableTransientANS(bool enable) {
    // TODO: implement enableTransientANS
    throw UnimplementedError();
  }

  @override
  Future<void> enableVirtualStereo(bool enable, int angle) {
    // TODO: implement enableVirtualStereo
    throw UnimplementedError();
  }

  @override
  Future<ZegoDeviceInfos> enumDevices() {
    var jsPromise = engine!.enumDevices();
    return promiseToFuture(jsPromise);
  }

  /// The return type is [ZegoCapabilityDetection]
  @override
  Future<ZegoCapabilityDetection> checkSystemRequirements() {
    var jsPromise = engine!.checkSystemRequirements();
    return promiseToFuture(jsPromise);
  }

  @override
  logoutRoom(String roomID) {
    if (roomID == null) {
      return null;
    }
    engine!.logoutRoom(roomID);
    return Future<void>.value();
  }

  @override
  on(String eventName, Function object) {
    return engine!.on(eventName, allowInterop<Function>(object));
  }

  @override
  Future<void> setAECMode(ZegoAECMode mode) {
    // TODO: implement setAECMode
    throw UnimplementedError("web-setAECMode");
  }

  @override
  Future<void> setANSMode(ZegoANSMode mode) {
    // TODO: implement setANSMode
    throw UnimplementedError("web-");
  }

  @override
  Future<void> setAudioEqualizerGain(int bandIndex, double bandGain) {
    // TODO: implement setAudioEqualizerGain
    throw UnimplementedError("web-");
  }

  @override
  Future<void> setBeautifyOption(ZegoBeautifyOption option,
      {ZegoPublishChannel? channel}) {
    // TODO: implement setBeautifyOption
    throw UnimplementedError("web-");
  }

  @override
  Future<void> setReverbAdvancedParam(ZegoReverbAdvancedParam param) {
    // TODO: implement setReverbAdvancedParam
    throw UnimplementedError("web-");
  }

  @override
  Future<void> setReverbEchoParam(ZegoReverbEchoParam param) {
    // TODO: implement setReverbEchoParam
    throw UnimplementedError("web-");
  }

  @override
  Future<void> setReverbPreset(ZegoReverbPreset preset) {
    // TODO: implement setReverbPreset
    throw UnimplementedError("web-");
  }

  @override
  setRoomExtraInfo(String roomID, String key, String value) {
    var jsPromise = engine!.setRoomExtraInfo(roomID, key, value);
    return promiseToFuture(jsPromise);
  }

  @override
  setVideoConfig(
      {ZegoVideoConfig? videoConfigNative,
      ZegoWebVideoConfig? videoConfigWeb,
      ZegoPublishChannel? channel}) {
    _assertCheck(videoConfigWeb, "videoConfigWeb");
    MapVideoOptions _mapVideoOptions = MapVideoOptions(
      width: videoConfigWeb!.constraints!.width,
      height: videoConfigWeb.constraints!.height,
      frameRate: videoConfigWeb.constraints!.frameRate,
      maxBitrate: videoConfigWeb.constraints!.maxBitrate,
    );
    var jsPromise =
        engine!.setVideoConfig(videoConfigWeb.localStream, _mapVideoOptions);
    return promiseToFuture(jsPromise);
  }

  @override
  Future<void> setVoiceChangerParam(ZegoVoiceChangerParam param) {
    // TODO: implement setVoiceChangerParam
    throw UnimplementedError("web-");
  }

  @override
  Future<void> setVoiceChangerPreset(ZegoVoiceChangerPreset preset) {
    // TODO: implement setVoiceChangerPreset
    throw UnimplementedError("web-");
  }

  @override
  dynamic startPlayingStream(String streamID,
      {playOptionWeb, ZegoCanvas? canvas, ZegoPlayerConfig? configNative}) {
    final jsPromise = engine!.startPlayingStream(streamID, playOptionWeb);
    return promiseToFuture(jsPromise);
  }

  @override
  dynamic startPublishingStream(String roomID,
      {localStream, ZegoWebPublishOption? webPublishOption}) {
    WebPublishOption? _webPublishOption;
    if (webPublishOption != null) {
      _webPublishOption = WebPublishOption(
        streamParams: webPublishOption.streamParams,
        extraInfo: webPublishOption.extraInfo,
        audioBitRate: webPublishOption.audioBitRate,
        cdnUrl: webPublishOption.cdnUrl,
      );
    }

    final bool successed = engine!.startPublishingStream(
      roomID,
      localStream,
      _webPublishOption,
    );
    return Future<bool>.value(successed);
  }

  @override
  stopPlayingStream(String streamID) {
    engine!.stopPlayingStream(streamID);
    return Future<void>.value();
  }

  @override
  stopPublishingStream({String? streamID, ZegoPublishChannel? channel}) {
    _assertCheck(streamID, "streamID");
    bool successed = engine!.stopPublishingStream(streamID);
    return Future<bool>.value(successed);
  }

  @override
  Future<bool> updateTextureRendererSize(int textureID, int width, int height) {
    // TODO: implement updateTextureRendererSize
    throw UnimplementedError("web-");
  }

  @override
  useVideoDevice(localStream, String deviceID) {
    var jsPromise = engine!.useVideoDevice(localStream, deviceID);
    return promiseToFuture<WebZegoResponse>(jsPromise);
  }

  @override
  useAudioDevice(localStream, String deviceID) {
    var jsPromise = engine!.useAudioDevice(localStream, deviceID);
    return promiseToFuture<WebZegoResponse>(jsPromise);
  }

  @override
  set onRoomStateUpdate(
      Function(String roomID, ZegoRoomState roomState, int errorCode,
              Map extendedData)?
          _onRoomStateUpdate) {
    // TODO: implement onRoomStateUpdate

    _callBack(
        String roomID, String roomState, int errorCode, String extendedData) {
      _onRoomStateUpdate!(
          roomID,
          enumFromString(ZegoRoomState.values, roomState),
          errorCode,
          {"extendedData": extendedData});
    }

    on("roomStateUpdate", _callBack);
  }

  @override
  set onRoomStreamUpdate(
      Function(String roomID, ZegoUpdateType updateType,
              List<ZegoStream> streamList, Map extendedData)?
          _onRoomStreamUpdate) {
    if (debug) {
      on("roomStreamUpdate", (String roomID, String updateType, List streamList,
          String extendedData) {
        List<ZegoStream> _streamList = [];
        for (var stream in streamList) {
          _streamList.add(
            ZegoStream(
              ZegoUser(stream.user.userID, stream.user.userName),
              stream.streamID,
              stream.extraInfo,
            ),
          );
        }
        _onRoomStreamUpdate!(
            roomID,
            enumFromString(ZegoUpdateType.values, updateType),
            _streamList,
            {"extendedData": extendedData});
      });
      return;
    }
    on("roomStreamUpdate", (String roomID, String updateType,
        List<WebStreamInfo> streamList, String extendedData) {
      List<ZegoStream> _streamList = [];
      for (var stream in streamList) {
        _streamList.add(
          ZegoStream(
            ZegoUser(stream.user.userID, stream.user.userName),
            stream.streamID,
            stream.extraInfo,
          ),
        );
      }
      _onRoomStreamUpdate!(
          roomID,
          enumFromString(ZegoUpdateType.values, updateType),
          _streamList,
          {"extendedData": extendedData});
    });
  }

  @override
  set onPublisherStateUpdate(
      Function(String? streamID, ZegoPublisherState state, int? errorCode,
              Map extendedData)?
          _onPublisherStateUpdate) {
    // TODO: implement onPublisherStateUpdate
    on("publisherStateUpdate", (zegoPublisherState) {
      _onPublisherStateUpdate!(
          zegoPublisherState.streamID,
          enumFromString(ZegoPublisherState.values, zegoPublisherState.state),
          zegoPublisherState.errorCode,
          {"extendedData": zegoPublisherState.extendedData ?? ""});
    });
  }

  @override
  set onRoomUserUpdate(
      Function(
              String roomID, ZegoUpdateType updateType, List<ZegoUser> userList)?
          _onRoomUserUpdate) {
    // TODO: implement onRoomUserUpdate
    if (debug) {
      on("roomUserUpdate", (String roomID, String updateType, List userList) {
        List<ZegoUser> _userList = [];
        for (WebUser user in userList as Iterable<WebUser>) {
          _userList.add(ZegoUser(user.userID, user.userName));
        }
        _onRoomUserUpdate!(
          roomID,
          enumFromString(ZegoUpdateType.values, updateType),
          _userList,
        );
      });
      return;
    }
    on("roomUserUpdate",
        (String roomID, String updateType, List<WebUser> userList) {
      List<ZegoUser> _userList = [];
      for (WebUser user in userList) {
        _userList.add(ZegoUser(user.userID, user.userName));
      }
      _onRoomUserUpdate!(
        roomID,
        enumFromString(ZegoUpdateType.values, updateType),
        _userList,
      );
    });
  }

  @override
  set onSoundLevelUpdate(
      Function(String? streamID, int? soundLevel, String? type)?
          _onSoundLevelUpdate) {
    print('音浪更新回调监听---soundLevelUpdate');
    on("soundLevelUpdate", (streamList) {
      _onSoundLevelUpdate!(
          streamList.streamID, streamList.soundLevel, streamList.type);
      print('soundLevelUpdate拿到数据::${streamList.toString()}');
    });
  }

  @override
  set onCapturedSoundLevelUpdate(
      Function(double soundLevel)? _onCapturedSoundLevelUpdate) {
    print('本地采集音频声浪回调监听---capturedSoundLevelUpdate');
    on("capturedSoundLevelUpdate", (soundLevelValue) {
      _onCapturedSoundLevelUpdate!(soundLevelValue);
    });
  }

  @override
  set onPlayerStateUpdate(
      Function(String? streamID, ZegoPlayerState state, int? errorCode,
              Map extendedData)?
          _onPlayerStateUpdate) {
    // TODO: implement onPlayerStateUpdate
    on("playerStateUpdate", (zegoPlayerState) {
      // print(
      //     "playerStateUpdate --> ${zegoPlayerState.streamID} ${zegoPlayerState.state} ${zegoPlayerState.errorCode} ${zegoPlayerState.extendedData}");
      _onPlayerStateUpdate!(
          zegoPlayerState.streamID,
          enumFromString(ZegoPlayerState.values, zegoPlayerState.state),
          zegoPlayerState.errorCode,
          {"extendedData": zegoPlayerState.extendedData ?? ""});
    });
  }

  @override
  set onIMRecvCustomCommand(
      Function(String _roomID, String _command)? _onIMRecvCustomCommand) {
    // TODO: implement _onIMRecvCustomCommand
    on("IMRecvCustomCommand", (roomID, fromUser, command) {
      _onIMRecvCustomCommand!(roomID, command);
    });
  }

  void _assertCheck(dynamic params, String paramsName) {
    assert(params != null, "${paramsName} not be null");
  }

  @override
  Future<void> startPreview({ZegoCanvas? canvas, ZegoPublishChannel? channel}) {
    // TODO: implement startPreview
    throw UnimplementedError();
  }

  @override
  Future<void> useFrontCamera(bool enable, {ZegoPublishChannel? channel}) {
    // TODO: implement useFrontCamera
    throw UnimplementedError();
  }

  @override
  Future<void> stopPreview({ZegoPublishChannel? channel}) {
    // TODO: implement stopPreview
    throw UnimplementedError();
  }

  @override
  Future<void> destroyEngine() {
    // TODO: implement destroyEngine
    throw UnimplementedError();
  }

  @override
  setStreamExtraInfo(String extraInfo,
      {String? webStreamID, ZegoPublishChannel? nativeChannel}) {
    _assertCheck(webStreamID, "webStreamID on web must not be null");
    var jsPromise = engine!.setStreamExtraInfo(webStreamID, extraInfo);
    return promiseToFuture(jsPromise);
  }

  @override
  Future<void> setSoundLevelDelegate(bool enable, [int interval = 1000]) {
    _assertCheck(enable, "enable on web must not be null");
    print('启动声浪监听---setSoundLevelDelegate，interval:$interval');

    var jsPromise = engine!.setSoundLevelDelegate(enable, interval);
    print('操作成功，interval:$interval，setSoundLevelDelegate：：$jsPromise');
    return Future.value();
  }

  @override
  Future setCaptureVolume(localStream, num volume) {
    _assertCheck(localStream, "localStream on web must");
    print('设置麦克风音量---setCaptureVolume，volume:$volume');
    var jsPromise = engine!.setCaptureVolume(localStream, volume);
    return promiseToFuture(jsPromise);
  }
}

extension ZegoPublisherStateExtension on ZegoPublisherState {
  String get desc {
    switch (this) {
      case ZegoPublisherState.NoPublish:
        return "NO_PUBLISH";
        break;
      case ZegoPublisherState.PublishRequesting:
        return "PUBLISH_REQUESTING";
        break;
      case ZegoPublisherState.Publishing:
        return "PUBLISHING";
        break;
    }
  }
}

extension ZegoUpdateTypeExtension on ZegoUpdateType {
  String get desc {
    switch (this) {
      case ZegoUpdateType.Add:
        return "ADD";
        break;
      case ZegoUpdateType.Delete:
        return "DELETE";
        break;
    }
  }
}

extension ZegoPlayerStateExtension on ZegoPlayerState {
  String get desc {
    switch (this) {
      case ZegoPlayerState.NoPlay:
        return "NO_PLAY";
        break;
      case ZegoPlayerState.PlayRequesting:
        return "PLAY_REQUESTING";
        break;
      case ZegoPlayerState.Playing:
        return "PLAYING";
        break;
    }
  }
}

T enumFromString<T>(List<T> originEnum, String? value) {
  return originEnum.firstWhere((type) {
    if (type is ZegoPublisherState) {
      ///自定义了字符串释义
      return type.desc == value;
    } else if (type is ZegoPlayerState) {
      ///自定义了字符串释义
      return type.desc == value;
    } else if (type is ZegoUpdateType) {
      return type.desc == value;
    }
    return describeEnum(type!) == value;
  }, orElse: () => originEnum.first);
}
