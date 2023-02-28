import 'dart:async';
import 'dart:io';

import 'package:im/db/async_db/async_write_db_utils.dart';
import 'package:sqflite/sqflite.dart';

import 'async_base_db.dart';
import 'async_insert_model.dart';
import 'db_dev_log.dart';

class AsyncDB {
  //单例
  static AsyncDB shared = AsyncDB();
  static final AsyncDB _instance = AsyncDB._internal();
  factory AsyncDB() => _instance;

  //读取的数据库连接对象
  AsyBaseDB baseDb;

  //储存的数据库地址
  String dbPath;

  //是否有写入任务
  var _isWriteLock = false;

  //自增的任务id
  var _autoTaskId = 1;

  //自增的权重值
  var _autoWeight = 2;

  static const String _insert = "insert";

  static const String _delete = "delete";

  static const String _update = "update";

  AsyncDB._internal() {
    init();
  }

  Future<void> init() async {}

  //打开相应路径的数据库
  Future<AsyncDB> openDataBase(String path) async {
    if (path != dbPath) {
      AsyDevLog.asyPrint("重开数据库");
      await baseDb?.close();
      baseDb = await AsyBaseDB.open(path);
      dbPath = path;
      await _isolateOpenDataBase();
    }
    return this;
  }

  //获取自增的任务id
  int getTaskId() {
    final i = _autoTaskId;
    _autoTaskId++;
    return i;
  }

  //获取自增的权重id
  int getWeight() {
    final i = _autoWeight;
    _autoWeight++;
    return i;
  }

  AsyBaseDB getSql3Db() {
    if (baseDb != null) {
      return baseDb;
    } else {
      throw "请先传入路径打开database";
    }
  }

  Future<AsyncDB> openAsDatabase(
    String path, {
    int version,
    OnDatabaseCreateFn onCreate,
    OnDatabaseVersionChangeFn onUpgrade,
  }) async {
    //查询是否是第一次创建数据库
    AsyDevLog.asyPrint("开始检查之前是否有数据库");
    final isExists = File(path).existsSync();
    final db = await openDataBase(path);
    const versionTableName = "AsyncVersion";
    const versionStr = "version";
    if (!isExists) {
      AsyDevLog.asyPrint("没有检测到数据库，开始调用创建的方法");
      if (onCreate != null) {
        await onCreate(db, version ?? 0);
      }
      AsyDevLog.asyPrint("创建好了数据库开始创建一个存版本号的表");
      //新的数据库创建好新建一个表添加版本号
      await db.execute("DROP TABLE IF EXISTS $versionTableName",
          isAsync: false);
      await db.execute('''
    CREATE TABLE $versionTableName (
      id INTEGER NOT NULL PRIMARY KEY,
      $versionStr INT NOT NULL
    );
  ''');
      AsyDevLog.asyPrint("检查到有数据库文件");
      AsyDevLog.asyPrint("插入版本号：$version");
      await getSql3Db().execute(
          "INSERT INTO $versionTableName ($versionStr) VALUES (${version ?? 0})");
    } else {
      if (version != null) {
        final sqfVersion = await getSql3Db().getVersion();
        if (sqfVersion != version) {
          bool needUpdate = false;
          int oVersion = 0;
          try {
            final List<Map<String, Object>> result = await getSql3Db()
                .select("SELECT * FROM $versionTableName where id = 1");
            final int oldVersion = result.first[versionStr];
            AsyDevLog.asyPrint("检测版本:老版本$oldVersion,新版本:$version");
            if (oldVersion > version) {
              throw "数据库版本异常：当前版本过高";
            }
            if (oldVersion < version && onUpgrade != null) {
              needUpdate = true;
              oVersion = oldVersion;
            }
          } catch (e) {
            if (sqfVersion > version) {
              throw "数据库版本异常：当前版本过高";
            }
            AsyDevLog.asyPrint("存在数据库但版本号没有被管理--${e.toString()}");
            //如果是老版本 并且用的sqfVersion数据库就使用自己的版本管理工具
            await db.execute("DROP TABLE IF EXISTS $versionTableName",
                isAsync: false);
            await getSql3Db().execute('''
                  CREATE TABLE $versionTableName (
                    id INTEGER NOT NULL PRIMARY KEY,
                    $versionStr INT NOT NULL
                  );
                ''');

            await getSql3Db().execute(
                "INSERT INTO $versionTableName ($versionStr) VALUES (${version ?? 0})");
            onUpgrade(db, sqfVersion, version);
          }
          if (needUpdate) {
            onUpgrade(db, oVersion, version);
            await getSql3Db().execute(
                "UPDATE $versionTableName SET $versionStr = ${version ?? 0} WHERE id = 1 ");
          }
        }
      }
    }
    return db;
  }

