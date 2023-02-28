import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:im/common/extension/list_extension.dart';
import 'package:im/dlog/business/dlog_cache_data_manager.dart';
import 'package:im/dlog/model/dlog_report_model.dart';
import 'package:im/dlog/service/dlog_analysis_service.dart';
import 'package:im/services/connectivity_service.dart';
import 'package:pedantic/pedantic.dart';

import '../../loggers.dart';

/// 数据上报状态
enum FBReportState {
  /// 正常上报
  FBReportNormal,

  /// 正在上报
  FBReporting,

  /// 上报失败
  FBReportFail,
}

class DLogReportDataManager {
  /// 状态
  FBReportState reportState;

  static final DLogReportDataManager instance = DLogReportDataManager._();

  /// 计时器
  Timer timer;

  /// 标记计时器是否挂起
  bool isSuspend = false;

  /// 每次上报指定条数数据
  int reportCount = 100;

  /// 缓存中的数据条数
  int cacheDataCount = 0;

  DLogReportDataManager._() {
    isSuspend = true;

    /// 网络发生变化时,进行通知
    Get.find<ConnectivityService>().onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.none) {
        return;
      }

      /// 网络发生了变化
      networkStateChange();
    });
  }

  /// 开启定时器检测数据服务
  Future<void> startService() async {
    wakeTimer();

    final queryCacheCount = await DLogCacheDataManager.queryCacheCount();
    cacheDataCount += queryCacheCount;
    // 初始化时,立即触发一次上报
    unawaited(reportData());
  }

  /// 添加新的数据
  Future<void> addReportData(DLogReportModel model) async {
    try {
      if (model == null) return;

      /// 向数据库添加缓存数据
      await DLogCacheDataManager.addCacheData(model);

      cacheDataCount++;
      if (cacheDataCount >= reportCount) {
        unawaited(reportData());
        debugPrint('数据上报: 已满指定上报条数');
      }

      /// 一旦有数据进来就唤醒计时器
      wakeTimer();
    } catch (e) {
      logger.warning(e);
    }
  }

  /// 唤醒计时器
  void wakeTimer() {
    if (isSuspend) {
      timer ??= Timer.periodic(const Duration(seconds: 60), (timer) {
        /// 开始上报
        reportData();
      });

      isSuspend = false;
    }
  }

  /// 休眠计时器
  void sleepTimer() {
    if (!isSuspend) {
      if (timer != null) {
        timer?.cancel();
        timer = null;
      }
      isSuspend = true;
    }
  }

  /// 进行数据上报
  Future<void> reportData() async {
    try {
      /// 休眠计时器
      sleepTimer();

      /// 当前数据是否在上报中,如果是不做任何处理,等待下次
      if (reportState == FBReportState.FBReporting) {
        debugPrint('数据上报: 缓存数据上报中...');
        return;
      }

      /// 标记状态为上报中
      reportState = FBReportState.FBReporting;

      /// 从数据库读取n条上报数据
      final uploadDataList =
          await DLogCacheDataManager.queryCacheWithCount(reportCount);

      /// 数据为空时,不做上报操作.只恢复数据上报状态
      if (uploadDataList.noValue) {
        reportState = FBReportState.FBReportNormal;
        debugPrint('数据上报: 数据库没有缓存数据了');
        return;
      }

      debugPrint('数据上报: 向后台上报数据条数: ${uploadDataList.length}');

      /// 发起网络请求上报数据
      await DLogAnalysisService.getInstance().request(uploadDataList);

      /// 上报成功删除缓存数据
      await DLogCacheDataManager.deleteCacheDataWithList(uploadDataList);

      /// 恢复上报状态
      reportState = FBReportState.FBReportNormal;

      cacheDataCount -= uploadDataList.length;
      if (cacheDataCount < 0) cacheDataCount = 0;

      /// 本次上报不满指定条数,说明当前数据库已经拿完数据了,不做递归上报操作
      if (uploadDataList.length < reportCount) {
        /// 数据上报完后,尝试着唤醒计时器再查一次数据是否上报完
        debugPrint('数据上报: 缓存数据全部上报完毕,尝试唤醒计时器检查一次');
        wakeTimer();
        return;
      }
      await reportData();
    } catch (e) {
      /// 上报失败
      reportState = FBReportState.FBReportFail;
      final connectivityResult = await Connectivity().checkConnectivity();

      /// 如果当前网络状态是有网,就进行唤醒计时器检测服务
      if (connectivityResult != ConnectivityResult.none) {
        /// 上传失败
        wakeTimer();
      }
      logger.warning(e);
    }
  }

  /// 网络发生变化,进行策略性数据上报
  /// 当前数据为上报失败状态时,网络发生变化就进行上报
  void networkStateChange() {
    if (reportState == FBReportState.FBReportFail) wakeTimer();
  }
}
