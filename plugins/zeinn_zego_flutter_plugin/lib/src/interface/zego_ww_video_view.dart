import 'package:flutter/material.dart';
import 'zego_ww_media_model.dart';
import 'zego_ww_video_view_impl_state.dart'
    if (dart.library.html) '../web/zego_ww_video_view_impl_state.dart'
    if (dart.library.io) '../native/zego_ww_video_view_impl_state.dart';

class ZegoWwVideoView extends StatefulWidget {
  final dynamic src;
  final Function(ZegoWwMediaModel?)? onMediaModelCreated;

  /// 3. 只要开启屏幕共享（混流回调），web端观众可以使用屏幕旋转。
  /// 必须添加Key，否则会被刷新视图
  ZegoWwVideoView({this.src, this.onMediaModelCreated, Key? key})
      : super(key: key);

  @override
  ZegoWwVideoViewImplState createState() {
    // TODO: implement createState
    return ZegoWwVideoViewImplState();
  }
}
