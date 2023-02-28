import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/app/modules/circle/controllers/circle_cached_controller.dart';
import 'package:im/app/modules/circle/controllers/circle_topic_controller.dart';
import 'package:im/app/modules/circle/models/guild_topic_sort_model.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/app/modules/mute/controllers/mute_listener_controller.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/db/db.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/global.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/circle/content/circle_post_image_item.dart';
import 'package:im/pages/guild_setting/circle/circle_share/circle_share_item.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/factory/abstract_rich_text_factory.dart';
import 'package:im/routes.dart';
import 'package:im/utils/cos_file_upload.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/storage_util.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/widgets/tab_bar/web_tab_bar.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:websafe_svg/websafe_svg.dart';

class CircleControllerParam {
  String guildId;
  String channelId;
  String topicId;
  bool autoPushCircleMessage;

  CircleControllerParam(
    this.guildId,
    this.channelId, {
    this.topicId,
    this.autoPushCircleMessage = false,
  });
}

class CircleController extends GetxController with GetTickerProviderStateMixin {
  static CircleController get to => GetInstance().find();

  ///圈子缩略图尺寸: 屏幕的3/4
  static int get circleThumbWidth =>
      (Get.width * 0.75 * Get.pixelRatio).toInt();

  String guildId;
  String channelId;
  String topicId;
  bool autoPushCircleMessage;

  CircleController(
    this.guildId,
    this.channelId, {
    this.topicId,
    this.autoPushCircleMessage = false,
  });

  bool _canRefresh = true;
  int nuReadNewsCount = 0;

  ///初始化完成
  bool initFinish = false;

  ///初始化失败
  bool initFailed = false;
  bool showFloatButton = true;
  ScrollDirection currentScrollDirection;

  /// 圈子信息
  CircleInfoDataModel circleInfoDataModel;
  List<CircleTopicDataModel> circleTopicList = [];
  List<CircleTopicDataModel> allCircleTopicList = [];
  List<CirclePostDataModel> circlePostList = [];
  List<CirclePinedPostDataModel> pinedList = [];
  GuildTopicSortModel sortModel;

  /// tabBar
  final String currentTopicId = null;
  TabController tabController;
  final WebTabBarModel tabBarModel = WebTabBarModel();

  DateTime entryTime;

  ///"最新"话题ID
  String get allTopicId =>
      circleTopicList
          .firstWhere((element) => element.type == CircleTopicType.all,
              orElse: () => null)
          ?.topicId ??
      '';

  ///"关注"话题ID
  String get subscriptionId => '1';

  @override
  Future<void> onInit() async {
    final cachedInfo = CircleCachedController.getCircleInfo(guildId);
    if (cachedInfo != null) {
      initCircleInfo(cachedInfo);
      updateTabController(currentTopicId: topicId);
      initFinish = true;
      refreshWidget();
    }
    await initFromNet();

    super.onInit();
  }

  @override
  void onClose() {
    tabController?.dispose();
    circleTopicEvent(currentTopicId, 2);
    super.onClose();
  }

  void updateTabIndex(String currentTopicId) {
    final index =
        circleTopicList.indexWhere((e) => e.topicId == currentTopicId);
    if (index < 0) return;
    tabController.index = index;
  }

  /// 如果有初始化圈子频道id， 需要改动tab位置
  void updateTabController({String currentTopicId}) {
    final originIndex = tabController?.index ?? -1;
    String originTopicId = currentTopicId;

    if (originTopicId.noValue) {
      originTopicId = circleTopicList.length > originIndex && originIndex >= 0
          ? circleTopicList[originIndex].topicId
          : '';
    }

    final initialIndex =
        circleTopicList.indexWhere((e) => e.topicId == originTopicId);

    if (OrientationUtil.portrait) {
      tabController?.removeListener(tabBarIndexChange);
      tabController = TabController(
          //TODO "min(circleTopicList.length - 1, 1)" 为兼容50服务端，60服务端发布后可以去掉判断
          initialIndex: max(min(circleTopicList.length - 1, 1), initialIndex),
          length: circleTopicList.length,
          vsync: this);
      tabController.addListener(tabBarIndexChange);
      tabBarIndexChange();
    } else {
      tabController?.removeListener(tabBarIndexChange);
      tabController = TabController(
          initialIndex: max(0, initialIndex),
          length: circleTopicList.length,
          vsync: this);
      tabBarModel.updateTabController(tabController);
      tabController.addListener(tabBarIndexChange);
      tabBarModel
          .updateTabTitles(circleTopicList.map((e) => e.topicName).toList());
      tabBarIndexChange();
    }

    refreshWidget();
  }

