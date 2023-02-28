import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/content_checker.dart';
import 'package:im/utils/cos_file_cache_index.dart';
import 'package:im/utils/get_image_fom_camera_or_file.dart';
import 'package:im/utils/image_operator_collection/status_widget.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/show_action_sheet.dart';
import 'package:im/utils/show_dialog.dart';
import 'package:im/utils/storage_util.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/button/back_button.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:pedantic/pedantic.dart';
import 'package:video_player/video_player.dart';

import 'gallery_gesture_wrapper.dart';
import 'model/gallery_model.dart';

void showVideoDialog(BuildContext context,
    {@required String url, Widget placeHolder, bool autoPlay = true}) {
  showCustomDialog(
      context: context,
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: GestureDetector(
            onLongPress: () {
              showCustomActionSheet([
                Text(
                  '保存视频'.tr,
                  style: Theme.of(context).textTheme.bodyText2,
                )
              ]).then((value) {
                if (value == 0) saveImageToLocal(url: url, isImage: false);
              });
            },
            child: GalleryGestureWrapper(
              isSelfGesture: true,
              child: VideoView(
                videoUrl: url,
                placeHolder: placeHolder,
                isNetResource: true,
                autoPlay: autoPlay,
              ),
            ),
          ),
        );
      });
}

class VideoView extends StatefulWidget {
  final bool isNetResource;

  /// 是否是本地文件
  final bool isFile;
  final String videoUrl;
  final String thumbUrl;
  final double thumbWidth;
  final double thumbHeight;
  final Widget placeHolder; // video 背景视图

  /// 从缓存取出图片
  /// param url
  final Future<File> Function(String) getFileFromCache;

  /// 保存图片到缓存中
  /// param1: url
  /// param2: fileBytes
  final Future<File> Function(String, Uint8List) saveFileToCache;

  final bool autoPlay;

  final GalleryModel model;

  const VideoView({
    this.thumbUrl,
    this.videoUrl,
    this.thumbWidth,
    this.thumbHeight,
    this.placeHolder,
    this.getFileFromCache,
    this.saveFileToCache,
    this.model,
    this.autoPlay = false,
    this.isNetResource = false,
    this.isFile = false,
  });

