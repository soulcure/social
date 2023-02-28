import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:im/api/entity/reply_markup.dart';
import 'package:im/db/db.dart';
import 'package:im/db/message_card_key_table.dart';
import 'package:im/db/quote_message_db.dart';
import 'package:im/db/reaction_table.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/json/du_entity.dart';
import 'package:im/pages/home/json/message_card_entity.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/in_memory_db.dart';
import 'package:im/utils/im_utils/channel_util.dart';
import 'package:pedantic/pedantic.dart';
import 'package:snowflake/snowflake.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';

import 'async_db/async_db.dart';
import 'async_db/async_insert_model.dart';
import 'message_search_table.dart';
import 'topic_db.dart';

class ChatTable {
  static const pageSize = 50;
  static const table = "Chat";

  static const columnChannelId = "channel_id";
  static const columnUserId = "user_id";
  static const columnGuildId = "guild_id";
  static const columnTime = "time";
  static const columnMessageId = "message_id";
  static const columnContent = "content";
  static const columnDeleted = "deleted";
  static const columnQuote1 = "quote_l1";
  static const columnQuote2 = "quote_l2";
  static const columnQuoteTotal = "quote_total";
  static const columnStatus = "status";
  static const columnLocalStatus = "localStatus";
  static const columnPin = "pin";
  static const columnRecall = "recall";
  static const columnReplyMarkup = "reply_markup";
  static const columnNonce = "nonce";
  static const columnUnreactive = "unreactive";

  /// sqfLite插件channel
  static const MethodChannel sqfLiteChannel =
      MethodChannel('com.tekartik.sqflite');

  ///批量插入消息：isUpdate 是否更新覆盖
  static Future<void> appendAll(List<MessageEntity> data,
      {bool isUpdate = false, bool hasReaction = true}) async {
    if (kIsWeb || data.isEmpty) return;

    ///todo 投票刷新消息不保持数据库
    final list = data.where((e) => e.content is! DuEntity).toList();

    MessageEntity lastCompleteMessage;
    MessageEntity lastVisibleMessage;

    final List<String> sqls = [];

    // await Db.db.transaction((txn) async {
    //   unawaited(MessageSearchTable.batchInsert(txn, list, isUpdate: isUpdate));
    //   final messageBatch = txn.batch();
    //   final messageCardKeyBatch = txn.batch();
    for (final e in list) {
      if (MessageEntity.messageIsNotVisible(e)) continue;

      ///获取最后一条完整和可见消息ID
      if (!e.isDeleted) {
        if (!e.isIncomplete &&
            (lastCompleteMessage == null ||
                lastCompleteMessage.messageIdBigInt < e.messageIdBigInt)) {
          lastCompleteMessage = e;
        }
        if (lastVisibleMessage == null ||
            lastVisibleMessage.messageIdBigInt < e.messageIdBigInt) {
          lastVisibleMessage = e;
        }
      }
      final map = e.toJson();
      final reactions = map['reactions'];
      processInsertMap(map);

      if (isUpdate) {
        sqls.add(Db.db.sqlToInsert(table, map));
        // messageBatch.insert(table, map,
        //     conflictAlgorithm: ConflictAlgorithm.replace);
      } else {
        sqls.add(Db.db.sqlToInsert(table, map));
        // messageBatch.insert(table, map);
      }
      TopicTable.append(sqls, map, isUpdate);

      if (hasReaction) {
        unawaited(_insertReactions(sqls, e.messageId, reactions));
      }
      if (e.content is MessageCardEntity) {
        final keys = (e.content as MessageCardEntity).keys;
        if (keys == null) continue;
        for (final entry in keys.entries) {
          sqls.add(Db.db.sqlToInsert(MessageCardKeyTable.table, {
            MessageCardKeyTable.columnChannelId: e.channelId,
            MessageCardKeyTable.columnKey: entry.key,
            MessageCardKeyTable.columnMessageId: e.messageId,
            MessageCardKeyTable.columnUserId: entry.value.userId,
            MessageCardKeyTable.columnMe: entry.value.me ? 1 : 0,
            MessageCardKeyTable.columnCount: entry.value.count,
          }));
          // messageCardKeyBatch.insert(
          //   MessageCardKeyTable.table,
          //   {
          //     MessageCardKeyTable.columnChannelId: e.channelId,
          //     MessageCardKeyTable.columnKey: entry.key,
          //     MessageCardKeyTable.columnMessageId: e.messageId,
          //     MessageCardKeyTable.columnUserId: entry.value.userId,
          //     MessageCardKeyTable.columnMe: entry.value.me ? 1 : 0,
          //     MessageCardKeyTable.columnCount: entry.value.count,
          //   },
          //   conflictAlgorithm: ConflictAlgorithm.replace,
          // );
        }
      }
    }

    // await messageCardKeyBatch.commit(noResult: true, continueOnError: true);
    // await messageBatch.commit(noResult: true, continueOnError: true);
    // });
    await Db.db.insertRows(sqls, weight: 100);

    if (lastCompleteMessage != null) {
      ChannelUtil.instance.updateLastCompleteMessageIdBox(
          lastCompleteMessage.channelId, lastCompleteMessage.messageIdBigInt);
    }
    if (lastVisibleMessage != null) {
      ChannelUtil.instance.updateLastVisibleMessageIdBox(
          lastVisibleMessage.channelId, lastVisibleMessage.messageIdBigInt);
    }
  }

