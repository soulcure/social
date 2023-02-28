import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/views/portrait/widgets/custom_tabbar_indicator.dart';
import 'package:im/app/modules/tc_doc_add_group_page/widgets/tc_doc_channels.dart';
import 'package:im/app/modules/tc_doc_add_group_page/widgets/tc_doc_members.dart';
import 'package:im/app/modules/tc_doc_add_group_page/widgets/tc_doc_roles.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/pages/search/widgets/search_input_box.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/fb_ui_kit/button/button_builder.dart';
import 'package:im/widgets/refresh/common_error_widget.dart';

import '../controllers/tc_doc_add_group_page_controller.dart';

class TcDocAddGroupPageView extends GetView<TcDocAddGroupPageController> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<TcDocAddGroupPageController>(builder: (c) {
      return Scaffold(
        backgroundColor: Get.theme.backgroundColor,
        appBar: FbAppBar.custom(
          '邀请协作者'.tr,
        ),
        body: SafeArea(
          top: false,
          child: controller.obx(
            (state) {
              return Column(
                children: [
                  _buildSearchBox(),
                  _buildTabBar(),
                  const SizedBox(height: 0.5),
                  Expanded(child: _buildTabBarView()),
                  _buildBottomBar(),
                ],
              );
            },
            onLoading: DefaultTheme.defaultLoadingIndicator(),
            onError: (e) {
              return CommonErrorMsgWidget(
                errorMsg: e,
                onRetry: controller.initPage,
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildTabBarView() {
    return TabBarView(controller: controller.tabController, children: [
      TcDocMembers(controller),
      TcDocRoles(controller),
      TcDocChannels(controller)
    ]);
  }

  Widget _buildSearchBox() {
    return Container(
      color: Colors.white,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SearchInputBox(
        searchInputModel: controller.searchInputModel,
        borderRadius: 4,
        hintText: "搜索服务器成员".tr,
        autoFocus: false,
        height: 36,
      ),
    );
  }

  Widget _buildTabBar() {
    final children = [
      Text('成员'.tr),
      Text('角色'.tr),
      Text('频道'.tr),
    ];
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
            width: 0.5,
            color: Get.theme.dividerTheme.color,
          )),
          color: appThemeData.backgroundColor,
        ),
        child: TabBar(
            isScrollable: true,
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            indicatorColor: primaryColor,
            unselectedLabelStyle: const TextStyle(fontSize: 14),
            labelStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            unselectedLabelColor: Get.textTheme.headline2.color,
            labelColor: Get.textTheme.bodyText2.color,
            controller: controller.tabController,
            tabs: children,
            indicator: MyUnderlineTabIndicator(
              insets: const EdgeInsets.only(bottom: 7),
              borderSide: BorderSide(width: 2, color: primaryColor),
            )),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(width: 0.5, color: Get.theme.dividerTheme.color)),
      ),
      child: Row(
        children: [
          Text(
            '已选择：%s'.trArgs([controller.tempDocGroups.length.toString()]),
            style: TextStyle(
              fontSize: 14,
              color: Get.theme.primaryColor,
            ),
          ),
          spacer,
          FbButton.elevated(
            "邀请".tr,
            status: controller.confirmStatus,
            width: 66,
            height: 32,
            primaryColor: Get.theme.primaryColor,
            onPressed: controller.onConfirm,
          )
        ],
      ),
    );
  }
}
