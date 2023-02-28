import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/relation_api.dart';
import 'package:im/app/modules/friend_list_page/controllers/friend_list_page_controller.dart';
import 'package:im/global.dart';
import 'package:im/pages/friend/relation.dart';
import 'package:im/pages/friend/widgets/relation_utils.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';

class FriendApplyPageController extends GetxController {
  static FriendApplyPageController get to =>
      Get.find<FriendApplyPageController>();

  List<FriendApply> _outgoingList = [];
  List<FriendApply> _incomingList = [];

  UnmodifiableListView<FriendApply> get outgoingList =>
      UnmodifiableListView(_outgoingList);

  UnmodifiableListView<FriendApply> get incomingList =>
      UnmodifiableListView(_incomingList);
  static ValueNotifier<int> friendApplyNum = ValueNotifier(0);

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {}

  Future init() async {
    return fetchData();
  }

  Future updateApplyNum() async {
    final res = await RelationApi.getPendingList(Global.user.id);
    friendApplyNum.value = res
        .where((v) => v.relationType == RelationType.pendingIncoming)
        .toList()
        .length;
    GlobalState.updateBadge();
  }

  Future fetchData() async {
    final res = await RelationApi.getPendingList(Global.user.id);
    res.forEach((v) {
      RelationUtils.update(v.userId, v.relationType);
    });
    _incomingList = res
        .where((v) => v.relationType == RelationType.pendingIncoming)
        .toList();
    friendApplyNum.value = _incomingList.length;
    _outgoingList = res
        .where((v) => v.relationType == RelationType.pendingOutgoing)
        .toList();
    update();
    GlobalState.updateBadge();
  }

  Future<void> apply(String userId) async {
    final res = await RelationApi.apply(Global.user.id, userId);
    _outgoingList.removeWhere((element) => element.userId == userId);
    _outgoingList.insert(
      0,
      FriendApply(
          userId: userId,
          time: res['timestamp'],
          relationType: RelationType.pendingOutgoing),
    );
    RelationUtils.update(userId, RelationType.pendingOutgoing);
    showToast('已发送好友请求'.tr);
    update();
  }

  Future<void> agree(String userId, {bool isShowToast = false}) async {
    await RelationApi.agree(Global.user.id, userId);
    await FriendListPageController.to.add(userId);
    final item =
        _incomingList.firstWhere((v) => v.userId == userId, orElse: () => null);
    if (item != null) {
      _incomingList.remove(item);
      RelationUtils.update(userId, RelationType.friend);
      unawaited(FriendListPageController.to.add(item.userId));
      unawaited(updateApplyNum());
      update();
    }
    if (isShowToast) {
      showToast('已通过对方的好友请求'.tr);
    }
  }

  Future<void> refuse(String userId) async {
    await RelationApi.refuse(Global.user.id, userId);
    _incomingList.removeWhere((v) => v.userId == userId);
    RelationUtils.update(userId, RelationType.none);
    unawaited(updateApplyNum());
    update();
  }

  Future<bool> cancel(String userId, {Rx<bool> loading}) async {
    final res = await showConfirmDialog(
      title: '提示'.tr,
      content: '确定撤回好友请求？'.tr,
    );
    if (res != true) return false;
    try {
      if (loading != null) loading.value = true;
      await RelationApi.cancel(Global.user.id, userId);
      _outgoingList.removeWhere((v) => v.userId == userId);
      RelationUtils.update(userId, RelationType.none);
      if (loading != null) loading.value = false;
      showToast('已撤回好友请求'.tr);
    } catch (e) {
      if (loading != null) loading.value = false;
    }
    update();
    return true;
  }

  void onApply({String requestId, String relationId, int timestamp}) {
    if (requestId == Global.user.id) {
      _outgoingList.removeWhere((element) => element.userId == relationId);
      _outgoingList.insert(
        0,
        FriendApply(
            userId: relationId,
            time: timestamp,
            relationType: RelationType.pendingOutgoing),
      );
      RelationUtils.update(relationId, RelationType.pendingOutgoing);
    } else if (relationId == Global.user.id) {
      _incomingList
        ..removeWhere((element) => element.userId == requestId)
        ..insert(
            0,
            FriendApply(
                userId: requestId,
                time: timestamp,
                relationType: RelationType.pendingIncoming));
      _outgoingList.removeWhere((ele) => ele.userId == requestId);
      RelationUtils.update(requestId, RelationType.pendingIncoming);
    }
    updateApplyNum();
    update();
  }

  /// 成为朋友
  void onFriend({String requestId, String relationId}) {
    if (requestId == Global.user.id) {
      FriendListPageController.to.add(relationId);
      _incomingList.removeWhere((v) => v.userId == relationId);
      RelationUtils.update(relationId, RelationType.friend);
    } else if (relationId == Global.user.id) {
      FriendListPageController.to.add(requestId);
      _outgoingList.removeWhere((v) => v.userId == requestId);
      RelationUtils.update(requestId, RelationType.friend);
    }
    updateApplyNum();
    update();
  }

  /// 其他人拒绝我的申请
  void onRefuse(String userId) {
    _outgoingList.removeWhere((v) => v.userId == userId);
    RelationUtils.update(userId, RelationType.none);
    update();
  }

  void onCancel({String relationId, String requestId}) {
    if (requestId == Global.user.id) {
      _outgoingList.removeWhere((v) => v.userId == relationId);
      RelationUtils.update(relationId, RelationType.none);
    } else if (relationId == Global.user.id) {
      _incomingList.removeWhere((v) => v.userId == requestId);
      RelationUtils.update(requestId, RelationType.none);
    }
    updateApplyNum();
    update();
  }
}
