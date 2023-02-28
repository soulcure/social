import 'dart:async';

import 'package:fb_live_flutter/live/event_bus_model/playback/playback_bus.dart';
import 'package:fb_live_flutter/live/model/room_list_model.dart';
import 'package:fb_live_flutter/live/pages/playback/widget/video_data.dart';
import 'package:fb_live_flutter/live/pages/playback/widget/vlc_player_with_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class PlaybackPlayWidget extends StatefulWidget {
  final RoomListModel roomModel;

  const PlaybackPlayWidget(this.roomModel);

  @override
  _PlaybackPlayWidgetState createState() => _PlaybackPlayWidgetState();
}

class _PlaybackPlayWidgetState extends State<PlaybackPlayWidget> {
  VlcPlayerController? _controller;
  final _key = GlobalKey<VlcPlayerWithControlsState>();

  late List<VideoData> listVideos;
  late int selectedVideoIndex;

  StreamSubscription? _playBackBus;

  void fillVideos() {
    listVideos = <VideoData>[];
    listVideos.add(VideoData(
      name: widget.roomModel.roomTitle,
      path: widget.roomModel.replayUrl,
      type: VideoType.network,
    ));
  }

  Future<void> changePlay() async {
    if ((await _controller!.isPlaying()) ?? false) {
      /// 如果播放中就暂停
      await _controller!.pause();
    } else {
      /// 否则播放[包含暂停情况与播放完成情况]
      await _controller!.play();
    }
  }

  @override
  void initState() {
    super.initState();

    fillVideos();
    selectedVideoIndex = 0;

    _playBackBus = playBackBus.on<PlayBackEvenModel>().listen((event) {
      changePlay();
    });

    final initVideo = listVideos[selectedVideoIndex];
    _controller = VlcPlayerController.network(
      initVideo.path!,
      hwAcc: HwAcc.FULL,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          VlcAdvancedOptions.networkCaching(2000),
        ]),
        subtitle: VlcSubtitleOptions([
          VlcSubtitleOptions.boldStyle(true),
          VlcSubtitleOptions.fontSize(30),
          VlcSubtitleOptions.outlineColor(VlcSubtitleColor.yellow),
          VlcSubtitleOptions.outlineThickness(VlcSubtitleThickness.normal),
          // works only on externally added subtitles
          VlcSubtitleOptions.color(VlcSubtitleColor.navy),
        ]),
        http: VlcHttpOptions([
          VlcHttpOptions.httpReconnect(true),
        ]),
        rtp: VlcRtpOptions([
          VlcRtpOptions.rtpOverRtsp(true),
        ]),
      ),
    );
    // _controller!.addOnInitListener(() async {
    //   await _controller!.startRendererScanning();
    // });
    // _controller!.addOnRendererEventListener((type, id, name) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VlcPlayerWithControls(
        key: _key,
        controller: _controller!,
        roomModel: widget.roomModel,
      ),
    );
  }

  Future releaseController() async {
    if (_controller?.value.isInitialized ?? false) {
      await _controller?.stop();
    }
    await _controller?.dispose();
  }

  @override
  void dispose() {
    super.dispose();
    releaseController();
    _playBackBus?.cancel();
    _playBackBus = null;
  }
}
