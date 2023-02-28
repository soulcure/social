import 'package:flutter/material.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/pages/home/view/chat_window.dart';

class VideoChatWindowScaffold extends StatefulWidget {
  final Widget child;

  const VideoChatWindowScaffold({this.child});

  @override
  _VideoChatWindowScaffoldState createState() =>
      _VideoChatWindowScaffoldState();
}

class _VideoChatWindowScaffoldState
    extends ChatWindowScaffoldState<VideoChatWindowScaffold> {
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return ValueListenableBuilder(
      valueListenable: fullScreen,
      builder: (context, presented, child) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.fastOutSlowIn,
          padding: presented
              ? const EdgeInsets.only()
              : EdgeInsets.only(
                  top: mq.padding.top + HomeScaffoldController.to.windowPadding,
                ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(presented ? 0 : 8)),
            child: Stack(
              children: <Widget>[
                child,
                // 点击蒙层，当home处于第二屏的时候不显示
                if (!presented)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => HomeScaffoldController.to.gotoWindow(1),
                    child: Container(),
                  ),
              ],
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
