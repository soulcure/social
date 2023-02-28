/*
 * @FilePath       : /social/lib/app/modules/wallet/views/wallet_home_page.dart
 * 
 * @Info           : 页面视图：钱包主页
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-04-07 16:08:18
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-05-13 19:47:47
 * 
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/wallet/controllers/wallet_collect_detail_controller.dart';
import 'package:im/app/modules/wallet/controllers/wallet_home_controller.dart';
import 'package:im/app/modules/wallet/models/wallet_collect_model.dart';
import 'package:im/app/modules/wallet/views/wallet_home_loading_view.dart';
import 'package:im/app/routes/app_pages.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/icon_font.dart';
import 'package:im/svg_icons.dart';
import 'package:im/themes/const.dart';
import 'package:im/web/pages/service/container_image.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/fb_ui_kit/button/button_builder.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/svg_tip_widget.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';

class WalletHomePage extends GetView<WalletHomeController> {
  @override
  Widget build(BuildContext context) => GetBuilder(
        init: controller,
        builder: (controller) {
          //  背景颜色
          final Color backgroundColor = getBackGroundColor(controller);
          return Scaffold(
            backgroundColor: backgroundColor,
            appBar: FbAppBar.custom(
              "数字藏品".tr,
              backgroundColor: backgroundColor,
            ),
            //  场景流转流程：
            //  - 1、判断是否是中国区域的手机号码，如果是就直接展示“仅限年满18周岁....”提示视图，否则执行步骤2
            //  - 2、查看是否isStartRequest = true,如果是就展示loading视图,isStartRequest = false,执行步骤3
            //  - 3、判断wallet是否为空，如果为空展示“当前网络不可用”提示视图，不为空就展示钱包信息
            body: !controller.isChineseMobile
                ? _assembleTipsView("仅限实名认证为年满18周岁的中国大陆用户使用".tr)
                : controller.isStartRequest
                    ? WalletHomeLoadingView()
                    : controller.wallet == null
                        ? _assembleErrorNetView()
                        : controller.isVerified
                            ? Column(
                                children: [
                                  _assembleUserInfo(),
                                  Expanded(
                                    child: _assembleCollectView(),
                                  ),
                                ],
                              )
                            : _assembleVerifyView(),
          );
        },
      );

  /// 组装视图：通用提示视图
  Widget _assembleTipsView(String tips) => Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: appThemeData.scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                IconFont.buffDaoFlag,
                color: const Color(0xFF1F2125).withOpacity(0.4),
                size: 48,
              ),
            ),
            sizeHeight24,
            SizedBox(
              width: 154,
              child: Text(
                tips,
                style: appThemeData.textTheme.caption,
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ],
        ),
      );

  /// 组转视图：网络异常展示视图
  Widget _assembleErrorNetView() => Container(
        margin: const EdgeInsets.only(top: 200),
        alignment: Alignment.topCenter,
        child: SvgTipWidget(
          svgName: SvgIcons.noNetState,
          textSize: 17,
          text: '当前网络不可用'.tr,
          desc: '当前网络不佳，请勿拍打设备\n检查你的网络设置'.tr,
        ),
      );

  /// 组装视图：实名验证页面
  Widget _assembleVerifyView() => Container(
        color: Colors.white,
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            _assembleTipsView("完成实名认证后，可获取数字藏品信息".tr),
            const SizedBox(height: 48),
            FbButton.elevated("实名认证，展示数字藏品".tr,
                size: FbButtonSize.big,
                onPressed: () =>
                    Get.toNamed(Routes.WALLET_VERIFIED_PAGE).then((value) {
                      if (value == null || value == false) {
                        return;
                      }
                      controller.updateWallet();
                    })),
          ],
        ),
      );

  /// 组装视图：用户信息
  Widget _assembleUserInfo() => Container(
        width: double.infinity,
        height: 104,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            RealtimeAvatar(
              userId: controller.userId,
              size: 64,
            ),
            sizeWidth12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.userName,
                    style: appThemeData.textTheme.bodyText1
                        .copyWith(fontSize: 17, fontWeight: FontWeight.w500),
                  ),
                  if (controller.isOwnWallet) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "数字地址：%s"
                                .trArgs([controller.wallet.address]).breakWord,
                            style: appThemeData.textTheme.caption.copyWith(
                              fontSize: 13,
                              height: 1.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (controller.wallet.address.isNotEmpty) ...[
                          GestureDetector(
                            onTap: () async {
                              await Clipboard.setData(ClipboardData(
                                  text: controller.wallet.address));
                              showToast("复制成功".tr);
                            },
                            child: Container(
                              color: Colors.transparent,
                              padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
                              child: Icon(
                                IconFont.buffChatCopy,
                                size: 16,
                                color: appThemeData.iconTheme.color,
                              ),
                            ),
                          ),
                        ],
                      ],
                    )
                  ],
                ],
              ),
            )
          ],
        ),
      );

  /// 组装视图：藏品展示
  Widget _assembleCollectView() => Container(
        color: Colors.white,
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(16),
        child: controller.wallet.collects.isEmpty
            ? _assembleTipsView(
                "暂无数字藏品".tr,
              )
            : Column(
                children: [
                  _assembleCollectCategory(),
                  const SizedBox(
                    height: 11,
                  ),
                  Expanded(
                    child: _assembleCollectGridView(),
                  ),
                ],
              ),
      );

  /// 组装视图：藏品 - 类别
  Widget _assembleCollectCategory() => Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: appThemeData.primaryColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              IconFont.buffDaoFlag,
              color: Colors.white,
              size: 13,
            ),
          ),
          sizeWidth8,
          Text(
            "数字藏品（%s）".trArgs([controller.wallet.collectTotal]),
            style: appThemeData.textTheme.caption.copyWith(
              fontSize: 13,
              height: 1.25,
            ),
          ),
        ],
      );

  /// 组装视图：藏品 - 藏品列表容器
  Widget _assembleCollectGridView() => GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemCount: controller.wallet.collects.length,
        itemBuilder: (context, index) =>
            _assembleCollectGridItem(controller.wallet.collects[index]),
      );

  /// 组装视图：藏品 - 藏品列表容器 - item
  Widget _assembleCollectGridItem(WalletCollectModel collect) =>
      GestureDetector(
        onTap: () async {
          //  控制器无法真实被销毁（经常出现， Why？）
          if (Get.isRegistered<WalletCollectDetailController>()) {
            await Get.delete<WalletCollectDetailController>();
          }
          unawaited(Get.toNamed(Routes.WALLET_COLLECT_DETAIL_PAGE,
              arguments: collect));
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            border: Border.all(
                color: appThemeData.dividerColor.withOpacity(0.2), width: 0.5),
          ),
          child: ContainerImage(
            collect.displayUrl,
            radius: 4,
            fit: BoxFit.fill,
          ),
        ),
      );

  /// 行为：获取背景颜色
  Color getBackGroundColor(WalletHomeController controller) =>
      (!controller.isChineseMobile ||
              (controller.wallet != null && !controller.isVerified))
          ? Colors.white
          : appThemeData.scaffoldBackgroundColor;
}