  static Future<void> _insertReactions(
      List<String> sqlList, String messageId, List<Map> reactions) async {
    if (messageId != null && reactions != null && reactions.isNotEmpty) {
      await ReactionTable.insertBatch(sqlList, messageId, reactions);
    }
  }

  ///使用sql批量插入消息
  static Future<void> appendAllBySql(List<String> sqlList) async {
    if (kIsWeb) return;

    if (sqlList.isEmpty) return;
    final length = sqlList.length;
    //限制sql语句每次最多50万条，防止sqlite执行时卡死
    // const int blockSize = 10;
    const int blockSize = 50 * 10000;
    var start = 0;
    var end = min(length, blockSize);
    List<String> blockList;
    while (start < end) {
      blockList = sqlList.sublist(start, end);
      await Db.db.insertRows(blockList).catchError((e) {
        throw e;
      });
      // sqfLiteBatchWrite(blockList);
      start = end;
      end = min(length, end + blockSize);
    }
  }

  static Future<void> append(MessageEntity message) async {
    ///不可见消息 不保存到消息表中
    if (MessageEntity.messageIsNotVisible(message)) return;
    unawaited(MessageSearchTable.insert(message));

    final map = message.toJson();
    processInsertMap(map);
    await Db.db
        .insert(table, map, conflictAlgorithm: InsertDBConflictType.replace);
    if (!message.isDeleted) {
      if (!message.isIncomplete) {
        ChannelUtil.instance.updateLastCompleteMessageIdBox(
            message.channelId, message.messageIdBigInt);
      }

      ///发送成功才更新 LastVisibleMessageId
      ///原因: 本地生成的ID可能比服务端返回大,导致设置loadMoreState状态出错
      if (message.content?.messageState?.value == MessageState.sent) {
        ChannelUtil.instance.updateLastVisibleMessageIdBox(
            message.channelId, message.messageIdBigInt);
      }
    }
    unawaited(TopicTable.appendTopic(map));
  }

  static void processInsertMap(Map<String, dynamic> map) {
    // 不保存的字段
    map.remove("action");
    map.remove("type");
    map.remove("seq");
    map.remove("reactions");
    if (map[columnReplyMarkup] != null) {
      map[columnReplyMarkup] = jsonEncode(map[columnReplyMarkup]);
    } else {
      map.remove(columnReplyMarkup);
    }

    ///fix: 移除私聊desc新增的字段
    map.remove("desc");
  }

  static Future<void> createTable(AsyncDB db, {String pre = ''}) async {
    await db.execute("DROP TABLE IF EXISTS $pre$table", isAsync: false);
    await db.execute('''
        CREATE TABLE $pre$table (
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
        ''', isAsync: false);
    if (pre.isEmpty) {
      await db.execute(
          "CREATE INDEX channel_id_time_index on"
          " $table ($columnChannelId)",
          isAsync: false);
    }
  }

  static Future checkTable() async {
    await Db.db.select("select * from $table limit 1");
  }

