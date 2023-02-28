import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/document_online/document_api.dart';
import 'package:im/app/modules/tc_doc_add_group_page/entities/tc_doc_group.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/global.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/search/model/search_member_model.dart';
import 'package:im/pages/search/model/search_model.dart';
import 'package:im/widgets/fb_ui_kit/button/button_builder.dart';
import 'package:im/widgets/toast.dart';
import 'package:oktoast/oktoast.dart';

// 最多协作者数量，100（包括所有者，所以实际数是99）
const int _maxGroupsNum = 100;

class TcDocAddGroupPageController extends GetxController
    with GetSingleTickerProviderStateMixin, StateMixin {
  final String guildId;
  final String fileId;
  SearchInputModel searchInputModel;

  // 由于接口问题，搜索关键字为空和非空用两个model和ui
  SearchMemberListModel searchMemberModel;

  TcDocAddGroupPageController({@required this.guildId, @required this.fileId});

  TabController tabController;

  // 原有的协作者列表
  List<TcDocGroup> docGroups = [];

  // 当前选择的协作者列表
  List<TcDocGroup> tempDocGroups = [];

  FbButtonStatus confirmStatus = FbButtonStatus.unable;

  String previousRoute;

  @override
  void onInit() {
    previousRoute = Get.previousRoute;
    searchMemberModel = SearchMemberListModel(guildId);
    searchInputModel = SearchInputModel();

    tabController = TabController(vsync: this, length: 3);
    initPage();
    super.onInit();
  }

  @override
  void onClose() {
    searchInputModel?.dispose();
    tabController?.dispose();
    super.onClose();
  }

  Future<void> initPage() async {
    // completeMemberModel.pageNum = 1;
    docGroups = [
      TcDocGroup(
        fileId: fileId,
        type: TcDocGroupType.user,
        role: TcDocGroupRole.edit,
        targetId: Global.user.id,
      )
    ];
    change(null, status: RxStatus.loading());
    await Future.wait([
      getDocGroups(),
    ]).then((value) {
      change(null, status: RxStatus.success());
    }).catchError((e, s) {
      logger.severe('获取协作者失败', e, s);
      final errorMsg =
          Http.isNetworkError(e) ? networkErrorText : '数据异常，请重试'.tr;
      change(e, status: RxStatus.error(errorMsg));
    });
  }

  Future<void> getDocGroups() async {
    final res = await DocumentApi.docGroups(fileId, pageSize: 100);
    final groups = (res['lists'] as List)
        .map((e) => TcDocGroup.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    docGroups.addAll(groups);
  }

  void toggleSelect(String id, TcDocGroupType type, [bool value]) {
    if (confirmStatus == FbButtonStatus.loading) return;
    final selectIdx =
        tempDocGroups.indexWhere((element) => element.targetId == id);
    if (selectIdx != -1) {
      if (value != true) tempDocGroups.removeAt(selectIdx);
    } else {
      final group = TcDocGroup(
          fileId: fileId, type: type, role: TcDocGroupRole.edit, targetId: id);
      if (value != false) {
        if (tempDocGroups.length + docGroups.length >= _maxGroupsNum) {
          showToast('最多添加%s个协作者'.trArgs([_maxGroupsNum.toString()]));
        } else {
          tempDocGroups.add(group);
        }
      }
    }
    confirmStatus =
        tempDocGroups.isEmpty ? FbButtonStatus.unable : FbButtonStatus.normal;
    update();
  }

  Future<void> onConfirm() async {
    if (tempDocGroups.isEmpty) return;
    confirmStatus = FbButtonStatus.loading;
    update();
    try {
      await DocumentApi.docBatch(fileId, tempDocGroups);
      Get.back(result: true);
      Toast.iconToast(icon: ToastIcon.success, label: "邀请成功".tr);
    } finally {
      confirmStatus = FbButtonStatus.normal;
      update();
    }
  }

  // 过滤掉已选过的用户
  List<UserInfo> filterUsers(List<UserInfo> users) {
    final newUsers = users
        .where((u) => docGroups.indexWhere((g) => g.targetId == u.userId) == -1)
        .toList();
    return newUsers;
  }

  /// 过滤已选过的用户，返回true，需要过滤
  bool filterUser(UserInfo user) {
    /// 过滤掉机器人
    return user.isBot ||
        docGroups.indexWhere((g) => g.targetId == user.userId) != -1;
  }

  // 过滤掉已选过的角色
  List<Role> filterRoles(List<Role> roles) {
    final newRoles = roles
        .where((u) =>
            docGroups.indexWhere((g) => g.targetId == u.id) == -1 && !u.managed)
        .toList();
    return newRoles;
  }

  // 过滤掉已选过的频道
  List<ChatChannel> filterChannels(List<ChatChannel> channels) {
    final newChannels = channels
        .where((u) => docGroups.indexWhere((g) => g.targetId == u.id) == -1)
        .toList();
    return newChannels;
  }

  /// 是否选中标记
  bool isSelected(String userId) =>
      tempDocGroups.firstWhere((element) => element.targetId == userId,
          orElse: () => null) !=
      null;
}
