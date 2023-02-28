import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:im/app/modules/mini_program_page/views/mini_program_page_view.dart';
import 'package:im/app/modules/tc_doc_page/controllers/tc_doc_page_controller.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/icon_font.dart';
import 'package:im/svg_icons.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/widgets/app_bar/appbar_action_model.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/fb_ui_kit/button/button_builder.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:websafe_svg/websafe_svg.dart';

class TcDocPageView extends MiniProgramPageView<TcDocPageController> {
  @override
  Widget buildNavigationBar() {
    return GetBuilder<TcDocPageController>(
      id: TcDocPageController.updateIdAppbar,
      builder: (c) {
        Widget child;
        if (c.tcDocInfo?.fileId == null) {
          child = const FbAppBar.diyTitleView(pageStep: 1);
        } else {
          final IconData collectIcon = c.tcDocInfo.isCollect()
              ? IconFont.buffCollectFill
              : IconFont.buffCollectOutline;
          final Color collectColor =
              c.tcDocInfo.isCollect() ? CustomColor.collect : null;
          child = FbAppBar.diyTitleView(
            pageStep: 1,
            titleBuilder: (context, style) => SizedBox(
              width: double.infinity,
              child: Row(children: [
                sizeWidth8,
                WebsafeSvg.asset(SvgIcons.tcDocLogo, width: 25.5, height: 22),
                sizeWidth8,
                SizedBox(
                  height: 24,
                  child: VerticalDivider(
                    width: 1,
                    color: Get.textTheme.headline2.color.withOpacity(0.2),
                  ),
                ),
                sizeWidth8,
                _buildOnlineUser(),
              ]),
            ),
            actions: [
              if (c.fromSelectPage)
                AppBarTextLightActionModel("下一步".tr, actionBlock: () {
                  Get.back(result: c.tcDocInfo);
                }),
              if (!c.fromSelectPage) ...[
                AppBarIconActionModel(
                  collectIcon,
                  showColor: collectColor,
                  actionBlock: c.toggleCollect,
                ),
                AppBarIconActionModel(
                  IconFont.buffChatForwardNew,
                  actionBlock: c.handleShareAction,
                ),
                AppBarIconActionModel(
                  IconFont.buffMoreHorizontal,
                  actionBlock: c.showActions,
                )
              ]
            ],
          );
        }
        return SizedBox(
          height: navigationBarHeight +
              Get.mediaQuery.viewPadding.top +
              // 注入css前添加高度以遮挡导航栏，大概45
              (controller.shouldShowAppbarExtra ? 45 : 0),
          child: child,
        );
      },
    );
  }

  @override
  Widget buildNavButtons() => const SizedBox();

  @override
  Widget buildSnackBar() {
    return Container(
      width: Get.width - 32,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: appThemeData.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '你在此文档的权限已发生变化'.tr,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          VerticalDivider(
            width: 0.5,
            indent: 10,
            endIndent: 10,
            color: Get.theme.dividerColor,
          ),
          sizeWidth12,
          FbButton.text(
            '点击刷新'.tr,
            onPressed: controller.refreshDoc,
          ),
        ],
      ),
    );
  }

  @override
  Widget buildWebView(TcDocPageController c) {
    if (!c.deleted && c.tcDocInfo == null) return sizedBox;
    if (c.deleted) {
      return Align(
        alignment: const Alignment(0, -0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(IconFont.buffDocDel, size: 60, color: Get.theme.disabledColor),
            sizeHeight16,
            Text('文档已被删除'.tr,
                style: TextStyle(fontSize: 15, color: Get.theme.disabledColor)),
          ],
        ),
      );
    }
    return super.buildWebView(c);
  }

  Widget _buildOnlineUser() {
    final uLen = controller.onlineUserNum;
    if (uLen == 0) return sizedBox;
    const avatarSize = 24.0;
    return GestureDetector(
      onTap: controller.showOnlinePopup,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (uLen > 0)
            RealtimeAvatar(
              userId: controller.onlineUserSet.first,
              size: avatarSize,
            ),
          if (uLen >= 2) ...[
            sizeWidth2,
            RealtimeAvatar(
              userId: controller.onlineUserSet.elementAt(1),
              size: avatarSize,
            ),
          ],
          if (uLen >= 3) ...[
            sizeWidth2,
            GestureDetector(
              child: Stack(
                children: [
                  RealtimeAvatar(
                    userId: controller.onlineUserSet.elementAt(2),
                    size: avatarSize,
                  ),
                  if (uLen >= 4)
                    Positioned.fill(
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.55),
                        ),
                        child: FittedBox(
                          child: Text(
                            '${min(uLen - 2, 99)}+',
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
