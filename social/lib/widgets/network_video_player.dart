import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/gallery/gallery_gesture_wrapper.dart';
import 'package:im/pages/home/view/record_view/sound_play_manager.dart';
import 'package:im/utils/image_operator_collection/image_collection.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/network_video_player_controller.dart';
import 'package:im/widgets/video_play_button.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import 'audio_player_manager.dart';
import 'custom/custom_page_route_builder.dart';

/// 这些变量是为了解决以下情况：
/// 打开外部视频，全屏播放，然后在当前频道收到任意信息
/// 会导致重新创建 [NetworkVideoPlayer]，因此 controller 之类的信息不能存在在 State 里
/// 在切换频道时需要销毁掉这些数据，因此，[NetworkVideoPlayer] 不适合用在 IM 意外的网络视频播放
Map<String, VideoPlayerController> _externalVideoControllers = {};
Map<String, ValueNotifier<bool>> _externalVideoPlaying = {};
Map<String, ValueNotifier<bool>> _externalVideoShowControls = {};

/// 私信单独拎出来后,有两个可以选中的channel,选中的channel不能释放.
Map<String, String> _externalChannelIdForMessage = {};

void clearNetVideoPlayerAfterChangeChannel() {
  /// 这个延迟是因为，执行切换频道的逻辑执行时，可能 UI 还没有切换过去，所以还不能销毁 ValueNotifier
  final List<String> cannotDisposedMessageId = [];
  _externalChannelIdForMessage.forEach((messageId, channelId) {
    if (GlobalState.selectedChannel.value?.id == channelId ||
        TextChannelController.dmChannel?.id == channelId)
      cannotDisposedMessageId.add(messageId);
  });
  const t = Duration(milliseconds: 500);
  _externalVideoControllers.forEach((key, value) {
    if (!cannotDisposedMessageId.contains(key))
      Future.delayed(t, value.dispose);
  });
  _externalVideoPlaying.forEach((key, value) {
    if (!cannotDisposedMessageId.contains(key))
      Future.delayed(t, value.dispose);
  });
  _externalVideoShowControls.forEach((key, value) {
    if (!cannotDisposedMessageId.contains(key))
      Future.delayed(t, value.dispose);
  });

  _externalVideoControllers
      .removeWhere((key, value) => !cannotDisposedMessageId.contains(key));
  _externalVideoPlaying
      .removeWhere((key, value) => !cannotDisposedMessageId.contains(key));
  _externalVideoShowControls
      .removeWhere((key, value) => !cannotDisposedMessageId.contains(key));
}

class NetworkVideoPlayer extends StatefulWidget {
  final String url;
  final double aspectRatio;
  final String thumb;
  final int duration;
  final String messageId;
  final String channelId;

  const NetworkVideoPlayer(this.url, this.messageId, this.channelId,
      {this.aspectRatio, this.thumb, this.duration});

  @override
  _NetworkVideoPlayerState createState() => _NetworkVideoPlayerState();
}

class _NetworkVideoPlayerState extends State<NetworkVideoPlayer> {
  VideoPlayerController _controller;
  final ValueNotifier<double> _aspectRatio = ValueNotifier(1);
  ValueNotifier<bool> _playing;
  ValueNotifier<bool> _showControl;
  bool _fullScreen = false;

  final heroTag = const Uuid().v1();
  Widget player;

