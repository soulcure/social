import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/app/modules/circle/controllers/circle_cached_controller.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:pedantic/pedantic.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'circle_controller.dart';

/// 圈子中，各个圈子频道列表的管理器
class CircleTopicController extends GetxController {
  final String topicId;

  CircleTopicController({this.topicId});

  /// 列表数据
  final RefreshController refreshController = RefreshController();

  final pageSize = '20';
  String listId = '0'; // 为loadMore准备的参数
  String hasNext = '0'; // 是否还需要loadMore
  List<CirclePostDataModel> list = [];

  /// 加载帖子完成
  bool loadFinish = false;

  /// 加载失败
  bool loadFailed = false;

  ///加载帖子列表时刻,在加载更多的时候确保不会有比这个时刻新的帖子
  String loadTime;

  ///帖子ID列表，用于加载更多时判断是否已经加载过帖子做去重操作
  Set<String> postIdSet = {};

  CircleController get circleController => CircleController.to;

  static CircleTopicController to({String topicId}) {
    assert(topicId != null);
    if (topicId == null) {
      return null;
    }
    CircleTopicController c;
    try {
      /// Get.find找不到，会主动报错
      c = Get.find<CircleTopicController>(tag: topicId);
    } catch (_) {}
    return c ??= Get.put(CircleTopicController(topicId: topicId), tag: topicId);
  }

  /// 加载首页数据
  Future<void> loadData({bool reload = false, bool scrollToTop = false}) async {
    if (loadFailed) {
      loadFailed = false;
      update();
    }
    final guildId = circleController.guildId;
    try {
      final res = await getPostList(
              guildId, circleController.channelId, topicId, pageSize, '0')
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Load timed out'),
      );
      //写入帖子缓存
      unawaited(CircleCachedController.putCirclePost(guildId, topicId, res));
      loadPost(res);
      refreshController.refreshCompleted();
      loadFinish = true;
      update();
    } catch (e) {
      if (reload)
        refreshController.refreshFailed();
      else {
        loadFailed = true;
        update();
      }
    }

    if (scrollToTop && refreshController.position.pixels != 0) {
      unawaited(Future.delayed(const Duration(milliseconds: 300)).then((value) {
        refreshController.position.animateTo(0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.bounceIn);
      }));
    }
  }

  void loadCached() {
    final cachedPost =
        CircleCachedController.getCirclePost(circleController.guildId, topicId);
    if (cachedPost != null) {
      loadPost(cachedPost);
      loadFinish = true;
      update();
    }
  }

  ///加载帖子Model
  void loadPost(Map res) {
    loadTime = res['now'].toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    hasNext = res['next'].toString() ?? '0';
    listId = res['list_id'].toString() ?? '0';
    final List mapList = res['records'] ?? [];
    postIdSet.clear();
    list = mapList.map((e) {
      final model = CirclePostDataModel.fromJson(e);
      postIdSet.add(model.postId);
      return model;
    }).toList();
  }

  /// 加载更多数据
  Future<void> loadMoreData() async {
    if ("1" != hasNext) {
      // 没有更多了
      refreshController.footerMode.value = LoadStatus.noMore;
      refreshController.loadComplete();
      return;
    }

    try {
      final res = await getPostList(circleController.guildId,
          circleController.channelId, topicId, pageSize, listId,
          createAt: loadTime);
      hasNext = res['next'].toString() ?? '0';
      listId = res['list_id'].toString() ?? '0';
      final List mapList = res['records'] ?? [];
      mapList.forEach((e) {
        final model = CirclePostDataModel.fromJson(e);
        if (!postIdSet.contains(model.postId)) {
          postIdSet.add(model.postId);
          list.add(model);
        }
      });
      refreshController.loadComplete();
    } catch (e) {
      refreshController.loadFailed();
    }
    update();
  }

  ///获取帖子列表，因为新增的关注话题需要另外的接口获取，所以在这判断区分使用
  Future<dynamic> getPostList(String guildId, String channelId, String topicId,
      String size, String listId,
      {String createAt}) async {
    if (topicId == '1') {
      final res = await CircleApi.circleFollowPostList(
          guildId, channelId, topicId, size, listId);
      return res;
    } else {
      final res = await CircleApi.circlePostList(
          guildId, channelId, topicId, size, listId);
      return res;
    }
  }

  void removeItem(String postId) {
    list.removeWhere((element) => element.postId == postId);
    update();
  }

  void updateItem(String postId, CirclePostDataModel item) {
    final index = list.indexWhere((e) => e.postId == postId);
    if (index >= 0) {
      list[index] = item;
      update();
    }
  }

  void insertItem(int index, CirclePostDataModel item) {
    if (index < list.length) {
      list.insert(index, item);
      update();
    }
  }
}