  ///进入和退出Topic埋点
  void circleTopicEvent(String topicId, int visitActionType) {
    int visitDuration = 0;
    if (visitActionType == 2 && entryTime != null) {
      final int sec = DateTime.now().difference(entryTime).inSeconds;
      visitDuration = sec ?? 0;
    }

    DLogManager.getInstance()
        .extensionEvent(logType: 'dlog_app_page_view_fb', extJson: {
      'visit_action_type': visitActionType,
      'page_catefory': 'page_circle',
      'page_id': 'page_circle_list',
      'page_param': topicId ?? '',
      'visit_duration': visitDuration,
      'guild_id': guildId ?? '',
    });
  }

  // 是为了控制只有当前主题列表可以滚动
  void tabBarIndexChange() {
    if (tabController.index >= circleTopicList.length) return;
    final oldTopicId = currentTopicId;
    final newTopicId = circleTopicList[tabController.index].topicId;

    if (OrientationUtil.landscape &&
        tabBarModel.selectIndex != tabController.index) {
      tabBarModel.selectIndex = tabController.index;
    }

    if (oldTopicId != newTopicId) {
      if (oldTopicId != null) {
        /// 退出topicId
        circleTopicEvent(oldTopicId, 2);
      }
      updateFloatState();

      entryTime = DateTime.now();

      /// 进入topicId
      circleTopicEvent(newTopicId, 1);
    }
  }

  ///新建帖子的按钮是否显示
  void updateFloatState() {
    final show = circleTopicList[tabController.index].topicId != subscriptionId;

    ///新旧值不相同才更新
    if (showFloatButton != show) {
      showFloatButton = show;
      update(['floatButton']);
    }
  }

  ///列表滚动时切换发布按钮展示
  void switchFloatButton(ScrollDirection direction) {
    //状态相同直接return
    if (currentScrollDirection == direction) return;
    //关注页滚动不需要展示发布按钮
    if (circleTopicList[tabController.index].topicId == subscriptionId) return;
    if (direction == ScrollDirection.reverse) {
      //向上滑动
      currentScrollDirection = ScrollDirection.reverse;
      showFloatButton = false;
      update(['floatButton']);
    } else if (direction == ScrollDirection.forward) {
      //向下滑动
      currentScrollDirection = ScrollDirection.forward;
      showFloatButton = true;
      update(['floatButton']);
    } else if (direction == ScrollDirection.idle) {
      //空闲状态
      currentScrollDirection = ScrollDirection.idle;
      //产品要求在操作空闲一秒后再弹出发布按钮
      Future.delayed(const Duration(seconds: 1), () {
        //弹出时需要判断是否在空闲状态和不在关注页面
        if (currentScrollDirection == ScrollDirection.idle &&
            circleTopicList[tabController.index].topicId != subscriptionId) {
          showFloatButton = true;
          update(['floatButton']);
        }
      });
    }
  }

