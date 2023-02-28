import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:im/db/async_db/async_db.dart';
import 'package:im/loggers.dart';
import 'package:pedantic/pedantic.dart';

import 'async_base_db.dart';
import 'async_insert_model.dart';
import 'db_dev_log.dart';

class WriteIsoLateObj {
  static List<WriteQuestionModel> questionPool = [];

  //当前写入线程的状态
  static WriteDBStatus status = WriteDBStatus.free;

  //所有插队等待返回的端口
  static List<SendPort> ports = [];

  //是否正在写入小单元
  static bool isWriting = false;

  //每个小任务单元的条数(决定其他任务插入的最小间隔)
  static int maxSectionNumber = 10000;

  //原生事务和flutter事务转化处理的临界值
  static int transactionNumber = 1000;

  //多个小写入任务合并成一个事务的最大条数
  static int maxSingleWriteNumber = 30000;

  //读取失败数量
  static int errorCount = 0;

  //插进来的任务数量，用于给任务编号
  static int taskIndex = 0;

  //当前的读取编号，用于异常监控
  static int nowReadIndex = 0;

  //写入的拥堵数量，超过这个数量会将单条写入sql合并操作
  static int maxWriteTaskNumber = 10;
}

class WriteDbUtils {
  SendPort writeSendPort;

  ReceivePort writeReceivePort = ReceivePort();

  //读取的数据库连接对象
  AsyBaseDB _sql3Db;

  //储存的数据库地址
  String _dbPath;

  /// sqfLite插件channel
  static const MethodChannel sqfLiteChannel =
      MethodChannel('com.tekartik.sqflite');

  //单例
  static WriteDbUtils shared = WriteDbUtils();

  static final WriteDbUtils _instance = WriteDbUtils._internal();
  factory WriteDbUtils() => _instance;

  static const timer = Duration(seconds: 3);

  WriteDbUtils._internal() {
    init();
  }
  void init() {
    //开启异常检测机制
    Timer.periodic(timer, (t) {
      //callback function
      checkError();
    });
  }

  Future<void> checkError() async {
    var taskId = 0;
    if (WriteIsoLateObj.questionPool.isNotEmpty) {
      final task = WriteIsoLateObj.questionPool.first;
      if (task.type == DBIsolateEventType.select) {
        taskId = task.taskID;
      }
    }
    //如果时隔三秒,上一次的读取任务任然没有完成，可能出现异常了，手动再激活一次任务池
    if (taskId == WriteIsoLateObj.nowReadIndex && taskId != 0) {
      AsyDevLog.asyPrint("有长时间没有没有响应的读取异常，手动再激活一次任务");
      WriteIsoLateObj.errorCount++;
      if (WriteIsoLateObj.errorCount >= 3) {
        if (WriteIsoLateObj.questionPool.isNotEmpty) {
          //清理掉第一条长时间没响应的sql
          final task = WriteIsoLateObj.questionPool.first;
          final AsyncDataBaseErrorModel errorModel =
              AsyncDataBaseErrorModel.createErrorModel(
                  "未知错误长时间无响应重启", "重启", task.models.first?.sql);
          if (task.port != null) {
            task.port.send(errorModel);
          }
          WriteIsoLateObj.questionPool.remove(task);
        }
        await _reopenDB();
      } else {
        WriteIsoLateObj.status = WriteDBStatus.free;
        unawaited(doQuestionPool());
      }
    }
    WriteIsoLateObj.nowReadIndex = taskId;
  }

  //打开相应路径的数据库
  Future<void> openDatabase(String path) async {
    if (path != _dbPath) {
      cleanAllTask();
      await _sql3Db?.close();
      _sql3Db = await AsyBaseDB.open(path);
      _dbPath = path;
      AsyDevLog.asyPrint("isolate打开了数据库");
    }
  }

  //取消之后的所有任务
  void cleanAllTask() {
    WriteIsoLateObj.questionPool.clear();
  }

