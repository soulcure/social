
import 'package:flutter/material.dart';
import 'package:zego_ww/src/interface/zego_ww_video_view.dart';

class ZegoWwVideoViewImplState extends State<ZegoWwVideoView> {
  dynamic src;
  @override
  void initState() {
    // TODO: implement initState
    src = widget.src;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return const Center(
      child: Text("UnimplementedError"),
    );
  }

}

