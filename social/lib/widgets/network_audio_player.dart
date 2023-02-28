import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/record_view/sound_play_manager.dart';
import 'package:im/utils/image_operator_collection/image_collection.dart';
import 'package:im/widgets/audio_player_manager.dart';
import 'package:im/widgets/video_play_button.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';

class NetworkAudioPlayer extends StatefulWidget {
  final String url;
  final String messageId;
  final String chatUserId;
  final String thumb;
  final String title;
  final String artist;
  final String albumName;
  final int duration;
  final bool canPlay;

  const NetworkAudioPlayer(this.url,
      {this.messageId = "",
      this.chatUserId = "",
      this.thumb,
      this.duration,
      this.title,
      this.artist,
      this.albumName,
      this.canPlay = true});

  @override
  _NetworkAudioPlayerState createState() => _NetworkAudioPlayerState();
}

class _NetworkAudioPlayerState extends State<NetworkAudioPlayer> {
  ValueNotifier<bool> playing = ValueNotifier(false);
  ValueNotifier<double> progress = ValueNotifier(0);
  ValueNotifier<Duration> duration = ValueNotifier(const Duration());

  @override
  void initState() {
    duration.value = Duration(seconds: widget.duration ?? 0);
    if (AudioPlayerManager.instance.key == widget.messageId) {
      listenAudioPlayer();
      //回到频道后恢复播放按钮状态
      playing.value = AudioPlayerManager.instance.isPlaying &&
          AudioPlayerManager.instance.playerUrl == widget.url;
    }
    super.initState();
  }

  @override
  void dispose() {
    removeListenAudioPlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.canPlay
        ? GestureDetector(onTap: _playAudio, child: _buildCover())
        : _buildCover();
  }

  Map<String, String> _thirdResHeader(String url) {
    if (url.contains("feishu.cn")) {
      return {
        "Cookie": "session=U7CK1RF-c09t7d68-96e8-48b1-b4fe-dd9bf5426931-NN5W4"
      };
    }
    return null;
  }

  Widget _buildCover() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const borderRadius = 5.0;
        return AudioWidget(
          playButton:
              widget.canPlay ? AudioPlayButton(playing) : const SizedBox(),
          progress: widget.canPlay
              ? AudioProgressIndicator(
                  progress,
                  height: 90,
                  duration: duration,
                  width: constraints.maxWidth - borderRadius * 2,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white60,
                  progressOnChanged: (progress) {
                    if (AudioPlayerManager.instance.key == widget.messageId) {
                      AudioPlayerManager.instance.seek(Duration(
                          seconds:
                              (progress * duration.value.inSeconds).toInt()));
                    }
                  },
                )
              : const SizedBox(),
          child: (widget.thumb?.isEmpty ?? true)
              ? Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: const Color(0xFFE0E2E6)))
              : ImageWidget.fromCachedNet(CachedImageBuilder(
                  imageUrl: widget.thumb,
                  fit: BoxFit.cover,
                  httpHeaders: _thirdResHeader(widget.thumb),
                  imageBuilder: (context, imageProvider) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(borderRadius),
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                  placeholder: (context, _) => Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(borderRadius),
                        color: Colors.black12),
                  ),
                )),
        );
      },
    );
  }

  Future _playAudio() async {
    if (GlobalState.mediaChannel.value != null) {
      showToast('您正在使用语音功能'.tr);
      return;
    }
    if (widget.url == null) {
      showToast('未能获取到播放地址'.tr);
      return;
    }
    unawaited(SoundPlayManager().stop());
    if (AudioPlayerManager.instance.key != widget.messageId) {
      await AudioPlayerManager.instance.playUrl(
          widget.url,
          widget.messageId,
          TextChannelController.dmChannel?.id ??
              GlobalState.selectedChannel.value?.id,
          title: widget.title,
          artist: widget.artist,
          thumb: widget.thumb);
      listenAudioPlayer();
      await AudioPlayerManager.instance.setNotification();
    } else {
      switch (AudioPlayerManager.instance.playerState) {
        case PlayerState.PLAYING:
          await AudioPlayerManager.instance.pause();
          break;
        case PlayerState.PAUSED:
          await AudioPlayerManager.instance.resume();
          break;
        case PlayerState.STOPPED:
        case PlayerState.COMPLETED:
          await AudioPlayerManager.instance.replay();
          break;
        default:
          break;
      }
      await AudioPlayerManager.instance.setNotification();
    }
  }

  void removeListenAudioPlayer() {
    AudioPlayerManager.instance.audioPlayerPosition
        .removeListener(_positionOnChanged);
    AudioPlayerManager.instance.audioPlayerDuration
        .removeListener(_durationOnChanged);
    AudioPlayerManager.instance.audioPlayerState
        .removeListener(_playStateOnChanged);
  }

  void listenAudioPlayer() {
    if (widget.messageId == AudioPlayerManager.instance.key) {
      removeListenAudioPlayer();
      AudioPlayerManager.instance.audioPlayerPosition
          .addListener(_positionOnChanged);
      AudioPlayerManager.instance.audioPlayerDuration
          .addListener(_durationOnChanged);
      AudioPlayerManager.instance.audioPlayerState
          .addListener(_playStateOnChanged);
    }
  }

  void _positionOnChanged() {
    final p = AudioPlayerManager.instance.audioPlayerPosition.value.inSeconds *
        1.0 /
        duration.value.inSeconds;
    if (p >= 0 && p <= 1) {
      progress.value = p;
    }
  }

  Future _durationOnChanged() async {
    duration.value = AudioPlayerManager.instance.audioPlayerDuration.value;
    await AudioPlayerManager.instance.setNotification();
  }

  void _playStateOnChanged() {
    switch (AudioPlayerManager.instance.playerState) {
      case PlayerState.PLAYING:
        playing.value = true;
        break;
      case PlayerState.PAUSED:
        playing.value = false;
        break;
      case PlayerState.STOPPED:
        progress.value = 0;
        playing.value = false;
        duration.value = Duration(seconds: widget.duration);
        break;
      case PlayerState.COMPLETED:
        progress.value = 1.0;
        playing.value = false;
        break;
      default:
        break;
    }
  }
}
