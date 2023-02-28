import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/api/util_api.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle/controllers/circle_topic_controller.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/utils.dart';
import 'package:im/services/connectivity_service.dart';
import 'package:im/utils/cos_file_cache_index.dart';
import 'package:im/utils/utils.dart';
import 'package:just_throttle_it/just_throttle_it.dart';
import 'package:oktoast/oktoast.dart';

import 'circle_video_controller.dart';

class CircleVideoPageController extends GetxController {
  CircleVideoPageController(this._param);

  static CircleVideoPageController to() =>
      Get.find<CircleVideoPageController>();
  final CircleVideoPageControllerParam _param;
  final CircleVideoController _circleVideoController = CircleVideoController();
  final List<CirclePostDataModel> _videoPostModels = [];
  final int _loadSize = 20;
  StreamSubscription<ConnectivityResult> _networkSubscription;
  PageController _pageController;
  String _videoListId = '0';
  int _initVideo = 0;
  bool _initComplete = false;
  bool _more = true;
  bool _buffering = true;
  Duration _position = const Duration();

  bool get buffering => _buffering;

  int get initVideo => _initVideo + _param.offset;

  List<CirclePostDataModel> get videoPostModels => _videoPostModels;

  bool get initComplete => _initComplete;

  PageController get pageController => _pageController;

  CircleVideoController get circleVideoController => _circleVideoController;

  ///浏览的圈子频道分类ID
  String get topicId => _param.topicId ?? '_all';

  ///加载更多时的排序方式
  String get sortType =>
      CircleController.to.sortModel?.getTopicSortApiKeyName(topicId);

  ///加载帖子列表时的时间戳
  String get loadTime => CircleTopicController.to(topicId: topicId).loadTime;

  ///如果没有传入多个帖子的Model则不开启帖子穿梭
  bool get lite => _param.circlePostDateModels?.isEmpty ?? true;

  @override
  void onInit() {
    _initVideoController();
    _networkCheck();
    super.onInit();
  }

  @override
  Future<void> onClose() async {
    _pageController?.dispose();
    await _circleVideoController?.dispose();
    await _networkSubscription?.cancel();
    super.onClose();
  }

  void _networkCheck() {
    Future.delayed(const Duration(seconds: 2), () async {
      if (ConnectivityService.to.disabled &&
          !isClosed &&
          !(await UtilApi.postNetWorkIsAvailabel())) {
        showToast("请检查网络后重试");
      }
    });
    _networkSubscription =
        ConnectivityService.to.onConnectivityChanged.listen((event) {
      if (event == ConnectivityResult.none)
        showToast("请检查网络后重试");
      else {
        _initVideoController();
      }
    });
  }

  void _initVideoController() {
    if (_initComplete) return;
    _circleVideoController.init(
      initialList: _loadVideos(),
      initPlayer: initVideo,
      videoProvider: (index, list) => _loadMore(),
    );
    _pageController = PageController(initialPage: initVideo);
    _pageController.addListener(() {
      final p = pageController.page;
      if (p % 1 == 0) {
        _circleVideoController.loadIndex(p ~/ 1);
        setAwake(true);
      }
    });
    _initComplete = true;
    update();
    _circleVideoController.addListener(() {
      ///使用节流每秒检查视频是否播放来产生准确的缓冲态
      Throttle.duration(const Duration(seconds: 1), _checkBuffer);
      update(['components', 'player']);
    });
  }

  ///作用是如果视频的[position]没有变动和VideoPlayer回报[isBuffering]，才设置为真正的缓冲状态
  ///因为IOS原生下的AVPlayer的[isPlaybackLikelyToKeepUp]会推测当前缓冲速度可以流畅播完视频
  ///的情况下才会返回true并告知VideoPlayer结束缓冲状态，所以在缓冲速度不够但又重新开始了播放时
  ///有可能会给VideoPlayer插件同时上报[isPlaying]和[isBuffering]都为true的情况，这时候会导致
  ///界面上的视频在播放但同时又在缓冲的魔幻组合，所以当视频的[position]在走动时，忽略缓冲态。
  void _checkBuffer() {
    final value = _circleVideoController.currentPlayer.playerController.value;
    _buffering = (value.position == _position) && value.isBuffering;
    _position = value.position;
  }

  ///获取含有视频的帖子
  List<CirclePostDataModel> _getVideoPost() {
    final List<CirclePostDataModel> models = [];
    for (final item in _param.circlePostDateModels) {
      if (item.postInfo['has_video'] == 1) models.add(item);
    }
    _videoListId = models.length.toString();
    return models;
  }

