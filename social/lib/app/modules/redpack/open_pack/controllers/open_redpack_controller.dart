/*
 * @FilePath       : /social/lib/app/modules/redpack/open_pack/controllers/open_redpack_controller.dart
 * 
 * @Info           : 打开红包信息流控制器
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-01-05 16:30:32
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-01-25 19:06:47
 * 
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:im/api/redpack_api.dart';
import 'package:im/app/modules/redpack/open_pack/models/open_redpack_collected_info_model.dart';
import 'package:im/app/modules/redpack/open_pack/models/open_redpack_collected_item_model.dart';
import 'package:im/app/modules/redpack/open_pack/models/open_redpack_detail_model.dart';
import 'package:im/app/routes/app_pages.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/loggers.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class OpenRedPackController extends GetxController
    with GetSingleTickerProviderStateMixin {
  /// GetX特性：暴露控制器
  static OpenRedPackController get to => Get.find<OpenRedPackController>();

  /// 页面刷新Key：红包头部封面
  static const String UPDATE_KEY_RED_PACK_HEADER = "update_key_red_pack_header";

  /// 上下文
  final BuildContext context;

  /// 页面上滑下拉加载控制器
  final RefreshController refreshController = RefreshController();

  /// 列表滚动控制器
  ScrollController scrollController = ScrollController();

  /// 红包详情数据
  final OpenRedPackDetailModel redPackDetail;

  /// 用来执行列表动画，但是不会改变_list的数据
  final GlobalKey<SliverAnimatedListState> listStateKey =
      GlobalKey<SliverAnimatedListState>();

  /// 头部红包高度
  double _redPackTopH = 0;

  double get redPackTopH => _redPackTopH;

  /// 头部红包高度
  double _redPackTopHStep = 0;

  double get redPackTopHStep => _redPackTopHStep;

  /// 构造函数
  OpenRedPackController({
    @required this.context,
    @required this.redPackDetail,
  }) : super();

  @override
  void onInit() {
    super.onInit();
    //  初始化红包高度:  顶部红包图片宽高比： 1500 × 448 ≈ 3.348
    _redPackTopH = Get.width / 3.3482;
  }

  @override
  void onReady() {
    super.onReady();
    //  - 旧的滑动距离
    double oldOffset = 0;
    //  滚动监听：
    //  - 1、只监听下拉滑动，不监听上拉滑动
    //  - 2、设置新老滚动值，获取旧值与新值的差，即红包头部的步进值
    //  - 3、在列表下拉过程中：判断步进值是大于0或小于0去判断是否做正向或者反向滚动；
    scrollController.addListener(() async {
      final double newOffset = scrollController.offset;
      //  --
      if (newOffset > 0) {
        oldOffset = 0;
        _redPackTopHStep = 0;
      }
      //  -- 正向实时计算红包封面高度
      else {
        final double step = newOffset.abs() - oldOffset;
        double currentValue = _redPackTopHStep;
        currentValue += step;
        oldOffset = newOffset.abs();
        if (currentValue < 0) {
          oldOffset = 0;
          currentValue = 0;
        }
        _redPackTopHStep = currentValue;
      }
      update([UPDATE_KEY_RED_PACK_HEADER]);
    });
    //  执行用户列表item动画
    //  - 遍历 红包信息， 领取信息 和 已领取用户列表
    for (var i = 0; i < redPackDetail.detailList.length; i++) {
      //  -- 设置动画执行时间：如果不需要动画就设置为0
      //  -- (i * 50) 延迟每个视图展示时间
      final int animaTime = redPackDetail.isNeedAnimation ? 300 : 0;
      listStateKey.currentState
          .insertItem(i, duration: Duration(milliseconds: animaTime));
    }
  }

  @override
  void onClose() {
    super.onClose();
  }

  // ====== Method - Self : Public ====== //

  /// 加载更多数据
  Future<void> loadMoreCollectedItem() async {
    //  1、如果没有更多页就不请求数据了
    if (!redPackDetail.hadNextPage) {
      refreshController.loadNoData();
      return;
    }
    //  2、如果为true，就查询更多
    //   - 2.1、获取已领取红包用户列表
    final OpenRedPackCollectedInfoModel collectedInfo =
        await RedPackAPI.getOpenRedPackRecord(
            redPackDetail.redPackId, redPackDetail.lastRedPackId);
    //  - 接口异常只刷新页面
    if (collectedInfo == null) {
      refreshController.loadComplete();
      return;
    }
    //  - 2.2、保存最新数据
    redPackDetail.detailStatus = collectedInfo.status;
    redPackDetail.maxCollectNum = collectedInfo.totalNum;
    redPackDetail.lastRedPackId = collectedInfo.lastRedPackId;
    redPackDetail.hadCollectedNum = collectedInfo.hadCollectedNum;
    redPackDetail.hadCollectedAmount = collectedInfo.hadCollectedAmount;
    //  - 2.3、如果小于30条就一定没有数据（后端说的）
    redPackDetail.hadNextPage = collectedInfo.items.length == 30;
    //  - 2.4、添加新数据
    final int oldListLength = redPackDetail.detailList.length;
    for (var i = 0; i < collectedInfo.items.length; i++) {
      redPackDetail.detailList.add(collectedInfo.items[i]);
      listStateKey.currentState
          .insertItem(oldListLength + i, duration: Duration.zero);
    }
    //  - 3、设置完成后加载
    refreshController.loadComplete();
  }

  // ====== Method - Self : Static ====== //

  /// 数据请求：获取已领取红包用户列表
  ///
  /// - detail: 红包详情数据
  /// - isNeedLoading: 是否需要Loading;如果为true就展示loading并可以执行跳转至红包详情页，为false时，不展示loading也不跳转
  ///
  static Future<OpenRedPackDetailModel> requestRedPackDetail(
      BuildContext context, OpenRedPackDetailModel detail,
      {bool isNeedLoading = true}) async {
    if (isNeedLoading) {
      Loading.show(context);
    }
    //  1、获取已领取红包用户列表
    final OpenRedPackCollectedInfoModel collectedInfo =
        await RedPackAPI.getOpenRedPackRecord(detail.redPackId, "0")
            .onError((error, stackTrace) {
          logger.warning("requestRedPackDetail - ${#line}: $error \n $stackTrace");
      return null;
    });
    //  2、如果数据为空就不执行任何操作，如果不为空就要展示用户并实现展示动画
    if (collectedInfo == null) {
      Loading.hide();
      return null;
    }
    //  3、更新红包信息
    detail.collectedMoney = collectedInfo.collectedMoney;
    detail.detailStatus = collectedInfo.status;
    detail.maxCollectNum = collectedInfo.totalNum;
    detail.hadCollectedNum = collectedInfo.hadCollectedNum;
    detail.hadCollectedAmount = collectedInfo.hadCollectedAmount;
    detail.lastRedPackId = collectedInfo.lastRedPackId;
    detail.hadNextPage = collectedInfo.items.length == 30;
    //  4、设置红包展示i信息：
    //  - 4.1、index=0,用于显示红包详情
    detail.detailList = [OpenRedPackCollectedItemModel(money: '0')];
    //  - 仅群红包展示领取信息和用户
    if (!detail.isDmRedPack) {
      //  - 4.1、index=1,用于显示领取信息
      detail.detailList.add(OpenRedPackCollectedItemModel(money: '0'));
      //  - 4.2、添加领取红包用户列表
      detail.detailList.addAll(collectedInfo.items);
    }
    if (isNeedLoading) {
      Loading.hide();
      //  避免快速点击页面的时候出现复用旧控制器
      if (Get.isRegistered<OpenRedPackController>()) {
        await Get.delete<OpenRedPackController>();
      }
      // 数据处理完成后前往红包详情页面
      await Get.toNamed(Routes.OPEN_RED_PACK, arguments: detail);
    }
    return detail;
  }
}