  AsyBaseDB getSql3Db() {
    if (_sql3Db != null) {
      return _sql3Db;
    } else {
      throw "请先传入路径打开database";
    }
  }

  Future<void> setup() async {
    //开辟新的isolate
    await Isolate.spawn(speak, writeReceivePort.sendPort);
    writeSendPort = await writeReceivePort.first;
  }

  static Future<void> speak(SendPort sendPort) async {
    //4.现在提供给主isolate一个用于给子isolate发消息的sendPort
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    //持续监听传过来的消息
    await for (final r in receivePort) {
      final DBWriteIsolateModel model = r[0];
      final SendPort port = r[1];
      receiveTask(model, port);
    }
  }

  static void receiveTask(DBWriteIsolateModel model, SendPort port) {
    switch (model.type) {
      case DBIsolateEventType.openDataBase:
        {
          shared.openDatabase(model.pathString);
          port.send("success");
        }
        break;
      case DBIsolateEventType.pause:
        pauseTask(port);
        break;
      case DBIsolateEventType.goOn:
        continueTask(port);
        break;
      case DBIsolateEventType.write:
        addTask(model, port);
        break;
      case DBIsolateEventType.update:
        addTask(model, port);
        break;
      case DBIsolateEventType.delete:
        addTask(model, port);
        break;
      case DBIsolateEventType.execute:
        addTask(model, port);
        break;
      case DBIsolateEventType.select:
        addTask(model, port);
        break;
      case DBIsolateEventType.cancel:
        cancelTask(port, model.taskId);
        break;
      case DBIsolateEventType.clear:
        addTask(model, port);
        break;
    }
  }

  static void cancelTask(SendPort port, int taskId) {
    for (final task in WriteIsoLateObj.questionPool) {
      if (task.taskID == taskId) {
        task.port.send(SqlReceiveResultType.cancel);
        WriteIsoLateObj.questionPool.remove(task);
        AsyDevLog.asyPrint("找到了取消的任务，已取消id($taskId)");
        break;
      }
    }
    port.send(SqlReceiveResultType.success);
  }

  //有新任务进来需要打断
  static void pauseTask(SendPort port) {
    final isFree = WriteIsoLateObj.status == WriteDBStatus.free;
    WriteIsoLateObj.status = WriteDBStatus.wait;
    final SendPort replyTo = port;
    WriteIsoLateObj.ports.add(replyTo);
    if (WriteIsoLateObj.questionPool.isNotEmpty || isFree) {
      for (final port in WriteIsoLateObj.ports) {
        port.send("success");
      }
      WriteIsoLateObj.ports.clear();
      AsyDevLog.asyPrint("通知打断，但是没有任务池，所以直接回复");
      WriteIsoLateObj.isWriting = false;
      WriteIsoLateObj.status = WriteDBStatus.free;
    }
  }

  //继续之前的任务
  static void continueTask(SendPort port) {
    AsyDevLog.asyPrint("写入的线程收到通知，继续写入");
    WriteIsoLateObj.status = WriteDBStatus.busy;
    final SendPort replyTo = port;
    if (WriteIsoLateObj.questionPool.isNotEmpty) {
      replyTo.send("success");
      doQuestionPool();
    } else {
      replyTo.send("error");
      doQuestionPool();
    }
  }

