import 'dart:convert';

import 'package:im/dlog/dao/dlog_db.dart';
import 'package:im/dlog/model/dlog_report_model.dart';
import 'package:sqflite/sqflite.dart';

import '../../loggers.dart';

class DLogTable {
  static const tableName = "fb_dlog_event_report_table";
  static const kColumnID = "id";
  static const kColumnDlogContentID = "dlog_content_id";
  static const kColumnDlogItemStatus = "dlog_item_status";
  static const kColumnDlogContent = "dlog_content";

  /// 创建据库表
  static Future<void> createTable(Database db) async {
    try {
      await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName ($kColumnID INTEGER PRIMARY KEY AUTOINCREMENT,
        $kColumnDlogItemStatus TEXT NOT NULL,
        $kColumnDlogContentID TEXT UNIQUE,
        $kColumnDlogContent NOT NULL
        )
      ''');
    } catch (e) {
      logger.warning(e);
    }
  }

  /// 插入数据
  static Future<void> append(DLogReportModel model,
      {ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace}) async {
    try {
      if (model == null ||
          model.dlogContent == null ||
          model.dlogContentID == null) {
        return;
      }
      await DLogDb.open();
      await DLogDb.db.insert(
          tableName,
          {
            kColumnDlogContentID: model.dlogContentID,
            kColumnDlogContent: model.dlogContent,
            kColumnDlogItemStatus: '0'
          },
          conflictAlgorithm: conflictAlgorithm);
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

      await DLogDb.open();

      await DLogDb.db.delete(tableName,
          where: '$kColumnDlogContentID = ?', whereArgs: [model.dlogContentID]);
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

      await DLogDb.open();

      final dlogBatch = DLogDb.db.batch();

      for (final m in list) {
        dlogBatch.delete(tableName,
            where: '$kColumnDlogContentID = ?', whereArgs: [m.dlogContentID]);
      }

      await dlogBatch.commit(continueOnError: true);
    } catch (e) {
      logger.warning(e);
    }
  }

  /// 根据条数查询数据
  static Future<List<DLogReportModel>> queryCacheWithCount(int count) async {
    try {
      await DLogDb.open();
      // await DLogDb.db.query(tableName, orderBy: kColumnID, limit: 20);
      final List<Map<String, dynamic>> listData = await DLogDb.db.rawQuery(
          'SELECT * FROM $tableName ORDER BY $kColumnID ASC limit 0, $count');

      if (listData == null || listData.isEmpty) {
        return [];
      }

      final List<DLogReportModel> list = [];
      for (final Map m in listData) {
        final String dlogContentID = m[kColumnDlogContentID] ?? '';
        final String dlogContent = m[kColumnDlogContent] ?? '';
        final int seqID = m[kColumnID] ?? 0;
        final DLogReportModel model = DLogReportModel(
            dlogContentID: dlogContentID,
            dlogContent: dlogContent,
            seqID: seqID.toString());
        if (model.dlogContent != null) {
          final Map map = jsonDecode(model.dlogContent);
          map['seq_id'] = model.seqID ?? '';
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
      await DLogDb.open();
      final listData =
          await DLogDb.db.rawQuery('SELECT COUNT (*) FROM $tableName');

      if (listData.length == null || listData.isEmpty) {
        return 0;
      }
      return listData?.first['COUNT (*)'] ?? 0;
    } catch (e) {
      logger.warning(e);
      return 0;
    }
  }
}
