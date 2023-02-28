import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/foundation.dart';
import '../zego_ww_defines.dart';
import '../zego_ww_web_defines.dart';

abstract class ZegoWwEngine {
  Future createEngine(
    dynamic appId, {

    /// web --> websocket
    String? server,

    /// mobile appSign
    String? appSign,

    /// mobile is test env
    bool? isTestEnv,

    /// mobile live scenario
    ZegoScenario? scenario,

    /// mobile enable use platform view
    bool? enablePlatformView,
  });

  Future loginRoom(
      {required String roomId,
      required String token,
      required String userId,
      required bool userUpdate});

  Future setCaptureVolume(dynamic /*MediaStream*/ localStream, num volume);

  dynamic useVideoDevice(dynamic /*MediaStream*/ localStream, String deviceID);

  dynamic useAudioDevice(dynamic /*MediaStream*/ localStream, String deviceID);

  dynamic enumDevices();

  dynamic checkSystemRequirements();

  dynamic createStream([source]);

  dynamic setRoomExtraInfo(String roomID, String key, String value);

  dynamic setStreamExtraInfo(String extraInfo,
      {String? webStreamID, ZegoPublishChannel? nativeChannel});

  // dynamic setVideoConfig(dynamic/*MediaStream*/ localStream, dynamic constraints);
  dynamic setVideoConfig({
    /// 安卓/iOS-视频配置
    ZegoVideoConfig? videoConfigNative,

    /// web-视频配置
    ZegoWebVideoConfig? videoConfigWeb,
    ZegoPublishChannel? channel,
  });

  Future<void> startPreview({ZegoCanvas? canvas, ZegoPublishChannel? channel});

  /// Stops the local video preview (for the specified channel).
  ///
  /// This function can be called to stop previewing when there is no need to see the preview locally.
  ///
  /// - [channel] Publish stream channel
  Future<void> stopPreview({ZegoPublishChannel? channel});

  dynamic startPublishingStream(String roomID,
      {dynamic /*MediaStream*/ localStream,
      ZegoWebPublishOption? webPublishOption});

  // dynamic startPlayingStream(String streamID, dynamic playOption);
  dynamic startPlayingStream(
    String streamID, {
    dynamic playOptionWeb,
    ZegoCanvas? canvas,
    ZegoPlayerConfig? configNative,
  });

  dynamic stopPublishingStream({String? streamID, ZegoPublishChannel? channel});

  dynamic destroyStream(dynamic streamID);

  dynamic stopPlayingStream(String streamID);

  dynamic logoutRoom(String roomID);

  dynamic on(String eventName, Function object);

  Future<void> destroyEngine();

  /// native onle implemente
  /// 视频画面数据相关
  Future<int> createTextureRenderer(int width, int height);

  Future<bool> updateTextureRendererSize(int textureID, int width, int height);

  Future<bool> destroyTextureRenderer(int textureID);

  /// Switches to the front or the rear camera (for the specified channel).
  ///
  /// This function is used to control the front or rear camera
  /// In the case of using a custom video capture function, because the developer has taken over the video data capturing, the SDK is no longer responsible for the video data capturing, this function is no longer valid.
  ///
  /// - [enable] Whether to use the front camera, true: use the front camera, false: use the the rear camera. The default value is true
  /// - [channel] Publishing stream channel
  Future<void> useFrontCamera(bool enable, {ZegoPublishChannel? channel});

  /// Enables or disables acoustic echo cancellation (AEC).
  ///
  /// Turning on echo cancellation, the SDK filters the collected audio data to reduce the echo component in the audio.
  /// It needs to be invoked before [startPublishingStream], [startPlayingStream], [startPreview], [createMediaPlayer] and [createAudioEffectPlayer] to take effect.
  ///
  /// - [enable] Whether to enable echo cancellation, true: enable, false: disable
  Future<void> enableAEC(bool enable);

  /// Sets the acoustic echo cancellation (AEC) mode.
  ///
  /// Switch different echo cancellation modes to control the extent to which echo data is eliminated.
  /// It needs to be invoked before [startPublishingStream], [startPlayingStream], [startPreview], [createMediaPlayer] and [createAudioEffectPlayer] to take effect.
  ///
  /// - [mode] Echo cancellation mode
  Future<void> setAECMode(ZegoAECMode mode);

