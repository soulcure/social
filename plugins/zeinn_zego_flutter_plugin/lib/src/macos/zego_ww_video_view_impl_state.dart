import 'package:flutter/material.dart';
import '../interface/zego_ww_video_view.dart';

class ZegoWwVideoViewImplState extends State<ZegoWwVideoView> {
  dynamic src;
  int _textureId = -1;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_textureId is int && _textureId >= 0) {
      return Texture(textureId: _textureId);
    }
    return Container();
  }
}
