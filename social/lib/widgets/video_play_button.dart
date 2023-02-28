import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/db/db.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/content_checker.dart';
import 'package:im/utils/image_operator_collection/status_widget.dart';
import 'package:im/utils/utils.dart';
import 'package:provider/provider.dart';

class VideoPlayButton extends StatelessWidget {
  final double width;
  final double height;
  final Color borderColor;
  final Color bgColor;

  const VideoPlayButton({
    this.width = 40.0,
    this.height = 40.0,
    this.borderColor,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor ?? Colors.white),
        color: bgColor ?? Colors.black.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.play_arrow,
        color: borderColor ?? Colors.white,
      ),
    );
  }
}

class VideoWidget extends StatelessWidget {
  final int duration;
  final Widget child;
  final double borderRadius;
  final Color backgroundColor;
  final Widget playButton;
  final String url;

  const VideoWidget(
      {this.child,
      this.duration,
      this.borderRadius = 0.0,
      this.backgroundColor = Colors.black,
      this.url,
      this.playButton = const VideoPlayButton()});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ValueListenableBuilder<Box<int>>(
          valueListenable: Db.rejectVideoBox.listenable(keys: [url ?? '']),
          builder: (context, box, _) {
            final rejected =
                box?.get(url ?? '', defaultValue: VideoCheckResult.passed) ==
                    VideoCheckResult.unPassed;
            if (rejected)
              return videoRejectWidget(context,
                  showBorder: true, size: 24, margin: 12);
            return _buildVideoPlayWidget();
          }),
    );
  }

  Widget _buildVideoPlayWidget() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
            decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(borderRadius))),
        child,
        Center(child: playButton),
        Positioned(
          height: 60,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            alignment: Alignment.bottomRight,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                colors: [Colors.black.withAlpha(0), Colors.black.withAlpha(77)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Text(
              duration != null && duration > 0
                  ? formatCountdownTime(duration)
                  : '',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class AudioWidget extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color backgroundColor;
  final Widget playButton;
  final Widget progress;

  const AudioWidget(
      {this.child,
      this.borderRadius = 0.0,
      this.backgroundColor = Colors.transparent,
      this.playButton = const SizedBox(),
      this.progress = const SizedBox()});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
            decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(borderRadius))),
        child,
        Center(child: playButton),
        Align(alignment: Alignment.bottomCenter, child: progress),
      ],
    );
  }
}

class AudioProgressIndicator extends StatefulWidget {
  final ValueNotifier<double> progress;
  final ValueNotifier<Duration> duration;
  final double progressHeight;
  final double height;
  final double width;
  final Color inactiveColor;
  final Color activeColor;
  final Function(double progress) progressOnChanged;

  const AudioProgressIndicator(this.progress,
      {this.height = 6,
      this.width = 100.0,
      this.progressHeight = 2.5,
      this.duration,
      this.inactiveColor = Colors.white,
      this.activeColor = Colors.blue,
      this.progressOnChanged});

  @override
  _AudioProgressIndicatorState createState() => _AudioProgressIndicatorState();
}

class _AudioProgressIndicatorState extends State<AudioProgressIndicator> {
  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(color: Colors.white, fontSize: 12);
    return Container(
      height: widget.height,
      alignment: Alignment.bottomCenter,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [Colors.black.withAlpha(0), Colors.black.withAlpha(77)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              MultiProvider(
                providers: [
                  ValueListenableProvider.value(value: widget.progress),
                  ValueListenableProvider.value(value: widget.duration)
                ],
                builder: (context, child) {
                  final progress = Provider.of<double>(context);
                  final duration = Provider.of<Duration>(context);
                  if (duration.inSeconds <= 0) {
                    return const Text("--/--", style: textStyle);
                  } else {
                    final secondStr = formatCountdownTime(
                        (progress * duration.inSeconds).toInt());
                    final durationStr = formatCountdownTime(duration.inSeconds);
                    return Text(
                      "$secondStr/$durationStr",
                      style: textStyle,
                    );
                  }
                },
              ),
              sizeWidth24,
            ],
          ),
          SizedBox(
            height: 20,
            child: ValueListenableBuilder(
                valueListenable: widget.progress,
                builder: (context, value, child) {
                  return SliderTheme(
                      data: const SliderThemeData(
                          trackHeight: 1,
                          thumbShape:
                              RoundSliderThumbShape(enabledThumbRadius: 4)),
                      child: Slider(
                        value: value,
                        onChanged: (value) {
                          widget.progressOnChanged?.call(value);
                        },
                        activeColor: widget.activeColor,
                        inactiveColor: widget.inactiveColor,
                      ));
                }),
          )
        ],
      ),
    );
  }
}

class AudioPlayButton extends StatefulWidget {
  final double width;
  final double heigth;
  final ValueNotifier<bool> playing;

  const AudioPlayButton(this.playing, {this.width = 40.0, this.heigth = 40.0});

  @override
  _AudioPlayButtonState createState() => _AudioPlayButtonState();
}

class _AudioPlayButtonState extends State<AudioPlayButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.heigth,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        color: Colors.black.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: ValueListenableBuilder(
        valueListenable: widget.playing,
        builder: (context, value, child) {
          return Icon(
            value ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
          );
        },
      ),
    );
  }
}