  ///sqLite 不支持建表后修改主键，或删除列。所以要修改列的类型，只能采用下面的方式<p>
  ///步骤：1 创建临时表 2 删除消息ID为reject开头的记录;  3 复制数据到临时表
  ///4 删除原表 5 创建原表 6 复制临时表数据到原表 7 删除临时表
  static Future<void> modifyTableColumn(AsyncDB db) async {
    try {
      await db.execute("DROP TABLE IF EXISTS tmp_$table");
      await createTable(db, pre: 'tmp_');
      await db.execute(
          // ignore: avoid_escaping_inner_quotes
          "DELETE FROM $table WHERE $columnMessageId LIKE \"reject%\"");
      await db.execute("alter table $table add column $columnNonce INTEGER");
      await db.execute("INSERT INTO tmp_$table SELECT * FROM $table");
      await db.execute("DROP TABLE IF EXISTS $table");
      await createTable(db);
      await db.execute("INSERT INTO $table SELECT * FROM tmp_$table");
      await db.execute("DROP TABLE IF EXISTS tmp_$table");
    } catch (e) {
      debugPrint('getChat -- modifyTableColumn e: $e');
    }
  }

  /// curFirstId:频道消息列表中的第一条消息ID
  /// before:是否向上查询,默认为true
  static Future<List<MessageEntity>> getChatHistory(
      String channelId, BigInt curFirstId,
      {bool before = true}) async {
    // debugPrint('getChat query 1: $channelId');
    String where = "$columnChannelId = $channelId";
    if (curFirstId != null) {
      where += ' AND $columnMessageId ${before ? '<' : '>'} $curFirstId';
    }
    // print("read local chat table: ${where.toString()}");
    final list = await Db.db.query(table,
        where: where,
        orderBy: '$columnMessageId ${before ? 'DESC' : 'ASC'}', // 按消息ID排序
        limit: pageSize,
        weight: 10);
    final reactionsMap = await queryMessageReactions(list);
    final List<Map<String, dynamic>> newMap = [];
    String msgId;
    for (var i = 0; i < list.length; i++) {
      msgId = list[i][columnMessageId].toString();
      newMap.add({...list[i], 'reactions': reactionsMap[msgId]});
    }
    return newMap.map((e) => MessageEntity.fromJson(e)).toList();
  }

  ///一次性查询消息list的所有表态，减少数据库操作次数
  static Future<Map<String, List<Map<String, dynamic>>>> queryMessageReactions(
      List<Map<String, dynamic>> messageList) async {
    final Map<String, List<Map<String, dynamic>>> listMap = {};
    final idSb = StringBuffer();
    var length = messageList.length;
    for (var i = 0; i < length; i++) {
      idSb.write("'${messageList[i][columnMessageId]}'");
      if (i != length - 1) {
        idSb.write(",");
      }
    }

    final reactionList =
        await Db.db.select("select * from ${ReactionTable.table} where "
            "${ReactionTable.columnMsgId} in (${idSb.toString()})");
    if (reactionList == null || reactionList.isEmpty) return listMap;
    length = reactionList.length;
    String msgId;
    for (var i = 0; i < length; i++) {
      msgId = reactionList[i][ReactionTable.columnMsgId].toString();
      if (listMap.containsKey(msgId)) {
        listMap[msgId].add(reactionList[i]);
      } else {
        listMap[msgId] = [reactionList[i]];
      }
    }
    return listMap;
  }

  /// 获取messageId前后的历史消息（50条）
  static Future<List<MessageEntity>> getMessageNearHistory(
      String channelId, String messageId,
      {bool before = true}) async {
    var where = "$columnChannelId = $channelId AND $columnMessageId "
        "${before ? '<=' : '>='} $messageId";
    final List<Map<String, dynamic>> list = [];

    //查询消息的上下附近的消息
    list.addAll(await Db.db.query(
      table,
      where: where,
      orderBy: '$columnMessageId ${before ? 'DESC' : 'ASC'}',
      limit: 5,
    ));

    final leftLimit = pageSize - list.length;
    where =
        "$columnChannelId = $channelId AND $columnMessageId ${before ? '>' : '<'}  $messageId";
    list.addAll(await Db.db.query(
      table,
      where: where,
      orderBy: '$columnMessageId ${before ? 'ASC' : 'DESC'}',
      limit: leftLimit,
    ));

    final reactionsMap = await queryMessageReactions(list);
    final List<Map<String, dynamic>> newMap = [];
    String msgId;
    for (var i = 0; i < list.length; i++) {
      msgId = list[i][columnMessageId].toString();
      newMap.add({...list[i], 'reactions': reactionsMap[msgId]});
    }
    return newMap.map((e) => MessageEntity.fromJson(e)).toList();
  }

