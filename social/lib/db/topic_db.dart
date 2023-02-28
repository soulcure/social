import 'package:flutter/foundation.dart';
import 'package:im/db/async_db/async_insert_model.dart';
import 'package:im/db/db.dart';
import 'package:im/db/reaction_table.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/reaction_model.dart';
import 'package:im/pages/home/view/text_chat/items/components/message_reaction.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';

import 'async_db/async_db.dart';
import 'chat_db.dart';

class TopicTable {
  static const tableTopic = "ChatTopic";

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

  ///批量插入消息：isUpdate 是否更新覆盖
  static void append(List<String> messageSqls, Map map, bool isUpdate) {
    if (map[columnQuote1] != null && map[columnQuote1].isNotEmpty) {
      messageSqls.add(Db.db.sqlToInsert(tableTopic, map));
    }
  }

  static Future<void> appendTopic(Map<String, dynamic> map) async {
    if (map[columnQuote1] != null && map[columnQuote1].isNotEmpty) {
      await Db.db.insert(tableTopic, map,
          conflictAlgorithm: InsertDBConflictType.replace);
    }
  }

  static Future<void> createTableTopic(AsyncDB db) async {
    ///如果存在话题详情表，则先删除在创建
    await db.execute("DROP TABLE IF EXISTS $tableTopic", isAsync: false);
    await db.execute('''
        CREATE TABLE $tableTopic (
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

    ///创建 "channel_id" "quote_l1"的联合索引
    await db.execute(
        "CREATE INDEX channel_quote_index on"
        " $tableTopic ($columnChannelId,$columnQuote1)",
        isAsync: false);
  }

  static Future checkTable() async {
    await Db.db.select("select * from $tableTopic limit 1");
  }

  ///sqLite 不支持建表后修改主键，或删除列。所以要修改列的类型，只能采用下面的方式<p>
  ///步骤：1 创建临时表 2 删除消息ID为reject开头的记录;  3 复制数据到临时表
  ///4 删除原表 5 创建原表 6 复制临时表数据到原表 7 删除临时表
  static Future<void> transferChatTopic(Database db) async {
    try {
      const String fields = '''
      $columnChannelId,$columnUserId,$columnGuildId,$columnTime,
      $columnMessageId,$columnContent,$columnDeleted,$columnQuote1,
      $columnQuote2,$columnQuoteTotal,$columnStatus,$columnLocalStatus,
      $columnPin,$columnRecall,$columnReplyMarkup,$columnNonce
      ''';
      await db.execute(
          "INSERT INTO $tableTopic ($fields) select $fields FROM ${ChatTable.table} WHERE $columnQuote1 IS NOT NULL");

      debugPrint('transferChatTopic -- modifyTableColumn success ');
    } catch (e) {
      debugPrint('transferChatTopic -- modifyTableColumn e: ${e.toString()}');
    }
  }

  static Future markDeleted(String messageId) async {
    await Db.db.update(tableTopic, {"deleted": 1},
        where: '$columnMessageId = $messageId');
  }

  static Future markRecalled(String messageId, String recalledBy) async {
    await Db.db.update(tableTopic, {"recall": recalledBy},
        where: '$columnMessageId = $messageId');
  }

  static Future<int> getMessageLengthByQuote(String quoteId) async {
    final res = await Db.db.query(tableTopic,
        where: "$columnQuote1 = '$quoteId' AND $columnDeleted != 1");
    final res2 = await Db.db.query(tableTopic,
        where: '$columnMessageId = $quoteId AND $columnDeleted != 1');
    if (res.isEmpty || res2.isEmpty) return 0;
    return res.length;
  }

  // TODO 可能有性能问题，另外如果查询速度比写入速度慢，就导致读错了
  static Future<int> getAllMessageLengthByQuote(String quoteId) async {
    final res = await Db.db.query(tableTopic,
        where:
            "$columnQuote1 = '$quoteId' AND $columnLocalStatus == 0 AND $columnDeleted == 0");
    return res.length;
  }

  static Future<MessageEntity> getFirstTopicChild(String quoteId) async {
    final res =
        await Db.db.query(tableTopic, where: "$columnQuote1 = '$quoteId'");
    if (res.isEmpty) return null;
    return MessageEntity.fromJson(res.first);
  }

  static Future<List<MessageEntity>> getTopics(MessageEntity message) async {
    final messageId = message.messageId;
    final channelId = message.channelId;
    final where =
        "$columnChannelId = $channelId AND $columnQuote1 = $messageId";

    final res = await Db.db.query(tableTopic, where: where);
    if (res.isEmpty) return const [];
    // final batch = Db.db.batch();
    final List<List<Map>> array = [];
    for (var i = 0; i < res.length; i++) {
      final subWhere =
          "${ReactionTable.columnMsgId} = ${res[i][columnMessageId]}";
      final result = await Db.db.query(ReactionTable.table, where: subWhere);
      array.add(result);
    }
    // final List reactions = await batch.commit();
    final List reactions = array;
    final List<Map<String, dynamic>> newMap = [];
    for (var i = 0; i < res.length; i++) {
      newMap.add({...res[i], 'reactions': reactions[i]});
    }
    final List<MessageEntity> list = newMap.map((e) {
      return MessageEntity.fromJson(e);
    }).toList();

    if (message.reactionModel == null ||
        message.reactionModel.reactions == null ||
        message.reactionModel.reactions.isEmpty) {
      final top = await Db.db.query(ReactionTable.table,
          where: "${ReactionTable.columnMsgId} = $messageId");

      List<ReactionEntity> reactionList = [];
      if (top != null && top.isNotEmpty) {
        reactionList = top.map((e) => ReactionEntity.fromMap(e)).toList();
      }
      message.reactionModel = ReactionModel(
          messageId: messageId, channelId: channelId, actions: reactionList);
    }

    if (list.isNotEmpty && list[0].messageId != message.messageId) {
      ///添加入口id
      list.insert(0, message);
    }
    return list;
  }
}