  @override
  void initState() {
    if (!_externalVideoPlaying.containsKey(widget.messageId)) {
      _externalVideoPlaying[widget.messageId] = ValueNotifier(false);
    }
    _playing = _externalVideoPlaying[widget.messageId];

    if (!_externalVideoShowControls.containsKey(widget.messageId)) {
      _externalVideoShowControls[widget.messageId] = ValueNotifier(false);
    }
    _showControl = _externalVideoShowControls[widget.messageId];
    _externalChannelIdForMessage[widget.messageId] = widget.channelId;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: _enterFullScreenAndPlay,
        child: Hero(
            tag: heroTag,
            child: Stack(
              children: [
                _buildCover(),
                AbsorbPointer(child: Center(child: _buildPlayButton())),
              ],
            )));
  }

  Widget _buildCover() {
    Widget coverWidget;
    if (_controller?.value?.size != null) {
      coverWidget = LayoutBuilder(builder: (context, constraint) {
        return Container(
            clipBehavior: Clip.antiAlias,
            height: constraint.maxHeight,
            width: constraint.maxWidth,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: const Color(0xFFE0E2E6)),
            child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox.fromSize(
                  size: _controller.value.size,
                  child: player,
                )));
      });
    } else if (widget.thumb?.isNotEmpty ?? false) {
      coverWidget = ImageWidget.fromCachedNet(CachedImageBuilder(
        imageUrl: widget.thumb,
        fit: BoxFit.cover,
        imageBuilder: (context, imageProvider) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
        placeholder: (context, _) => Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4), color: Colors.black12),
        ),
      ));
    } else {
      coverWidget = Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: const Color(0xFFE0E2E6)));
    }
    return VideoWidget(
      duration: widget.duration,
      borderRadius: 5,
      url: widget.url,
      playButton: const SizedBox(),
      child: coverWidget,
    );
  }

  Future _enterFullScreenAndPlay() async {
    _fullScreen = true;
    if (widget.url == null) {
      showToast('未能获取到播放地址'.tr);
      return;
    }
    if (GlobalState.mediaChannel.value != null) {
      showToast('您正在使用语音功能'.tr);
      return;
    }
    if (AudioPlayerManager.instance.isPlaying) {
      unawaited(AudioPlayerManager.instance.stop());
    }

    unawaited(SoundPlayManager().stop());

    /// 这是用来把封面图换成 VideoPlayer 的，实际上就第一次有需要
    setState(() {});
    setAwake(true);
    if (_controller == null) {
      if (!_externalVideoControllers.containsKey(widget.messageId)) {
        _externalVideoControllers[widget.messageId] =
            VideoPlayerController.network(widget.url);
      }
      _playing.value = true;
      _controller = _externalVideoControllers[widget.messageId]
        ..addListener(() {
          final val = _controller?.value;
          if (val != null && !val.isPlaying && val.position == val.duration) {
            _playing.value = false;
          } else {
            _playing.value = val.isPlaying;
          }
          if ((val?.aspectRatio ?? 1.0) != _aspectRatio.value) {
            _aspectRatio.value = val?.aspectRatio ?? 1.0;
          }
        });
      unawaited(_controller.initialize().then((value) {
        ///非全屏播放时直接Return避免网络慢时退出全屏后仍播放视频
        if (!_fullScreen) return;
        _playing.value = true;
        _controller.play();
        _controller.setVolume(1);
      }));

      player = VideoPlayer(_controller);
      if (widget.aspectRatio != null && widget.aspectRatio != 0) {
        player = AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: player,
        );
      } else {
        player = ValueListenableBuilder(
          valueListenable: _aspectRatio,
          builder: (context, value, child) {
            return AspectRatio(
              aspectRatio: value,
              child: child,
            );
          },
          child: player,
        );
      }
    }

    if (_controller.value.duration != _controller.value.position) {
      await _controller.play();
      await _controller.setVolume(1);
      _playing.value = true;
    }

    unawaited(Navigator.push(
        context,
        CustomPageRouteBuilder(
            (context, animation, secondaryAnimation) => buildHeroPage())));
  }

  Future _exitFullScreen() async {
    _fullScreen = false;
    await _controller.pause();
    await _controller.setVolume(0);
    setAwake(false);
    _playing.value = false;
  }

  Widget _buildPlayButton() {
    return ValueListenableBuilder(
      valueListenable: _playing,
      builder: (context, playing, child) =>
          Visibility(visible: !playing, child: child),
      child: GestureDetector(
          onTap: () async {
            if (_controller.value.duration == _controller.value.position) {
              await _controller.seekTo(Duration.zero);
            }
            if (_controller.value.isPlaying) {
              await _controller.pause();
              await _controller.setVolume(0);
            } else {
              await _controller.play();
              await _controller.setVolume(1);
            }
          },
          child: const VideoPlayButton()),
    );
  }

  Widget buildHeroPage() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GalleryGestureWrapper(
        isSelfGesture: true,
        onDismiss: _exitFullScreen,
        onTap: () async {
          _showControl.value = !_showControl.value;
        },
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Hero(
                    tag: heroTag,
                    transitionOnUserGestures: true,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        player,
                        _buildPlayButton(),
                      ],
                    )),
              ),
              ValueListenableBuilder(
                valueListenable: _showControl,
                builder: (context, visible, child) {
                  return Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: AnimatedOpacity(
                      duration: kThemeAnimationDuration,
                      opacity: visible ? 1 : 0,
                      child: child,
                    ),
                  );
                },
                child: NetWorkVideoControl(_controller,
                    allowScrubbing: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
