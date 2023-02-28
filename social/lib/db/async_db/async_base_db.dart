import 'package:sqflite/sqflite.dart';

import 'db_dev_log.dart';
// import 'package:sqlite3/sqlite3.dart';

///读取数据库的调用原始类类，更换数据库需要再这里更改
class AsyBaseDB {
  Database _sql3Db;

  static Future<AsyBaseDB> open(String path) async {
    final db = AsyBaseDB();
    AsyDevLog.asyPrint("打开数据库:$path");
    db._sql3Db = await openDatabase(path);
    return db;
  }

  Future execute(String sql, [List<Object> parameters = const []]) async {
    return _sql3Db.execute(sql, parameters);
  }

  Future<List<Map<String, Object>>> select(String sql,
      [List<Object> parameters]) {
    final result = _sql3Db.rawQuery(sql, parameters);
    return result;
  }

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action,
      {bool exclusive}) {
    return _sql3Db.transaction(action, exclusive: exclusive);
  }

  Future<int> getVersion() {
    return _sql3Db.getVersion();
  }

  Future<void> close() async {
    await _sql3Db.close();
  }
}
