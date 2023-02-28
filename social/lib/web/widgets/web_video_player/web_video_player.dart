import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/utils/image_operator_collection/image_collection.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/utils/web_util/web_util.dart';
import 'package:im/web/widgets/web_video_player/web_video_control.dart';
import 'package:im/widgets/button/custom_icon_button.dart';
import 'package:im/widgets/custom/custom_page_route_b2t.dart';
import 'package:im/widgets/mouse_hover_builder.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:video_player/video_player.dart';

/// 记录当前的选中的频道
String _currentChannelId;

/// 暂存播放器
Map<String, VideoPlayerController> _controllerMap = {};

/// 暂存播放状态
Map<String, bool> _playMap = {};

VideoPlayerController _getController(String key) {
  if (_currentChannelId != GlobalState.selectedChannel.value?.id) {
    /// 当切换频道后，则清楚缓存
    _controllerMap.clear();
    _playMap.clear();
    _currentChannelId = GlobalState.selectedChannel.value?.id;
  }
  return _controllerMap[key];
}

void clearVideoCache() {
  _controllerMap.clear();
  _playMap.clear();
}

class WebVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String thumbUrl;
  final int duration;
  final String messageId;
  final String quoteL1;
  final bool fullScreen;
  final Duration position; // 指定在哪个位置开始播放
  final double padding; // 特别小的长的视频需要加上

  const WebVideoPlayer({
    this.videoUrl,
    this.thumbUrl,
    this.duration,
    this.messageId,
    this.quoteL1,
    this.fullScreen = false,
    this.position,
    this.padding = 0,
  });

  @override
  _WebVideoPlayerState createState() => _WebVideoPlayerState();
}

class _WebVideoPlayerState extends State<WebVideoPlayer> {
  VideoPlayerController _controller;
  VideoPlayer _player;
  final ValueNotifier _hoverValue = ValueNotifier(false);
  DateTime _preHoverTime = DateTime.now();
  bool _played = false; // 是否播放过

  @override
  void initState() {
    () async {
      final _cacheController = _getController(mapKey);
      if (widget.fullScreen) {
        /// 如果是全屏模式，则独享单独的播放控制器
        _controller = VideoPlayerController.network(widget.videoUrl);
        await _controller.initialize();
        if (widget.position != null) {
          await _controller.seekTo(widget.position);
        }
        _player = VideoPlayer(_controller);
        _played = true;
        await _controller.play();
      } else if (_cacheController == null) {
        /// 如果没有换成则初始化一个
        _controller = VideoPlayerController.network(widget.videoUrl);
        await _controller.initialize();
        _controllerMap[mapKey] = _controller;
        _player = VideoPlayer(_controller);
      } else {
        /// 如果有有缓存，则使用缓存的播放器
        _controller = _cacheController;
        _player = VideoPlayer(_controller);
        if (_playMap[mapKey] == true) {
          await Future.delayed(const Duration(milliseconds: 300)).then((value) {
            _controller.play();
          });
        }
        final position = await _controller.position;
        _played = position.inMilliseconds > 0;
      }
      if (mounted) setState(() {});
    }();

    super.initState();
  }

  // Center _placeholder() {
  //   if (widget.fullScreen) {
  //     return const Center(
  //       child: SizedBox(
  //           width: 50,
  //           height: 50,
  //           child: CircularProgressIndicator(
  //             strokeWidth: 3,
  //           )),
  //     );
  //   }
  //   return Center(
  //     child: ImageWidget.fromCachedNet(CachedImageBuilder(
  //       imageUrl: widget.thumbUrl,
  //     )),
  //   );
  // }

