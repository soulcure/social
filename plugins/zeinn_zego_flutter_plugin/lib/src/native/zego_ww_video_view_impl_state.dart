import 'package:flutter/material.dart';
import '../interface/zego_ww_video_view.dart';
import '../native/zego_ww_media_model_impl.dart';

class ZegoWwVideoViewImplState extends State<ZegoWwVideoView> {
  dynamic src;
  int? _textureId = -1;
  @override
  void initState() {
    // TODO: implement initState

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      ZegoWwMediaModelImpl mediaModel = ZegoWwMediaModelImpl((int textureId) {
        /// 视频流刷新
        if (_textureId != textureId) {
          setState(() {
            _textureId = textureId;
          });
        }
      });

      _textureId = mediaModel.src = widget.src;
    });
    _textureId = widget.src;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_textureId is int && _textureId! >= 0) {
      return Texture(textureId: _textureId!);
    }
    return Container();
  }
}
