import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/role_bean.dart';
import 'package:im/api/relation_api.dart';
import 'package:im/api/user_api.dart';
import 'package:im/app/modules/friend_apply_page/controllers/friend_apply_page_controller.dart';
import 'package:im/app/modules/friend_list_page/controllers/friend_list_page_controller.dart';
import 'package:im/app/modules/mute/controllers/mute_list_controller.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/pages/friend/relation.dart';
import 'package:im/pages/friend/widgets/relation_utils.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/tab_bar.dart';
import 'package:im/pages/member_list/model/member_list_model.dart';
import 'package:im/pages/remark_modification_page.dart';
import 'package:im/routes.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/show_action_sheet.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/widgets/remove_member_widget.dart';
import 'package:im/widgets/toast.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';

class UserInfoViewModel extends GetxController {
  static int associatedWidgetId = 1001;

  final String uId;
  final String gId;
  final UserInfo userInfo;
  final bool showRemoveFromGuild;

  UserInfoViewModel(
      {@required this.uId,
      @required this.gId,
      @required this.userInfo,
      @required this.showRemoveFromGuild});

  static UserInfoViewModel get to {
    if (GetInstance().isRegistered<UserInfoViewModel>())
      return GetInstance().find<UserInfoViewModel>();
    return null;
  }

  // ????????????????????????
  List<GuildTarget> commonGuilds = [];
  List<UserInfo> commonFriends = [];

  // ????????????????????????
  final Rx<bool> agreeLoading = false.obs;
  final Rx<bool> refuseLoading = false.obs;

  // ?????????????????????
  final Rx<bool> applyLoading = false.obs;
  final Rx<bool> videoDisabled = true.obs;

  @override
  void onInit() {
    super.onInit();
    if (Global.user.id != userId) {
      // ??????????????????
      Future.delayed(const Duration(milliseconds: 300), () {
        unawaited(fetchAssociatedData());
      });
    }

    UserApi.getAllowRoster('video').then((res) {
      videoDisabled.value = !res;
    });

    if (userInfo != null) {
      Db.userInfoBox.put(userInfo.userId, userInfo);
    }

    if (GlobalState.isDmChannel) {
      UserInfo.get(userId, forceFromNet: true);
    } else if (guildId.hasValue) {
      if (userInfo == null)
        RoleBean.updateFromNet(userId: userId, guildId: guildId);
      else
        RoleBean.update(userInfo.userId,
            ChatTargetsModel.instance.selectedChatTarget.id, userInfo.roles);
    }
  }

  String get userId => uId ?? userInfo?.userId ?? '';

  String get guildId => gId ?? ChatTargetsModel.instance.selectedChatTarget?.id;

  bool get hideGuildInfo =>
      !showRemoveFromGuild ||
      HomeTabBar.currentIndex != 0 ||
      GlobalState.isDmChannel;

  /// ???????????????????????????
  Future<void> fetchAssociatedData() async {
    final res = await RelationApi.getRelation(Global.user.id, userId);
    final RelationType type = RelationTypeExtension.fromInt(res['type'] ?? 0);
    RelationUtils.update(userId, type);
    commonGuilds = (res['guilds'] as List)
        .map((v) => GuildTarget.tmp(
            id: v['guild_id'].toString(),
            icon: v['icon'].toString(),
            name: v['name'].toString()))
        .toList();
    commonFriends = (res['relations'] as List)
        .map((v) => UserInfo(
            userId: v['user_id'], avatar: v['avatar'], nickname: v['nickname']))
        .toList();
    update([associatedWidgetId]);
  }

