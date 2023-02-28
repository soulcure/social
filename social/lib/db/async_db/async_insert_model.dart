import 'dart:isolate';

import 'async_write_db_utils.dart';

class AsyncInsertModel {
  static final RegExp _sqlParametersReg =
      RegExp(r"VALUES\s*\(\s*\?", caseSensitive: false);

  //要查询的sql
  String sql;
  //sql的参数
  List<Object> parameters;

  void exchangeSqlString() {
    //将参数转换到sql里
    if (parameters != null && parameters.isNotEmpty) {
      try {
        //替换填充参数型sql语句中的?为带入参数
        if (_sqlParametersReg.hasMatch(sql)) {
          /// 拆分SQL,然后和parameter组装在一起,例如:
          /// sql = insert values(?) into example
          /// parameters = ["text"]
          /// splitSqls = ['insert value(', ') into example'];
          /// parameters\splitSqls合并后 insert value("text") into example
          final splitSqls = sql.split("?");
          if (splitSqls.length != parameters.length + 1) {
            sql = "转化失败:$sql";
          } else {
            final StringBuffer result = StringBuffer();
            for (int i = 0; i < parameters.length; i++) {
              // parameters不预先处理好的原因是:放这里处理少一次for循环
              // String需特殊处理的原因:对原来就有的单引号进行转义
              final String parameter = (parameters[i] is String)
                  ? "'${parameters[i].toString().replaceAll("'", "''")}'"
                  : parameters[i].toString();
              result.write(splitSqls[i] + parameter);
            }
            result.write(splitSqls.last);
            sql = result.toString();
          }
        }

        ///如果已经把参数成功并入sql语句，就删除parameters
        parameters = null;
      } catch (_) {
        sql = "sql参数转化失败";
      }
    }
  }
}

enum InsertDBConflictType { ignore, replace }

//在没有加单独判断的情况下，枚举值越大越插入队列的权重越高。
enum DBIsolateEventType {
  //打开or更换数据库
  openDataBase,
  //打断当前的操作
  pause,
  //继续之前的操作
  goOn,
  //写入数据任务
  write,
  //更新数据任务
  update,
  //删除任务
  delete,
  //直接执行
  execute,
  //读取
  select,
  //取消某个sql操作
  cancel,
  //清空所有队列
  clear
}

//写入线程的状态
enum WriteDBStatus {
  //当前空闲
  free,
  //正在写入
  busy,
  //被锁，等待其他线程解锁
  wait,
  //发生异常，停止所有写库操作
  stop
}

//sql执行的结果
enum SqlReceiveResultType {
  //当前空闲
  success,
  //正在写入
  allSuccess,
  error,
  cancel,
}

class AsyncDataBaseErrorModel {
  String sqlMessage;
  String taskMessage;
  String sql;
  String pollMessage;

  static AsyncDataBaseErrorModel createErrorModel(
      String sqlMessage, String taskMessage, String sql) {
    final AsyncDataBaseErrorModel model = AsyncDataBaseErrorModel();
    model.sqlMessage = sqlMessage;
    model.taskMessage = taskMessage;
    model.sql = sql;
    model.pollMessage = "任务池:${WriteIsoLateObj.questionPool.length}";
    return model;
  }

  String toErrorMessage() {
    return "数据库出错(info:$sqlMessage,类型:$taskMessage, sql:$sql ,$pollMessage)";
  }
}

//对isolate做通信的model
class DBWriteIsolateModel {
  //操作的类型
  DBIsolateEventType type = DBIsolateEventType.write;
  //数据库地址
  String pathString = "";
  //表名
  String tableName = "";
  //要写入的数据
  List<Map<String, Object>> maps = [];
  //要查询的sql
  List<AsyncInsertModel> models;
  //冲突的解决方式
  InsertDBConflictType conflictAlgorithm;
  //权重
  int weight = 0;
  //任务id
  int taskId = 0;

  WriteQuestionModel exchangeTaskModel() {
    final model = WriteQuestionModel();
    model.tableName = tableName;
    model.pathString = pathString;
    model.type = type;
    model.weight = weight;
    if (type == DBIsolateEventType.write && models == null) {
      model.models = [];
      for (final map in maps) {
        var keys = StringBuffer();
        var unKnownWord = StringBuffer();
        final List<Object> valueArray = [];
        for (final key in map.keys) {
          valueArray.add(map[key]);
          keys.write(",$key");
          unKnownWord.write(",?");
        }
        keys = StringBuffer(keys.toString().substring(1));
        unKnownWord = StringBuffer(unKnownWord.toString().substring(1));
        final AsyncInsertModel sModel = AsyncInsertModel();
        var sqlHeader = "insert or replace into";
        if (conflictAlgorithm == InsertDBConflictType.ignore) {
          sqlHeader = "insert or ignore into";
        }
        sModel.sql = "$sqlHeader $tableName ($keys) VALUES ($unKnownWord)";
        sModel.parameters = valueArray;
        model.models.add(sModel);
      }
    } else {
      model.models = models;
    }
    return model;
  }
}

//写入任务的model
class WriteQuestionModel {
  //通知结果的port
  SendPort port;
  //表名
  String tableName = "";
  //数据库地址
  String pathString = "";
  //进行中的进度
  int progress = 0;
  //要查询的sql
  List<AsyncInsertModel> models = [];
  //操作
  DBIsolateEventType type = DBIsolateEventType.write;
  //任务id
  int taskID = 0;
  //权重
  int weight = 0;
  //通知结果的portList
  List<SendPort> ports = [];
  //每个任务报错之后有一次重试
  bool isRetry = false;
  //每个port所分的sql个数
  List<int> portSqlCountList = [];
}
