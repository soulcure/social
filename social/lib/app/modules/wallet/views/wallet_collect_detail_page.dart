// ignore_for_file: implementation_imports
/*
 * @FilePath       : /social/lib/app/modules/wallet/views/wallet_collect_detail_page.dart
 * 
 * @Info           : 页面视图：钱包 - 藏品详情
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-04-07 17:35:38
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-06-01 15:33:16
 * 
 */
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/wallet/controllers/wallet_collect_detail_controller.dart';
import 'package:im/app/theme/app_colors.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/svg_icons.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/image_operator_collection/image_collection.dart';
import 'package:im/utils/image_operator_collection/image_widget.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/fb_ui_kit/button/button_builder.dart';
import 'package:im/widgets/fb_ui_kit/tag/tag_builder.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:oktoast/oktoast.dart';
import 'package:websafe_svg/websafe_svg.dart';

class WalletCollectDetailPage extends GetView<WalletCollectDetailController> {
  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white,
            alignment: Alignment.topCenter,
            child: WebsafeSvg.asset(
              SvgIcons.gradientWGW,
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
              width: Get.width,
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: const FbAppBar.custom(
              "",
              backgroundColor: Colors.transparent,
            ),
            body: GetBuilder(
              init: controller,
              builder: (controller) => SafeArea(
                bottom: controller.isOwn,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _assembleCollectView(),
                              sizeHeight12,
                              _assembleUserInfoCell(),
                              sizeHeight12,
                              _assembleCell(
                                child: _assembleTitleRow(
                                    title: "来自艺术家".tr,
                                    subTitle: controller.collect.author,
                                    maxWidth: double.infinity),
                              ),
                              sizeHeight12,
                              _assembleCell(
                                child: Column(
                                  children: [
                                    _assembleTitleWithArrowRow(
                                      title: "技术信息".tr,
                                      onTap: () => _showCollectInfoSheet(
                                        context,
                                        controller.collect.seriesId,
                                        controller.collect.hash,
                                        controller.collect.txHash,
                                        controller.collect.verifyDateStr,
                                      ),
                                    ),
                                    _assembleDivideRow(),
                                    _assembleTitleRow(
                                      title: "唯一编号".tr,
                                      subTitle: controller.collect.seriesId,
                                    ),
                                    _assembleDivideRow(),
                                    _assembleTitleRow(
                                      title: "作品 Hash".tr,
                                      subTitle: controller.collect.hash,
                                    ),
                                    _assembleDivideRow(),
                                    _assembleTitleRow(
                                      title: "交易 Hash".tr,
                                      subTitle: controller.collect.txHash,
                                    ),
                                    _assembleDivideRow(),
                                    _assembleTitleRow(
                                      title: "认证时间".tr,
                                      subTitle:
                                          controller.collect.verifyDateStr,
                                    ),
                                  ],
                                ),
                              ),
                              //  不是自己就没有按钮，需要设置底部边距
                              if (!controller.isOwn) const SizedBox(height: 48),
                            ],
                          ),
                        ),
                      ),
                      if (controller.isOwn)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: FbButton.outlined(
                            controller.isCanSetNftAvatar
                                ? "设为Fanbook头像".tr
                                : "取消设为Fanbook头像".tr,
                            size: FbButtonSize.free,
                            width: double.infinity,
                            primaryColor: controller.isCanSetNftAvatar
                                ? null
                                : redTextColor,
                            onPressed: () => _showChangeAvatarSheet(context),
                          ),
                        )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );

  /// 组装视图：藏品展示
  Widget _assembleCollectView() => Column(
        children: [
          sizeHeight32,
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                  color: appThemeData.dividerColor.withOpacity(0.2),
                  width: 0.5),
            ),
            child: ImageWidget.fromCachedNet(
              CachedImageBuilder(
                width: 240,
                height: 240,
                imageUrl: controller.collect.displayUrl,
                cacheManager: CustomCacheManager.instance,
              ),
            ),
          ),
          sizeHeight32,
          Text(
            "《${controller.collect.name}》",
            style: appThemeData.textTheme.bodyText1.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            "NO.%s".trArgs(
              ["${controller.collect.seriesIndex}"],
            ),
            style: appThemeData.textTheme.bodyText1.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
          ),
          sizeHeight32,
        ],
      );

  /// 组装视图：类表单容器
  Widget _assembleCell({Widget child}) => Container(
        decoration: BoxDecoration(
          color: appThemeData.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.all(Radius.circular(6)),
        ),
        child: child,
      );

  /// 组装视图：用户信息
  Widget _assembleUserInfoCell() => _assembleCell(
        child: SizedBox(
          height: 64,
          child: Row(children: [
            sizeWidth16,
            RealtimeAvatar(
              userId: controller.collect.collectorId,
              size: 40,
            ),
            sizeWidth8,
            Text(
              controller.collect.collectorName,
              style: appThemeData.textTheme.bodyText1.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            sizeWidth8,
            FbTag.label(
              "拥有者",
              primaryColor: appThemeData.primaryColor,
            ),
            sizeWidth16,
          ]),
        ),
      );

  /// 组装视图：标题 - 子标题
  Widget _assembleTitleRow({
    String title,
    String subTitle,
    double maxWidth = 127,
  }) =>
      SizedBox(
        height: 48,
        child: Row(
          children: [
            sizeWidth16,
            Expanded(
              flex: 0,
              child: Text(
                title,
                style: appThemeData.textTheme.bodyText1.copyWith(
                  fontSize: 14,
                  height: 1.2,
                ),
              ),
            ),
            sizeWidth8,
            Expanded(
              child: Container(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: maxWidth,
                  child: Text(
                    subTitle,
                    textAlign: TextAlign.right,
                    style: appThemeData.textTheme.headline2.copyWith(
                      fontSize: 14,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            sizeWidth16,
          ],
        ),
      );

  /// 组装视图：标题 - 箭头
  Widget _assembleTitleWithArrowRow({String title, Function onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: appThemeData.textTheme.bodyText1.copyWith(
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
              ),
              Icon(
                IconFont.buffPayArrowNext,
                color: appThemeData.textTheme.headline2.color.withOpacity(0.4),
                size: 16,
              ),
            ],
          ),
        ),
      );

  /// 组装视图：分割线
  Widget _assembleDivideRow({bool isNeedMargin = true}) => Container(
        height: 1,
        color: appThemeData.dividerColor,
        margin: EdgeInsets.only(
          left: isNeedMargin ? sizeWidth16.width : 0,
        ),
      );

  /// 组装视图：Sheet - 信息栏
  Widget _assembleCollectInfoSheetCell({
    String title,
    String subTitle,
    String content,
    bool isNeedCopy = true,
    bool isNeedDivide = true,
  }) =>
      Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: sizeWidth16.width),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sizeHeight16,
            Text(
              title,
              style: appThemeData.textTheme.bodyText2.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            sizeHeight12,
            Text(
              subTitle,
              style: appThemeData.textTheme.headline2.copyWith(
                fontSize: 13,
              ),
            ),
            sizeHeight12,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    content,
                    style: appThemeData.textTheme.headline2.copyWith(
                      fontSize: 13,
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isNeedCopy)
                  GestureDetector(
                    onTap: () async {
                      //  如果参数不为空就执行复制
                      if (content.isEmpty) {
                        return;
                      }
                      await Clipboard.setData(ClipboardData(text: content));
                      showToast("复制成功".tr);
                    },
                    child: Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.only(left: 12),
                      child: Icon(
                        IconFont.buffChatCopy,
                        color: appThemeData.textTheme.headline2.color,
                        size: 16,
                      ),
                    ),
                  )
              ],
            ),
            sizeHeight16,
            if (isNeedDivide) _assembleDivideRow(isNeedMargin: false),
          ],
        ),
      );

  /// 组装视图：Sheet - 点
  Widget _assembleDotView({double withOpacity = 1}) => Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: appThemeData.dividerColor.withOpacity(withOpacity),
        shape: BoxShape.circle,
      ));

  /// 组装视图：Sheet - 藏品头像
  Widget _assembleNFTAvatar(String avatarUrl) => Stack(
        alignment: Alignment.center,
        children: [
          Avatar(
            url: avatarUrl,
            radius: 35,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: appThemeData.primaryColor,
                border: Border.all(color: Colors.white, width: 2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                IconFont.buffDaoFlag,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );

  /// 展示弹窗：藏品信息Sheet
  void _showCollectInfoSheet(
    BuildContext context,
    String seriesId,
    String hash,
    String txHash,
    String verifyDateStr,
  ) =>
      showBottomModal(
        context,
        bottomInset: false,
        headerBuilder: (context, state) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                "技术信息".tr,
                style: appThemeData.textTheme.bodyText2.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Positioned(
                right: sizeWidth16.width,
                child: GestureDetector(
                  onTap: Get.back,
                  child: Icon(
                    IconFont.buffNavBarCloseItem,
                    color: appThemeData.textTheme.bodyText2.color,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        builder: (context, state) => Container(
          color: Colors.white,
          child: Column(
            children: [
              _assembleCollectInfoSheetCell(
                title: "唯一编号".tr,
                subTitle: "该数字藏品唯一的身份标识".tr,
                content: seriesId,
              ),
              _assembleCollectInfoSheetCell(
                title: "作品 Hash".tr,
                subTitle: "链上作品的数字存证".tr,
                content: hash,
              ),
              _assembleCollectInfoSheetCell(
                title: "交易 Hash".tr,
                subTitle: "此次交易行为的数字存证".tr,
                content: txHash,
              ),
              _assembleCollectInfoSheetCell(
                title: "认证时间".tr,
                subTitle: "作品上链的时间".tr,
                content: verifyDateStr,
                isNeedCopy: false,
                isNeedDivide: false,
              ),
              sizeHeight32,
            ],
          ),
        ),
      );

  /// 展示弹窗：修改头像Sheet
  Future<void> _showChangeAvatarSheet(BuildContext context) async {
    bool isConfirm = false;
    if (controller.isCanSetNftAvatar) {
      //  修改头像
      isConfirm = await showBottomModal(
        context,
        bottomInset: false,
        builder: (context, state) => SafeArea(
          top: false,
          child: Container(
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                sizeHeight32,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (Global.user.avatarNftId.isNotEmpty)
                      _assembleNFTAvatar(Global.user.avatarNft)
                    else
                      Avatar(
                        url: Global.user.avatar,
                        radius: 35,
                      ),
                    sizeWidth12,
                    _assembleDotView(withOpacity: 0.3),
                    sizeWidth4,
                    _assembleDotView(withOpacity: 0.6),
                    sizeWidth4,
                    _assembleDotView(),
                    sizeWidth12,
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Avatar(
                          url: controller.collect.displayUrl,
                          radius: 35,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: appThemeData.primaryColor,
                              border: Border.all(color: Colors.white, width: 2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              IconFont.buffDaoFlag,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                sizeHeight32,
                Text(
                  "确定将数字藏品设置为Fanbook头像吗？\n 替换后展示如上".tr,
                  textAlign: TextAlign.center,
                  style: appThemeData.textTheme.headline2.copyWith(
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                sizeHeight32,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FbButton.subElevated(
                      "取消",
                      size: FbButtonSize.free,
                      width: 130,
                      onPressed: () => Get.back(result: false),
                    ),
                    sizeWidth12,
                    FbButton.elevated(
                      "确定",
                      size: FbButtonSize.free,
                      width: 130,
                      onPressed: () => Get.back(result: true),
                    )
                  ],
                ),
                sizeHeight32,
              ],
            ),
          ),
        ),
      );
    } else {
      //  取消头像设置
      isConfirm = await showConfirmDialog(content: '确定取消设置吗？'.tr);
    }
    // 如果不是确定，就不执行更新操作
    if (!isConfirm) return;
    await controller.changeUserAvatar(context);
  }
}