  Future<void> onMoreAction(UserInfo user,
      {bool showRemoveMember = true}) async {
    final relation = RelationUtils.getRelation(userId);
    final isInGuild = RoleBean.isInGuild(user.userId, guildId);
    final List<FutureOr<Widget>> actions = [
      Text(
        "???????????????".tr,
        style: appThemeData.textTheme.bodyText2,
        key: const ValueKey(0),
      ),
    ];
    VoidCallback friendHandler;
    if (!user.isBot) {
      switch (relation) {
        case RelationType.none:
        case RelationType.unrelated:
          friendHandler = () async {
            /// fix: ????????????????????????????????????????????????
            await FriendApplyPageController.to.apply(userId);
            if (OrientationUtil.portrait) Get.back();
          };
          actions.add(Text('????????????'.tr,
              style: appThemeData.textTheme.bodyText2, key: const ValueKey(1)));
          break;
        case RelationType.pendingIncoming:
          friendHandler = () async {
            /// fix: 2022.3.10 ????????????????????????????????????????????????????????????????????????agree???????????????????????????apply?????????1032??????
            await FriendApplyPageController.to.agree(userId);
            if (OrientationUtil.portrait) Get.back();
          };
          actions.add(Text('????????????'.tr,
              style: appThemeData.textTheme.bodyText2, key: const ValueKey(1)));
          break;
        case RelationType.pendingOutgoing:
          actions.add(Text('??????????????????'.tr,
              style: appThemeData.textTheme.bodyText2, key: const ValueKey(1)));
          friendHandler = () async {
            final res = await FriendApplyPageController.to.cancel(userId);
            if (res == true && OrientationUtil.portrait) Get.back();
          };
          break;
        case RelationType.friend:
          actions.add(Text('????????????'.tr,
              style: appThemeData.textTheme.bodyText1
                  .copyWith(color: DefaultTheme.dangerColor),
              key: const ValueKey(1)));
          friendHandler = () async {
            final res = await FriendListPageController.to.remove(userId);
            if (res == true && OrientationUtil.portrait) Get.back();
          };
          break;
        default:
      }
    }

    final isInBlacklist =
        FriendListPageController.to.blackListIsContain(userId);
    actions.add(Text(isInBlacklist ? "????????????".tr : '??????'.tr,
        style: isInBlacklist
            ? appThemeData.textTheme.bodyText1
            : appThemeData.textTheme.bodyText2
                .copyWith(color: DefaultTheme.dangerColor),
        key: const ValueKey(2)));
    actions.add(Text('??????'.tr,
        style: appThemeData.textTheme.bodyText2
            .copyWith(color: DefaultTheme.dangerColor),
        key: const ValueKey(3)));

    bool isMute = false;
    // ?????????????????????
    if (gId != '0') {
      final hasMutePermission = hasPermission(Permission.MUTE, user);
      // ???????????????????????????????????????
      if (hasMutePermission && !GlobalState.isDmChannel) {
        if (isInGuild) {
          final Future<Widget> future = Future(() async {
            final mutedTime =
                await MuteListController.to.getMutedTime(userId, guildId);
            isMute = mutedTime > 0;
            return Text(isMute ? "????????????".tr : '??????'.tr,
                style: appThemeData.textTheme.bodyText2
                    .copyWith(color: DefaultTheme.dangerColor),
                key: const ValueKey(4));
          });
          actions.add(future);
        }
      }
    }

    //?????????????????????????????????????????????'???????????????'
    if (!GlobalState.isDmChannel &&
        guildId != null &&
        isInGuild &&
        hasPermission(Permission.KICK_MEMBERS, user) &&
        //relation != RelationType.friend &&   //?????????????????????????????????
        TextChannelController.dmChannel?.type != ChatChannelType.group_dm &&
        showRemoveMember) {
      actions.add(Text(
        '????????????'.tr,
        style: appThemeData.textTheme.bodyText2
            .copyWith(color: DefaultTheme.dangerColor),
        key: const ValueKey(5),
      ));
    }

    final valueKey = await showCustomActionSheet<ValueKey<int>>(actions);
    if (valueKey == null) return;

    switch (valueKey.value) {
      case 0:
        await Routes.push(
            Get.context, RemarkModificationPage(userId), remarkModification,
            fullScreenDialog: true);
        break;
      case 1:
        friendHandler();
        break;
      case 2:
        unawaited(_showShieldInfo(isInBlacklist, userId));
        break;
      case 3:
        unawaited(Routes.pushToTipOffPage(
          Get.context,
          guildId: guildId,
          accusedUserId: user.userId,
          accusedName: user.nickname,
        ));
        break;
      case 4:
        await _resolveMute(isMute, user);
        break;
      case 5:
        await _removeMember(user);
        break;
    }
  }

  /// ????????????
  Future<void> _removeMember(UserInfo user) async {
    final String memberId = userId;
    final String memberName = user.showName();

    final removeMemberWidget = RemoveMemberWidget(
      guildId,
      memberId,
      memberName,
      user.isBot,
      RemoveMemberWidgetFrom.card,
    );

    final isRemoved = await Get.bottomSheet<bool>(removeMemberWidget);
    if (isRemoved == true) {
      await MemberListModel.instance.remove(userId);
      Get.back();
    }
  }

