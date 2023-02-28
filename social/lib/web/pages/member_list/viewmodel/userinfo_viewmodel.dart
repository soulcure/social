import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/friend_apply_page/controllers/friend_apply_page_controller.dart';
import 'package:im/app/modules/friend_list_page/controllers/friend_list_page_controller.dart';
import 'package:im/global_methods/goto_direct_message.dart';
import 'package:im/pages/friend/relation.dart';
import 'package:im/pages/friend/widgets/relation_utils.dart';
import 'package:im/routes.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/web/pages/main/main_model.dart';
import 'package:oktoast/oktoast.dart';

class UserinfoViewmodel {
  Rx<bool> loading = false.obs;
  String userId;

  UserinfoViewmodel({
    this.userId,
  });

  void directChat() {
    if (OrientationUtil.landscape) {
      Get.back();
      MainRouteModel.instance.goBack();
    }
    gotoDirectMessageChat(userId);
  }

  void reportFriend(BuildContext context, UserInfo userInfo) {
    Routes.pushToTipOffPage(
      context,
      accusedUserId: userInfo.userId,
      accusedName: userInfo.nickname,
    );
  }

  /// 屏蔽和解除屏蔽
  Future<void> shieldFriend(BuildContext context) async {
    final isInBlackList =
        FriendListPageController.to.blackListIsContain(userId);
    if (isInBlackList) {
      if (FriendListPageController.to.blackListIsContain(userId)) {
        final result =
            await FriendListPageController.to.removeFromBlackList(userId);
        if (result) {
          showToast("已解除屏蔽".tr);
        } else {
          showToast("解除屏蔽失败，请检查网络。".tr);
        }
      } else {
        showToast("已被解除屏蔽".tr);
      }
    } else {
      final res = await showConfirmDialog(
          title: '屏蔽'.tr, content: '屏蔽后，你将不再收到对方的私聊，确定屏蔽?'.tr);
      if (res == true) {
        if (FriendListPageController.to.blackListIsContain(userId)) {
          showToast("已被屏蔽".tr);
        } else {
          final result = await FriendListPageController.to.addBlackId(userId);
          if (result) {
            showToast("已被你屏蔽".tr);
          } else {
            showToast("屏蔽失败，请检查网络。".tr);
          }
        }
      }
    }
  }

  /// 撤回好友请求
  Future<void> cancelFriendRequest(BuildContext context) async {
    final relation = RelationUtils.getRelation(userId);
    if (relation == RelationType.pendingIncoming) {
      final res = await showConfirmDialog(
        title: '通过好友请求'.tr,
        content: '对方添加你为好友，通过请求？'.tr,
        cancelText: '忽略'.tr,
        confirmText: '通过'.tr,
        barrierDismissible: true,
      );
      try {
        if (res == true) {
          loading.value = true;
          await FriendApplyPageController.to.agree(userId);
        } else if (res == false) {
          await FriendApplyPageController.to.refuse(userId);
        }
        loading.value = false;
      } catch (e) {
        loading.value = false;
      }
    } else if (relation == RelationType.pendingOutgoing) {
      try {
        await FriendApplyPageController.to.cancel(userId, loading: loading);
      } catch (e) {
        loading.value = false;
      }
    }
  }

  /// 添加好友申请
  Future<void> applyFriendRequest() async {
    loading.value = true;
    try {
      await FriendApplyPageController.to.apply(userId);
      loading.value = false;
    } catch (e) {
      loading.value = false;
    }
  }
}
