import 'package:flutter/foundation.dart';
import 'package:im/api/entity/task_bean.dart';
import 'package:im/api/text_chat_api.dart';
import 'package:im/pages/home/json/task_entity.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:pedantic/pedantic.dart';

import 'async_db/async_db.dart';
import 'async_db/async_insert_model.dart';
import 'db.dart';
import 'message_search_table.dart';

class QuoteMessageTable {
  static const table = "QuoteMessage";

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

  static Future<void> createTable(AsyncDB db) async {
    await db.execute("DROP TABLE IF EXISTS $table", isAsync: false);
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
          $columnNonce INTEGER
          )
        ''', isAsync: false);
    await db.execute(
        "CREATE INDEX channel_id_quote_index on"
        " $table ($columnChannelId)",
        isAsync: false);
  }

  static Future checkTable() async {
    await Db.db.select("select * from $table limit 1");
  }

  static Future<void> appendAll(List<MessageEntity> list) async {
    if (list.isEmpty) return;
    //??????????????????????????????????????????????????????????????????????????????
    for (final e in list) {
      final map = e.toQuoteJson();
      await Db.db
          .insert(table, map, conflictAlgorithm: InsertDBConflictType.replace);
    }
  }

  static Future<void> append(MessageEntity message,
      {InsertDBConflictType conflictAlgorithm =
          InsertDBConflictType.replace}) async {
    unawaited(MessageSearchTable.insert(message,
        conflictAlgorithm: conflictAlgorithm));
    final map = message.toQuoteJson();
    await Db.db.insert(table, map, conflictAlgorithm: conflictAlgorithm);
  }

  static Future<MessageEntity> getMessage(String id) async {
    final res = await Db.db.query(table, where: '$columnMessageId = $id');
    if (res.isEmpty) return null;
    return MessageEntity.fromJson(res.single);
  }

  ///???????????????????????????id????????????????????????
  static Future<MessageEntity> getTask(
      String channelId, String messageId, List<TaskBean> undoneTasks) async {
    if (!kIsWeb) {
      final res =
          await Db.db.query(table, where: '$columnMessageId = $messageId');
      if (res != null && res.isNotEmpty) {
        final MessageEntity taskMsg = MessageEntity.fromJson(res.single);
        if (taskMsg != null &&
            taskMsg.content != null &&
            taskMsg.content is TaskEntity) {
          return taskMsg;
        }
      }
    }
    final List<String> messageIdList = [];
    for (final TaskBean item in undoneTasks) {
      if (item.channelId == channelId) {
        ///???????????????messageId??????????????????????????????messageId??????
        if (!messageIdList.contains(item.taskMessageId))
          messageIdList.add(item.taskMessageId);
      }
    }

    if (messageIdList.isEmpty) return null;

    ///?????????????????????????????????????????????
    final List<MessageEntity> remoteMessages =
        await TextChatApi.getBatchMessages(
      channelId,
      [messageIdList.last],
      showDefaultErrorToast: true,
    ).catchError((e) {
      print(e);
      return null;
    });

    if (remoteMessages == null) return null;
    if (!kIsWeb) await appendAll(remoteMessages);

    final MessageEntity first = remoteMessages.firstWhere(
        (e) => e.channelId == channelId && e.messageId == messageId,
        orElse: () => null);

    return first;
  }
}