  ///加载圈子视频
  List<VideoProxyController> _loadVideos() {
    if (lite) {
      return _genController(_liteDecodePost());
    } else {
      final res = _getVideoPost();
      final postVideos = _fullDecodePost(res);
      return _genController(postVideos);
    }
  }

  ///加载更多
  Future<List<VideoProxyController>> _loadMore() async {
    if (!_more || lite) return [];
    if (ConnectivityService.to.state == ConnectivityResult.none) return [];
    final res = await _getMoreVideoPost();
    final videos = _fullDecodePost(res);
    return _genController(videos);
  }

  ///生成控制器
  List<VideoProxyController> _genController(List<PostVideo> postVideos) {
    final List<VideoProxyController> controllers = [];
    for (final item in postVideos) {
      controllers.add(
        VideoProxyController(
          () => CosUploadFileIndexCache.videoControllerDispatch(item.videoUrl),
          postVideo: item,
        ),
      );
    }
    return controllers;
  }

  ///获取视频帖子
  Future<List<CirclePostDataModel>> _getMoreVideoPost() async {
    final List<CirclePostDataModel> videoPostDataModels = [];
    final m = _param.model.postInfoDataModel;
    final res = await CircleApi.circlePostList(m.guildId, m.channelId, topicId,
        _loadSize.toString(), _videoListId.toString(),
        hasVideo: '1', sortType: sortType ?? '', createAt: loadTime);
    if (res['next'] == '0')
      _more = false;
    else
      _more = true;
    _videoListId = res['list_id'];
    for (final item in res['records']) {
      videoPostDataModels.add(CirclePostDataModel.fromJson(item));
    }
    return videoPostDataModels;
  }

  ///判断帖子类型获取内容Item
  List _getContent(CirclePostInfoDataModel model) {
    return jsonDecode(
        model.contentV2.hasValue ? model.contentV2 : model.content);
  }

  ///单帖子解析
  List<PostVideo> _liteDecodePost() {
    final List<PostVideo> videos = [];
    final content = _getContent(_param.model.postInfoDataModel);
    final contentItem = Document.fromJson(content).toDelta().toList();

    ///遍历帖子视频元素
    for (int i = 0; i < contentItem.length; i++) {
      final item = contentItem[i];
      if (item.isVideo) {
        final videoUrl = RichEditorUtils.getEmbedAttribute(item, 'source');
        final thumbUrl = RichEditorUtils.getEmbedAttribute(item, 'thumbUrl');
        videos.add(PostVideo(videoUrl: videoUrl, thumbUrl: thumbUrl));
        _videoPostModels.add(_param.model);
      }
    }
    return videos;
  }

  ///多帖子穿梭解析
  List<PostVideo> _fullDecodePost(
    List<CirclePostDataModel> circlePostDataModels,
  ) {
    final List<PostVideo> videos = [];
    int initIndex = 0;
    for (final item in circlePostDataModels) {
      if (item.postInfoDataModel.postId == _param.model.postId)
        _initVideo = initIndex;
      final content = _getContent(item.postInfoDataModel);
      final contentItems = Document.fromJson(content).toDelta().toList();

      ///遍历帖子视频元素
      for (int i = 0; i < contentItems.length; i++) {
        final contentItem = contentItems[i];
        if (contentItem.isVideo) {
          final videoUrl =
              RichEditorUtils.getEmbedAttribute(contentItem, 'source');
          final thumbUrl =
              RichEditorUtils.getEmbedAttribute(contentItem, 'thumbUrl');
          videos.add(PostVideo(videoUrl: videoUrl, thumbUrl: thumbUrl));
          _videoPostModels.add(item);
          initIndex++;
        }
      }
    }
    return videos;
  }
}

class CircleVideoPageControllerParam {
  ///用户进入的帖子Model
  final CirclePostDataModel model;

  ///用户点击时帖子处于的圈子频道ID
  final String topicId;

  ///如果传入了批量的帖子列表则会开启帖子穿梭浏览
  final List<CirclePostDataModel> circlePostDateModels;

  ///在文章帖子详情页里存在用户点击帖子内的第N个视频则需要索引作为偏移
  final int offset;

  CircleVideoPageControllerParam({
    @required this.model,
    this.circlePostDateModels,
    this.topicId,
    this.offset = 0,
  });
}

class PostVideo {
  final String videoUrl;
  final String thumbUrl;

  PostVideo({
    this.videoUrl,
    this.thumbUrl,
  });
}
