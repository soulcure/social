import 'package:flutter/material.dart';

class PlayVideo {}

class GalleryModel extends ChangeNotifier {
  /// 是否显示返回按钮
  bool isShowBack;

  bool _play = true;

  bool get play => _play;

  GalleryModel({this.isShowBack = true});

  void setPlay(bool isPlay) {
    _play = isPlay;
    notifyListeners();
  }
}
