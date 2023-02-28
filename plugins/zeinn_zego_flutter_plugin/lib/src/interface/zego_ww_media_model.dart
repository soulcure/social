import 'package:flutter/material.dart';

abstract class ZegoWwMediaModel {
  dynamic src;

  void play();

  void pause();

  set muted(bool _muted);

  bool? get active;

  bool? autoplay;
  bool isPip = false;

  dynamic requestPIP();

  dynamic exitPIP();

  dynamic pictureInPictureEnabled();

  VoidCallback? onLeavePip;
}