  /// - ??????/????????????
  Future _resolveMute(bool isMute, UserInfo user) async {
    if (isMute) {
      final res = await showConfirmDialog(
        content: '???????????????????'.tr,
        confirmStyle: const TextStyle(
          color: Color(0xFF198CFE),
          fontSize: 16,
        ),
      );
      if (!res) return;
      final success =
          await MuteListController.to.removeFromMuteList(user.userId, guildId);
      if (success) {
        Toast.iconToast(icon: ToastIcon.success, label: "???????????????".tr);
      } else {
        showToast("???????????????????????????????????????".tr);
      }
    } else {
      unawaited(Routes.pushMuteTimeSettingPage(
        Get.context,
        guildId,
        user.userId,
      ));
    }
  }

  /// ?????????????????????
  Future<void> _showShieldInfo(bool isInBlackList, String blackId) async {
    if (isInBlackList) {
      if (FriendListPageController.to.blackListIsContain(blackId)) {
        final result =
            await FriendListPageController.to.removeFromBlackList(blackId);
        if (result) {
          showToast("???????????????".tr);
          Get.back();
        } else {
          showToast("???????????????????????????????????????".tr);
        }
      } else {
        showToast("??????????????????".tr);
        Get.back();
      }
    } else {
      final res = await showConfirmDialog(
          title: '??????'.tr, content: '?????????????????????????????????????????????????????????????'.tr);
      if (res == true) {
        if (FriendListPageController.to.blackListIsContain(blackId)) {
          showToast("????????????".tr);
          Get.back();
        } else {
          final result = await FriendListPageController.to.addBlackId(blackId);
          if (result) {
            showToast("???????????????".tr);
            Get.back();
          } else {
            showToast("?????????????????????????????????".tr);
          }
        }
      }
    }
  }

  /// ??????????????????
  Future<void> agreeApply() async {
    try {
      agreeLoading.value = true;
      await FriendApplyPageController.to.agree(userId);
      agreeLoading.value = false;
      showToast('??????????????????????????????'.tr);
    } catch (e) {
      agreeLoading.value = false;
      unawaited(fetchAssociatedData());
    }
  }

  /// ??????????????????
  Future<void> agreeRefuse() async {
    try {
      refuseLoading.value = true;
      await FriendApplyPageController.to.refuse(userId);
      showToast('??????????????????????????????'.tr);
      refuseLoading.value = false;
    } catch (e) {
      refuseLoading.value = false;
      unawaited(fetchAssociatedData());
    }
  }

  /// ??????????????????
  Future<void> cancelApply() async {
    final relation = RelationUtils.getRelation(userId);
    if (relation == RelationType.pendingIncoming) {
      final res = await showConfirmDialog(
        title: '??????????????????'.tr,
        content: '??????????????????????????????????????????'.tr,
        cancelText: '??????'.tr,
        confirmText: '??????'.tr,
        barrierDismissible: true,
      );
      try {
        if (res == true) {
          applyLoading.value = true;
          await FriendApplyPageController.to.agree(userId);
        } else if (res == false) {
          await FriendApplyPageController.to.refuse(userId);
        }
        applyLoading.value = false;
      } catch (e) {
        applyLoading.value = false;
        unawaited(fetchAssociatedData());
      }
    } else if (relation == RelationType.pendingOutgoing) {
      try {
        await FriendApplyPageController.to
            .cancel(userId, loading: applyLoading);
      } catch (e) {
        unawaited(fetchAssociatedData());
      }
    }
  }

  /// ??????????????????
  Future<void> sendApply() async {
    applyLoading.value = true;
    try {
      await FriendApplyPageController.to.apply(userId);
      applyLoading.value = false;
    } catch (e) {
      applyLoading.value = false;
      unawaited(fetchAssociatedData());
    }
  }

  bool hasPermission(Permission p, UserInfo user) {
    if (user.userId == Global.user.id) return false;

    if (PermissionUtils.comparePosition(roleIds: user.roles) != 1) return false;

    final gp = PermissionModel.getPermission(
        ChatTargetsModel.instance.selectedChatTarget.id);
    if (!PermissionUtils.oneOf(gp, [p])) return false;

    if (PermissionUtils.isGuildOwner(userId: user.userId)) return false;

    return true;
  }
}
