import 'package:im/dlog/dao/dlog_non_mobile_db.dart';
import 'package:im/dlog/dao/dlog_table.dart';
import 'package:im/dlog/model/dlog_report_model.dart';
import 'package:im/utils/universal_platform.dart';

import '../../loggers.dart';

class DLogCacheDataManager {
  /// 添加缓存
  static Future<void> addCacheData(DLogReportModel model) async {
    try {
      if (model == null) return;
      if (UniversalPlatform.isMobileDevice) {
        await DLogTable.append(model);
      } else {
        await DLogNonMobileDB.append(model);
      }
    } catch (e) {
      logger.warning(e);
    }
  }

  /// 批量删除
  static Future<void> deleteCacheDataWithList(
      List<DLogReportModel> list) async {
    try {
      if (list == null || list.isEmpty) return;

      if (UniversalPlatform.isMobileDevice) {
        await DLogTable.deleteAll(list);
      } else {
        await DLogNonMobileDB.deleteAll(list);
      }
    } catch (e) {
      logger.warning(e);
    }
  }

  /// 根据条数查询
  static Future<List<DLogReportModel>> queryCacheWithCount(int count) async {
    try {
      if (UniversalPlatform.isMobileDevice) {
        return DLogTable.queryCacheWithCount(count);
      } else {
        return DLogNonMobileDB.queryCacheWithCount(count);
      }
    } catch (e) {
      logger.warning(e);
      return [];
    }
  }

  /// 查询数据条数
  static Future<int> queryCacheCount() async {
    try {
      if (UniversalPlatform.isMobileDevice) {
        return DLogTable.queryCacheCount();
      } else {
        return DLogNonMobileDB.queryCacheCount();
      }
    } catch (e) {
      logger.warning(e);
      return 0;
    }
  }
}