  //添加执行任务
  static void addTask(DBWriteIsolateModel model, SendPort port) {
    final SendPort replyTo = port;
    final WriteQuestionModel qModel = model.exchangeTaskModel();
    qModel.port = replyTo;
    WriteIsoLateObj.taskIndex++;
    qModel.taskID = WriteIsoLateObj.taskIndex;
    final pool = WriteIsoLateObj.questionPool;
    //默认插入到数组最后面
    var index = pool.length;
    for (int i = 0; i < pool.length; i++) {
      //1.先通过权重排序一次
      if (pool[i].weight < qModel.weight) {
        AsyDevLog.asyPrint("新任务有优先级(${qModel.weight})，根据优先级进行了插队");
        index = i;
        break;
      } else if (pool[i].weight == qModel.weight) {
        //2.判断读写优先级来选择插入到队列中的位置 3.根据子任务数排序，任务少的优先执行
        if (pool[i].type.index < qModel.type.index ||
            (pool[i].type.index == qModel.type.index) &&
                (pool[i].models.length > qModel.models.length)) {
          index = i;
          break;
        }
      }
    }
    AsyDevLog.asyPrint("新线程收到新的${qModel.type}任务插入到任务池去，插到$index");
    pool.insert(index < 0 ? 0 : index, qModel);
    checkStatus();
  }

  //检查当前的运行状态是否要执行
  static void checkStatus() {
    if (WriteIsoLateObj.status == WriteDBStatus.free) {
      AsyDevLog.asyPrint("当前没有其他任务,立即执行任务");
      doQuestionPool();
    } else if (WriteIsoLateObj.status == WriteDBStatus.busy) {
      AsyDevLog.asyPrint(
          "当前有其他写入任务，加入任务池排队(当前任务类型${WriteIsoLateObj.questionPool.first.type},池子任务数：${WriteIsoLateObj.questionPool.length})");
    } else if (WriteIsoLateObj.status == WriteDBStatus.wait) {
      AsyDevLog.asyPrint("当前写入通道暂停，加入任务池排队等待激活");
    }
  }

  static Future<void> doQuestionPool() async {
    if (WriteIsoLateObj.questionPool.isNotEmpty &&
        WriteIsoLateObj.status != WriteDBStatus.stop) {
      WriteIsoLateObj.status = WriteDBStatus.busy;
      await changeFuture().then((value) {
        if (WriteIsoLateObj.status == WriteDBStatus.stop) return;
        if (WriteIsoLateObj.questionPool.isNotEmpty) {
          checkWriteTaskCount();
          AsyDevLog.asyPrint(
              "执行池子里的第一个任务,子任务数${WriteIsoLateObj.questionPool[0].models?.length}/进度${WriteIsoLateObj.questionPool[0].progress}");
          AsyDevLog.asyPrint(
              "第一个sql:${WriteIsoLateObj.questionPool[0].models?.first?.sql}");
          doWriteQuestion(WriteIsoLateObj.questionPool[0]);
        } else {
          AsyDevLog.asyPrint("池子里的任务执行完了");
          WriteIsoLateObj.status = WriteDBStatus.free;
        }
      });
      //因为这里的future是放到最后入栈的，中间可能会插入其他代码，所以再做一次判断

    } else {
      AsyDevLog.asyPrint("当前没有任务了");
      WriteIsoLateObj.status = WriteDBStatus.free;
    }
  }

  //将小批量的写入任务合并到一个事务中执行
  static void checkWriteTaskCount() {
    ///如果写入的任务超过设定的合并数额就开始合并
    if (WriteIsoLateObj.questionPool.length >
            WriteIsoLateObj.maxWriteTaskNumber &&
        WriteIsoLateObj.questionPool.first.type == DBIsolateEventType.write) {
      final listModel = WriteQuestionModel();
      final List<WriteQuestionModel> rmArray = [];
      for (int i = 0; i < WriteIsoLateObj.questionPool.length; i++) {
        final task = WriteIsoLateObj.questionPool[i];

        ///如果合并的任务数没有达到就继续合并
        if (task.type == DBIsolateEventType.write &&
            (listModel.models.length + task.models.length <
                WriteIsoLateObj.maxSingleWriteNumber) &&
            task.progress == 0) {
          rmArray.add(task);
          listModel.ports.add(task.port);
          listModel.portSqlCountList.add(task.models.length);
          task.models.forEach((element) {
            ///合并之前都先转化为纯字符串sql
            element.exchangeSqlString();
            listModel.models.add(element);
          });
        } else {
          break;
        }
      }
      if (rmArray.length > 1) {
        rmArray.forEach((element) {
          WriteIsoLateObj.questionPool.remove(element);
        });
        WriteIsoLateObj.questionPool.insert(0, listModel);
        AsyDevLog.asyPrint(
            "对任务进行了合并，合并后的任务数:${WriteIsoLateObj.questionPool.length}");
      }
    }
  }