  /// Enables or disables automatic gain control (AGC).
  ///
  /// When the auto gain is turned on, the sound will be amplified, but it will affect the sound quality to some extent.
  /// It needs to be invoked before [startPublishingStream], [startPlayingStream], [startPreview], [createMediaPlayer] and [createAudioEffectPlayer] to take effect.
  ///
  /// - [enable] Whether to enable automatic gain control, true: enable, false: disable
  Future<void> enableAGC(bool enable);

  /// Enables or disables active noise suppression (ANS, aka ANC).
  ///
  /// Turning on the noise suppression switch can reduce the noise in the audio data and make the human voice clearer.
  /// It needs to be invoked before [startPublishingStream], [startPlayingStream], [startPreview], [createMediaPlayer] and [createAudioEffectPlayer] to take effect.
  ///
  /// - [enable] Whether to enable noise suppression, true: enable, false: disable
  Future<void> enableANS(bool enable);

  /// Enables or disables transient noise suppression.
  ///
  /// Suppress transient noises such as keyboard and desk knocks
  /// It needs to be invoked before [startPublishingStream], [startPlayingStream], [startPreview], [createMediaPlayer] and [createAudioEffectPlayer] to take effect.
  ///
  /// - [enable] Whether to enable transient noise suppression, true: enable, false: disable
  Future<void> enableTransientANS(bool enable);

  /// Sets the automatic noise suppression (ANS) mode.
  ///
  /// Default is medium mode
  /// It needs to be invoked before [startPublishingStream], [startPlayingStream], [startPreview], [createMediaPlayer] and [createAudioEffectPlayer] to take effect.
  ///
  /// - [mode] Audio Noise Suppression mode
  Future<void> setANSMode(ZegoANSMode mode);

  /// Enables or disables the beauty features (for the specified channel).
  ///
  /// The current beauty function is simple and may not meet the developer's expectations, it is recommended to use [enableCustomVideoCapture] function to connect to a third party professional beauty SDK to get the best results.
  /// The [setBeautifyOption] function can be called to adjust the beauty parameters after the beauty function is enabled.
  /// In the case of using a custom video capture function, because the developer has taken over the video data capturing, the SDK is no longer responsible for the video data capturing, this function is no longer valid.
  ///
  /// - [featureBitmask] Beauty features, bitmask format, you can choose to enable several features in [ZegoBeautifyFeature] at the same time
  /// - [channel] Publishing stream channel
  Future<void> enableBeautify(int featureBitmask, {ZegoPublishChannel? channel});

  /// Sets up the beauty parameters (for the specified channel).
  ///
  /// Developer need to call [enableBeautify] function first to enable the beautify function before calling this function
  /// In the case of using a custom video capture function, because the developer has taken over the video data capturing, the SDK is no longer responsible for the video data capturing, this function is no longer valid.
  ///
  /// - [option] Beauty configuration options
  /// - [channel] Publishing stream channel
  Future<void> setBeautifyOption(ZegoBeautifyOption option,
      {ZegoPublishChannel? channel});

  /// Set the sound equalizer (EQ).
  ///
  /// - [bandIndex] Band frequency index, the value range is [0, 9], corresponding to 10 frequency bands, and the center frequencies are [31, 62, 125, 250, 500, 1K, 2K, 4K, 8K, 16K] Hz.
  /// - [bandGain] Band gain for the index, the value range is [-15, 15]. Default value is 0, if all gain values in all frequency bands are 0, EQ function will be disabled.
  Future<void> setAudioEqualizerGain(int bandIndex, double bandGain);

  /// Setting up the voice changer via preset enumeration.
  ///
  /// Voice changer effect is only effective for the captured sound.
  /// This function is an encapsulated version of [setVoiceChangerParam], which provides some preset values. If you need to configure the voice changer effects, please use [setVoiceChangerParam]
  /// This function is mutually exclusive with [setReverbPreset]. If used at the same time, it will produce undefined effects.
  /// Some enumerated preset will modify the parameters of reverberation or reverberation echo, so after calling this function, calling [setVoiceChangerParam], [setReverbAdvancedParam], [setReverbEchoParam] may affect the voice changer effect.
  /// If you need to configure the reverb/echo/voice changer effect, please use [setReverbAdvancedParam], [setReverbEchoParam], [setVoiceChangerParam] together.
  ///
  /// - [preset] The voice changer preset enumeration
  Future<void> setVoiceChangerPreset(ZegoVoiceChangerPreset preset);

