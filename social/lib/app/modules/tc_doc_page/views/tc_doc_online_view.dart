import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/tc_doc_page/controllers/tc_doc_online_controller.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/refresh/common_error_widget.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class TcDocOnlineView extends StatefulWidget {
  final String fileId;

  const TcDocOnlineView(this.fileId);

  @override
  State<TcDocOnlineView> createState() => _TcDocOnlineViewState();
}

class _TcDocOnlineViewState extends State<TcDocOnlineView> {
  TcDocOnlineController tcDocOnlineController;

  RefreshController refreshController;

  @override
  void initState() {
    super.initState();
    refreshController = RefreshController();
    tcDocOnlineController =
        TcDocOnlineController(widget.fileId, refreshController);
  }

  @override
  void dispose() {
    refreshController?.dispose();
    if (Get.isRegistered<TcDocOnlineController>()) {
      Get.delete<TcDocOnlineController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TcDocOnlineController>(
        init: tcDocOnlineController,
        builder: (c) {
          return c.obx(
            (state) {
              return SmartRefresher(
                enablePullDown: false,
                enablePullUp: true,
                controller: refreshController,
                onLoading: c.onLoading,
                footer: ClassicFooter(
                  idleText: ''.tr,
                  loadingText: ''.tr,
                  canLoadingText: ''.tr,
                  failedText: '加载失败'.tr,
                  noDataText: ''.tr,
                ),
                child: ListView.builder(
                  itemBuilder: (_, i) => _buildItem(c.onlineIds.elementAt(i)),
                  itemCount: c.onlineIds.length,
                ),
              );
            },
            onLoading: DefaultTheme.defaultLoadingIndicator(),
            onError: (e) {
              return CommonErrorMsgWidget(
                errorMsg: e,
                onRetry: c.initPage,
              );
            },
          );
        });
  }

  Widget _buildItem(String uid) {
    return Container(
      height: 56,
      color: Get.theme.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          RealtimeAvatar(userId: uid, size: 32, tapToShowUserInfo: true),
          sizeWidth12,
          Expanded(child: RealtimeNickname(userId: uid)),
        ],
      ),
    );
  }
}
