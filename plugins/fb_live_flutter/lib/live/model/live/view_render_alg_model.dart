import 'package:flutter/cupertino.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

class ViewRenderAlgModel {
  ZegoViewMode viewMode = ZegoViewMode.AspectFill;

  double viewWidth = FrameSize.winWidth();
  double viewHeight = FrameSize.winHeight();

  bool needRotate = false;

  Axis axis = Axis.vertical;

  ViewRenderAlgModel();
}
