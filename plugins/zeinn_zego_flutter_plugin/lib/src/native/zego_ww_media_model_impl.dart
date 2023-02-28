import 'package:flutter/material.dart';

import '../interface/zego_ww_media_model.dart';

class ZegoWwMediaModelImpl extends ZegoWwMediaModel {
  final ValueChanged<int> textTureIdChanged;

  ZegoWwMediaModelImpl(this.textTureIdChanged);

  int _textureId = -1;

  @override
  set src(_src) {
    // TODO: implement src
    if (_src == src) {
      return;
    }
    _textureId = _src ?? -1;
    textTureIdChanged.call(_textureId);
  }

  @override
  // TODO: implement src
  get src => _textureId;

  @override
  bool get active {
    return false;
  }

  @override
  void pause() {
    // TODO: implement pause
  }

  @override
  dynamic requestPIP() {
    // TODO: implement requestPIP
  }

  @override
  void play() {
    // TODO: implement play
  }

  @override
  set muted(bool _muted) {
    // TODO: implement muted
  }

  @override
  set autoplay(bool? _autoplay) {
    // TODO: implement autoplay
    super.autoplay = _autoplay;
  }

  @override
  // TODO: implement autoplay
  bool? get autoplay => super.autoplay;

  @override
  exitPIP() {
    // TODO: implement exitPIP
    throw UnimplementedError();
  }

  @override
  pictureInPictureEnabled() {
    // TODO: implement pictureInPictureEnabled
    throw UnimplementedError();
  }
}