  ///同步查询(直接查询，快但是不被管理，尽量不要用)
  Future<List<Map<String, Object>>> syncSelect(String sql,
      [List<Object> parameters]) async {
    AsyDevLog.asyPrint("开始读取");

    var needContinue = false;
    if (shared._isWriteLock) {
      needContinue = true;
      AsyDevLog.asyPrint("读取:发现数据库被占用了，开始暂停其他线程的写入");
      await _pauseWrite();
      AsyDevLog.asyPrint("已解除占用,继续读取任务");
    }
    try {
      final res = await getSql3Db().select(sql, parameters ?? []);
      if (needContinue) {
        await _continueWrite();
      }
      AsyDevLog.asyPrint("读取完成：数量${res.length}");
      return res;
    } catch (e) {
      if (e.toString().contains("already-closed") ||
          e.toString().contains("no such table")) {
        AsyDevLog.asyPrint("数据库异常关闭$e");
        await baseDb.close();
        baseDb = await AsyBaseDB.open(dbPath);
        return Future.delayed(const Duration(milliseconds: 100), () {
          return select(sql, parameters: parameters);
        });
      } else {
        AsyDevLog.asyPrint("请求数据库错误$e");
        rethrow;
      }
    }
  }

  ///异步队列查询
  Future<List<Map<String, Object>>> select(String sql,
      {List<Object> parameters, int weight = 0, int taskId = 0}) async {
    AsyDevLog.asyPrint("开始异步读取");
    final DBWriteIsolateModel model = DBWriteIsolateModel();
    final qModel = AsyncInsertModel();
    qModel.sql = sql;
    qModel.parameters = parameters;
    model.models = [qModel];
    model.weight = weight;
    model.taskId = taskId;
    model.type = DBIsolateEventType.select;
    final List<Map<String, Object>> resultFromIsoLate =
        await WriteDbUtils.sendMessage2IsoLate(model);
    AsyDevLog.asyPrint("读取完成：${resultFromIsoLate.length}");
    return resultFromIsoLate;
  }

  ///带语法糖的查询
  Future<List<Map<String, Object>>> query(String table,
      {List<String> columns,
      String where,
      String orderBy,
      int limit,
      int offset,
      int weight = 0,
      int taskId = 0}) {
    AsyDevLog.asyPrint("语法糖读取转化sql");
    StringBuffer col = StringBuffer("*");
    if (columns != null && columns.isNotEmpty) {
      col = StringBuffer();
      for (final c in columns) {
        col.write(",$c");
      }
      col = StringBuffer(col.toString().substring(1));
    }
    final colString = col.toString();
    var sql = "SELECT $colString FROM $table";
    if (where != null) {
      sql += " WHERE $where";
    }
    if (orderBy != null) {
      sql += " ORDER BY $orderBy";
    }
    if (limit != null) {
      sql += " Limit $limit";
    }
    if (offset != null) {
      sql += " offset $offset";
    }
    return select(sql, weight: weight, taskId: taskId);
  }

  //插入一个
  Future<void> insert(String tableName, Map<String, Object> values,
      {InsertDBConflictType conflictAlgorithm,
      int weight = 0,
      int taskId = 0}) async {
    AsyDevLog.asyPrint("插入一个");
    return insertArray(tableName, [values],
        conflictAlgorithm: conflictAlgorithm, weight: weight, taskId: taskId);
  }

  //将插入任务转化为sql
  String sqlToInsert(String tableName, Map<String, Object> values,
      {InsertDBConflictType conflictAlgorithm,
      int weight = 0,
      int taskId = 0}) {
    final DBWriteIsolateModel model = DBWriteIsolateModel();
    model.maps = [values];
    model.tableName = tableName;
    model.conflictAlgorithm = conflictAlgorithm;
    final WriteQuestionModel qModel = model.exchangeTaskModel();
    qModel.models.first.exchangeSqlString();
    return qModel.models.first.sql;
  }

  //批量插入
  Future<void> insertArray(String tableName, List<Map<String, Object>> models,
      {InsertDBConflictType conflictAlgorithm,
      int weight = 0,
      int taskId = 0}) async {
    AsyDevLog.asyPrint("准备传入新线程开始批量写");
    shared._isWriteLock = true;
    //写入的isolate端口
    final DBWriteIsolateModel model = DBWriteIsolateModel();
    model.maps = models;
    model.tableName = tableName;
    model.weight = weight;
    model.taskId = taskId;
    model.conflictAlgorithm = conflictAlgorithm;
    final resultFromIsoLate = await WriteDbUtils.sendMessage2IsoLate(model);
    AsyDevLog.asyPrint("写入完成：$resultFromIsoLate");
    if (resultFromIsoLate == SqlReceiveResultType.allSuccess) {
      shared._isWriteLock = false;
    }
  }

