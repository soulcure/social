import 'dart:async';

import 'package:get/get.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/app/modules/circle_detail/entity/circle_detail_message.dart';
import 'package:im/db/cicle_news_table.dart';
import 'package:im/utils/im_utils/channel_util.dart';

/// * 圈子动态详情 - 底部定位按钮 Controller
class BottomPositionController extends GetxController {
  static BottomPositionController to(
      {CirclePostNewsPositionObj obj, String tagId}) {
    try {
      if (Get.isRegistered<BottomPositionController>(tag: tagId)) {
        return Get.find<BottomPositionController>(tag: tagId);
      }
    } catch (_) {}
    return Get.put(BottomPositionController(obj, tagId), tag: tagId);
  }

  /// * 动态ID
  String postId;

  /// * 圈子频道ID
  String postChannelId;

  /// * 用于定位的数据
  CirclePostNewsPositionObj positionObj;

  /// * 是否有未读消息
  bool get hasUnread => positionObj.hasAt || positionObj.hasNews;

  bool get hasAt => positionObj.hasAt;

  /// * 未读消息数
  final unreadNum = 0.obs;

  /// * 未读艾特id
  final unreadAtUserId = ''.obs;

  /// * 可视范围内最后一条回复
  final lastBeanInView = Rx<CommentMessageEntity>(null);

  CommentMessageEntity get lastBean => lastBeanInView.value;

  ///监听lastBean的变化
  Worker _lastUpdaterWorker;
  Worker _lastUpdater2Worker;

  ///是否正在计算中
  bool _isCounting = false;

  /// * 是否自动跳转到底部
  bool isSelfJumpBottom = false;

  BottomPositionController(this.positionObj, this.postId) {
    _lastUpdaterWorker =
        interval<void>(lastBeanInView, _count, time: 500.milliseconds);
    _lastUpdater2Worker =
        debounce<void>(lastBeanInView, _count, time: 500.milliseconds);
    positionObj ??= CirclePostNewsPositionObj();
  }

  /// * 增加未读消息
  void addUnRead(CommentMessageEntity message, {bool isAtMe = false}) {
    if (isAtMe) positionObj.atMap[message.messageIdBigInt] = message.userId;
    positionObj.newsMap[message.messageIdBigInt] = message.userId;
    updateNumAndId();
  }

  /// * 删除未读消息
  void removeUnRead(CommentMessageEntity message) {
    positionObj.atMap.remove(message.messageIdBigInt);
    positionObj.newsMap.remove(message.messageIdBigInt);
    updateNumAndId();
  }

  String getAtUserId() {
    if (positionObj.hasAt) return positionObj.atMap[positionObj.firstAtKey];
    return null;
  }

  /// * 更新未读数和艾特ID
  void updateNumAndId() {
    if (checkIsReturn()) return;
    unreadNum.value = positionObj.newsMap.length;
    unreadAtUserId.value = getAtUserId();
    // debugPrint(
    //     'getChat bottom update: ${unreadNum.value}, ${unreadAtUserId.value}');
  }

  /// * 列表滚动时，更新最后一条回复的值
  void updateLastBean(
      {CommentMessageEntity lastComment, bool forceCount = false}) {
    if (lastComment != null &&
        (lastBean == null ||
            lastComment.messageIdBigInt > lastBean.messageIdBigInt)) {
      // debugPrint('getChat bottom updateLastBean: $lastComment');
      lastBeanInView.value = lastComment;
    } else if (forceCount) {
      _count(null);
    }
  }

  /// * 计算剩余未读数和艾特
  void _count(_) {
    // debugPrint('getChat bottom count - isCounting:$_isCounting');
    if (_isCounting || !hasUnread) return;
    _isCounting = true;
    if (lastBean != null) {
      final commentIdInt = lastBean.messageIdBigInt;
      if (positionObj.hasAt)
        positionObj.atMap.removeWhere((key, value) => key <= commentIdInt);
      if (positionObj.hasNews) removeUnreadByCommentId(commentIdInt);
    }
    updateNumAndId();
    _isCounting = false;
    checkToLast();
  }

  /// * 检查是否到最后，且还有未读数
  void checkToLast() {
    final c = CircleDetailController.to(postId: postId);
    if (c.totalReplySize == 0) {
      if (positionObj.hasNews) {
        removeUnreadByCommentId(positionObj.lastNewsKey);
        positionObj.atMap.clear();
        updateNumAndId();
      }
    } else {
      //是否到了最后的一条
      final toLast = c.reachEnd &&
          c.bottomIndex != null &&
          c.bottomIndex >= c.replySize - 1;
      if (toLast && positionObj.hasNews) {
        removeUnreadByCommentId(positionObj.lastNewsKey);
        positionObj.atMap.clear();
        updateNumAndId();
      }
    }
  }

