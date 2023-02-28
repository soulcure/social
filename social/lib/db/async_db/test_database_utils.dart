import 'package:im/db/async_db/async_db.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:pedantic/pedantic.dart';

class TestDatabaseUtils {
  AsyncDB db = AsyncDB.shared;

  final table = "testDatabase";

  final columnChannelId = "channel_id";
  final columnUserId = "user_id";
  final columnGuildId = "guild_id";
  final columnTime = "time";
  final columnMessageId = "message_id";
  final columnContent = "content";
  final columnDeleted = "deleted";
  final columnQuote1 = "quote_l1";
  final columnQuote2 = "quote_l2";
  final columnQuoteTotal = "quote_total";
  final columnStatus = "status";
  final columnLocalStatus = "localStatus";
  final columnPin = "pin";
  final columnRecall = "recall";
  final columnReplyMarkup = "reply_markup";
  final columnNonce = "nonce";
  final columnUnreactive = "unreactive";

  int testSingleChannelBigNumberMessageWriteTime = 0;

  bool checkRight = true;

  static int messageId = 0;

  Future<void> startTest() async {
    logger.info("开始测试数据库");
    logger.info("准备删除测试表");
    await deleteTable();
    logger.info("准备新建测试表");
    await createTable();
    logger.info("写入单频道大量消息测试开始");
    final firstWriteModel = await testSingleChannelBigNumberMessageWrite();
    logger.info("写入多频道小批量消息测试开始");
    final secondWrteModel = await testManyChannelBigNumberMessageWrite();
    logger.info("写入多频道大批量小批量都有的测试开始");
    final thirdWrteModel = await testSynthesizeWritePerformance();
    logger.info("读取多频道大批量小批量都有的测试开始");
    final readFirstWriteModelTime = await redAndCheckData(firstWriteModel);
    logger.info("读取多频道小批量消息测试开始");
    final readSecondWriteModelTime = await redAndCheckData(secondWrteModel);
    logger.info("读取多频道大批量小批量都有的测试开始");
    final readThirdWriteModelTime = await redAndCheckData(thirdWrteModel);
    logger.info("测试完成!");
    printTime(firstWriteModel, readFirstWriteModelTime);
    printTime(secondWrteModel, readSecondWriteModelTime);
    printTime(thirdWrteModel, readThirdWriteModelTime);
    await checkError();
    logger.info(
        "一共用时${firstWriteModel.time + secondWrteModel.time + thirdWrteModel.time + readFirstWriteModelTime + readSecondWriteModelTime + readThirdWriteModelTime}ms");
    logger.info("正确性验证：${checkRight ? "正确" : "错误"}");
  }

  void printTime(TestDatabaseModel model, int readTime) {
    logger.info(
        "写入${model.channelCount}个频道，共${model.textCount * (model.channelCount - model.specialCount) + model.specialCount * model.specialTextCount}条消息，用时：${model.time} ms");
    logger.info(
        "读取${model.channelCount}个频道，共${model.textCount * (model.channelCount - model.specialCount) + model.specialCount * model.specialTextCount}条消息，用时：$readTime ms");
  }

  ///如果之前有没有删除的表就先删除
  Future<void> deleteTable() async {
    try {
      await db.execute("DROP TABLE $table");
    } catch (_) {}
  }

  ///创建测试表
  Future<void> createTable() async {
    await db.execute('''
        CREATE TABLE $table (
          $columnChannelId TEXT,
          $columnUserId TEXT,
          $columnGuildId TEXT,
          $columnContent TEXT,
          $columnMessageId INTEGER PRIMARY KEY,
          $columnTime INTEGER,
          $columnDeleted INTEGER,
          $columnQuote1 TEXT,
          $columnQuote2 TEXT,
          $columnQuoteTotal INTEGER,
          $columnStatus INTEGER,
          $columnLocalStatus INTEGER,
          $columnPin TEXT,
          $columnRecall TEXT,
          $columnReplyMarkup TEXT,
          $columnNonce INTEGER,
          $columnUnreactive INTEGER
          )
        ''');
  }

  ///测试单个频道的大量消息写入
  Future<TestDatabaseModel> testSingleChannelBigNumberMessageWrite() async {
    final TestDatabaseModel writeModel = TestDatabaseModel();
    writeModel.channelId = 100000;
    writeModel.channelCount = 1;
    writeModel.textCount = 50000;
    logger.info("开始单个频道5w条数据的测试");
    await writeModel.doTask();
    return writeModel;
  }

  ///测试单个频道的大量消息写入
  Future<TestDatabaseModel> testManyChannelBigNumberMessageWrite() async {
    final TestDatabaseModel writeModel = TestDatabaseModel();
    writeModel.channelId = 200000;
    writeModel.channelCount = 1000;
    writeModel.textCount = 30;
    logger.info("开始1000个频道每个30条消息的测试");
    await writeModel.doTask();
    return writeModel;
  }

