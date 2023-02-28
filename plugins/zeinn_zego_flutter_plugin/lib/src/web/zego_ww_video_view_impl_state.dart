import 'dart:html';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'zego_ww_media_model_impl.dart';
import '../interface/zego_ww_video_view.dart';

class ZegoWwVideoViewImplState extends State<ZegoWwVideoView> {
  dynamic src;

  late VideoElement videoElement;
  ZegoWwMediaModelImpl? mediaModel;
  Widget? _webcamWidget;

  @override
  void initState() {
    debugPrint("model刷新 。。。 ${widget.src}");
    videoElement = VideoElement();
    mediaModel = ZegoWwMediaModelImpl(videoElement);
    mediaModel!.src = widget.src;
    String _viewId = DateTime.now().toIso8601String();
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      return videoElement;
    });

    widget.onMediaModelCreated?.call(mediaModel);
    _webcamWidget = HtmlElementView(key: UniqueKey(), viewType: _viewId);
    print("model刷新 。。。 $_webcamWidget");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    /*
    if (mediaModel.src != null) {
      return _webcamWidget == null ? Container() : _webcamWidget;
    }
    return Container();
    */
    return _webcamWidget == null ? Container() : _webcamWidget!;
  }
}