  /// Setting up the specific voice changer parameters.
  ///
  /// Voice changer effect is only effective for the captured sound.
  /// This function is an advanced version of [setVoiceChangerPreset], you can configure the voice changer effect by yourself.
  /// If you need to configure the reverb/echo/voice changer effect, please use [setReverbAdvancedParam], [setReverbEchoParam], [setVoiceChangerParam] together.
  ///
  /// - [param] Voice changer parameters
  Future<void> setVoiceChangerParam(ZegoVoiceChangerParam param);

  /// Setting up the reverberation via preset enumeration.
  ///
  /// Support dynamic settings when publishing stream.
  /// This function is a encapsulated version of [setReverbAdvancedParam], which provides some preset values. If you need to configure the reverb, please use [setReverbAdvancedParam]
  /// This function is mutually exclusive with [setVoiceChangerPreset]. If used at the same time, it will produce undefined effects.
  /// If you need to configure the reverb/echo/voice changer effect, please use [setReverbAdvancedParam], [setReverbEchoParam], [setVoiceChangerParam] together.
  ///
  /// - [preset] The reverberation preset enumeration
  Future<void> setReverbPreset(ZegoReverbPreset preset);

  /// Setting up the specific reverberation parameters.
  ///
  /// Different values dynamically set during publishing stream will take effect. When all parameters are set to 0, the reverberation is turned off.
  /// This function is an advanced version of [setReverbPreset], you can configure the reverb effect by yourself.
  /// If you need to configure the reverb/echo/voice changer effect, please use [setReverbAdvancedParam], [setReverbEchoParam], [setVoiceChangerParam] together.
  ///
  /// - [param] Reverb advanced parameter
  Future<void> setReverbAdvancedParam(ZegoReverbAdvancedParam param);

  /// Setting up the specific reverberation echo parameters.
  ///
  /// This function can be used with voice changer and reverb to achieve a variety of custom sound effects
  /// If you need to configure the reverb/echo/voice changer effect, please use [setReverbAdvancedParam], [setReverbEchoParam], [setVoiceChangerParam] together.
  ///
  /// - [param] The reverberation echo parameter
  Future<void> setReverbEchoParam(ZegoReverbEchoParam param);

  /// Enables the virtual stereo feature.
  ///
  /// Note: You need to set up a dual channel setAudioConfig for the virtual stereo to take effect!
  ///
  /// - [enable] true to turn on the virtual stereo, false to turn off the virtual stereo
  /// - [angle] angle of the sound source in the virtual stereo, ranging from 0 to 180, with 90 being the front, and 0 and 180 being respectively Corresponds to rightmost and leftmost, usually use 90.
  Future<void> enableVirtualStereo(bool enable, int angle);

  /// 启动声浪监听
  /// Parameters
  /// bool	开启或关闭音浪回调
  /// interval?	需要回调的时间间隔，默认1000ms，可选
  Future<void> setSoundLevelDelegate(bool enable, [int interval = 1000]);

  /// 房间状态回调
  Function(String roomID, ZegoRoomState? roomState, int errorCode,
      Map extendedData)? onRoomStateUpdate;

  /// 房间流发生变化回调
  Function(String roomID, ZegoUpdateType? updateType,
      List<ZegoStream> streamList, Map extendedData)? onRoomStreamUpdate;

  /// 推流状态回调
  Function(String? streamID, ZegoPublisherState? state, int? errorCode,
      Map extendedData)? onPublisherStateUpdate;

  /// 监听声浪回调接口
  Function(String? streamID, int? soundLevel, String? type)? onSoundLevelUpdate;

  /// 监听声浪回调接口
  Function(double soundLevel)? onCapturedSoundLevelUpdate;

  /// 房间人数变化回调
  Function(String roomID, ZegoUpdateType? updateType, List<ZegoUser> userList)?
      onRoomUserUpdate;

  /// 拉流状态回调
  Function(String? streamID, ZegoPlayerState? state, int? errorCode,
      Map extendedData)? onPlayerStateUpdate;

  /// 自定义消息
  Function(String roomID, String command)? onIMRecvCustomCommand;

  T? enumFromMappingEnum<T, T2>(List<T> originEnum, T2 mappingEnum) {
    if (mappingEnum == null) {
      return null;
    }
    return originEnum.firstWhereOrNull(
        (type) => describeEnum(type!) == describeEnum(mappingEnum));
  }
}
