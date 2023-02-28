import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/document_online/document_api.dart';
import 'package:im/app/modules/tc_doc_add_group_page/entities/tc_doc_group.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/global.dart';
import 'package:im/loggers.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class TcDocGroupsPageController extends GetxController with StateMixin {
  RefreshController refreshController;

  final String guildId;
  final String fileId;

  TcDocGroupsPageController({@required this.guildId, @required this.fileId});

  int page = 1;
  int pageSize = 20;
  int total = 0;
  List<TcDocGroup> groups = [];

  @override
  void onInit() {
    refreshController = RefreshController();
    groups.add(TcDocGroup(
        fileId: fileId,
        type: TcDocGroupType.user,
        role: TcDocGroupRole.edit,
        targetId: Global.user.id));
    initPage();
    super.onInit();
  }

  Future<void> initPage() async {
    page = 1;
    groups.removeRange(1, groups.length);
    change(null, status: RxStatus.loading());
    await fetchGroups().then((value) {
      change(null, status: RxStatus.success());
    }).catchError((e, s) {
      logger.severe('获取协作者错误', e, s);
      final errorMsg =
          Http.isNetworkError(e) ? networkErrorText : '数据异常，请重试'.tr;
      change(e, status: RxStatus.error(errorMsg));
    });
  }

  Future<void> fetchGroups() async {
    await DocumentApi.docGroups(fileId,
            page: page, pageSize: pageSize, showDefaultErrorToast: false)
        .then((res) {
      (res['lists'] as List).forEach((e) {
        final g = TcDocGroup.fromJson(Map<String, dynamic>.from(e));
        if (g.targetId != Global.user.id) {
          groups.add(g);
        }
      });
      page++;
      // 文档所有者不会出现在协作者列表中，需要+1
      total = (res['total'] ?? 0) + 1;
      update();
      final hasMoreData = (res['lists'] as List).length == pageSize;
      refreshController.loadComplete();
      if (!hasMoreData) {
        refreshController.loadNoData();
      }
    }).catchError((e) {
      refreshController.loadFailed();
      throw e;
    });
  }

  void onLoading() {}

  Future<void> updateGroup(TcDocGroup group, TcDocGroupRole role) async {
    await DocumentApi.docGroupUpdate(fileId, group.groupId, role);
    final groupIdx =
        groups.indexWhere((element) => element.groupId == group.groupId);
    if (groupIdx < 0) return;
    groups.replaceRange(groupIdx, groupIdx + 1, [group.copyWith(role: role)]);
    update();
  }

  Future<void> deleteGroup(TcDocGroup group) async {
    await DocumentApi.docGroupDel(group.groupId);
    groups.remove(group);
    total--;
    update();
  }
}
