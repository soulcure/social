import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle_video_page/controllers/circle_video_controller.dart';
import 'package:im/app/modules/circle_video_page/controllers/circle_video_page_controller.dart';
import 'package:im/pages/guild_setting/guild/container_image.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class CircleVideoPlayer extends StatefulWidget {
  const CircleVideoPlayer(this.proxyController, {key}) : super(key: key);
  final VideoProxyController proxyController;

  @override
  _CircleVideoPlayerState createState() => _CircleVideoPlayerState();
}

class _CircleVideoPlayerState extends State<CircleVideoPlayer> {
  Duration position;
  bool showThumb = true;
  bool willPop = false;

  VideoPlayerValue get playerValue =>
      widget.proxyController.playerController.value;

  VideoPlayerController get playController =>
      widget.proxyController.playerController;

  @override
  void initState() {
    position = playerValue.position;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CircleVideoPageController>(
      id: 'player',
      builder: (_) {
        _checkRealPlay();
        return VisibilityDetector(
          onVisibilityChanged: (info) {
            if (info.visibleFraction == 0) {
              //当前组件不可见，暂停视频
              playController?.pause();
            } else if (info.size.width < Get.size.width) {
              //用户滑动返回，当前组件可见宽度小于屏幕宽度，暂停视频
              willPop = true;
              playController?.pause();
            } else if (info.size.width == Get.size.width && willPop) {
              //用户滑动返回过程中取消返回，组件重新满屏，重新播放视频
              willPop = false;
              playController?.play();
            }
          },
          key: Key(widget.proxyController.postVideo.videoUrl),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 54),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: showThumb ? 0 : 1,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: playerValue.aspectRatio,
                      child:
                          VideoPlayer(widget.proxyController.playerController),
                    ),
                  ),
                ),
                if (showThumb && !widget.proxyController.banned)
                  ContainerImage(
                    widget.proxyController.postVideo.thumbUrl,
                    cacheManager: CircleCachedManager.instance,
                    fit: BoxFit.contain,
                    thumbWidth: CircleController.circleThumbWidth,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _checkRealPlay() {
    if (playerValue.position != position && showThumb == true)
      Future.delayed(
          const Duration(milliseconds: 100), () => showThumb = false);
  }
}
