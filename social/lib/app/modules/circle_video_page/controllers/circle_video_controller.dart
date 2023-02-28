import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle_video_page/controllers/circle_video_page_controller.dart';
import 'package:im/loggers.dart';
import 'package:pedantic/pedantic.dart';
import 'package:video_player/video_player.dart';

typedef LoadMoreVideo = Future<List<VideoProxyController>> Function(
  int index,
  List<VideoProxyController> list,
);

class CircleVideoController extends ChangeNotifier {
  /// 到第几个触发预加载视频列表，例如：1:最后一个，2:倒数第二个
  final int loadMoreCount = 2;

  /// 预加载多少个视频
  final int cacheCount = 1;

  /// 提供视频的builder
  LoadMoreVideo _videoProvider;

  bool isDispose = false;

  void loadIndex(int target, {bool reload = false}) {
    if (!reload) {
      if (index.value == target) return;
    }
    final oldIndex = index.value;
    final newIndex = target;

    /// 暂停之前的视频
    if (oldIndex != newIndex) {
      playerOfIndex(oldIndex)?.pause(reset: true);
    }

    /// 开始播放当前的视频
    playerOfIndex(newIndex)?.playerController?.addListener(_didUpdateValue);
    playerOfIndex(newIndex)?.play(newIndex);

    final List<int> loadField = [newIndex - cacheCount, newIndex + cacheCount];

    for (var i = 0; i < playerList.length; i++) {
      if ((i < loadField[0] || i > loadField[1]) &&
          playerOfIndex(i)?.prepared == true) {
        playerOfIndex(i)?.dispose();
      } else if ((i >= loadField[0] && i <= loadField[1]) &&
          i != newIndex &&
          playerOfIndex(i)?.prepared == false) {
        playerOfIndex(i)?.init();
      }
    }

    /// 快到最底部，添加更多视频
    if (playerList.length - newIndex <= loadMoreCount + 1) {
      _videoProvider?.call(newIndex, playerList)?.then(
        (list) {
          playerList.addAll(list);
          if (Get.isRegistered<CircleVideoPageController>())
            CircleVideoPageController.to().update();
        },
      );
    }

    /// 完成
    index.value = target;
  }

  void _didUpdateValue() {
    if (!isDispose) notifyListeners();
  }

  /// 获取指定index的player
  VideoProxyController playerOfIndex(int index) {
    if (index < 0 || index > playerList.length - 1) {
      return null;
    }
    return playerList[index];
  }

  /// 视频总数目
  int get videoCount => playerList.length;

  /// 初始化
  void init({
    List<VideoProxyController> initialList,
    int initPlayer,
    LoadMoreVideo videoProvider,
  }) {
    playerList.addAll(initialList);
    _videoProvider = videoProvider;
    index.value = initPlayer;
    loadIndex(initPlayer, reload: true);
    _didUpdateValue();
  }

  /// 目前的视频序号
  ValueNotifier<int> index = ValueNotifier<int>(0);

  /// 视频列表
  List<VideoProxyController> playerList = [];

  ///
  VideoProxyController get currentPlayer =>
      index.value < playerList.length ? playerList[index.value] : null;

  /// 销毁所有控制器
  @override
  Future<void> dispose() async {
    isDispose = true;
    await currentPlayer?.pause();
    for (final player in playerList) {
      await player.dispose();
    }
    playerList.clear();
    super.dispose();
  }
}

typedef ControllerSetter<T> = Future<void> Function(T controller);
typedef ControllerBuilder<T> = T Function();

class VideoProxyController {
  VideoPlayerController _playController;

  final PostVideo postVideo;

  final ControllerBuilder<VideoPlayerController> _builder;

  VideoProxyController(
    ControllerBuilder<VideoPlayerController> builder, {
    this.postVideo,
  }) : _builder = builder;

  VideoPlayerController get playerController {
    return _playController ??= _builder.call();
  }

  bool get prepared => _prepared;
  bool _prepared = false;

  bool get banned => _banned;
  bool _banned = false;

  Future<void> dispose() async {
    try {
      await _playController?.dispose();
    } catch (e) {
      logger.printError(info: e);
    }
    _prepared = false;
    _playController = null;
  }

  Future<void> init() async {
    if (_prepared) return;
    try {
      await _playController?.initialize();
    } on PlatformException catch (e) {
      _banned = e.code == "403";
    } catch (e) {
      logger.printError(info: e.toString());
    }
    await _playController?.setLooping(true);
    _prepared = true;
  }

  Future<void> pause({bool reset = false}) async {
    if (!_prepared) return;
    await _playController?.pause();
    if (reset) await _playController?.seekTo(Duration.zero);
  }

  Future<void> play(int index) async {
    await init();
    if (!_prepared) return;
    if (!Get.isRegistered<CircleVideoPageController>()) {
      unawaited(dispose());
      return;
    }
    if (CircleVideoPageController.to().pageController.page.round() == index) {
      unawaited(_playController?.play());
    }
  }
}