  /// * 跳转
  Future<void> jump() async {
    final c = CircleDetailController.to(postId: postId);
    if (positionObj.hasAt) {
      final commentId = positionObj.firstAtKey;
      await c.goToComment(commentId.toString(), toDown: true);
      positionObj.atMap.remove(commentId);
      removeUnreadByCommentId(commentId);
      updateNumAndId();
    } else if (positionObj.hasNews) {
      final commentId = positionObj.lastNewsKey;
      c.jumpToBottom();
      removeUnreadByCommentId(commentId);
      updateNumAndId();
    }
  }

  /// * 根据已读的commentId，删除未读数据，同步更新圈子频道的未读数
  void removeUnreadByCommentId(BigInt commentId) {
    // print('getChat newsMapRemove: $commentId');
    if (commentId == null) return;
    final cId = commentId.toString();
    final proLen = positionObj.newsMap.length;
    positionObj.newsMap.removeWhere((key, value) => key <= commentId);

    // 如果未读数据有被变化，则同步更新圈子频道的未读数
    if (proLen != positionObj.newsMap.length) {
      final c = CircleDetailController.to(postId: postId);
      //用于上报已读的消息
      final uploadLast = CommentMessageEntity(
          topicId: c.postChannel?.id, commentId: cId, guildId: c.guildId);
      CircleNewsTable.batchDelete(postChannelId, commentId: cId).then((_) {
        ChannelUtil.instance.resetUnreadById(postChannelId, last: uploadLast);
      });
    }
  }

  ///检查是否：不计算直接返回
  bool checkIsReturn() {
    ///判断消息公屏是否自动跳转底部，是则返回true
    if (isSelfJumpBottom) {
      // debugPrint('getChat bottom isSelfJumpBottom: $isSelfJumpBottom');
      isSelfJumpBottom = false;
      _isCounting = false;
      return true;
    }
    return false;
  }

  @override
  void onClose() {
    super.onClose();
    _close();
  }

  void _close() {
    _lastUpdaterWorker?.dispose();
    _lastUpdater2Worker?.dispose();
  }
}

/// * 圈子动态详情 - 顶部定位按钮 Controller
/// * 只显示艾特，不显示数量
class TopPositionController extends GetxController {
  static TopPositionController to(
      {CirclePostNewsPositionObj obj, String tagId}) {
    try {
      if (Get.isRegistered<TopPositionController>(tag: tagId)) {
        return Get.find<TopPositionController>(tag: tagId);
      }
    } catch (_) {}
    return Get.put(TopPositionController(obj, tagId), tag: tagId);
  }

  ///圈子消息定位数据
  CirclePostNewsPositionObj positionObj;

  /// * 是否有未读艾特
  bool get hasAt => positionObj.hasAt;

  /// * 未读艾特id
  final unreadAtUserId = ''.obs;

  /// * 可视范围内第一条回复
  final firstBeanInView = Rx<CommentMessageEntity>(null);

  CommentMessageEntity get firstBean => firstBeanInView.value;

  ///监听lastBean的变化
  Worker _lastUpdaterWorker;
  Worker _lastUpdater2Worker;

  ///是否正在计算中
  bool _isCounting = false;

  String postId;

  TopPositionController(this.positionObj, this.postId) {
    _lastUpdaterWorker =
        interval<void>(firstBeanInView, _count, time: 500.milliseconds);
    _lastUpdater2Worker =
        debounce<void>(firstBeanInView, _count, time: 500.milliseconds);
    positionObj ??= CirclePostNewsPositionObj();
  }

  String getAtUserId() {
    if (positionObj.hasAt) return positionObj.atMap[positionObj.lastAt];
    return null;
  }

  /// * 更新艾特ID
  void updateId() {
    unreadAtUserId.value = getAtUserId();
    // debugPrint('getChat top unreadAtUserId: ${unreadAtUserId.value}');
  }

  /// * 列表滚动时，更新第一条回复的值
  void updateFirstBean({CommentMessageEntity firstComment}) {
    if (firstComment != null &&
        (firstBean == null ||
            firstComment.messageIdBigInt < firstBean.messageIdBigInt)) {
      // debugPrint('getChat top updateFirstBean: $firstComment');
      firstBeanInView.value = firstComment;
    }
  }

  /// * 计算剩余未读数和艾特
  void _count(_) {
    // debugPrint('getChat top count - isCounting:$_isCounting');
    if (_isCounting || !hasAt) return;

    _isCounting = true;
    if (firstBean != null) {
      final commentIdInt = firstBean.messageIdBigInt;
      if (hasAt)
        positionObj.atMap.removeWhere((key, value) => key >= commentIdInt);
    }
    updateId();
    _isCounting = false;
  }

  /// * 清空数据
  void clear() {
    positionObj.atMap.clear();
    updateId();
  }

  /// 跳转艾特
  Future<void> jump() async {
    final detailController = CircleDetailController.to(postId: postId);
    if (hasAt) {
      final commentId = positionObj.lastAt;
      await detailController.goToComment(commentId.toString());
      positionObj.atMap.remove(commentId);
    }
    updateId();
  }

  @override
  void onClose() {
    super.onClose();
    _close();
  }

  void _close() {
    _lastUpdaterWorker?.dispose();
    _lastUpdater2Worker?.dispose();
  }
}