  //插入一个sql
  Future<void> insertRow(String sql,
      {List<Object> parameters, int weight = 0, int taskId = 0}) async {
    return insertRows([sql],
        parameters: [parameters], weight: weight, taskId: taskId);
  }

  //插入批量sql
  Future<void> insertRows(List<String> sql,
      {List<List<Object>> parameters, int weight = 0, int taskId = 0}) async {
    AsyDevLog.asyPrint("批量插入sql：（sql数量${sql.length}）");
    shared._isWriteLock = true;
    final DBWriteIsolateModel model = DBWriteIsolateModel();
    final List<AsyncInsertModel> array = [];
    for (int i = 0; i < sql.length; i++) {
      final qModel = AsyncInsertModel();
      qModel.sql = sql[i];
      if (parameters != null && parameters.isNotEmpty) {
        qModel.parameters = parameters[i];
      }
      array.add(qModel);
    }
    model.models = array;
    model.weight = weight;
    model.taskId = taskId;
    model.type = DBIsolateEventType.write;
    final resultFromIsoLate = await WriteDbUtils.sendMessage2IsoLate(model);
    AsyDevLog.asyPrint("插入完成：$resultFromIsoLate");
    if (resultFromIsoLate == SqlReceiveResultType.allSuccess) {
      shared._isWriteLock = false;
    }
  }

  //批量更新
  Future<void> updateArray(List<String> sqlArray,
      {List<List<Object>> parameters, int weight = 0, int taskId = 0}) async {
    AsyDevLog.asyPrint("准备传入新线程开始批量改");
    shared._isWriteLock = true;
    //写入的isolate端口
    final DBWriteIsolateModel model = DBWriteIsolateModel();
    final List<AsyncInsertModel> modelArray = [];
    for (var i = 0; i < sqlArray.length; i++) {
      final model = AsyncInsertModel();
      model.sql = sqlArray[i];
      if (parameters != null && i < parameters.length) {
        model.parameters = parameters[i];
      }
      modelArray.add(model);
    }
    model.models = modelArray;
    model.weight = weight;
    model.taskId = taskId;
    model.type = DBIsolateEventType.write;
    final resultFromIsoLate = await WriteDbUtils.sendMessage2IsoLate(model);
    AsyDevLog.asyPrint("改写完成：$resultFromIsoLate");
    if (resultFromIsoLate == SqlReceiveResultType.allSuccess) {
      shared._isWriteLock = false;
    }
  }