  ///综合写入性能测试
  Future<TestDatabaseModel> testSynthesizeWritePerformance() async {
    final TestDatabaseModel writeModel = TestDatabaseModel();
    writeModel.channelId = 300000;
    writeModel.channelCount = 1000;
    writeModel.textCount = 30;
    writeModel.specialCount = 4;
    writeModel.specialTextCount = 5000;
    logger.info("开始4个频道5k数据，其他996个频道30条数据的测试");
    await writeModel.doTask();
    return writeModel;
  }

  ///对模型数据进行读取，每个频道为一个事务。多频道读取较慢。
  Future<int> redAndCheckData(TestDatabaseModel testModel) async {
    final int channelId = testModel.channelId;
    logger.info("开始读取数据");
    final List<List<Map<String, Object>>> allList = [];
    final start = DateTime.now().millisecondsSinceEpoch;
    for (int j = 0; j < testModel.channelCount; j++) {
      ///读取所有服务器的数据放到数组中
      final String where = "$columnChannelId = ${channelId + j}";
      final list = await db.query(table, where: where);
      allList.add(list);
    }

    ///计时只记读取的时间，后面转换和校验的时间不算。
    final end = DateTime.now().millisecondsSinceEpoch;
    logger.info("读取完成");
    print("开始验证写入和读取的正确性");
    if (allList.length == testModel.channelCount) {
      for (int i = 0; i < allList.length; i++) {
        final newList =
            allList[i].map((e) => MessageEntity.fromJson(e)).toList();
        if ((i < testModel.specialCount &&
                newList.length == testModel.specialTextCount) ||
            (i >= testModel.specialCount &&
                newList.length == testModel.textCount)) {
          for (int j = 0; j < newList.length; j++) {
            final model = newList[j];
            if (model.userId != "$j") {
              checkRight = false;
            }
          }
        } else {
          checkRight = false;
        }
      }
    } else {
      checkRight = false;
    }
    logger.info("验证正确性完成 : ${checkRight ? "正确" : "错误"}");
    return end - start;
  }

  ///开始容错测试
  Future<void> checkError() async {
    logger.info("开始容错测试，插入1000个正常任务，和一个错误的sql");
    final List<String> sqls = [];
    for (int i = 0; i < 1000; i++) {
      final String str =
          "insert or ignore into $table (channel_id,user_id,message_id,quote_l1,quote_l2,quote_total,recall,pin,guild_id,time,content,deleted,status,localStatus,nonce,unreactive) values ('400000','$i','${400000 + i}',null,null,null,null,null,'189278210867855360',0,null,0,0,5,null,0)";
      sqls.add(str);
    }
    final str = "insert or ignore into $table 123";
    sqls.insert(200, str);
    sqls.forEach((element) {
      db.insertRow(element).catchError((e) {
        logger.info("找到了错误,错误的sql:$element");
      });
    });
  }
}

///测试任务
class TestDatabaseModel {
  AsyncDB db = AsyncDB.shared;

  final table = "testDatabase";

  ///channel的起始id
  int channelId;

  ///多少个channel
  int channelCount = 1;

  ///每个channel里面的消息数量
  int textCount = 1;

  ///插入多次少特殊数量的数据
  int specialCount = 0;

  ///每次插入的特殊数量有多少个
  int specialTextCount = 0;

  ///耗时多少
  int time = 0;

  ///测试大量频道的小批量消息接入
  Future<void> doTask() async {
    logger.info("制造数据中");
    final List<List<String>> sqls = [];
    for (int j = 0; j < channelCount; j++) {
      final List<String> sqlArray = [];
      var count = textCount;

      ///如果有特殊数量的需求就添加特定数量
      if (j < specialCount) {
        count = specialTextCount;
      }
      for (int i = 0; i < count; i++) {
        sqlArray.add(createSqlString("${channelId + j}", "$i"));
      }
      sqls.add(sqlArray);
    }
    logger.info("开始执行");
    final start = DateTime.now().millisecondsSinceEpoch;
    int lastDoIndex;
    for (int i = 0; i < sqls.length; i++) {
      if (i == specialCount - 1 &&
          specialCount > 0 &&
          specialTextCount > textCount) {
        ///最后一个最大的会放到最后执行，就等待最后一个
        lastDoIndex = i;
      } else if (i == sqls.length - 1) {
        ///没有特殊的话最后一个就是队列最后的
        if (lastDoIndex == null) {
          lastDoIndex = i;
        } else {
          unawaited(db.insertRows(sqls[i]));
        }
      } else {
        unawaited(db.insertRows(sqls[i]));
      }
    }

    ///等待队列中最后的任务执行完就是总耗时
    await db.insertRows(sqls[lastDoIndex]);
    final end = DateTime.now().millisecondsSinceEpoch;
    time = end - start;
    logger.info("完成,耗时: $time 毫秒");
    return;
  }

  String createSqlString(String channelId, String userId) {
    TestDatabaseUtils.messageId += 1;
    return "insert or ignore into $table (channel_id,user_id,message_id,quote_l1,quote_l2,quote_total,recall,pin,guild_id,time,content,deleted,status,localStatus,nonce,unreactive) values ('$channelId','$userId','${TestDatabaseUtils.messageId}',null,null,null,null,null,'189278210867855360',0,null,0,0,5,null,0)";
  }
}
