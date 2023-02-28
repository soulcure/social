import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:im/common/extension/list_extension.dart';
import 'package:im/dlog/model/dlog_report_model.dart';

import '../../loggers.dart';

class DLogNonMobileDB {
  static Box<DLogReportModel> dLogReportBox;

  static const dLogBoxName = "DLogReportBox";

  static Future<void> open() async {
    if (Hive.isBoxOpen(dLogBoxName)) {
      return;
    }
    dLogReportBox = await Hive.openBox<DLogReportModel>(dLogBoxName);
  }

  /// 插入数据
  static Future<void> append(
    DLogReportModel model,
  ) async {
    try {
      if (model == null ||
          model.dlogContent == null ||
          model.dlogContentID == null) {
        return;
      }
      await DLogNonMobileDB.open();
      await dLogReportBox.add(model);
    } catch (e) {
      logger.warning(e);
    }
  }

  /// 删除
  static Future<void> delete(DLogReportModel model) async {
    try {
      if (model == null) {
        return;
      }

      await DLogNonMobileDB.open();

      final index = dLogReportBox.values.toList().indexWhere(
          (element) => element.dlogContentID == model.dlogContentID);
      await dLogReportBox.deleteAt(index);
    } catch (e) {
      logger.warning(e);
    }
  }

  /// 批量删除
  static Future<void> deleteAll(List<DLogReportModel> list) async {
    try {
      if (list == null || list.isEmpty) {
        return;
      }

      await DLogNonMobileDB.open();

      final values = dLogReportBox.values.toList();
      final keys = [];
      for (final m in list) {
        final index = values
            .indexWhere((element) => element.dlogContentID == m.dlogContentID);
        final key = dLogReportBox.keyAt(index);
        keys.add(key);
      }

      /// 根据查询的key集合批量删除数据
      await dLogReportBox.deleteAll(keys);
    } catch (e) {
      logger.warning(e);
    }
  }

  /// 根据条数查询数据
  static Future<List<DLogReportModel>> queryCacheWithCount(int count) async {
    try {
      await DLogNonMobileDB.open();
      final List<DLogReportModel> listData = dLogReportBox.values.toList();

      if (listData == null || listData.isEmpty) {
        return [];
      }

      final List<DLogReportModel> list = [];

      for (int i = 0; i < listData.length; i++) {
        /// 超出指定条数就跳出循环
        if (i >= count) break;
        final key = dLogReportBox.keyAt(i);

        final DLogReportModel m = listData[i];
        final String dLogContentID = m.dlogContentID ?? '';
        final String dLogContent = m.dlogContent ?? '';
        final String seqID = key?.toString() ?? '';
        final DLogReportModel model = DLogReportModel(
            dlogContentID: dLogContentID,
            dlogContent: dLogContent,
            seqID: seqID);
        if (model.dlogContent != null) {
          final Map map = jsonDecode(model.dlogContent);
          map['seq_id'] = model?.seqID ?? '';
          model.dlogContent = jsonEncode(map);
          list.add(model);
        }
      }
      return list;
    } catch (e) {
      logger.warning(e);
      return [];
    }
  }

  /// 根据条数查询数据
  static Future<int> queryCacheCount() async {
    try {
      await DLogNonMobileDB.open();
      final listData = dLogReportBox.values.toList();

      if (listData.noValue) {
        return 0;
      }
      return listData?.length ?? 0;
    } catch (e) {
      logger.warning(e);
      return 0;
    }
  }
}
