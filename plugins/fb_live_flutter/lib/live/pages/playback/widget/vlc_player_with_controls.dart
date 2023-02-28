import 'dart:io';

import 'package:fb_live_flutter/live/model/room_list_model.dart';
import 'package:fb_live_flutter/live/pages/live_room/decoration/bg_box_decoration.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

import 'controls_overlay.dart';

typedef OnStopRecordingCallback = void Function(String);

class VlcPlayerWithControls extends StatefulWidget {
  final VlcPlayerController? controller;
  final bool showControls;

  final RoomListModel? roomModel;

  const VlcPlayerWithControls({
    Key? key,
    required this.controller,
    this.showControls = true,
    this.roomModel,
  })  : assert(controller != null, 'You must provide a vlc controller'),
        super(key: key);

  @override
  VlcPlayerWithControlsState createState() => VlcPlayerWithControlsState();
}

class VlcPlayerWithControlsState extends State<VlcPlayerWithControls>
    with AutomaticKeepAliveClientMixin {
  VlcPlayerController? _controller;

  final double initSnapshotRightPosition = 10;
  final double initSnapshotBottomPosition = 10;

  double sliderValue = 0;
  double volumeValue = 50;
  String position = '';
  String duration = '';
  int numberOfCaptions = 0;
  int numberOfAudioTracks = 0;
  bool validPosition = false;

  double recordingTextOpacity = 0;
  DateTime lastRecordingShowTime = DateTime.now();
  bool isRecording = false;

  //
  List<double> playbackSpeeds = [0.5, 1.0, 2.0];
  int playbackSpeedIndex = 1;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller!.addListener(listener);
  }

  @override
  void dispose() {
    _controller!.removeListener(listener);
    super.dispose();
  }

  Future<bool?> get isCanChangeState async {
    return _controller!.isPlaying();
  }

  Future listener() async {
    if (!mounted) return;

    if (_controller!.value.isInitialized) {
      final oPosition = _controller?.value.position;
      final oDuration = _controller?.value.duration;
      if (oPosition != null && oDuration != null) {
        if (oDuration.inHours == 0) {
          final strPosition = oPosition.toString().split('.')[0];
          final strDuration = oDuration.toString().split('.')[0];
          if ((await isCanChangeState)!) {
            position =
                "${strPosition.split(':')[1]}:${strPosition.split(':')[2]}";
          }
          duration =
              "${strDuration.split(':')[1]}:${strDuration.split(':')[2]}";
        } else {
          if ((await isCanChangeState)!) {
            position = oPosition.toString().split('.')[0];
          }
          duration = oDuration.toString().split('.')[0];
        }
        validPosition = oDuration.compareTo(oPosition) >= 0;

        /// iOS有问题，进度条会回退
        if ((await isCanChangeState)! || !Platform.isIOS) {
          sliderValue = validPosition ? oPosition.inSeconds.toDouble() : 0;
          if (sliderValue == 0) {
            position = "00:00";
          }
        }
      }
      numberOfCaptions = _controller!.value.spuTracksCount;
      numberOfAudioTracks = _controller!.value.audioTracksCount;
      // update recording blink widget
      if (_controller!.value.isRecording && _controller!.value.isPlaying) {
        if (DateTime.now().difference(lastRecordingShowTime).inSeconds >= 1) {
          lastRecordingShowTime = DateTime.now();
          recordingTextOpacity = 1 - recordingTextOpacity;
        }
      } else {
        recordingTextOpacity = 0;
      }
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          width: FrameSize.winWidth(),
          height: FrameSize.winHeight(),
          decoration: const BgBoxDecoration(),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              Center(
                child: VlcPlayer(
                  controller: _controller!,
                  aspectRatio: FrameSize.winWidth() / FrameSize.winHeight(),
                  placeholder: const Center(child: CircularProgressIndicator()),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: AnimatedOpacity(
                  opacity: recordingTextOpacity,
                  duration: const Duration(seconds: 1),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: const [
                      Icon(Icons.circle, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        'REC',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ControlsOverlay(controller: _controller),
            ],
          ),
        ),
        Visibility(
          visible: widget.showControls,
          child: UnconstrainedBox(
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: FrameSize.winWidth(),
                child: Row(
                  children: [
                    IconButton(
                      color: Colors.white,
                      icon: _controller!.value.isPlaying
                          ? Image.asset(
                              'assets/live/main/playback_mini_pause.png',
                              width: 24.px,
                              height: 24.px,
                            )
                          : Image.asset(
                              'assets/live/main/playback_mini_play.png',
                              width: 24.px,
                              height: 24.px,
                            ),
                      onPressed: _togglePlaying,
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          /// 这个duration文字的长度是变化的
                          /// '' 、'00:00'、'00:01'等长度不一样
                          Container(
                            alignment: Alignment.center,
                            width: 65.px,
                            child: Text(
                              !strNoEmpty(position) ? "00:00" : position,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              activeColor: Colors.white,
                              inactiveColor: Colors.white70,
                              value: sliderValue,
                              max: !validPosition
                                  ? 1.0
                                  : _controller!.value.duration.inSeconds
                                      .toDouble(),
                              onChanged: validPosition
                                  ? _onSliderPositionChanged
                                  : null,
                            ),
                          ),
                          Container(
                            alignment: Alignment.center,
                            width: 65.px,
                            child: Text(
                              !strNoEmpty(duration) ? "00:00" : duration,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Space(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future _togglePlaying() async {
    _controller!.value.isPlaying
        ? await _controller?.pause()
        : await _controller?.play();
  }

  void _onSliderPositionChanged(double progress) {
    setState(() {
      /// iOS拖动就改变进度
      final oPosition = Duration(seconds: progress.toInt());
      final oDuration = _controller?.value.duration;
      if (oDuration != null) {
        if (oDuration.inHours == 0) {
          final strPosition = oPosition.toString().split('.')[0];
          position =
              "${strPosition.split(':')[1]}:${strPosition.split(':')[2]}";
        } else {
          position = oPosition.toString().split('.')[0];
        }
      }
      sliderValue = progress.floor().toDouble();
    });
    //convert to Milliseconds since VLC requires MS to set time
    _controller!.setTime(sliderValue.toInt() * 1000);
  }
}