  ///查询最后一条完整消息
  static Future<MessageEntity> getLastCompleteMessage(String channelId) async {
    final where =
        "$columnChannelId = $channelId AND $columnLocalStatus != ${MessageLocalStatus.incomplete.index} "
        " AND $columnDeleted == 0 ";
    final list = await Db.db.query(
      table,
      where: where,
      orderBy: '$columnMessageId DESC',
      limit: 1,
    );
    if (list.isNotEmpty) {
      return MessageEntity.fromJson(list.first);
    }
    return null;
  }

  /// 搜索本地服务器内文本消息：
  static Future<List<MessageEntity>> searchGuildChatHistory(
    String guildId, {
    String keyword,
    BigInt lastId,
    int size,
  }) async {
    String where =
        "$columnGuildId = $guildId AND $columnDeleted = 0 AND $columnRecall ISNULL";
    if (lastId != null) {
      where += ' AND $columnMessageId < $lastId';
    }
    if (keyword != null && keyword.isNotEmpty) {
      // 只搜索文本、富文本、圈子分享消息
      where +=
          ' AND ($columnContent LIKE \'%"type":"text","text":"%$keyword%"%\'';
      where += ' OR $columnContent LIKE \'%"type":"richText",%"%$keyword%"%\'';
      // where +=
      //     ' OR $columnContent LIKE \'%"type":"circleShareEntity",%"title":"%$keyword%"%\'';
      where += ')';
      where += ' COLLATE NOCASE'; // 不区分大小写
    }
    debugPrint('getChat searchGuild where: $where');
    final maps = await Db.db.query(
      table,
      where: where,
      limit: size,
      orderBy: '$columnMessageId DESC', // 按消息发送时间降序
    );
    return maps.map((e) => MessageEntity.fromJson(e)).toList();
  }

  ///删除频道的消息表，相关引用表、搜索表的记录
  static Future clearChatHistory(String channelId) async {
    final deleteSql = getDeleteSql(table, {columnChannelId: channelId});
    //引用表、搜索表 也要一起删除， 表态表外键关联消息表，级联删除
    final deleteSql1 = getDeleteSql(QuoteMessageTable.table,
        {QuoteMessageTable.columnChannelId: channelId});
    final deleteSql2 = getDeleteSql(MessageSearchTable.table,
        {MessageSearchTable.columnChannel: channelId});
    await Db.db.deleteArray([deleteSql, deleteSql1, deleteSql2]);
    // sqfLiteBatchWrite([deleteSql, deleteSql1, deleteSql2]);
  }

  ///批量删除频道的消息记录
  static Future batchClearChatHistory(
      String guildId, Iterable<String> channelIds) async {
    ///加入或者退出服务台前先判断HIVEDB里面是否有这个服务台ID，如果没有就不需要清除SQLITE里面的数据。在加入服务台时这个方法几乎不会走，只是为了保险。
    if (guildId != null && !Db.guildBox.containsKey(guildId)) return;
    logger.info("清除数据库残留数据开始");
    String ids;
    final list = channelIds.toList();
    final length = channelIds.length;
    //限制每次最多50个频道ID
    const blockSize = 50;
    var start = 0;
    var end = min(length, blockSize);
    List<String> blockList;
    while (start < end) {
      blockList = list.sublist(start, end);
      ids = blockList.map((e) => "'$e'").join(',');
      //一起删除: 引用表、搜索表
      await Db.db.deleteArray([
        "delete from $table where $columnChannelId in ($ids)",
        "delete from ${QuoteMessageTable.table} where ${QuoteMessageTable.columnChannelId} in ($ids)",
        "delete from ${MessageSearchTable.table} where ${MessageSearchTable.columnChannel} in ($ids)"
      ]);
      start = end;
      end = min(length, end + blockSize);
    }
    logger.info("清除数据库残留数据结束");
  }

  static Future deletePermanently(String messageId,
      {bool hasQuote = false}) async {
    final deleteSql = getDeleteSql(table, {columnMessageId: messageId});

    final list = [deleteSql];

    if (hasQuote) {
      final deleteSqlTopic =
          getDeleteSql(TopicTable.tableTopic, {columnMessageId: messageId});
      list.add(deleteSqlTopic);
    }
    await Db.db.deleteArray(list);
  }

  static Future markDeleted(String messageId) async {
    await Db.db
        .update(table, {"deleted": 1}, where: '$columnMessageId = $messageId');
    await MessageSearchTable.markDeleted(messageId);
    await TopicTable.markDeleted(messageId);
  }

  static Future markRecalled(String messageId, String recalledBy) async {
    await Db.db.update(table, {"recall": recalledBy},
        where: '$columnMessageId = $messageId');
    await MessageSearchTable.markRecalled(messageId, recalledBy);
    await TopicTable.markRecalled(messageId, recalledBy);
  }

