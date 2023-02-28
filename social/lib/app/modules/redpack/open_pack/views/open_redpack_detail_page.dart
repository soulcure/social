/*
 * @FilePath       : /social/lib/app/modules/redpack/open_pack/views/open_redpack_detail_page.dart
 * 
 * @Info           : 打开红包详情页面，提供展示弹窗
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-01-05 16:30:32
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-03-11 16:57:56
 * 
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/redpack/open_pack/controllers/open_redpack_controller.dart';
import 'package:im/app/modules/redpack/open_pack/models/open_redpack_collected_item_model.dart';
import 'package:im/app/modules/redpack/open_pack/models/open_redpack_detail_model.dart';
import 'package:im/app/theme/app_colors.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

// ignore: must_be_immutable
class OpenRedPackDetailPage extends GetView<OpenRedPackController> {
  /// 构造函数
  const OpenRedPackDetailPage({Key key}) : super(key: key);

  /// 构造函数
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<OpenRedPackController>(
        tag: tag,
        builder: (controller) => Container(
          color: Get.theme.backgroundColor,
          child: Stack(
            children: [
              /// 头部信息优化
              GetBuilder<OpenRedPackController>(
                id: OpenRedPackController.UPDATE_KEY_RED_PACK_HEADER,
                builder: (controller) => Container(
                  height: controller.redPackTopH + controller.redPackTopHStep,
                  color: Get.theme.backgroundColor,
                  child: Stack(children: [
                    Container(
                      height: controller.redPackTopHStep,
                      color: redTextColor,
                    ),
                    //  红包背景图(1500 × 448 ~ 3.348)
                    Positioned(
                        left: 0,
                        right: 0,
                        bottom: 3,
                        child: Image.asset(
                          "assets/images/red_pack_detail_header.png",
                          fit: BoxFit.fill,
                        )),
                  ]),
                ),
              ),
              //  设置标题栏，
              const FbAppBar.custom(
                "",
                setLeadingIconWhite: true,
                backgroundColor: Colors.transparent,
              ),
              //  红包详情和领取用户信息
              Container(
                width: double.infinity,
                height: double.infinity,
                margin: EdgeInsets.only(top: controller.redPackTopH - 3),
                child: SmartRefresher(
                    enablePullDown: false,
                    enablePullUp: true,
                    controller: controller.refreshController,
                    onLoading: controller.loadMoreCollectedItem,
                    footer: CustomFooter(
                      builder: (context, mode) => mode == LoadStatus.loading
                          ? const CupertinoActivityIndicator.partiallyRevealed(
                              radius: 8)
                          : sizedBox,
                    ),
                    child: CustomScrollView(
                        controller: controller.scrollController,
                        //  强行实现苹果风格的列表样式
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverAnimatedList(
                            key: controller.listStateKey,
                            itemBuilder: (context, index, animation) =>
                                _assembleListItem(index, animation),
                          ),
                        ])),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====== Method - Self: Private ====== //

  /// 组装视图： 列表item
  Widget _assembleListItem(int index, Animation<double> animation) {
    switch (index) {
      //  红包详情图
      case 0:
        return _assembleHeader(animation);
      //  如果不是私信红包就展示：领取红包用户及相关信息
      case 1:
        return _assembleCollectedInfo(animation);
      default:
        return _assembleCollectedItem(
            controller.redPackDetail.detailList[index], animation);
    }
  }

  /// 组装视图：成员红包 - 头部视图
  Widget _assembleHeader(Animation<double> animation) {
    return Container(
        margin: const EdgeInsets.only(left: 20, top: 24, right: 20),
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.5, end: 1).animate(animation),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              //  - 用户信息
              _assembleHeaderUserInfo(),
              const SizedBox(
                height: 12,
              ),
              // - 红包备注
              Text(controller.redPackDetail.remark,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: appThemeData.textTheme.headline2.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  )),
              // - 红包金额和存入支付宝余额
              _assembleHeaderCollectStatus(),
            ],
          ),
        ));
  }

  /// 组装视图 - 头部子视图：用户信息
  Widget _assembleHeaderUserInfo() => //  - 用户信息
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          RealtimeAvatar(
            userId: controller.redPackDetail.userId,
            size: 24,
          ),
          const SizedBox(
            width: 8,
          ),
          Flexible(
              child: Text(
            "%s 发出的红包".trArgs([controller.redPackDetail.userName]),
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Get.textTheme.bodyText2.color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          )),
          const SizedBox(
            width: 6,
          ),
          if (controller.redPackDetail.isLuckRedPack) ...[
            const Icon(
              IconFont.buffIconPing,
              size: 20,
              color: goldLuckColor,
            ),
          ]
        ],
      );

  /// 组装视图 - 头部子视图：红包领取状态金额以及领取说明
  Widget _assembleHeaderCollectStatus() {
    //  是否展示金额
    bool isShowMoney = true;
    //  默认红包状态说明
    String statusText = "已存入支付宝余额".tr;
    //  - 私信红包：展示金额和说明
    if (controller.redPackDetail.isDmRedPack) {
      isShowMoney = true;
      //  展示逻辑：
      //  - 1、如果是自己的红包就展示对方领取状态
      //  - 2、如果是别人发的红包就展示默认状态说明
      statusText = controller.redPackDetail.isOwner
          ? (controller.redPackDetail.detailStatus ==
                  RedPackDetailStatus.HAD_BEEN_COLLECTED
              ? "对方已领取".tr
              : "等待对方领取".tr)
          : statusText;
      //  - 其它红包：新红包或者已领取需要展示金额，其它就只展示领取说明
    }
    //  群红包只有抢到了才展示金额(异常下的时候如果为0也展示)
    else {
      //  展示金额条件：抢到金额就展示，没抢到就不展示
      isShowMoney = double.parse(controller.redPackDetail.collectedMoney) > 0;
      //  不展示金额下的判断：
      //  - 1、status为2或3展示相应文字
      //  - 2、其它情况不显示文字
      if (!isShowMoney) {
        statusText = controller.redPackDetail.detailStatus ==
                RedPackDetailStatus.OVER_DATE
            ? "红包已过期".tr
            : controller.redPackDetail.detailStatus ==
                    RedPackDetailStatus.HAD_BEEN_COLLECTED
                ? "红包已领完".tr
                : "";
      }
    }
    return Container(
      color: Get.theme.backgroundColor,
      margin: const EdgeInsets.only(left: 20, top: 24, right: 20, bottom: 32),
      child: Column(
        children: [
          /// 判断是否是私聊，私聊的话要展示
          if (isShowMoney) ...[
            Text.rich(
              TextSpan(
                // 金额说明：私信的时候只能发单个红包，所以红包的总金额就是领取的金额；如果不是私信红包就要根据抢红包接口或已领取用户列表（如果已抢到）获取展示的金额
                text: controller.redPackDetail.isDmRedPack
                    ? controller.redPackDetail.amount
                    : controller.redPackDetail.collectedMoney,
                style: const TextStyle(
                  color: goldDeepColor,
                  fontSize: 40,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: " ${"元".tr}",
                    style: const TextStyle(
                      color: goldDeepColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  )
                ].toList(),
              ),
            ),
            const SizedBox(
              height: 12,
            ),
          ],
          Text(
            statusText,
            style: TextStyle(
              color: goldDeepColor,
              fontSize: isShowMoney ? 14 : 16,
              fontWeight: isShowMoney ? FontWeight.w400 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 组装视图 - 领取用户列表: 领取信息
  Widget _assembleCollectedInfo(Animation<double> animation) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 15),
        end: const Offset(0, 0),
      ).animate(animation),
      child: Column(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Text(
              "已领取${controller.redPackDetail.hadCollectedNum}/${controller.redPackDetail.maxCollectNum}个, 共${controller.redPackDetail.hadCollectedAmount}/${controller.redPackDetail.amount}元",
              style: TextStyle(
                color: appThemeData.textTheme.headline2.color,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Container(
            height: 0.5,
            margin: const EdgeInsets.only(left: 20, bottom: 6),
            color: appThemeData.dividerColor.withOpacity(0.2),
          ),
        ],
      ));

  /// 组装视图：已领取红包列表视图
  Widget _assembleCollectedItem(
          OpenRedPackCollectedItemModel item, Animation<double> animation) =>
      SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 15),
            end: const Offset(0, 0),
          ).animate(animation),
          child: Container(
            height: 64,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                RealtimeAvatar(
                  userId: item.userId,
                  size: 40,
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: RealtimeNickname(
                              userId: item.userId,
                              style: TextStyle(
                                color: Get.textTheme.bodyText2.color,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          Text(
                            "${item.money}元",
                            style: TextStyle(
                              color: Get.textTheme.bodyText2.color,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              formatDate2Str(
                                  DateTime.fromMillisecondsSinceEpoch(
                                          item.collectTime * 1000)
                                      .toLocal()),
                              style: TextStyle(
                                color: appThemeData.textTheme.headline2.color,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          //  最佳手气：如果是拼手气红包以及是手气王才展示
                          if (controller.redPackDetail.isLuckRedPack &&
                              item.isLuckGay == 1)
                            ...[
                              const Icon(
                                IconFont.buffCircleLike2New,
                                color: redTextColor,
                                size: 12,
                              ),
                              const SizedBox(
                                width: 4,
                              ),
                              const Text(
                                "手气最佳",
                                style: TextStyle(
                                  color: redTextColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ].toList(),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ));
}
