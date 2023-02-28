import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/image_operator_collection/image_collection.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/utils/web_util/web_util.dart';
import 'package:im/widgets/button/custom_icon_button.dart';
import 'package:im/widgets/custom/custom_page_route_builder.dart';
import 'package:im/widgets/mouse_hover_builder.dart';
import 'package:oktoast/oktoast.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerView extends StatefulWidget {
  final String videoUrl;
  final String thumbUrl;
  final int duration;

  const VideoPlayerView({this.videoUrl, this.thumbUrl, this.duration});

  @override
  _VideoPlayerViewState createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  bool _fullScreen = false;
  VideoPlayerController _controller;
  VideoPlayer _player;
  final ValueNotifier _hoverValue = ValueNotifier(false);
  double _backVolumValue = 0;

  // ignore: unused_field
  DateTime _preHoverTime = DateTime.now();

  void _playOrPause({VideoPlayerValue value}) {
    value ??= _controller.value;
    if (value.isPlaying)
      _controller.pause();
    else {
      if (value.position.inMilliseconds >= value.duration.inMilliseconds - 50)
        _controller.seekTo(Duration.zero);
      _controller.play();
    }
  }

  @override
  void initState() {
    () async {
      _controller = VideoPlayerController.network(widget.videoUrl);
      await _controller.initialize();
      _player = VideoPlayer(_controller);
      setState(() {});
    }();
    super.initState();
  }

  Center _placeholder() {
    return Center(
      child: ImageWidget.fromCachedNet(CachedImageBuilder(
        imageUrl: widget.thumbUrl,
      )),
    );
  }

  Widget playButton(VideoPlayerValue value, double safeValue) {
    return GestureDetector(
        onTap: _playOrPause,
        child: Center(child: MouseHoverBuilder(builder: (context, selected) {
          final size = 48 * (_fullScreen ? 2 : 1) * (selected ? 1.3 : 1);
          final fontSize = 19 * (_fullScreen ? 2 : 1) * (selected ? 1.3 : 1);
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: Colors.black.withOpacity(0.45)),
            padding: const EdgeInsets.only(left: 6),
            child: Icon(
              selected ? IconFont.webVideoPlayBig : IconFont.webVideoPalyMiddle,
              color: Colors.white,
              size: fontSize,
            ),
          );
        })));
  }

  Widget buildBottomBar(VideoPlayerValue value, double safeValue) {
    final double size = _fullScreen ? 24 : 18;
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x08000000), Color(0x30000000)]),
        ),
        height: _fullScreen ? 76 : 60,
        child: Column(
          children: [
            Stack(
              children: <Widget>[
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: CustomIconButton(
                        padding: const EdgeInsets.all(6),
                        size: size,
                        iconData: value.isPlaying
                            ? Icons.pause
                            : IconFont.webVideoPalySmall,
                        iconColor: Colors.white,
                        onPressed: () => _playOrPause(value: value),
                      ),
                    ),
                    Text(
                      '${twoDigits(value.position.inMinutes)}:${twoDigits(value.position.inSeconds - value.position.inMinutes * 60)}/${twoDigits(value.duration.inMinutes)}:${twoDigits(value.duration.inSeconds - value.duration.inMinutes * 60)}',
                      maxLines: 1,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
                Positioned(
                  right: 4,
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      CustomIconButton(
                        padding: const EdgeInsets.all(6),
                        size: size,
                        iconData: IconFont.webDownload,
                        iconColor: Colors.white,
                        onPressed: () {
                          webUtil.downloadFile(widget.videoUrl);
                        },
                      ),
                      if (_fullScreen) sizeWidth16,
                      CustomIconButton(
                        padding: const EdgeInsets.all(6),
                        size: size,
                        iconData: IconFont.webFullScreen,
                        iconColor: Colors.white,
                        onPressed: () {
                          _enterFullScreen();
                        },
                      ),
                      if (_fullScreen) sizeWidth16,
                      CustomIconButton(
                        leading: Container(
                          width: 80,
                          height: 10,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          child: Slider(
                            value: value.volume * 100,
                            activeColor: Colors.white,
                            inactiveColor: const Color(0xFF737780),
                            max: 100,
                            onChanged: (v) {
                              _controller.setVolume(v / 100);
                            },
                            onChangeEnd: (v) {
                              _controller.setVolume(v / 100);
                            },
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(0, 6, 4, 6),
                        size: size,
                        iconData: value.volume != 0
                            ? IconFont.webVolumeUp
                            : IconFont.webVolumeClose,
                        iconColor: Colors.white,
                        onPressed: () {
                          if (value.volume != 0) {
                            _backVolumValue = value.volume;
                            _controller.setVolume(0);
                          } else {
                            _controller.setVolume(_backVolumValue);
                          }
                        },
                      ),
                    ],
                  ),
                )
              ],
            ),
            sizeHeight8,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: SizedBox(
                height: 10,
                child: Slider(
                  activeColor: Theme.of(context).primaryColor,
                  inactiveColor: Colors.white,
                  max: value.duration.inMilliseconds * 1.0,
                  value: safeValue,
                  onChanged: (v) {
                    var safeValue = v <= 0 ? 0 : v;
                    safeValue = safeValue >= value.duration.inMilliseconds
                        ? value.duration.inMilliseconds
                        : safeValue;
                    _controller
                        .seekTo(Duration(milliseconds: safeValue.floor()));
                  },
                  onChangeEnd: (v) {
                    var safeValue = v <= 0 ? 0 : v;
                    safeValue = safeValue >= value.duration.inMilliseconds
                        ? value.duration.inMilliseconds
                        : safeValue;
                    _controller
                        .seekTo(Duration(milliseconds: safeValue.floor()));
                    _controller.play();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _playOrPause,
      onDoubleTap: () {
        if (!_fullScreen) _enterFullScreen();
      },
      child: MouseRegion(
        onEnter: (_) => _hoverValue.value = true,
        onExit: (_) => _hoverValue.value = false,
        onHover: (_) {
          if (_fullScreen) {
            _preHoverTime = DateTime.now();
          }
        },
        child: Stack(
          children: [
            /// 主播放器
            if (_controller?.value?.isInitialized ?? false)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: _player,
                ),
              )
            else
              _placeholder(),
            Container(
              color: Colors.transparent,
            ),

            /// 各种控件显示
            if (_controller?.value?.isInitialized ?? false)
              ValueListenableBuilder(
                valueListenable: _controller,
                builder: (context, value, child) {
                  double safeValue = value.position.inMilliseconds * 1.0;
                  safeValue = safeValue <= 0 ? 0 : safeValue;
                  safeValue = safeValue >= value.duration.inMilliseconds
                      ? value.duration.inMilliseconds * 1.0
                      : safeValue;

//                  final _hideBottomBar = _fullScreen && _preHoverTime.isBefore(DateTime.now().add(const Duration(seconds: 1)));
                  return Stack(
                    children: [
                      if (!value.isPlaying) playButton(value, safeValue),
                      ValueListenableBuilder(
                        valueListenable: _hoverValue,
                        builder: (context, hoverValue, _) {
                          return Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 150),
                              reverseDuration:
                                  const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SizeTransition(
                                      sizeFactor: animation, child: child),
                                );
                              },
                              child: (hoverValue ||
                                      value.position.inMilliseconds > 0)
                                  ? buildBottomBar(value, safeValue)
                                  : const SizedBox(),
                            ),
                          );
                        },
                      )
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _enterFullScreen() {
    if (!_fullScreen) {
      _fullScreen = true;
      showToast('按 [ESC] 即可退出全屏模式'.tr,
          textStyle: const TextStyle(fontSize: 40, color: Colors.white),
          position: ToastPosition.top);
      Navigator.push(
          context,
          CustomPageRouteBuilder(
              (context, animation, secondaryAnimation) => buildPage()));
    } else {
      _fullScreen = false;
      () async {
        /// 重新初始化
        await _controller.pause();
        final position = await _controller.position;
        _controller = VideoPlayerController.network(widget.videoUrl);
        await _controller.initialize();
        await _controller.seekTo(position);
        _player = VideoPlayer(_controller);
        setState(() {});
      }();
      Get.back();
    }
  }

  Widget buildPage() {
    return WillPopScope(
      onWillPop: () async {
        _enterFullScreen();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: build(context),
        ),
      ),
    );
  }
}