  ///1.5.0以前版本使用，后续删除
  static Future<BigInt> getLastMessageId(String channelId) async {
    if (kIsWeb) {
      try {
        /// web 重连时还是要去内存中的最后一条消息
        return InMemoryDb.getMessageList(channelId)?.lastMessageId;
      } catch (e) {
        return null;
      }
    }

    final result = await Db.db.query(table,
        where: "$columnChannelId = $channelId",
        orderBy: "$columnMessageId DESC",
        limit: 1);
    if (result.isEmpty) return null;
    try {
      return BigInt.from(result.single[columnMessageId]);
    } catch (e) {
      return null;
    }
  }

  static Future<MessageEntity> getMessage(String id) async {
    final res = await Db.db.query(table, where: '$columnMessageId = $id');
    if (res.isEmpty) return null;
    return MessageEntity.fromJson(res.single);
  }

  static String get _getDisplayableWhereString => """
  $columnDeleted == 0 
  AND (
        $columnLocalStatus = ${MessageLocalStatus.normal.index}
        OR $columnLocalStatus = ${MessageLocalStatus.incomplete.index}
      )
  """;

  /// 获取可正常显示的消息
  /// 非撤回、非删除、 localStatus = normal | incomplete
  static Future<MessageEntity> getDisplayableMessage(String id) async {
    final res = await Db.db.query(table,
        where: '$columnMessageId = $id AND $_getDisplayableWhereString');
    if (res.isEmpty) return null;
    return MessageEntity.fromJson(res.single);
  }

  static void modifyMessage(
    String messageId, {
    MessageContentEntity content,
    ReplyMarkup replyMarkup,
  }) {
    Db.db.update(
        table,
        {
          columnContent: jsonEncode(content.toJson()),
          columnReplyMarkup:
              replyMarkup == null ? "" : jsonEncode(replyMarkup.toJson()),
        },
        where: "$columnMessageId = $messageId");
  }

  ///修改原消息的localStatus，比如：机器人修改消息
  static void modifyMessageLocalStatus(
      String messageId, MessageLocalStatus localStatus) {
    Db.db.update(table, {columnLocalStatus: localStatus.index},
        where: "$columnMessageId = $messageId");
  }

  static void updatePin(String messageId, String pin) {
    Db.db.update(table, {columnPin: pin},
        where: "$columnMessageId = $messageId");
    Db.db.update(TopicTable.tableTopic, {TopicTable.columnPin: pin},
        where: "${TopicTable.columnMessageId} = $messageId");
  }

  static idWorker worker;

  //服务端的起始时间 | 已和服务端确认用了东八区的时间,自测时间戳用0时区有问题.
  static final idStartDate =
      DateTime.parse('2019-08-08T08:08:08+08:00').millisecondsSinceEpoch;

  ///雪花算法生成本地的消息ID
  static String generateLocalMessageId(BigInt preId) {
    if (preId != null) {
      return (preId + BigInt.from(1)).toString();
    }
    //30，30：是服务端的机器和数据中心标识参数
    worker ??= idWorker(config(30, 30, idStartDate));
    final msId = worker.generate().toString();
    return msId;
  }

  ///解析雪花消息ID，获取时间
  static int getTimeByMessageId(BigInt messageId) {
    var idInt = messageId.toInt();
    idInt = idInt >> 22;
    idInt += idStartDate;
    // final time = DateTime.fromMillisecondsSinceEpoch(idInt);
    // debugPrint('getChat getTimeByMessageId: $messageId - $time');
    return idInt;
  }

  // 删除置顶消息和引用的消息
  static Future deleteStickAndQuoteMessage(Database db) async {
    final num = await db.delete(table,
        where:
            '$columnLocalStatus = ${MessageLocalStatus.sticky.index} or $columnLocalStatus = ${MessageLocalStatus.quote.index}');
    logger.info('从聊天表删除置顶和引用消息：$num 条');
  }

  ///专门用于写入的数据库方法，单独线程
  // static Future<void> sqfLiteBatchWrite(List<String> sqlList) async {
  //   if (kIsWeb) return;
  //
  //   ///fix for macos 此处报错
  //   try {
  //     await sqfLiteChannel
  //         .invokeMethod("batchWrite", {"path": Db.db.dbPath, "sql": sqlList});
  //   } catch (e) {
  //     print(e);
  //   }
  // }
}