  //更新一个
  Future<void> update(String table, Map<String, Object> values,
      {String where, int weight = 0, int taskId = 0}) async {
    AsyDevLog.asyPrint("更新一个转化sql");
    StringBuffer set = StringBuffer();
    for (final v in values.keys) {
      if (values[v] != null) {
        if (values[v] is String) {
          final String strValue = values[v];
          set.write(",$v = '${strValue.replaceAll("'", "''")}'");
        } else {
          set.write(",$v = ${values[v]}");
        }
      }
    }
    if (set.length > 0) {
      set = StringBuffer(set.toString().substring(1));
    }
    var sql = "UPDATE $table SET $set";
    if (where != null) {
      sql += " WHERE $where";
    }
    AsyDevLog.asyPrint("更新转化完的sql:$sql");
    return updateArray([sql], weight: weight, taskId: taskId);
  }

  //批量删除
  Future<void> deleteArray(List<String> sqlArray,
      {List<List<Object>> parameters, int weight = 0, int taskId = 0}) async {
    AsyDevLog.asyPrint("准备传入新线程开始批量删除");
    shared._isWriteLock = true;
    //写入的isolate端口
    final DBWriteIsolateModel model = DBWriteIsolateModel();
    final List<AsyncInsertModel> modelArray = [];
    for (var i = 0; i < sqlArray.length; i++) {
      final model = AsyncInsertModel();
      model.sql = sqlArray[i];
      if (parameters != null && parameters.length > i) {
        model.parameters = parameters[i];
      }
      modelArray.add(model);
    }
    model.models = modelArray;
    model.weight = weight;
    model.taskId = taskId;
    model.type = DBIsolateEventType.write;
    final resultFromIsoLate = await WriteDbUtils.sendMessage2IsoLate(model);
    AsyDevLog.asyPrint("删除完成：$resultFromIsoLate");
    if (resultFromIsoLate == SqlReceiveResultType.allSuccess) {
      shared._isWriteLock = false;
    }
  }

  //更改一个sql
  void updateRaw(String sql,
      {List<Object> arguments, int weight = 0, int taskId = 0}) {
    updateArray([sql], parameters: [arguments], weight: weight, taskId: taskId);
  }

  /// 删除
  Future<void> delete(String sql,
      {List<Object> arguments, int weight = 0, int taskId = 0}) async {
    return deleteArray([sql],
        parameters: [arguments], weight: weight, taskId: taskId);
  }

  /// 直接执行sql语句
  Future<void> execute(String sql,
      {List<Object> arguments,
      bool isAsync = true,
      int weight = 0,
      int taskId = 0}) async {
    final sqlString = sql.toLowerCase();
    if (sqlString.startsWith(_insert)) {
      return insertRow(sql,
          parameters: arguments, weight: weight, taskId: taskId);
    } else if (sqlString.startsWith(_delete)) {
      return delete(sql, arguments: arguments, weight: weight, taskId: taskId);
    } else if (sqlString.startsWith(_update)) {
      return updateRaw(sql,
          arguments: arguments, weight: weight, taskId: taskId);
    } else {
      //是否需要异步执行
      if (isAsync) {
        final DBWriteIsolateModel model = DBWriteIsolateModel();
        final qModel = AsyncInsertModel();
        qModel.sql = sql;
        qModel.parameters = arguments;
        model.models = [qModel];
        model.weight = weight;
        model.taskId = taskId;
        model.type = DBIsolateEventType.execute;
        await WriteDbUtils.sendMessage2IsoLate(model);
        AsyDevLog.asyPrint("直接执行sql完成");
      } else {
        var needContinue = false;
        if (shared._isWriteLock) {
          needContinue = true;
          AsyDevLog.asyPrint("直接执行sql:发现数据库被占用了，开始暂停其他线程的写入");
          await _pauseWrite();
          AsyDevLog.asyPrint("已解除写入的占用,继续sql操作");
        }
        try {
          final res = await getSql3Db().execute(sql, arguments ?? []);
          if (needContinue) {
            await _continueWrite();
          }
          return res;
        } catch (error) {
          if (needContinue) {
            await _continueWrite();
          }
          rethrow;
        }
      }
    }
  }

  //有新的高优先级任务进来，打断写入
  static Future _pauseWrite() async {
    if (!shared._isWriteLock) {
      return;
    }
    AsyDevLog.asyPrint("通知写入线程去打断");
    final DBWriteIsolateModel model = DBWriteIsolateModel();
    model.type = DBIsolateEventType.pause;
    final resultFromIsoLate = await WriteDbUtils.sendMessage2IsoLate(model);
    AsyDevLog.asyPrint("主线程收到新线程的结果：$resultFromIsoLate");
    shared._isWriteLock = false;
  }

  //其他线程执行完相应操作，继续写入
  static Future _continueWrite() async {
    AsyDevLog.asyPrint("收到其他线程的完成提醒,通知写入线程继续");
    final DBWriteIsolateModel model = DBWriteIsolateModel();
    model.type = DBIsolateEventType.goOn;
    final String resultFromIsoLate =
        await WriteDbUtils.sendMessage2IsoLate(model);
    AsyDevLog.asyPrint("结果：$resultFromIsoLate");
    if (resultFromIsoLate == "success") {
      shared._isWriteLock = true;
    }
  }

  Future<void> cancelTask(int taskId) async {
    if (taskId == 0) {
      return;
    }
    AsyDevLog.asyPrint("准备取消一个任务(id:$taskId)");
    final taskModel = DBWriteIsolateModel();
    taskModel.taskId = taskId;
    taskModel.type = DBIsolateEventType.cancel;
    await WriteDbUtils.sendMessage2IsoLate(taskModel);
  }

  Future _isolateOpenDataBase() async {
    final DBWriteIsolateModel model = DBWriteIsolateModel();
    model.type = DBIsolateEventType.openDataBase;
    if (dbPath != null) {
      model.pathString = dbPath;
      await WriteDbUtils.sendMessage2IsoLate(model);
    } else {
      throw "没有数据库路径";
    }
  }

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action,
      {bool exclusive}) {
    return baseDb.transaction(action, exclusive: exclusive);
  }

  Future<void> clearAllTask() async {
    final taskModel = DBWriteIsolateModel();
    taskModel.type = DBIsolateEventType.clear;
    await WriteDbUtils.sendMessage2IsoLate(taskModel);
  }

  Future<void> close() async {
    AsyDevLog.asyPrint("关闭数据库");
    dbPath = "";
    await baseDb.close();
  }
}

typedef OnDatabaseCreateFn = FutureOr<void> Function(AsyncDB db, int version);

typedef OnDatabaseVersionChangeFn = FutureOr<void> Function(
    AsyncDB db, int oldVersion, int newVersion);
