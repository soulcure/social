import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:im/app/modules/circle_video_page/components/circle_video_component.dart';
import 'package:im/app/modules/circle_video_page/components/circle_video_player.dart';
import 'package:im/app/modules/circle_video_page/controllers/circle_video_page_controller.dart';
import 'package:im/icon_font.dart';
import 'package:im/utils/utils.dart';
import 'package:just_throttle_it/just_throttle_it.dart';

class CircleVideoPageView extends StatefulWidget {
  const CircleVideoPageView(this.controller, {Key key}) : super(key: key);

  final CircleVideoPageController controller;

  @override
  _CircleVideoPageViewState createState() => _CircleVideoPageViewState();
}

class _CircleVideoPageViewState extends State<CircleVideoPageView>
    with WidgetsBindingObserver {
  //因用户退出前台的自动暂停
  bool autoPause = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    setAwake(true);
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = widget
        .controller?.circleVideoController?.currentPlayer?.playerController;
    switch (state) {
      case AppLifecycleState.inactive:
        if (c.value.isPlaying) {
          c.pause();
          autoPause = true;
        }
        break;
      case AppLifecycleState.resumed:
        if (autoPause && mounted) {
          c.play();
          autoPause = false;
        }
        if (c.value.isPlaying) {
          setAwake(true);
        }
        break;
      case AppLifecycleState.paused:
        setAwake(false);
        break;
      case AppLifecycleState.detached:
        break;
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    setAwake(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return SafeArea(
      child: Stack(
        children: [
          PageView.builder(
            controller: c.pageController,
            physics: const CircleVideoScrollPhysics(),
            itemCount: c.circleVideoController.videoCount,
            allowImplicitScrolling: true,
            scrollDirection: Axis.vertical,
            itemBuilder: (context, index) {
              final ValueNotifier<bool> likeNotifier = ValueNotifier(false);
              final player = c.circleVideoController.playerOfIndex(index);
              return Stack(
                children: [
                  CircleVideoPlayer(player),
                  CircleVideoComponent(
                    c.videoPostModels[index],
                    player,
                    likeNotifier,
                    () => likeNotifier.value = true,
                  ),
                ],
              );
            },
          ),
          const Positioned(
            top: 0,
            left: 0,
            child: CircleVideoBackButton(),
          ),
        ],
      ),
    );
  }
}

class CircleVideoBackButton extends StatelessWidget {
  const CircleVideoBackButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Throttle.milliseconds(500, Navigator.of(context).maybePop),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color.fromRGBO(0, 0, 0, .1),
            ),
            alignment: Alignment.center,
            child: const Icon(
              IconFont.buffNavBarBackItem,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class CircleVideoScrollPhysics extends BouncingScrollPhysics {
  const CircleVideoScrollPhysics({ScrollPhysics parent})
      : super(parent: parent);

  @override
  CircleVideoScrollPhysics applyTo(ScrollPhysics ancestor) {
    return CircleVideoScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 100,
        stiffness: 1,
        damping: .43,
      );
}