  static Future<void> doWriteQuestion(WriteQuestionModel model) async {
    if (WriteIsoLateObj.isWriting) {
      return;
    }
    WriteIsoLateObj.isWriting = true;
    if (model.type == DBIsolateEventType.clear) {
      WriteIsoLateObj.questionPool.remove(model);
      clearTaskPool();
      model.port.send(SqlReceiveResultType.success);
    } else if (model.type == DBIsolateEventType.select) {
      await doSelectTask(model);
    } else {
      //没有返回值的执行sql
      await doWriteTask(model);
    }
    WriteIsoLateObj.isWriting = false;
    unawaited(doQuestionPool());
  }

  //清空任务队列
  static void clearTaskPool() {
    //先给队列中的等待的回调发送取消的错误，然后清空
    for (final task in WriteIsoLateObj.questionPool) {
      if (task.ports.isNotEmpty) {
        for (final port in task.ports) {
          port.send(SqlReceiveResultType.cancel);
        }
      } else {
        task.port.send(SqlReceiveResultType.cancel);
      }
    }
    AsyDevLog.asyPrint("队列已经全部发送取消信息开始清空数组");
    WriteIsoLateObj.questionPool.clear();
  }

  static Future<void> doSelectTask(WriteQuestionModel model) async {
    AsyDevLog.asyPrint("查询任务");
    //查询
    try {
      final res = await shared
          .getSql3Db()
          .select(model.models.first.sql, model.models.first.parameters);
      model.port.send(res);
      WriteIsoLateObj.errorCount = 0;
      AsyDevLog.asyPrint(
          "读取完成,向外发送信号（剩余任务数量:${WriteIsoLateObj.questionPool.length}）");
    } catch (e) {
      await doError(model, e.toString(), "读取");
      return;
    }
    WriteIsoLateObj.questionPool.remove(model);
  }

  static Future<void> doWriteTask(WriteQuestionModel model) async {
    if (WriteIsoLateObj.status == WriteDBStatus.wait) {
      //如果是其他线程在占用数据库就终止任务池的进行
      for (final port in WriteIsoLateObj.ports) {
        port.send(SqlReceiveResultType.success);
      }
      WriteIsoLateObj.ports.clear();
      AsyDevLog.asyPrint("被其他线程插队，直接终止,当前进度${model.progress}");
      WriteIsoLateObj.isWriting = false;
      WriteIsoLateObj.status = WriteDBStatus.free;
      return;
    }
    //筛选进入批量进入事务的sql
    var count = 0;
    final List<AsyncInsertModel> sqlArray = [];
    for (int i = model.progress; i < model.models.length; i++) {
      sqlArray.add(model.models[i]);
      count++;
      model.progress++;
      //进行完一个最小单元就将future优先级往后掉，使其他线程的信号优先执行，
      if (count >= WriteIsoLateObj.maxSectionNumber) {
        break;
      }
    }
    if (model.type == DBIsolateEventType.write &&
        model.models.length > WriteIsoLateObj.transactionNumber) {
      //如果是大批量的是就一次性传一个list到原生一起开事务
      final List<String> sqlList = [];
      for (final sqlModel in sqlArray) {
        sqlList.add(sqlModel.sql);
      }
      await sqfLiteBatchWrite(sqlList).catchError((e) async {
        model.progress -= count;
        await doError(model, e.toString(), "异步原生写入失败");
        return;
      });
    } else if (model.models.length == 1) {
      //如果是一个就不开启显性事务
      await shared
          .getSql3Db()
          .execute(sqlArray.first.sql, sqlArray.first.parameters)
          .catchError((e) async {
        model.progress = 0;
        await doError(model, e.toString(), "单条写入");
        return;
      });
    } else {
      //如果是小批量就直接用一个事务提交
      await shared.getSql3Db().transaction((txn) async {
        for (int i = 0; i < sqlArray.length; i++) {
          await txn.execute(sqlArray[i].sql, sqlArray[i].parameters);
        }
      }).catchError((e) async {
        model.progress -= count;
        await doError(model, e.toString(), "批量写入");
        return;
      });
    }
    if (model.progress >= model.models.length - 1) {
      //如果进度已满就返回，否则就继续下一个任务单元
      AsyDevLog.asyPrint(
          "新线程任务写完,向外发送信号（剩余任务数量:${WriteIsoLateObj.questionPool.length}）");
      final isAllSuccess = WriteIsoLateObj.questionPool.length <= 1;
      if (model.ports.isNotEmpty) {
        for (final port in model.ports) {
          port?.send(isAllSuccess
              ? SqlReceiveResultType.allSuccess
              : SqlReceiveResultType.success);
        }
      } else {
        ///此处port逻辑上不应该为null，但bugly上有一台设备有上报，暂时找不出原因。需要之后再排查。
        ///bugly：（https://bugly.qq.com/v2/crash-reporting/errors/617a8513ab/1809473?pid=2&crashDataType=undefined）
        model.port?.send(isAllSuccess
            ? SqlReceiveResultType.allSuccess
            : SqlReceiveResultType.success);
      }
      WriteIsoLateObj.questionPool.remove(model);
    }
  }

