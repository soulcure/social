import 'dart:math';

import 'package:flutter/material.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/utils/web_util/web_util.dart';
import 'package:im/widgets/button/custom_icon_button.dart';
import 'package:video_player/video_player.dart';

class WebVideoControl extends StatelessWidget {
  static double _backVolumValue = 0;

  final bool fullScreen;
  final VideoPlayerController player;
  final VideoPlayerValue playerValue;
  final double positionValue;
  final String videoUrl;
  final VoidCallback enterFullScreenCallback;
  final VoidCallback playCallback;

  const WebVideoControl({
    this.fullScreen,
    this.player,
    this.playerValue,
    this.positionValue,
    this.videoUrl,
    this.enterFullScreenCallback,
    this.playCallback,
  });

  void _playOrPause() {
    if (playerValue.isPlaying)
      player.pause();
    else {
      if (position >= duration - 50) player.seekTo(Duration.zero);
      player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double size = fullScreen ? 24 : 18;
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x08000000), Color(0xFF000000)]),
        ),
        height: fullScreen ? 76 : 60,
        child: Column(
          children: [
            Stack(
              children: <Widget>[
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: CustomIconButton(
                        padding: const EdgeInsets.all(6),
                        size: size,
                        iconData: playerValue.isPlaying
                            ? Icons.pause
                            : IconFont.webVideoPalySmall,
                        iconColor: Colors.white,
                        onPressed: playCallback ?? _playOrPause,
                      ),
                    ),
                    Text(
                      '$currentPositionString/$durationString',
                      maxLines: 1,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
                Positioned(
                  right: 4,
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      CustomIconButton(
                        padding: const EdgeInsets.all(6),
                        size: size,
                        iconData: IconFont.webDownload,
                        iconColor: Colors.white,
                        onPressed: () {
                          webUtil.downloadFile(videoUrl);
                        },
                      ),
                      if (fullScreen) sizeWidth16,
                      CustomIconButton(
                        padding: const EdgeInsets.all(6),
                        size: size,
                        iconData: IconFont.webFullScreen,
                        iconColor: Colors.white,
                        onPressed: enterFullScreenCallback,
                      ),
                      if (fullScreen) sizeWidth16,
                      CustomIconButton(
                        leading: Container(
                          width: 80,
                          height: 10,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          child: Slider(
                            value: playerValue.volume * 100,
                            activeColor: Colors.white,
                            inactiveColor: const Color(0xFF737780),
                            max: 100,
                            onChanged: (v) {
                              player.setVolume(v / 100);
                            },
                            onChangeEnd: (v) {
                              player.setVolume(v / 100);
                            },
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(0, 6, 4, 6),
                        size: size,
                        iconData: playerValue.volume != 0
                            ? IconFont.webVolumeUp
                            : IconFont.webVolumeClose,
                        iconColor: Colors.white,
                        onPressed: () {
                          if (playerValue.volume != 0) {
                            _backVolumValue = playerValue.volume;
                            player.setVolume(0);
                          } else {
                            player.setVolume(_backVolumValue);
                          }
                        },
                      ),
                    ],
                  ),
                )
              ],
            ),
            sizeHeight8,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: SizedBox(
                height: 10,
                child: Slider(
                  activeColor: Theme.of(context).primaryColor,
                  inactiveColor: Colors.white,
                  max: duration,
                  value: positionValue,
                  onChanged: (v) {
                    final safeValue = min(max(0, v), duration);
                    player.seekTo(Duration(milliseconds: safeValue.floor()));
                  },
                  onChangeEnd: (v) {
                    final safeValue = min(max(0, v), duration);
                    player.seekTo(Duration(milliseconds: safeValue.floor()));
                    player.play();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double get position => (playerValue?.position?.inMilliseconds ?? 0) * 1.0;

  double get duration => (playerValue?.duration?.inMilliseconds ?? 0) * 1.0;

  String get currentPositionString {
    final p = player.value.position;
    return '${twoDigits(p.inMinutes)}:${twoDigits(p.inSeconds - p.inMinutes * 60)}';
  }

  String get durationString {
    final p = player.value;
    return '${twoDigits(p.duration?.inMinutes ?? 0)}:${twoDigits((p.duration?.inSeconds ?? 0) - (p.duration?.inMinutes ?? 0) * 60)}';
  }
}
