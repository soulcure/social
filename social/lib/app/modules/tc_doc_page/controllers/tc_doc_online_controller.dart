import 'dart:collection';

import 'package:get/get.dart';
import 'package:im/app/modules/document_online/document_api.dart';
import 'package:im/app/modules/tc_doc_page/controllers/tc_doc_page_controller.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/global.dart';
import 'package:im/loggers.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class TcDocOnlineController extends GetxController with StateMixin {
  final String fileId;
  final RefreshController refreshController;

  TcDocOnlineController(
    this.fileId,
    this.refreshController,
  );

  int page = 1;
  int pageSize = 10;
  int total = 0;
  LinkedHashSet<String> onlineIds = LinkedHashSet<String>();

  @override
  void onInit() {
    onlineIds.add(Global.user.id);
    initPage();
    super.onInit();
  }

  Future<void> initPage() async {
    change(null, status: RxStatus.loading());
    await fetchOnlineUser().then((value) {
      change(null, status: RxStatus.success());
    }).catchError((e, s) {
      logger.severe('获取文档在线用户错误', e, s);
      final errorMsg =
          Http.isNetworkError(e) ? networkErrorText : '数据异常，请重试'.tr;
      change(e, status: RxStatus.error(errorMsg));
    });
  }

  Future<void> fetchOnlineUser() async {
    await DocumentApi.docOnlineUser(fileId,
            page: page, pageSize: pageSize, showDefaultErrorToast: false)
        .then((res) {
      onlineIds.addAll(LinkedHashSet<String>.from(res['lists']));
      page++;
      total = res['count'] ?? 0;
      update();
      final hasMoreData = onlineIds.length != total;
      refreshController?.loadComplete();
      if (!hasMoreData) {
        refreshController?.loadNoData();
      }
      // 更新文档页成员列表页数据
      if (Get.isRegistered<TcDocPageController>()) {
        Get.find<TcDocPageController>().setOnlineUser(onlineIds, total);
      }
    }).catchError((e) {
      refreshController?.loadFailed();
      throw e;
    });
  }

  void onLoading() {
    fetchOnlineUser();
  }
}