  static Future<void> doError(
      WriteQuestionModel model, String e, String typeString) async {
    if (!model.isRetry) {
      model.isRetry = true;
      logger.info("${"数据库错误  sql（${model.models[0].sql}）"}$e，第一次出错，重启数据库链接并重试");
      await _reopenDB();
    } else {
      try {
        ///如果是合并后的任务，就找出出错的那次任务从合并任务里剔除掉然后继续执行
        if (model.ports.isNotEmpty) {
          int errorIndex; //找到报错的sql
          for (int i = 0; i < model.models.length; i++) {
            if (e.contains(model.models[i].sql)) {
              errorIndex = i;
              break;
            }
          }

          ///找到了报错的sql
          if (errorIndex != null) {
            AsyDevLog.asyPrint("检测到合并任务的第$errorIndex个sql出错了");
            var taskIndex = 0;
            for (int i = 0; i < model.ports.length; i++) {
              if (errorIndex < taskIndex + model.portSqlCountList[i]) {
                AsyDevLog.asyPrint("检测到合并任务的第$i个数据任务出错了");
                //找到错误的sql删除，然后外抛异常
                final AsyncDataBaseErrorModel errorModel =
                    AsyncDataBaseErrorModel.createErrorModel(
                        e.toString(), typeString, model.models[errorIndex].sql);
                model.ports[i].send(errorModel);
                model.models.removeRange(
                    taskIndex, taskIndex + model.portSqlCountList[i]);
                model.ports.removeAt(i);
                //删除后重置进度条
                model.progress = 0;
                //极端情况下集合被删除完了直接从队列中去掉
                if (model.ports.isEmpty) {
                  WriteIsoLateObj.questionPool.remove(model);
                }
                break;
              } else {
                taskIndex += model.portSqlCountList[i];
              }
            }
          } else {
            ///没有找到了报错的sql将合并任务都抛异常
            final AsyncDataBaseErrorModel errorModel =
                AsyncDataBaseErrorModel.createErrorModel(
                    e.toString(), typeString, "");
            model.ports.forEach((element) {
              element.send(errorModel);
            });
            WriteIsoLateObj.questionPool.remove(model);
          }
        } else {
          ///不是合并任务一次重试后依然出错就上报并外抛错误
          AsyDevLog.asyPrint("${"数据库错误  sql（${model.models[0].sql}）"}$e,外抛错误");
          final AsyncDataBaseErrorModel errorModel =
              AsyncDataBaseErrorModel.createErrorModel(
                  e.toString(), typeString, model.models[0].sql);

          ///此处port逻辑上不应该为null，但bugly上有一台设备有上报，暂时找不出原因。需要之后再排查。
          ///bugly：（https://bugly.qq.com/v2/crash-reporting/errors/617a8513ab/1809473?pid=2&crashDataType=undefined）
          model.port?.send(errorModel);
          WriteIsoLateObj.questionPool.remove(model);
        }
      } catch (_) {
        WriteIsoLateObj.questionPool.remove(model);
      }
      await doQuestionPool();
    }
  }

