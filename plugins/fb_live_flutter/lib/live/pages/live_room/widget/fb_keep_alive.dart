import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:flutter/material.dart';

class FBKeepAliveFull extends StatelessWidget {
  const FBKeepAliveFull({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FBKeepAlive(
      child: SizedBox(
        width: FrameSize.screenW(),
        height: FrameSize.screenH(),
      ),
    );
  }
}

class FBKeepAlive extends StatefulWidget {
  final Widget child;

  const FBKeepAlive({Key? key, required this.child}) : super(key: key);

  @override
  _FBKeepAliveState createState() => _FBKeepAliveState();
}

class _FBKeepAliveState extends State<FBKeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      /// [2021 12.28]
      /// 5. @何旭 @王增阳 横屏反转后，右侧安全区 与 张 沟通确认
      top: false,
      bottom: false,
      child: widget.child,
    );
  }

  @override
  bool get wantKeepAlive => true;
}
