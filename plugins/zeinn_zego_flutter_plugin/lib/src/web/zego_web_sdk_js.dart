/*
 * @Author: sunboylu
 * @Date: 2021-01-11 19:33:44
 * @LastEditors: sunboylu
 * @LastEditTime: 2021-01-14 18:21:54
 * @Description:
 */

@JS("ZegoExpressEngine")
library ZegoExpressEngine;

import 'dart:html';

import 'package:js/js.dart';

@JS()
class ZegoExpressEngine {
  external ZegoExpressEngine(dynamic appid, String? server);

  external dynamic loginRoom(
      String? roomid, String? token, dynamic options, dynamic config);

  external dynamic createStream([ZegoLocalStreamConfig? source]);

  external dynamic startPublishingStream(
      String roomID, dynamic localStream, WebPublishOption? publishOption);

  external dynamic startPlayingStream(String streamID, dynamic playOption);

  external dynamic stopPublishingStream(String? streamID);

  external dynamic destroyStream(MediaStream streamID);

  external dynamic stopPlayingStream(String streamID);

  external dynamic logoutRoom(String roomID);

  external dynamic setDebugVerbose(bool enable);

  external dynamic setVideoConfig(MediaStream? localStream, dynamic constraints);

  external dynamic setRoomExtraInfo(String roomID, String key, String value);

  external dynamic setStreamExtraInfo(String? streamID, String extraInfo);

  external dynamic  setSoundLevelDelegate(bool bool, int interval);

  external dynamic on(String eventName, Function object);

  external dynamic enumDevices();

  external dynamic checkSystemRequirements();

  external dynamic useVideoDevice(MediaStream localStream, String deviceID);

  external dynamic useAudioDevice(MediaStream localStream, String deviceID);

  external dynamic getVersion();

  external dynamic setCaptureVolume(MediaStream localStream, num volume);
}

@JS()
@anonymous
class ZegoDeviceInfos {
  external factory ZegoDeviceInfos({
    List<ZegoDeviceInfo>? microphones,
    List<ZegoDeviceInfo>? speakers,
    List<ZegoDeviceInfo>? cameras,
  });

  external List<ZegoDeviceInfo> get microphones;

  external List<ZegoDeviceInfo> get speakers;

  external List<ZegoDeviceInfo> get cameras;
}

@JS()
@anonymous
class ZegoDeviceInfo {
  external factory ZegoDeviceInfo({
    String? deviceName,
    String? deviceID,
  });

  external String get deviceName;

  external String get deviceID;
}

@JS()
@anonymous
class WebUser {
  external factory WebUser({
    String? userID,
    String? userName,
  });

  external String get userID;

  external String get userName;
}

@JS()
@anonymous
class ZegoJSConfig {
  external factory ZegoJSConfig({
    bool? userUpdate,
  });

  external bool get userUpdate;
}

@JS()
@anonymous
class MapVideoOptions {
  external factory MapVideoOptions(
      {int? width, int? height, int? frameRate, int? maxBitrate});

  external int get width;

  external int get height;

  external int get frameRate;

  external int get maxBitrate;
}

@JS()
@anonymous
class WebZegoResponse {
  external factory WebZegoResponse({
    num? errorCode,
    String? extendedData,
  });

  external num get errorCode;

  external String get extendedData;
}

@JS()
@anonymous
class WebStreamInfo {
  external factory WebStreamInfo({
    String? streamID,
    WebUser? user,
    String? extraInfo,
    String? urlsFLV,
    String? urlsRTMP,
    String? urlsHLS,
    String? urlsHttpsFLV,
    String? urlsHttpsHLS,
  });

  external String get streamID;

  external WebUser get user;

  external String get extraInfo;

  external String get urlsFLV;

  external String get urlsRTMP;

  external String get urlsHLS;

  external String get urlsHttpsFLV;

  external String get urlsHttpsHLS;
}

@JS()
@anonymous
class WebPublishOrPlayerStateResult {
  external factory WebPublishOrPlayerStateResult({
    String? streamID,
    String? state,
    int? errorCode,
    String? extendedData,
  });

  external String get streamID;

  external String get state;

  external int get errorCode;

  external String get extendedData;
}

@JS()
@anonymous
class WebPublishOption {
  external factory WebPublishOption({
    String? streamParams,
    String? extraInfo,
    int? audioBitRate,
    String? cdnUrl,
  });

  external String get streamParams;

  external String get extraInfo;

  external int get audioBitRate;

  external String get cdnUrl;
}

@JS()
@anonymous
class ZegoLocalStreamConfig {
  external factory ZegoLocalStreamConfig({
    ZegoCamera? camera,
    ZegoScreen? screen,
  });

  external ZegoCamera get camera;

  external ZegoScreen get screen;
}

@JS()
@anonymous
class ZegoCamera {
  external factory ZegoCamera({
    bool? audio,
    String? audioInput,
    double? audioBitrate,
    bool? video,
    String? videoInput,
    int? videoQuality,
    String? facingMode,
    int? channelCount,
    bool? ANS,
    bool? AGC,
    bool? AEC,
    double? width,
    double? height,
    double? bitrate,
    double? frameRate,
    String? startBitrate,
  });

  external bool get audio;

  external String get audioInput;

  external double get audioBitrate;

  external bool get video;

  external String get videoInput;

  external int get videoQuality;

  external String get facingMode;

  external int get channelCount;

  external bool get ANS;

  external bool get AGC;

  external bool get AEC;

  external double get width;

  external double get height;

  external double get bitrate;

  external double get frameRate;

  external String get startBitrate;
}

@JS()
@anonymous
class ZegoScreen {
  external factory ZegoScreen({
    bool? audio,
    int? videoQuality,
    double? width,
    double? height,
    double? bitrate,
    double? frameRate,
    String? startBitrate,
  });

  external bool get audio;

  external int get videoQuality;

  external double get width;

  external double get height;

  external double get bitrate;

  external double get frameRate;

  external String get startBitrate;
}

@JS()
@anonymous
class ZegoCapabilityDetection {
  external factory ZegoCapabilityDetection({
    bool? webRTC,
    bool? customCapture,
    bool? camera,
    bool? microphone,
    bool? screenSharing,
    // bool videoCodec,
    // bool errInfo,
    // bool result,
  });

  external bool get webRTC;

  external bool get customCapture;

  external bool get camera;

  external bool get microphone;

  external bool get screenSharing;

// external bool get videoCodec;
//
// external bool get errInfo;
//
// external bool get result;
}