  Widget playButton(VideoPlayerValue value, double safeValue) {
    return GestureDetector(
        onTap: _playOrPause,
        child: Center(child: MouseHoverBuilder(builder: (context, selected) {
          final double size =
              48.0 * (widget.fullScreen ? 2 : 1) * (selected ? 1.3 : 1);
          final double fontSize =
              19.0 * (widget.fullScreen ? 2 : 1) * (selected ? 1.3 : 1);
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: Colors.black.withOpacity(0.45)),
            padding: EdgeInsets.only(
                left: widget.fullScreen ? 4 : 2,
                top: widget.fullScreen ? 4 : 2),
            child: Icon(
              selected ? IconFont.webVideoPlayBig : IconFont.webVideoPalyMiddle,
              color: Colors.white,
              size: fontSize,
            ),
          );
        })));
  }

  @override
  Widget build(BuildContext context) {
    final child = GestureDetector(
      onTap: _playOrPause,
      onDoubleTap: () {
        if (!widget.fullScreen && (_controller?.value?.isInitialized ?? false))
          _enterFullScreen();
      },
      child: MouseRegion(
        onEnter: (_) => _hoverValue.value = true,
        onExit: (_) => _hoverValue.value = false,
        onHover: (_) {
          if (widget.fullScreen) //记录鼠标滑动时间，来控制bottombar是否隐藏
            _preHoverTime = DateTime.now();
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            /// 主播放器
            // Visibility(
            //   // visible: _controller?.value?.isInitialized ?? false,
            //   child: Container(
            //     alignment: Alignment.center,
            //     color: Colors.red,
            //     child: AspectRatio(
            //         aspectRatio: _controller?.value?.aspectRatio ?? 16 / 9,
            //         child: Stack(children: [
            //           Container(
            //             padding: const EdgeInsets.all(1),
            //             color: Colors.transparent,
            //             child: _placeholder(),
            //           ),
            //         ])),
            //   ),
            // ),
            Container(
              color: Theme.of(context).backgroundColor,
              child: const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                  )),
            ),
            ImageWidget.fromCachedNet(CachedImageBuilder(
              width: double.infinity,
              fit: BoxFit.cover,
              imageUrl: widget.thumbUrl,
            )),

            if (_player != null) IgnorePointer(child: _player),

            // Visibility(
            //   visible: !(_controller?.value?.isInitialized ?? false),
            //   child: _placeholder(),
            // ),
            // Container(
            //   color: Colors.transparent,
            // ),

            // 各种控件显示
            // if (_controller?.value?.isInitialized ?? false)
            ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, value, child) {
                final double position =
                    (value?.position?.inMilliseconds ?? 0) * 1.0;
                final double duration =
                    (value?.duration?.inMilliseconds ?? 0) * 1.0;
                final double safeValue = min(max(0, position), duration);
                // 通过hover时间，计算是否要隐藏工具栏
                final _fullScreenHideBottomBar = widget.fullScreen &&
                    value.isPlaying &&
                    _preHoverTime.isBefore(
                        DateTime.now().subtract(const Duration(seconds: 1)));
                return ValueListenableBuilder(
                  valueListenable: _hoverValue,
                  builder: (context, hoverValue, _) {
                    final _fullShortHideBottomBar =
                        !widget.fullScreen && value.isPlaying && !hoverValue;
                    final _barVisible = _played &&
                        (hoverValue || position > 0) &&
                        !_fullScreenHideBottomBar &&
                        !_fullShortHideBottomBar;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        if (!value.isPlaying) playButton(value, safeValue),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            reverseDuration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SizeTransition(
                                    sizeFactor: animation, child: child),
                              );
                            },
                            child: _barVisible
                                ? WebVideoControl(
                                    fullScreen: widget.fullScreen,
                                    player: _controller,
                                    playerValue: value,
                                    positionValue: safeValue,
                                    videoUrl: widget.videoUrl,
                                    enterFullScreenCallback: _enterFullScreen,
                                    playCallback: _playOrPause,
                                  )
                                : const SizedBox(),
                          ),
                        ),
                        Visibility(
                          visible:
                              !widget.fullScreen && !_played && !_barVisible,
                          child: Positioned(
                            bottom: 6,
                            right: 6 + widget.padding,
                            left: 14 + widget.padding,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  durationString,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                                CustomIconButton(
                                  padding: const EdgeInsets.all(6),
                                  size: 18,
                                  iconData: IconFont.webDownload,
                                  iconColor: Colors.white,
                                  onPressed: () =>
                                      webUtil.downloadFile(widget.videoUrl),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
    if (widget.fullScreen) {
      return WillPopScope(
        onWillPop: _enterFullScreen,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Focus(
              autofocus: true,
              onKey: (_, key) {
                if (key.physicalKey == PhysicalKeyboardKey.escape) {
                  _enterFullScreen();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: child),
        ),
      );
    }
    return child;
  }

  /// 暂停或播放
  void _playOrPause({VideoPlayerValue value}) {
    _played = true;
    value ??= _controller.value;
    _playMap[mapKey] = !value.isPlaying;

    if (value.isPlaying) {
      _controller.pause();
    } else {
      final double position = (value?.position?.inMilliseconds ?? 0) * 1.0;
      final double duration = (value?.duration?.inMilliseconds ?? 0) * 1.0;
      if (position >= duration - 50) _controller.seekTo(Duration.zero);
      _controller.play();
    }
  }

  Future<bool> _enterFullScreen() async {
    if (!mounted) return true;
    final position = await _controller.position;
    if (!widget.fullScreen) {
      // 进入全屏
      if (_controller.value.isPlaying) unawaited(_controller.pause());
      showToast('按 [ESC] 即可退出全屏模式'.tr,
          textStyle: const TextStyle(fontSize: 20, color: Colors.white),
          position: ToastPosition.top);
      final resultPosition = await Navigator.push(
          context,
          FadeThroughPageRouter(WebVideoPlayer(
            videoUrl: widget.videoUrl,
            thumbUrl: widget.thumbUrl,
            duration: widget.duration,
            messageId: widget.messageId,
            quoteL1: widget.quoteL1,
            fullScreen: true,
            position: position,
          )));
      if (mounted && resultPosition != null) {
        unawaited(_controller.seekTo(resultPosition));
      }
    } else {
      // 退出全屏
      /// 重新初始化
      final _controller = _getController(mapKey);
      if (_controller != null) {
        unawaited(_controller.seekTo(position));
      }
      Navigator.of(context).pop(position);
    }
    return false;
  }

  String get durationString {
    final p = _controller.value;
    return '${twoDigits(p.duration?.inMinutes ?? 0)}:${twoDigits((p.duration?.inSeconds ?? 0) - (p.duration?.inMinutes ?? 0) * 60)}';
  }

  String get mapKey =>
      '${widget.quoteL1 ?? ''}${widget.messageId ?? widget.videoUrl ?? ''}';
}
