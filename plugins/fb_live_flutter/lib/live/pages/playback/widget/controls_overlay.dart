import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class ControlsOverlay extends StatelessWidget {
  const ControlsOverlay({Key? key, this.controller}) : super(key: key);

  final VlcPlayerController? controller;

  static const double _buttonIconSize = 100;

  static const Color _iconColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 50),
      reverseDuration: const Duration(milliseconds: 200),
      child: Builder(
        builder: (ctx) {
          if (controller!.value.isEnded || controller!.value.hasError) {
            return Center(
              child: FittedBox(
                child: IconButton(
                  onPressed: _replay,
                  color: _iconColor,
                  iconSize: _buttonIconSize,
                  icon: Image.asset(
                    'assets/live/main/ic_play.png',
                    width: 60.px,
                    height: 60.px,
                  ),
                ),
              ),
            );
          }

          switch (controller!.value.playingState) {
            case PlayingState.initialized:
            case PlayingState.stopped:
            case PlayingState.paused:
              return SizedBox.expand(
                child: Container(
                  color: Colors.black45,
                  alignment: Alignment.center,
                  child: FittedBox(
                    child: Center(
                      child: IconButton(
                        onPressed: _play,
                        color: _iconColor,
                        iconSize: _buttonIconSize,
                        icon: Image.asset(
                          'assets/live/main/ic_play.png',
                          width: 60.px,
                          height: 60.px,
                        ),
                      ),
                    ),
                  ),
                ),
              );

            case PlayingState.buffering:
            case PlayingState.playing:
              return GestureDetector(onTap: _pause);

            case PlayingState.ended:
            case PlayingState.error:
              return Center(
                child: FittedBox(
                  child: IconButton(
                    onPressed: _replay,
                    color: _iconColor,
                    iconSize: _buttonIconSize,
                    icon: Image.asset(
                      'assets/live/main/ic_play.png',
                      width: 60.px,
                      height: 60.px,
                    ),
                  ),
                ),
              );
            default:
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Future<void> _play() {
    return controller!.play();
  }

  Future<void> _replay() async {
    await controller!.stop();
    await controller!.play();
  }

  Future<void> _pause() async {
    if (controller!.value.isPlaying) {
      await controller!.pause();
    }
  }
}