  Future<void> initFromNet() async {
    if (guildId == null || guildId.isEmpty) return;

    ///断网状态重新init时回到加载态
    if (initFailed) {
      initFailed = false;
      refreshWidget();
    }
    try {
      if (channelId == null || channelId.isEmpty) {
        final result = await CircleApi.circlePostInfo(guildId).timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Load timed out'),
        );
        final circleList = result['list'];
        for (var i = 0; i < circleList?.length ?? 0; i++) {
          channelId = circleList[i]['channel_id'].toString() ?? '';
          break;
        }
      }
      if (channelId == null || channelId.isEmpty) return;
      final circleInfo = await CircleApi.circleInfo(guildId, channelId).timeout(
        const Duration(seconds: 5),
        onTimeout: () => TimeoutException('Load timed out'),
      );

      ///缓存写入
      unawaited(CircleCachedController.putCircleInfo(guildId, circleInfo));

      initCircleInfo(circleInfo);

      updateTabController(currentTopicId: topicId);

      initFinish = true;

      refreshWidget();
    } catch (_) {
      initFailed = true;
      refreshWidget();
    }
  }

  ///初始化圈子信息
  void initCircleInfo(Map circleInfo) {
    final List topicList = circleInfo['topic'] ?? [];
    final List topicAddPostList = circleInfo['topic_add_post'] ?? [];
    final List circleRecords = circleInfo['records'] ?? [];
    final circleDesc = circleInfo['channel'] ?? {};
    final pinnedInfo = circleInfo['top'] ?? {};
    final List pinnedRecords = pinnedInfo['records'] ?? [];

    pinedList =
        pinnedRecords.map((e) => CirclePinedPostDataModel.fromJson(e)).toList();

    circleInfoDataModel = CircleInfoDataModel.fromJson(circleDesc);

    circleTopicList =
        topicList.map((e) => CircleTopicDataModel.fromJson(e)).toList();

    for (final topic in circleTopicList) {
      PermissionModel.initChannelPermission(
          topic.guildId, topic.topicId, topic.overwrite);
    }

    allCircleTopicList =
        topicAddPostList.map((e) => CircleTopicDataModel.fromJson(e)).toList();

    circlePostList =
        circleRecords.map((e) => CirclePostDataModel.fromJson(e)).toList();

    ///channelId要及时赋值，从圈子外露频道进来时查询列表时，需要这个id当参数
    channelId = circleInfoDataModel?.channelId;
  }

  /// 更新内存数据，这里会考虑到如果不是全部的tab栏，也能同步做更新
  void updateItem(String topicId, CirclePostDataModel model) {
    CircleTopicController.to(topicId: topicId).updateItem(model.postId, model);
    if (circleTopicList.isNotEmpty && topicId != allTopicId) {
      CircleTopicController.to(topicId: allTopicId)
          .updateItem(model.postId, model);
    }
  }

  /// 删除内存数据，这里会考虑到如果不是全部的tab栏，也能同步做更新
  void removeItem(String topicId, String postId) {
    CircleTopicController.to(topicId: topicId).removeItem(postId);
    if (circleTopicList.isNotEmpty && topicId != allTopicId) {
      CircleTopicController.to(topicId: allTopicId).removeItem(postId);
    }
  }

  ///更新关注列表数据
  void updateSubscriptionItem(CirclePostDataModel model) {
    CircleTopicController.to(topicId: subscriptionId)
        .updateItem(model.postId, model);
  }

  ///删除关注列表数据
  void removeSubscriptionItem(String postId) {
    CircleTopicController.to(topicId: subscriptionId).removeItem(postId);
  }

  ///加载关注列表数据
  void loadSubscriptionList() {
    CircleTopicController.to(topicId: subscriptionId).loadData();
  }

  /// 更新所有需要更新的主题列表
  void updateTopicList() {
    final topicSort = Db.guildTopicSortCategoryBox?.get(guildId);
    for (final topic in circleTopicList) {
      try {
        // 如果本地的主题列表已经有默认的排序方式了，就不需要去做主动更新
        if (topicSort?.containsKey(topic.topicId) ?? false) continue;
        final controller = Get.find<CircleTopicController>(tag: topic.topicId);
        controller.loadData(reload: true);
        // ignore: empty_catches
      } catch (e) {}
    }
  }

  Future refreshPinnedList({List<CirclePinedPostDataModel> list}) async {
    if (list != null) {
      pinedList = list;
    } else {
      final res = await CircleApi.circleDynamicPinList(guildId, channelId);
      final List records = res['records'] ?? [];
      pinedList =
          records.map((e) => CirclePinedPostDataModel.fromJson(e)).toList();
    }
    refreshWidget();
  }

  void updateCircleInfoDataModel(Map data) {
    // 如果更新的服务器信息不包含sort_type，就不该去请求更新列表
    final needRefreshList = data.containsKey('sort_type') &&
        data['sort_type'] != circleInfoDataModel.sortType;
    circleInfoDataModel.updateCircleInfoDataModel(data);
    if (needRefreshList) updateTopicList();
    refreshWidget();
  }

  Future updateCircleTopics() async {
    sortModel ??= GuildTopicSortModel(guildId: guildId);
    final String sortType = sortModel.getTopicSortApiKeyName("_all");

    final circleInfo =
        await CircleApi.circleInfo(guildId, channelId, sortType: sortType);
    final List topic = circleInfo['topic'] ?? [];
    final List topicAddPost = circleInfo['topic_add_post'] ?? [];
    final List defaultRecords = circleInfo['records'] ?? [];

    circleTopicList =
        topic.map((e) => CircleTopicDataModel.fromJson(e)).toList();

    allCircleTopicList =
        topicAddPost.map((e) => CircleTopicDataModel.fromJson(e)).toList();

    circlePostList =
        defaultRecords.map((e) => CirclePostDataModel.fromJson(e)).toList();
    updateTabController();

    refreshWidget();
  }

  void refreshWidget() {
    if (_canRefresh) update();
  }

  @override
  void dispose() {
    _canRefresh = false;
    super.dispose();
  }

  int topicAtIndex(String topicId) {
    return circleTopicList.indexWhere((element) => element.topicId == topicId);
  }

  /// 判断有没有当前选中圈子频道的发布权限
  bool hasCurrentTopicPermission(String topicId) {
    if (PermissionUtils.isGuildOwner()) {
      return true;
    }
    final GuildPermission gp = PermissionModel.getPermission(guildId);
    if (gp == null) {
      return true;
    }
    return PermissionUtils.oneOf(gp, [Permission.CIRCLE_POST],
        channelId: topicId);
  }

  /// 点击发布动态入口埋点
  void createMomentEvent() {
    DLogManager.getInstance().customEvent(
      actionEventId: 'post_issue_click',
      actionEventSubId: 'click_post_issue_entrance',
      extJson: {"guild_id": guildId},
    );
  }

  /// 点击发布动态入口分类埋点
  void createCircleActionEvent({String type = 'photo'}) {
    DLogManager.getInstance().customEvent(
        actionEventId: 'post_issue_click',
        actionEventSubId: 'click_post_issue_entrance_type',
        actionEventSubParam: type,
        extJson: {"guild_id": guildId});
  }

  /// 创建圈子动态
  Future<void> createMoment() async {
    createMomentEvent();

    // 正在发送中
    if (UploadStatusController.to.isSending(channelId)) return;

    if (MuteListenerController.to.isMuted) {
      // 是否被禁言
      showToast('你已被禁言，无法操作'.tr);
      return;
    }
    final hasPermission = allCircleTopicList.any(
      (element) =>
          element.topicId != '1' &&
          PermissionUtils.hasPermission(
              guildId: guildId,
              channelId: element.topicId,
              permission: Permission.CIRCLE_POST),
    );
    if (!hasPermission) {
      showToast('你没有发布动态的权限'.tr);
      return;
    }

    if (guildId.isEmpty || channelId.isEmpty) {
      showToast('参数获取错误，请刷新重试。'.tr);
      return;
    }

    await createCircleAction();
    createCircleActionEvent();
  }

  /// 发送动态
  static Future<void> sendDynamic(
      {int timeMillis,
      bool needSaveToAlbum = false,
      String channelId,
      String guildId}) async {
    final time = timeMillis ?? DateTime.now().millisecondsSinceEpoch;
    UploadStatusController.to.updateProgress(channelId);

    final model = Db.circleDraftBox.get(channelId);

    if (model == null) return;
    try {
      // 获取资源
      final assets = CirclePostInfoDataModel.getMediaList(
              model.contentV2, model.content, model.postType)
          .map((e) => CirclePostImageItem.fromJson(e))
          .toList();

      if (assets.isNotEmpty) {
        final isVideo = assets.first?.type == 'video';
        final totalUploadFile = isVideo ? 3 : assets.length;
        final itemP = 90 / totalUploadFile;
        // 获取提及的人

        CosFileUploadQueue.instance.registCallback(
            onSendProgress: (fileId, progress) {
          final index = int.parse(fileId);
          final currentProgress = index * itemP + itemP * progress;
          UploadStatusController.to
              .updateProgress(channelId, progress: currentProgress.toInt());
        }, onError: (fileId, error) {
          UploadStatusController.to.uploadFail(channelId);
        });

        if (isVideo) {
          final videoItem = assets.first;
          if (videoItem != null &&
              !videoItem.url.startsWith('http://') &&
              !videoItem.url.startsWith('https://')) {
            videoItem.thumbUrl =
                await videoItem.uploadImage(videoItem.thumbName);
            final name = await MediaPicker.generateVideo(
                requestId: videoItem.requestId,
                progressCallback: (_, progress) {
                  final currentProgress = itemP * (1 + progress);
                  UploadStatusController.to.updateProgress(channelId,
                      progress: currentProgress.toInt());
                });
            unawaited(MediaPicker.destroyNvsContext());
            videoItem.url =
                await videoItem.uploadVideo(name: name, queueIndex: 2);
          }
        } else {
          for (int i = 0; i < assets.length; i++) {
            await assets[i].upload(queueIndex: i);
            UploadStatusController.to.updateProgress(channelId,
                progress: (90 * (i / assets.length)).toInt());
          }
        }
      }

      final contentAtList =
          CirclePostInfoDataModel.getAtList(model.contentV2, model.content);

      UploadStatusController.to.updateProgress(channelId, progress: 90);

      // 处理内容
      final content = CirclePostInfoDataModel.getSendContent(
          model.contentV2, model.content, assets);

      final String hashStr = '${model.title}$content$time';
      final String hashV = generateMd5(hashStr);
      final res = await CircleApi.createCircle(
        guildId,
        channelId,
        model.topicId,
        model.postId,
        title: model.title,
        contentV2: content,
        postType: model.postType,
        mentions: contentAtList,
        hash: hashV,
        fileId: model.docItem?.fileId ?? '',
      );

      final ret = CirclePostInfoDataModel.fromJson(res);

      // 更新列表
      if (Get.isRegistered<CircleController>())
        CircleController.to.updateByNewDynamic(ret);
      showToast('发布成功'.tr);

      UploadStatusController.to.updateProgress(channelId, progress: 100);

      // 删除SDK草稿
      for (final asset in assets) {
        if (asset.requestId.hasValue)
          unawaited(MediaPicker.isDraftExist(requestId: asset.requestId)
              .then((exist) {
            if (exist) MediaPicker.deleteDraft(requestId: asset.requestId);
          }));
      }
      unawaited(Db.circleDraftBox.delete(channelId));

      // 更新分享出去的动态
      if (model.postId.hasValue && postInfoMap[ret.postId] != null) {
        postInfoMap[ret.postId].titleListener.value = ret.title;
        postInfoMap[ret.postId].contentListener.value = ret.contentV2;
      }

      // 保存相册
      if (needSaveToAlbum) {
        for (final asset in assets) {
          if (asset.type == 'video') {
            if (model.postId.noValue)
              unawaited(MediaPicker.generateVideo(requestId: asset.requestId)
                  .then((value) {
                unawaited(saveImageToLocal(
                    localFilePath: value,
                    url: asset.url,
                    isImage: false,
                    isShowToast: false));
              }));
            else
              unawaited(saveImageToLocal(
                  url: asset.url, isImage: false, isShowToast: false));
          } else {
            unawaited(saveImageToLocal(
                localFilePath: '${Global.deviceInfo.mediaDir}${asset.name}',
                url: asset.url,
                isShowToast: false));
          }
        }
      }
    } catch (e) {
      UploadStatusController.to.uploadFail(channelId);
      logger.severe('circle_controller.sendDynamic', '发布动态异常: $e');
    } finally {
      CosFileUploadQueue.instance.disposeCallback();
    }
  }

  /// 根据刚创建的动态来更新列表
  void updateByNewDynamic(CirclePostInfoDataModel model) {
    final index = circleTopicList.indexWhere((e) => e.topicId == model.topicId);
    if (index >= 0) {
      if (OrientationUtil.portrait)
        tabController.index = index;
      else
        tabBarModel.select(index);
      try {
        final currentTopicId = circleTopicList[tabController.index].topicId;
        CircleTopicController.to(topicId: currentTopicId).loadData();

        // 如果创建的动态不是全部选项，全部选项也需要刷新
        if (allTopicId != model.topicId) {
          CircleTopicController.to(topicId: allTopicId).loadData();
        }
        //自己发的帖子默认订阅所以需要刷新关注列表
        loadSubscriptionList();
        // ignore: empty_catches
      } catch (e) {}
    }
  }

  Widget bottomOption(
    String asset,
    String title,
    GestureTapCallback onTapAction,
  ) {
    return FadeButton(
      onTap: onTapAction,
      child: SizedBox(
        child: Column(
          children: [
            WebsafeSvg.asset(asset, width: 56, height: 56),
            const SizedBox(height: 13),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xff363940),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> createCircleAction({bool isCache = false}) async {
    /// 发送过程中不能点击创建
    if (UploadStatusController.to.isSending(channelId)) return;

    List<CirclePostImageItem> _assetList = [];
    if (!isCache) {
      /// 检测相册权限
      final hasPermission = await checkPhotoAlbumPermissions();

      /// 未授权
      if (hasPermission != true) return;
    }

    unawaited(MediaChannelApi.init(
        logEvent: (actionId, actionSubId, actionEventSubParam, extJson) {
      DLogManager.getInstance().customEvent(
          actionEventId: actionId,
          actionEventSubId: actionSubId,
          actionEventSubParam: actionEventSubParam,
          extJson: {"guild_id": guildId});
    }));
    await MediaPicker.setupNvs();

    if (Db.circleDraftBox.get(channelId) == null) {
      _assetList = await AbstractRichTextFactory.instance.pickImages(9, []);
      if (_assetList == null || _assetList.isEmpty) return;
    } else {
      // 如果有缓存，需要清除进度
      UploadStatusController.to.delete(channelId);
    }

    CircleTopicDataModel defaultTopic = circleTopicList[tabController.index];
    if (defaultTopic.type == CircleTopicType.subscribe ||
        defaultTopic.type == CircleTopicType.all) {
      // 在关注或最新tab
      final firstCustomTopic = circleTopicList.firstWhere(
          (e) =>
              e.type == CircleTopicType.common &&
              hasCurrentTopicPermission(e.topicId),
          orElse: () => null);
      if (firstCustomTopic != null &&
          hasCurrentTopicPermission(firstCustomTopic.topicId)) {
        // 有自定义数据, 默认不选择
        defaultTopic = null;
      } else if (defaultTopic.type == CircleTopicType.subscribe &&
          circleTopicList.length > 1) {
        // 如果没有自定义数据，就默认选择最新
        defaultTopic = circleTopicList[1];
      }
    } else if (!hasCurrentTopicPermission(defaultTopic.topicId)) {
      defaultTopic = null;
    }

    await Routes.pushCreateMomentPage(
      Get.context,
      guildId,
      channelId,
      defaultTopic: defaultTopic,
      topics: allCircleTopicList,
      assetList: _assetList ?? [],
    );
  }
}