  static Future<void> writeMsg(String tableName, AsyncInsertModel model) async {
    try {
      return shared
          .getSql3Db()
          .execute(model.sql ?? "", model.parameters ?? []);
    } catch (e) {
      if (e.toString().contains("locked")) {
        await Future.delayed(const Duration(milliseconds: 100), () {
          writeMsg(tableName, model);
        });
      } else {
        AsyDevLog.asyPrint("${"写入数据库错误  sql（${model.sql}）"}$e");
        rethrow;
      }
    }
  }

  //发送一条消息给isolate
  static Future sendMessage2IsoLate(DBWriteIsolateModel eventModel,
      {bool needNewIsoLate = false}) async {
    if (needNewIsoLate) {
      //放到新的isolate执行(该方法不支持sqfite这种与原生有桥接的库)
      if (shared.writeSendPort == null) {
        await shared.setup();
      }
      final ReceivePort receivePort = ReceivePort();
      shared.writeSendPort.send([eventModel, receivePort.sendPort]);
      final res = await receivePort.first;
      if (res is AsyncDataBaseErrorModel) {
        final AsyncDataBaseErrorModel errorModel = res;
        logger.info(errorModel.toErrorMessage());
        throw errorModel.toErrorMessage();
      } else {
        return res;
      }
    } else {
      //放到主isolate执行,主isolate无需创建新的连接
      if (eventModel.type == DBIsolateEventType.openDataBase) {
        shared._sql3Db = AsyncDB.shared.baseDb;
        return;
      }
      final ReceivePort receivePort = ReceivePort();
      receiveTask(eventModel, receivePort.sendPort);
      final res = await receivePort.first;
      if (res is AsyncDataBaseErrorModel) {
        final AsyncDataBaseErrorModel errorModel = res;
        logger.info(errorModel.toErrorMessage());
        throw errorModel.toErrorMessage();
      } else if (res == SqlReceiveResultType.cancel) {
        throw "任务被取消";
      } else {
        return res;
      }
    }
  }

  //未知错误的保护机制就重启数据库
  static Future _reopenDB() async {
    //准备重启数据库，先暂停所有操作
    WriteIsoLateObj.status = WriteDBStatus.stop;
    final String dbPath = AsyncDB.shared.dbPath;
    await AsyncDB.shared.close();
    await AsyncDB.shared.openDataBase(dbPath);
    WriteIsoLateObj.status = WriteDBStatus.free;
    WriteIsoLateObj.isWriting = false;
    //重启完成后继续之前的队列
    unawaited(doQuestionPool());
  }

  ///专门用于写入的数据库方法，单独线程
  static Future<void> sqfLiteBatchWrite(List<String> sqlList) async {
    if (kIsWeb) return;

    ///fix for macos 此处报错
    try {
      await sqfLiteChannel.invokeMethod(
          "batchWrite", {"path": AsyncDB.shared.dbPath, "sql": sqlList});
    } catch (e) {
      if (Platform.isMacOS) {
        logger.info(e.toString());
      } else {
        rethrow;
      }
    }
  }

  ///桥接原生来重置future的位置
  static Future<void> changeFuture() async {
    ///fix for macos 此处报错
    await sqfLiteChannel.invokeMethod("changeFuture");
  }
}
