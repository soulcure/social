import 'dart:math';

import 'package:flutter/material.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/utils.dart';
import 'package:video_player/video_player.dart';

/// Displays the play/buffering status of the video controlled by [controller].
///
/// If [allowScrubbing] is true, this widget will detect taps and drags and
/// seek the video accordingly.
///
/// [padding] allows to specify some extra padding around the progress indicator
/// that will also detect the gestures.
class NetWorkVideoControl extends StatefulWidget {
  /// Construct an instance that displays the play/buffering status of the video
  /// controlled by [controller].
  ///
  /// Defaults will be used for everything except [controller] if they're not
  /// provided. [allowScrubbing] defaults to false, and [padding] will default
  /// to `top: 5.0`.
  NetWorkVideoControl(
    this.controller, {
    VideoProgressColors colors,
    this.allowScrubbing,
    this.padding = const EdgeInsets.only(top: 5),
  }) : colors = colors ??
            VideoProgressColors(playedColor: primaryColor.withOpacity(0.7));

  /// The [VideoPlayerController] that actually associates a video with this
  /// widget.
  final VideoPlayerController controller;

  /// The default colors used throughout the indicator.
  ///
  /// See [VideoProgressColors] for default values.
  final VideoProgressColors colors;

  /// When true, the widget will detect touch input and try to seek the video
  /// accordingly. The widget ignores such input when false.
  ///
  /// Defaults to false.
  final bool allowScrubbing;

  /// This allows for visual padding around the progress indicator that can
  /// still detect gestures via [allowScrubbing].
  ///
  /// Defaults to `top: 5.0`.
  final EdgeInsets padding;

  @override
  _NetWorkVideoControlState createState() => _NetWorkVideoControlState();
}

class _NetWorkVideoControlState extends State<NetWorkVideoControl> {
  _NetWorkVideoControlState() {
    listener = () {
      if (!mounted) {
        return;
      }
      setState(() {});
    };
  }

  VoidCallback listener;

  VideoPlayerController get controller => widget.controller;

  VideoProgressColors get colors => widget.colors;

  @override
  void initState() {
    super.initState();
    controller.addListener(listener);
  }

  @override
  void deactivate() {
    controller.removeListener(listener);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    Widget progressIndicator;
    if (controller.value.isInitialized) {
      final int duration = controller.value.duration.inMilliseconds;
      final int position = controller.value.position.inMilliseconds;

      int maxBuffering = 0;
      for (final DurationRange range in controller.value.buffered) {
        final int end = range.end.inMilliseconds;
        if (end > maxBuffering) {
          maxBuffering = end;
        }
      }

      progressIndicator = ClipRRect(
        borderRadius: BorderRadius.circular(3.5),
        child: Stack(
          fit: StackFit.passthrough,
          children: <Widget>[
            LinearProgressIndicator(
              value: maxBuffering / duration,
              minHeight: 7,
              valueColor: AlwaysStoppedAnimation<Color>(colors.bufferedColor),
              backgroundColor: colors.backgroundColor,
            ),
            LinearProgressIndicator(
              value: position / duration,
              minHeight: 7,
              valueColor: AlwaysStoppedAnimation<Color>(colors.playedColor),
              backgroundColor: Colors.transparent,
            ),
          ],
        ),
      );
      final double process = max(0, min(position / duration, 1));
      progressIndicator = AbsorbPointer(
          child: Slider(
              value: process,
              activeColor: Theme.of(context).primaryColor,
              inactiveColor: const Color(0xFF737780),
              onChanged: (value) {}));
    } else {
      progressIndicator = LinearProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(colors.playedColor),
        backgroundColor: colors.backgroundColor,
      );
    }

    Widget result;
    if (widget.allowScrubbing) {
      result = _VideoScrubber(
        controller: controller,
        child: progressIndicator,
      );
    } else {
      result = progressIndicator;
    }

    return DefaultTextStyle(
      style: const TextStyle(color: Colors.white, fontSize: 12, height: 1),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragDown: (details) {},
        onHorizontalDragUpdate: (details) {},
        child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () async {
                    if (controller.value.isPlaying) {
                      await controller.pause();
                    } else {
                      if (controller.value.duration ==
                          controller.value.position) {
                        await controller.seekTo(Duration.zero);
                      }
                      await controller.play();
                    }
                  },
                  icon: Icon(
                    controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                Container(
                    width: 42,
                    alignment: Alignment.centerLeft,
                    child: Text(currentPositionString, maxLines: 1)),
                const SizedBox(width: 8),
                Expanded(child: result),
                const SizedBox(width: 8),
                Text(durationString),
              ],
            )),
      ),
    );
  }

  String get currentPositionString {
    final p = controller.value.position;
    return '${twoDigits(p.inMinutes)}:${twoDigits(p.inSeconds - p.inMinutes * 60)}';
  }

  String get durationString {
    final p = controller.value;
    return '${twoDigits(p.duration?.inMinutes ?? 0)}:${twoDigits((p.duration?.inSeconds ?? 0) - (p.duration?.inMinutes ?? 0) * 60)}';
  }
}

class _VideoScrubber extends StatefulWidget {
  const _VideoScrubber({
    @required this.child,
    @required this.controller,
  });

  final Widget child;
  final VideoPlayerController controller;

  @override
  _VideoScrubberState createState() => _VideoScrubberState();
}

class _VideoScrubberState extends State<_VideoScrubber> {
  bool _controllerWasPlaying = false;

  VideoPlayerController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    void seekToRelativePosition(Offset globalPosition) {
      final isPlaying = controller.value.isPlaying;
      final RenderBox box = context.findRenderObject();
      final Offset tapPos = box.globalToLocal(globalPosition);
      final double relative = tapPos.dx / box.size.width;
      final Duration position = controller.value.duration * relative;
      controller.seekTo(position);
      isPlaying ? controller.play() : controller.pause();
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (details) {
        if (!controller.value.isInitialized) {
          return;
        }
        _controllerWasPlaying = controller.value.isPlaying;
        if (_controllerWasPlaying) {
          controller.pause();
        }
      },
      onHorizontalDragUpdate: (details) {
        if (!controller.value.isInitialized) {
          return;
        }
        seekToRelativePosition(details.globalPosition);
      },
      onHorizontalDragEnd: (details) {
        if (_controllerWasPlaying) {
          controller.play();
        }
      },
      onTapDown: (details) {
        if (!controller.value.isInitialized) {
          return;
        }
        seekToRelativePosition(details.globalPosition);
      },
      child: SizedBox(
        height: 40,
        child: Center(child: widget.child),
      ),
    );
  }
}