  @override
  _VideoViewState createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> {
  VideoPlayerController _videoPlayerController;
  final ValueNotifier<bool> _initFinish = ValueNotifier(false);
  bool _showControlBar = false;
  bool _autoPlay = false;

  /// 预播放视频，等待50秒加载时间
  Future<void> prePlayVideo() async {
    if (widget.model == null) return;
    final galleryModel = widget.model;
    for (int i = 0; i < 500; i++) {
      if (galleryModel.play == false) {
        _autoPlay = false;
        return;
      } // 强制退出
      if (_videoPlayerController != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          widget.model.setPlay(false);
          setAwake(true);
          await _videoPlayerController.play();
        }
        break;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  Future<void> init() async {
    final url = widget.videoUrl;
    // 本地文件不需要审核
    final isFile =
        widget.isFile || CosUploadFileIndexCache.cachePath(url) != null;
    if (!isFile) {
      final passed = await CheckUtil.startCheck(
        VideoCheckItem.fromUrl(widget.videoUrl),
        toastError: false,
      );
      if (!passed) {
        refresh();
        return;
      }
    }
    if (url == null || url.isEmpty) {
      return;
    }

    if (widget.isNetResource || kIsWeb) {
      _videoPlayerController = VideoPlayerController.network(url);
      await _videoPlayerController.initialize();
      if (widget.autoPlay) await _videoPlayerController.play();
    } else if (widget.isFile) {
      _videoPlayerController = VideoPlayerController.file(File(url));
      await _videoPlayerController.initialize();
      if (widget.autoPlay) await _videoPlayerController.play();
    } else {
      // 如果需要缓存视频则加上.videocache
      // _videoPlayerController = VideoPlayerController.network("$url.cachevideo");
      _videoPlayerController =
          CosUploadFileIndexCache.videoControllerDispatch(url);

      await _videoPlayerController.initialize();
      if (widget.model.play && widget.autoPlay) {
        _autoPlay = true;
        unawaited(prePlayVideo());
      }
    }

// 防止从缩略图到视频播放切换过程中的黑屏。（黑屏原因是视频还未播放，但是缩略图已经不显示了）。
    await Future.delayed(const Duration(milliseconds: 200));
    _initFinish.value = true;
  }

  @override
  void dispose() {
    // 先暂停，再dispose，因为dispose不能马上暂停播放，会有1-2秒的延时
    if (_videoPlayerController?.value?.isPlaying ?? false) {
      _videoPlayerController.pause();
    }
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(VideoView oldWidget) {
    if (_videoPlayerController?.value?.isPlaying ?? false)
      _videoPlayerController.pause();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  Center _placeholder() {
    return Center(
      child: widget.placeHolder ?? Container(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = Stack(children: <Widget>[
      ValueListenableBuilder(
          valueListenable: _initFinish,
          builder: (context, value, _) {
            final hasBufferSize =
                (_videoPlayerController?.value?.buffered?.length ?? 0) > 0;
            return Visibility(
              visible: !value || !hasBufferSize,
              child: _placeholder(),
            );
          }),
      ValueListenableBuilder(
          valueListenable: _initFinish,
          builder: (context, value, _) {
            return Visibility(
              visible: value,
              child: Stack(
                children: <Widget>[
                  if (_videoPlayerController?.value?.isInitialized ?? false)
                    Center(
                      child: AspectRatio(
                        aspectRatio: _videoPlayerController.value.aspectRatio,
                        child: VideoPlayer(_videoPlayerController),
                      ),
                    ),
                  if (_videoPlayerController?.value != null)
                    ValueListenableBuilder(
                      valueListenable: _videoPlayerController,
                      builder: (context, value, _) {
                        double safeValue = value.position.inMilliseconds * 1.0;
                        safeValue = safeValue <= 0 ? 0 : safeValue;
                        safeValue = safeValue >= value.duration.inMilliseconds
                            ? value.duration.inMilliseconds * 1.0
                            : safeValue;
                        if (_autoPlay && value.isPlaying) _autoPlay = false;
                        if (!value.isPlaying) setAwake(false);
                        return Stack(
                          children: <Widget>[
                            Container(
                              padding: EdgeInsets.only(
                                  top: MediaQuery.of(context).viewInsets.top +
                                      20,
                                  left: 8),
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.height,
                              alignment: Alignment.topLeft,
                              child: _showControlBar && widget.model.isShowBack
                                  ? Container(
                                      decoration: const BoxDecoration(
                                          gradient: RadialGradient(
                                        colors: [
                                          Color(0x40000000),
                                          Color(0x00000000)
                                        ],
                                      )),
                                      child: CustomBackButton(
                                          color: Colors.white,
                                          onPressed: () {
                                            _videoPlayerController.pause();
                                            Get.back();
                                          }),
                                    )
                                  : const SizedBox(),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: MediaQuery.of(context).padding.bottom,
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
                                child:
                                    _showControlBar || OrientationUtil.landscape
                                        ? GestureDetector(
                                            onHorizontalDragStart: (_) {},
                                            onHorizontalDragUpdate: (_) {},
                                            onHorizontalDragEnd: (_) {},
                                            child: buildControls(
                                                value, safeValue, context),
                                          )
                                        : Container(),
                              ),
                            ),
                            if (!value.isPlaying && !_autoPlay)
                              GestureDetector(
                                onTap: () {
                                  if (value.isPlaying) {
                                    _videoPlayerController.pause();
                                  } else {
                                    if (safeValue >=
                                        value.duration.inMilliseconds - 50)
                                      _videoPlayerController
                                          .seekTo(Duration.zero);
                                    setAwake(true);
                                    _videoPlayerController.play();
                                  }
                                },
                                child: Center(
                                    child: Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                      gradient: const RadialGradient(
                                        colors: [
                                          Color(0x40000000),
                                          Color(0x00000000)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(42)),
                                  padding: const EdgeInsets.only(left: 6),
                                  child: const Icon(
                                    IconFont.buffAudioVisualPlay,
                                    color: Colors.white,
                                    size: 38,
                                  ),
                                )),
                              )
                          ],
                        );
                      },
                    ),
                ],
              ),
            );
          }),

      /// 初始化loading
      FutureBuilder(
          future: _isCachedVideo(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.data.toString() == "true") {
              return const SizedBox();
            } else {
              return ValueListenableBuilder(
                  valueListenable: _initFinish,
                  builder: (context, value, _) {
                    return Visibility(
                      visible: !value,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );
                  });
            }
          }),
    ]);
    if (isVideoReject)
      return videoRejectWidget(context,
          testStyle: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).iconTheme.color));
    return GestureDetector(
      onTap: () {
        setState(() {
          _showControlBar = !_showControlBar;
        });
      },
      child: child,
    );
  }

  bool get isVideoReject => VideoCheckItem.isError(widget.videoUrl);

  Container buildControls(
      VideoPlayerValue value, double safeValue, BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x08000000), Color(0x30000000)]),
      ),
      height: 56,
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () {
              if (value.isPlaying) {
                _videoPlayerController.pause();
              } else {
                if (safeValue >= value.duration.inMilliseconds - 50)
                  _videoPlayerController.seekTo(Duration.zero);
                _videoPlayerController.play();
                setAwake(true);
              }
            },
            icon: Icon(
              value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 24,
            ),
          ),
          Container(
              width: 42,
              alignment: Alignment.centerLeft,
              child: Text(
                '${twoDigits(value.position.inMinutes)}:${twoDigits(value.position.inSeconds - value.position.inMinutes * 60)}',
                maxLines: 1,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              )),
          sizeWidth8,
          Expanded(
            child: SizedBox(
              height: 10,
              child: Slider(
                activeColor: Theme.of(context).primaryColor,
                inactiveColor: const Color(0xFF737780),
                max: value.duration.inMilliseconds * 1.0,
                value: safeValue,
                onChanged: (v) {
                  var safeValue = v <= 0 ? 0 : v;
                  safeValue = safeValue >= value.duration.inMilliseconds
                      ? value.duration.inMilliseconds
                      : safeValue;
                  _videoPlayerController
                      .seekTo(Duration(milliseconds: safeValue.floor()));
                  setAwake(true);
                },
                onChangeEnd: (v) {
                  var safeValue = v <= 0 ? 0 : v;
                  safeValue = safeValue >= value.duration.inMilliseconds
                      ? value.duration.inMilliseconds
                      : safeValue;
                  _videoPlayerController
                      .seekTo(Duration(milliseconds: safeValue.floor()));
                  _videoPlayerController.play();
                  setAwake(true);
                },
              ),
            ),
          ),
          sizeWidth8,
          Text(
            '${twoDigits(value.duration.inMinutes)}:${twoDigits(value.duration.inSeconds - value.duration.inMinutes * 60)}',
            maxLines: 1,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          sizeWidth8,
        ],
      ),
    );
  }

  Future<bool> _isCachedVideo() async {
    final cachedPath = await MultiImagePicker.cachedVideoPath(widget.videoUrl);
    return File(cachedPath).existsSync();
  }
}
