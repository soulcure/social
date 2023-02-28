import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/pages/home/model/chat_target_model.dart';

class AudioPlayerManager {
  factory AudioPlayerManager() => _getInstance();

  static AudioPlayerManager get instance => _getInstance();
  static AudioPlayerManager _instance;

  // ignore: prefer_constructors_over_static_methods
  static AudioPlayerManager _getInstance() {
    return _instance ??= AudioPlayerManager._internal();
  }

  static bool get isInPlaying {
    if (_instance == null) return false;
    return _instance.isPlaying;
  }

  static String get currentChannelId {
    if (_instance == null) return '';
    return _instance.channelId;
  }

  AudioPlayer _audioPlayer;
  String _playUrl = "";
  String _key = "";
  String _title = "";
  String _thumb = "";
  String _artist = "";
  String _channelId = "";

  ValueNotifier<PlayerState> audioPlayerState =
      ValueNotifier(PlayerState.STOPPED);
  ValueNotifier<Duration> audioPlayerPosition = ValueNotifier(const Duration());
  ValueNotifier<Duration> audioPlayerDuration = ValueNotifier(const Duration());
  ValueNotifier<String> audioPlayerError = ValueNotifier("");

  AudioPlayerManager._internal() {
    _audioPlayer = AudioPlayer();
    _audioPlayer.onAudioPositionChanged
        .listen((event) => audioPlayerPosition.value = event);
    _audioPlayer.onDurationChanged
        .listen((event) => audioPlayerDuration.value = event);
    // ignore: deprecated_member_use
    _audioPlayer.onNotificationPlayerStateChanged
        .listen((event) => audioPlayerState.value = event);
    _audioPlayer.onPlayerError
        .listen((event) => audioPlayerError.value = event);
    _audioPlayer.onPlayerStateChanged
        .listen((event) => audioPlayerState.value = event);

    GlobalState.selectedChannel.addListener(_selectedChannelOnChanged);
  }

  String get playerUrl => _playUrl;

  String get key => _key;

  String get title => _title;

  String get artist => _artist;

  String get thumb => _thumb;

  String get channelId => _channelId;

  Future<int> get playerDuration => _audioPlayer.getDuration();

  Future<int> get playerPosition => _audioPlayer.getCurrentPosition();

  Future pause() async {
    await _audioPlayer.pause();
    audioPlayerState.value = PlayerState.PLAYING;
  }

  Future stop() async {
    await _audioPlayer.stop();
    audioPlayerState.value = PlayerState.STOPPED;
  }

  Future resume() async {
    await _audioPlayer.resume();
    audioPlayerState.value = PlayerState.PLAYING;
  }

  PlayerState get playerState => _audioPlayer.state;

  bool get isPlaying => _audioPlayer.state == PlayerState.PLAYING;

  Future playUrl(String url, String key, String channelId,
      {String title = "未知歌曲",
      String artist = "未知艺术家",
      String thumb = ""}) async {
    await stop();
    removeAllListener();
    _key = key;
    _playUrl = url;
    _title = title;
    _artist = artist;
    _thumb = thumb;
    _channelId = channelId;
    await _audioPlayer.play(url);
  }

  Future<int> seek(Duration position) {
    return _audioPlayer.seek(position);
  }

  Future replay() async {
    await _audioPlayer.seek(const Duration());
    await _audioPlayer.resume();
  }

  Future setNotification() async {
    if (Platform.isIOS) {
      await _audioPlayer.notificationService.setNotification(
          title: _title.tr ?? "未知歌曲".tr,
          artist: _artist.tr ?? "未知艺术家".tr,
          imageUrl: _thumb ?? "",
          duration:
              Duration(seconds: (await _audioPlayer.getDuration()) ~/ 1000),
          elapsedTime:
              Duration(seconds: await _audioPlayer.getCurrentPosition()));
    }
  }

  void removeAllListener() {
    audioPlayerState.dispose();
    audioPlayerPosition.dispose();
    audioPlayerDuration.dispose();
    audioPlayerError.dispose();

    audioPlayerState = ValueNotifier(PlayerState.STOPPED);
    audioPlayerPosition = ValueNotifier(const Duration());
    audioPlayerDuration = ValueNotifier(const Duration());
    audioPlayerError = ValueNotifier("");
  }

  Future _selectedChannelOnChanged() async {
    final channelType = GlobalState.selectedChannel?.value?.type;
    if (channelType == ChatChannelType.guildVideo ||
        channelType == ChatChannelType.guildVoice) {
      await stop();
    }
  }
}
